# -*- coding: utf-8 -*-
"""
Created on Mon Aug 19 18:53:44 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import pickle, gzip
import sys, os, re
import geopy.distance
import calendar 
import csv
import xarray as xr
import rasterio
import shapefile
import shapely.geometry as geometry
import datetime


#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

shp = shapefile.Reader('%s/basins/c_analysb.shp'%dataDirDiscovery)
basins = shp.shapes()
basinRecords = shp.records()

nukeLatLon = np.genfromtxt('%s/script-data/nuke-lat-lon.csv'%dataDirDiscovery, delimiter=',', skip_header=0)
entsoeLatLon = np.genfromtxt('%s/script-data/entsoe-lat-lon.csv'%dataDirDiscovery, delimiter=',', skip_header=0)
plantLatLon = np.concatenate((nukeLatLon,entsoeLatLon),axis=0)

gldasQs = []
gldasQsb = []
gldasQsm = []

for year in range(1979, 2018+1):
    for month in range(1, 12+1):
        curDate = datetime.datetime(year, month, 1, 0, 0, 0)
        print('loading %d/%d'%(year, month))
        tmpVic = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/GLDAS/noah-1-1979-2018/GLDAS_NOAH10_M.A%d%02d.001.grb.SUB.nc4'%(year, month), \
                                 decode_times=True, decode_cf=False)
        tmpNoah = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/GLDAS/noah-1-1979-2018/GLDAS_NOAH10_M.A%d%02d.001.grb.SUB.nc4'%(year, month), \
                                  decode_times=True, decode_cf=False)
        tmpMosaic = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/GLDAS/noah-1-1979-2018/GLDAS_NOAH10_M.A%d%02d.001.grb.SUB.nc4'%(year, month), \
                                    decode_times=True, decode_cf=False)
        tmpVic['time'] = [curDate]
        tmpNoah['time'] = [curDate]
        tmpMosaic['time'] = [curDate]
        
        tmpMeanQs = (tmpVic[['Qs']] + tmpNoah[['Qs']] + tmpMosaic[['Qs']]) / 3.0
        tmpMeanQsb = (tmpVic[['Qsb']] + tmpNoah[['Qsb']] + tmpMosaic[['Qsb']]) / 3.0
        tmpMeanQsm = (tmpVic[['Qsm']] + tmpNoah[['Qsm']] + tmpMosaic[['Qsm']]) / 3.0
        
        if len(gldasQs) == 0:
            gldasQs = tmpMeanQs[['Qs']]
            gldasQsb = tmpMeanQsb[['Qsb']]
            gldasQsm = tmpMeanQsm[['Qsm']]
        else:
            gldasQs = xr.concat([gldasQs, tmpMeanQs[['Qs']]], dim='time')
            gldasQsb = xr.concat([gldasQsb, tmpMeanQsb[['Qsb']]], dim='time')
            gldasQsm = xr.concat([gldasQsm, tmpMeanQsm[['Qsm']]], dim='time')
        

gldas_qsAcc = gldasQs.Qs.where(gldasQs['Qs'] != -9999.)
gldas_qsbAcc = gldasQsb.Qsb.where(gldasQsb['Qsb'] != -9999.)
gldas_qsmAcc = gldasQsm.Qsm.where(gldasQsm['Qsm'] != -9999.)

# def is_ja(month):
#     return (month == 7) | (month == 8)

# qsAcc_ja = gldasNoaa_qsAcc.sel(time=is_ja(gldasNoaa_qsAcc['time.month']))
# qsbAcc_ja = gldasNoaa_qsbAcc.sel(time=is_ja(gldasNoaa_qsbAcc['time.month']))
# qsmAcc_ja = gldasNoaa_qsmAcc.sel(time=is_ja(gldasNoaa_qsmAcc['time.month']))

qs_ja = gldas_qsAcc + gldas_qsbAcc + gldas_qsmAcc

# long-term summertime mean runoff
qsMean_ja = qs_ja.mean(dim='time')

lats = qs_ja.lat.values
lons = qs_ja.lon.values

if os.path.isfile('%s/script-data/basin-masks.dat'%dataDirDiscovery):
    with gzip.open('%s/script-data/basin-masks.dat'%dataDirDiscovery, 'rb') as f:
        basinMasks = pickle.load(f)
else:
    basinMasks = np.full([len(lats), len(lons), plantLatLon.shape[0]], False)
    basinInds = np.full([plantLatLon.shape[0]], np.nan)

    for p in range(plantLatLon.shape[0]):    
        print('processing plant %d of %d'%(p, plantLatLon.shape[0]))
        pLat = plantLatLon[p,1]
        pLon = plantLatLon[p,2]
        
        # find basin for this plant
        plantBasinId = -1
        for i in range(len(basins)):
            boundary = basins[i]
            if geometry.Point(pLon, pLat).within(geometry.shape(boundary)):
                print('building basin mask')
                plantBasinId = i
                basinInds[p] = i

                minLon, minLat, maxLon, maxLat = boundary.bbox
                bounding_box = geometry.box(minLon, minLat, maxLon, maxLat)

                for xInd,x in enumerate(lats):
                    for yInd,y in enumerate(lons):
                        pt = geometry.Point(y, x)
                        if bounding_box.contains(pt):
                            basinMasks[xInd, yInd, p] = pt.within(geometry.shape(boundary))
                        else:
                            basinMasks[xInd, yInd, p] = False
                            
#     for p in range(plantLatLon.shape[0]):
#         basinMasks[:, :, p] = np.flipud(basinMasks[:, :, p])

    with gzip.open('%s/script-data/basin-masks.dat'%dataDirDiscovery, 'wb') as f:
        pickle.dump(basinMasks, f)

# loading runoff data
print('loading gldas (qs)...')
qs_ja.load()
print('loading gldas (qs mean)')
qsMean_ja.load()

plantYearRangeEntsoe = [2015,2018]    
plantYearRangeNuke = [2007,2018]

numDaysEntsoe = 0
for y in range(plantYearRangeEntsoe[0],plantYearRangeEntsoe[1]+1):
    for m in range(1, 12+1):
        curMonthRange = calendar.monthrange(y,m) 
        for d in range(0, curMonthRange[1]):
            numDaysEntsoe += 1

numDaysNuke = 0
for y in range(plantYearRangeNuke[0],plantYearRangeNuke[1]+1):
    for m in range(1, 12+1):
        curMonthRange = calendar.monthrange(y,m) 
        for d in range(0, curMonthRange[1]):
            numDaysNuke += 1

qsAnomTimeSeriesEntsoe = np.full([29, numDaysEntsoe], np.nan)
qsAnomTimeSeriesNuke = np.full([66, numDaysNuke+1], np.nan)

nukePlantId = 0
entsoePlantId = 0

# load runoff for each basin
for b in range(basinMasks.shape[2]):
    
    pId = plantLatLon[b,0]
    
    print('building time series for plant %d'%b)
    
    curQs = qs_ja.where(basinMasks[:, :, b])
    curQsMean = qsMean_ja.where(basinMasks[:, :, b])
    curQsAnomTimeSeries = curQs.sum(dim='lat').sum(dim='lon') / curQsMean.sum(dim='lat').sum(dim='lon')
    
    # all the years, months, days that we need qs values for (2007-2018 for nuke, 2015-2018 for entsoe)
    entsoePlant = False
    nukePlant = False
    if plantLatLon[b, 0] < 50:
        plantYearRange = plantYearRangeEntsoe
        entsoePlant = True
    else:
        plantYearRange = plantYearRangeNuke
        nukePlant = True
        
    yearRange = []
    monthRange = []
    dayRange = []

    dayInd = 0
    for y in range(plantYearRange[0],plantYearRange[1]+1):
        for m in range(1, 12+1):
            curMonthRange = calendar.monthrange(y,m) 
            tmp = curQsAnomTimeSeries.where((curQsAnomTimeSeries['time.month'] == m) & (curQsAnomTimeSeries['time.year'] == y), drop=True)
            
            if tmp.size == 0:
                tmp = np.nan
            
            for d in range(0, curMonthRange[1]):
                yearRange.append(y)
                monthRange.append(m)
                dayRange.append(d+1)
                    
                if entsoePlant:
                    qsAnomTimeSeriesEntsoe[entsoePlantId, dayInd] = tmp
                elif nukePlant:
                    qsAnomTimeSeriesNuke[nukePlantId, dayInd] = tmp
                
                dayInd += 1
    
    yearRange = np.array(yearRange)
    monthRange = np.array(monthRange)
    dayRange = np.array(dayRange)
    
    if entsoePlant: entsoePlantId += 1
    if nukePlant: 
        qsAnomTimeSeriesNuke[nukePlantId, 0] = pId
        nukePlantId += 1


# write runoff data to file
np.savetxt("%s/script-data/nuke-qs-gldas-basin-avg.csv"%dataDirDiscovery, qsAnomTimeSeriesNuke, delimiter=",", fmt='%f')

yearHeader = []
monthHeader = []
dayHeader = []
# gen dates for entsoe data
for y in range(2015,2018+1):
    for m in range(1,12+1):
        curMonthRange = calendar.monthrange(y,m) 
        for d in range(0, curMonthRange[1]):
            yearHeader.append(y)
            monthHeader.append(m)
            dayHeader.append(d+1)

yearHeader = np.array(yearHeader)
monthHeader = np.array(monthHeader)
dayHeader = np.array(dayHeader)

qsAnomTimeSeriesEntsoe = np.insert(qsAnomTimeSeriesEntsoe, 0, dayHeader, axis=0)
qsAnomTimeSeriesEntsoe = np.insert(qsAnomTimeSeriesEntsoe, 0, monthHeader, axis=0)
qsAnomTimeSeriesEntsoe = np.insert(qsAnomTimeSeriesEntsoe, 0, yearHeader, axis=0)
np.savetxt("%s/script-data/entsoe-qs-gldas-basin-avg.csv"%dataDirDiscovery, qsAnomTimeSeriesEntsoe, delimiter=",", fmt='%f')





