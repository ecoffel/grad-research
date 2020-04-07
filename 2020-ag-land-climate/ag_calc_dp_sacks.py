


import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import datetime
import geopy.distance
import xarray as xr
import cartopy.crs as ccrs

import warnings
warnings.filterwarnings('ignore')

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'

crop = sys.argv[1]
wxData = sys.argv[2]

years = [1981, 2018]

# load the sacks crop calendars

sacksStart = np.genfromtxt('%s/sacks/sacks-planting-end-%s.txt'%(dataDirDiscovery, crop), delimiter=',')
sacksStart[sacksStart<0] = np.nan
sacksEnd = np.genfromtxt('%s/sacks/sacks-harvest-start-%s.txt'%(dataDirDiscovery, crop), delimiter=',')
sacksEnd[sacksEnd<0] = np.nan

sacksStart = np.roll(sacksStart, int(sacksStart.shape[1]/2), axis=1)
sacksEnd = np.roll(sacksEnd, int(sacksEnd.shape[1]/2), axis=1)

sacksLat = np.linspace(90, -90, 360)
sacksLon = np.linspace(0, 360, 720)


dp = []

for y, year in enumerate(range(years[0], years[1]+1)):
    print('processing year %d for %s...'%(year, crop))

    dpMean = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/dp_mean_%d.nc'%year, decode_cf=False)
    dims = dpMean.dims
    startingDate = datetime.datetime(year, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in dpMean.time:
        delta = datetime.timedelta(days=int(curTTime.values))
        tDt.append(startingDate + delta)
    dpMean['time'] = tDt


    # load previous year
    dpMeanLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/dp_mean_%d.nc'%(year-1), decode_cf=False)

    dims = dpMeanLastYear.dims
    startingDate = datetime.datetime(year-1, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in dpMeanLastYear.time:
        delta = datetime.timedelta(days=int(curTTime.values))
        tDt.append(startingDate + delta)
    dpMeanLastYear['time'] = tDt

        
    dpMean.load()
    dpMeanLastYear.load()
    
    sys.exit()
    
    lat = dpMean.latitude.values
    lon = dpMean.longitude.values
    dp = dpMean.d2m
    dpMeanLastYear = dpMeanLastYear.d2m
    
    if len(gdd) == 0:
        dp = np.zeros([len(lat), len(lon), len(range(years[0], years[1]+1))])
    
    for xlat in range(len(lat)):
        for ylon in range(len(lon)):
            
            sacksNearestX = np.where((abs(sacksLat-lat[xlat]) == np.nanmin(abs(sacksLat-lat[xlat]))))[0][0]
            sacksNearestY = np.where((abs(sacksLon-lon[ylon]) == np.nanmin(abs(sacksLon-lon[ylon]))))[0][0]
            
            if ~np.isnan(sacksStart[sacksNearestX,sacksNearestY]) and ~np.isnan(sacksEnd[sacksNearestX,sacksNearestY]):
                
                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if sacksStart[sacksNearestX,sacksNearestY] > sacksEnd[sacksNearestX,sacksNearestY]:
                    curTmax = xr.concat([tmaxLastYear[int(sacksStart[sacksNearestX,sacksNearestY]):, xlat, ylon], \
                                         tmax[:int(sacksEnd[sacksNearestX,sacksNearestY]), xlat, ylon]], dim='time')
                    
                    curTmin = xr.concat([tminLastYear[int(sacksStart[sacksNearestX,sacksNearestY]):, xlat, ylon], \
                                         tmin[:int(sacksEnd[sacksNearestX,sacksNearestY]), xlat, ylon]], dim='time')
                else:
                    curTmax = tmax[int(sacksStart[sacksNearestX,sacksNearestY]):int(sacksEnd[sacksNearestX,sacksNearestY]), xlat, ylon]
                    curTmin = tmin[int(sacksStart[sacksNearestX,sacksNearestY]):int(sacksEnd[sacksNearestX,sacksNearestY]), xlat, ylon]
                
                curYearGdd = (curTmax.where(curTmax > t_low) + curTmin.where(curTmin > t_low))/2-t_low
                curYearGdd = curYearGdd.sum(dim='time')

                gdd[xlat, ylon, y] = curYearGdd.values

                curYearKdd = curTmax.where(curTmax > t_high)-t_high
                curYearKdd = curYearKdd.sum(dim='time')

                kdd[xlat, ylon, y] = curYearKdd.values

with gzip.open('%s/daily-max-dp-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, years[0], years[1]), 'wb') as f:
    pickle.dump(kdd, f)
