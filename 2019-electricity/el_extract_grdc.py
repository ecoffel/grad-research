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
import shapefile
import shapely.geometry as geometry


#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data'
dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

shp = shapefile.Reader('%s/basins/c_analysb.shp'%dataDirDiscovery)
basins = shp.shapes()
basinRecords = shp.records()

nukeLatLon = np.genfromtxt('%s/script-data/nuke-lat-lon.csv'%dataDirDiscovery, delimiter=',', skip_header=0)
entsoeLatLon = np.genfromtxt('%s/script-data/entsoe-lat-lon-nonforced.csv'%dataDirDiscovery, delimiter=',', skip_header=0)
plantLatLon = np.concatenate((nukeLatLon,entsoeLatLon),axis=0)

grdcRefData = []

with open('%s/grdc/grdc_reference_stations/grdc_reference_stations.csv'%dataDir, 'r') as f:
    i = 0
    for line in f:
        if i == 0:
            i += 1
            continue
        
        # remove commas between quotes
        line = re.sub(r'(?!(([^"]*"){2})*[^"]*$),', '', line)
        
        parts = line.split(',')
        
        grdcId = int(parts[0])
        grdcLat = float(parts[7])
        grdcLon = float(parts[8])
        
        grdcRefData.append((grdcId, grdcLat, grdcLon))
        
        i += 1

grdcRefData = np.array(grdcRefData)

grdcMatchIds = []
grdcDists = []

for p in range(plantLatLon.shape[0]):
    
    print('processing plant %d'%p)
    
    pLat = plantLatLon[p,1]
    pLon = plantLatLon[p,2]
    ptPlant = geometry.Point(pLon, pLat)
    
    # find basin for this plant
    plantBasinId = -1
    for i in range(len(basins)):
        boundary = basins[i]
        if ptPlant.within(geometry.shape(boundary)):
            plantBasinId = i
    
    minDist = -1
    minDistId = -1    
    for g in range(grdcRefData.shape[0]):
        
        gLat = grdcRefData[g,1]
        gLon = grdcRefData[g,2]
        ptGuage = geometry.Point(gLon, gLat)
        
        d = geopy.distance.great_circle((pLat,pLon), (gLat,gLon)).km
        
        # check that plant and guage are both in the same basin
        guageBasinId = -1
        
        # find basin for guage
        for i in range(len(basins)):
            boundary = basins[i]
            
            minLon, minLat, maxLon, maxLat = boundary.bbox
            bounding_box = geometry.box(minLon, minLat, maxLon, maxLat)
            
            if bounding_box.contains(ptGuage):
                if ptGuage.within(geometry.shape(boundary)):
                    guageBasinId = i
            
        # skip gague if not in same basin as plant
        if guageBasinId != plantBasinId:
            continue
        
        if minDist == -1 or d < minDist:
            minDist = d
            minDistId = grdcRefData[g,0]
    
    if minDistId == -1:
        minDist = np.nan
    elif minDist > 250:
        minDist = np.nan
        minDistId = -1
    
    grdcDists.append(minDist)
    print('min dist id = %d'%minDistId)
    grdcMatchIds.append((plantLatLon[p,0], minDistId))

# these are the station ids that correspond to the plant lat/lons
grdcMatchIds = np.array(grdcMatchIds)
grdcDists = np.array(grdcDists)

# with open('grdc-data-lon-lat.dat', 'wb') as f:
#     pickle.dump({'ids':grdcMatchIds, 'dists':grdcDists}, f)

grdcDataNuke = []
grdcDataEntsoe = []

