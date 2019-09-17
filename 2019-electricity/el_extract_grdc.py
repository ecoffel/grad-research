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

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data'

nukeLatLon = np.genfromtxt('nuke-lat-lon.csv', delimiter=',', skip_header=0)
entsoeLatLon = np.genfromtxt('entsoe-lat-lon.csv', delimiter=',', skip_header=0)
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
    
    pLat = plantLatLon[p,1]
    pLon = plantLatLon[p,2]
    
    minDist = -1
    minDistId = -1    
    for g in range(grdcRefData.shape[0]):
        
        gLat = grdcRefData[g,1]
        gLon = grdcRefData[g,2]
        
        d = geopy.distance.vincenty((pLat,pLon), (gLat,gLon)).km
        
        if minDist == -1 or d < minDist:
            minDist = d
            minDistId = grdcRefData[g,0]
    
    
#    if minDist > 200:
#        minDistId = -1
#    else:
#        grdcDists.append(minDist)
    
    grdcMatchIds.append((plantLatLon[p,0], minDistId))

# these are the station ids that correspond to the plant lat/lons
grdcMatchIds = np.array(grdcMatchIds)

grdcDataNuke = []
grdcDataEntsoe = []



for g in range(len(grdcMatchIds)):
    
    plantId = int(grdcMatchIds[g][0])
    minDistId = grdcMatchIds[g][1]
    
    
    # all the years, months, days that we need qs values for (2007-2018 for nuke, 2015-2018 for entsoe)
    #entsoe
    if plantId < 50:
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
            
            with open('%s/grdc/grdc_data/%d_Q_Day.Cmd.txt'%(dataDir, minDistId), 'r') as f:
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
            
            with open('%s/grdc/grdc_data/%d_Q_Month.txt'%(dataDir, minDistId), 'r') as f:
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
        
    if plantId < 50:
        # don't insert the plant id for entsoe
        grdcDataEntsoe.append(curGrdcData)
    else:
        # do insert plant id for nuke
        grdcDataNuke.append(np.insert(curGrdcData, 0, plantId))
            

grdcDataNuke = np.array(grdcDataNuke)
grdcDataEntsoe = np.array(grdcDataEntsoe)

# write runoff data to file
np.savetxt("nuke-qs-grdc.csv", grdcDataNuke, delimiter=",", fmt='%f')

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
np.savetxt("entsoe-qs-grdc.csv", grdcDataEntsoe, delimiter=",", fmt='%f')





