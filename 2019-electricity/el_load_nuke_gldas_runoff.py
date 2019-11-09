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
import datetime, calendar

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

startYear = 2007
endYear = 2018

startYearEntsoe = 2015
endYearEntsoe = 2018

startYearNuke = 2007
endYearNuke = 2018

shp = shapefile.Reader('%s/basins/c_analysb.shp'%dataDirDiscovery)
basins = shp.shapes()
basinRecords = shp.records()

nukeLatLon = np.genfromtxt('%s/script-data/nuke-lat-lon.csv'%dataDirDiscovery, delimiter=',', skip_header=0)
entsoeLatLon = np.genfromtxt('%s/script-data/entsoe-lat-lon-nonforced.csv'%dataDirDiscovery, delimiter=',', skip_header=0)

gldasQs = []
gldasQsb = []

for year in range(startYear, endYear+1):
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
                
        if len(gldasQs) == 0:
            gldasQs = tmpMeanQs[['Qs']]
            gldasQsb = tmpMeanQsb[['Qsb']]
        else:
            gldasQs = xr.concat([gldasQs, tmpMeanQs[['Qs']]], dim='time')
            gldasQsb = xr.concat([gldasQsb, tmpMeanQsb[['Qsb']]], dim='time')

print('loading selected data')
gldas_qsAcc = gldasQs.Qs.where(abs(gldasQs['Qs']) < 5e4) * 3600 * 24
gldas_qsAcc.load()
gldas_qsbAcc = gldasQsb.Qsb.where(abs(gldasQsb['Qsb']) < 5e4) * 3600 * 24
gldas_qsbAcc.load()

print('mapping monthly gldas onto daily for entsoe')

# find # of days in time period
nDays = 0
for year in range(startYearEntsoe, endYearEntsoe+1):
    for month in range(1, 12+1):
        curMonthRange = calendar.monthrange(year, month)
        nDays += curMonthRange[1]
        
qTimeSeries = np.full([entsoeLatLon.shape[0]+3, nDays], np.nan)
for p in range(entsoeLatLon.shape[0]):
    qsTmp = gldas_qsAcc.sel(lat=entsoeLatLon[p,1], lon=entsoeLatLon[p,2], method='nearest')
    qsbTmp = gldas_qsbAcc.sel(lat=entsoeLatLon[p,1], lon=entsoeLatLon[p,2], method='nearest')
    
    print('plant %d of %d'%(p+1, entsoeLatLon.shape[0]))
    
    dayInd = 0
    for year in range(startYearEntsoe, endYearEntsoe+1):
        for month in range(1, 12+1):
            curMonthRange = calendar.monthrange(year, month)
            
            tmpQs = qsTmp.where((qsTmp['time.month'] == month) & (qsTmp['time.year'] == year), drop=True)
            tmpQsb = qsbTmp.where((qsbTmp['time.month'] == month) & (qsbTmp['time.year'] == year), drop=True)
            for day in range(0, curMonthRange[1]):  
                
                # if on first plant, set rows 0-2 to be the year/month/day time series
                if p == 0:
                    qTimeSeries[0, dayInd] = year
                    qTimeSeries[1, dayInd] = month
                    qTimeSeries[2, dayInd] = day+1
                    
                if tmpQs.size > 0 and tmpQsb.size > 0:
                    qTimeSeries[p+3, dayInd] = tmpQs.values[0] + tmpQsb.values[0]
                dayInd += 1
                
np.savetxt('%s/script-data/entsoe-qs-gldas-all-nonforced.csv'%dataDirDiscovery, qTimeSeries, delimiter = ',', fmt = '%f')






# find # of months in time period
nMonths = 0
for year in range(startYearNuke, endYearNuke+1):
    for month in range(1, 12+1):
        nMonths += 1
        
qTimeSeriesNuke = np.full([nukeLatLon.shape[0], nMonths+1], np.nan)
for p in range(nukeLatLon.shape[0]):
    qsTmp = gldas_qsAcc.sel(lat=nukeLatLon[p,1], lon=nukeLatLon[p,2], method='nearest')
    qsbTmp = gldas_qsbAcc.sel(lat=nukeLatLon[p,1], lon=nukeLatLon[p,2], method='nearest')
    
    print('plant %d of %d'%(p+1, nukeLatLon.shape[0]))
    
    monthInd = 1
    qTimeSeriesNuke[p,0] = nukeLatLon[p,0]
    for year in range(startYearNuke, endYearNuke+1):
        for month in range(1, 12+1):
            curMonthRange = calendar.monthrange(year, month)
            
            tmpQs = qsTmp.where((qsTmp['time.month'] == month) & (qsTmp['time.year'] == year), drop=True)
            tmpQsb = qsbTmp.where((qsbTmp['time.month'] == month) & (qsbTmp['time.year'] == year), drop=True)
            if tmpQs.size > 0 and tmpQsb.size > 0:
                qTimeSeriesNuke[p, monthInd] = tmpQs.values[0] + tmpQsb.values[0]
            monthInd += 1
np.savetxt('%s/script-data/nuke-qs-gldas-all.csv'%dataDirDiscovery, qTimeSeriesNuke, delimiter = ',', fmt = '%f')