for g in range(len(grdcMatchIds)):
    
    plantId = int(grdcMatchIds[g][0])
    minDistId = grdcMatchIds[g][1]
    
    
    # all the years, months, days that we need qs values for (2007-2018 for nuke, 2015-2018 for entsoe)
    #entsoe
    if plantId < 60:
        plantYearRange = [2015,2018]    
    else:
        plantYearRange = [2007,2018]
        
    yearRange = []
    monthRange = []
    dayRange = []
    
    for y in range(plantYearRange[0],plantYearRange[1]+1):
        for m in range(1, 12+1):
            curMonthRange = calendar.monthrange(y,m) 
            for d in range(0, curMonthRange[1]):
                yearRange.append(y)
                monthRange.append(m)
                dayRange.append(d+1)
    
    yearRange = np.array(yearRange)
    monthRange = np.array(monthRange)
    dayRange = np.array(dayRange)
    
    
    # create nan time series for all days in time series
    curGrdcData = np.zeros(len(yearRange))
    curGrdcData[curGrdcData == 0] = np.nan
    
    # if a station has been identified
    if minDistId != -1:
        # if the daily data exists...
        if os.path.exists('%s/grdc/grdc_data/%d_Q_Day.Cmd.txt'%(dataDir, minDistId)):
        
            i = 0
            
            with open('%s/grdc/grdc_data/%d_Q_Day.Cmd.txt'%(dataDir, minDistId), 'r', encoding='latin') as f:
                for line in f:
                    if line[0] == '#':
                        continue
                    
                    if i == 0:
                        i += 1
                        continue
                    
                    parts = line.split(';')
                    
                    date = parts[0]
                    dateParts = date.split('-')
                    
                    curYear = int(dateParts[0])
                    curMonth = int(dateParts[1])
                    curDay = int(dateParts[2])
                    
                    # what index in the time series are we at
                    curDateIndex = np.where((yearRange==curYear) & (monthRange==curMonth) & (dayRange==curDay))[0]
                    
                    value = float(parts[2])
                    
                    if value < -500:
                        value = np.nan
                    
                    curGrdcData[curDateIndex] = value
                    
                    i += 1
        
        # if no daily data, try monthly
        elif os.path.exists('%s/grdc/grdc_data/%d_Q_Month.txt'%(dataDir, minDistId)):
            
            i = 0
            
            with open('%s/grdc/grdc_data/%d_Q_Month.txt'%(dataDir, minDistId), 'r', encoding='latin') as f:
                for line in f:
                    if line[0] == '#':
                        continue
                    
                    if i == 0:
                        i += 1
                        continue
                    
                    parts = line.split(';')
                    
                    date = parts[0]
                    dateParts = date.split('-')
                    
                    curYear = int(dateParts[0])
                    curMonth = int(dateParts[1])
                    
                    # what index in the time series are we at
                    curDateIndex = np.where((yearRange==curYear) & (monthRange==curMonth))[0]
                    
                    value = float(parts[2])
                    
                    if value < -500:
                        value = np.nan
                    
                    # fill all values in current month
                    for index in curDateIndex:
                        curGrdcData[index] = value
                    
                    i += 1
        
    if plantId < 60:
        # don't insert the plant id for entsoe
        grdcDataEntsoe.append(curGrdcData)
    else:
        # do insert plant id for nuke
        grdcDataNuke.append(np.insert(curGrdcData, 0, plantId))
            

grdcDataNuke = np.array(grdcDataNuke)
grdcDataEntsoe = np.array(grdcDataEntsoe)

# write runoff data to file
np.savetxt('%s/script-data/nuke-qs-grdc.csv'%dataDirDiscovery, grdcDataNuke, delimiter=",", fmt='%f')

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

grdcDataEntsoe = np.insert(grdcDataEntsoe, 0, dayHeader, axis=0)
grdcDataEntsoe = np.insert(grdcDataEntsoe, 0, monthHeader, axis=0)
grdcDataEntsoe = np.insert(grdcDataEntsoe, 0, yearHeader, axis=0)
np.savetxt('%s/script-data/entsoe-qs-grdc-nonforced.csv'%dataDirDiscovery, grdcDataEntsoe, delimiter=",", fmt='%f')





