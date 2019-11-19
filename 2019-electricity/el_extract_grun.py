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
import datetime, calendar


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

grunData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/GRUN/GRUN_v1_GSWP3_WGS84_05_1902_2014.nc', \
                                 decode_times=True, decode_cf=False)

dims = grunData.dims
startingDate = datetime.datetime(1902, 1, 1, 0, 0, 0)
tDt = []
for curTTime in grunData.time:
    delta = datetime.timedelta(days=int(curTTime.values))
    tDt.append(startingDate + delta)
grunData['time'] = tDt
grunData.load()

plantYearRange = [2007,2018]
yearRange = []
monthRange = []
for y in range(plantYearRange[0],plantYearRange[1]+1):
    for m in range(1, 12+1):
        yearRange.append(y)
        monthRange.append(m)

yearRange = np.array(yearRange)
monthRange = np.array(monthRange)

grunDataNuke = np.full([nukeLatLon.shape[0], 1+len(monthRange)], np.nan)

for p in range(nukeLatLon.shape[0]):
    print('plant %d of %d'%(p, nukeLatLon.shape[0]))
    plantId = nukeLatLon[p,0]
    
    curGrun = grunData.Runoff.sel(Y = nukeLatLon[p,1], X = nukeLatLon[p,2], \
                               time=grunData['time.year'].isin(np.arange(plantYearRange[0], plantYearRange[1]+1)), method='nearest')
    grunDataNuke[p,1:1+curGrun.size] = curGrun.values
    # do insert plant id for nuke
    grunDataNuke[p,0] = plantId
            

# write runoff data to file
np.savetxt('%s/script-data/nuke-qs-grun.csv'%dataDirDiscovery, grunDataNuke, delimiter=",", fmt='%f')




