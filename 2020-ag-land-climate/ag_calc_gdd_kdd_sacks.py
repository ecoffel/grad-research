


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

# low and high temps for gdd/kdd calcs, taken from Butler, et al, 2015, ERL
t_low = 9
t_high = 29

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


# calculate gdd/kdd from cpc temperature data
gdd = [] #np.zeros([360, 720, len(range(years[0]-1, years[1]+1))])
kdd = [] #np.zeros([360, 720, len(range(years[0]-1, years[1]+1))])

for y, year in enumerate(range(years[0], years[1]+1)):
    print('processing year %d for %s...'%(year, crop))

    if wxData == 'cpc':
        dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%year, decode_cf=False)
        dims = dsMax.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMax.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMax['time'] = tDt
        
        dsMin = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmin/tmin.%d.nc'%year, decode_cf=False)
        dims = dsMin.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMin.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMin['time'] = tDt
        
        # load previous year
        dsMaxLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%(year-1), decode_cf=False)
        
        dims = dsMaxLastYear.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMaxLastYear.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMaxLastYear['time'] = tDt
        
        dsMinLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmin/tmin.%d.nc'%(year-1), decode_cf=False)
        
        dims = dsMinLastYear.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMinLastYear.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMinLastYear['time'] = tDt
        
    elif wxData == 'era5':
        dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/tasmax_%d.nc'%year, decode_cf=False)
        dims = dsMax.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMax.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMax['time'] = tDt
        
        dsMin = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/tasmin_%d.nc'%year, decode_cf=False)
        dims = dsMin.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMin.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMin['time'] = tDt
        
        
        # load previous year
        dsMaxLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/tasmax_%d.nc'%(year-1), decode_cf=False)
        
        dims = dsMaxLastYear.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMaxLastYear.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMaxLastYear['time'] = tDt
        
        dsMinLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/tasmin_%d.nc'%(year-1), decode_cf=False)
        
        dims = dsMinLastYear.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMinLastYear.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMinLastYear['time'] = tDt
        
        
    dsMax.load()
    dsMin.load()
    dsMaxLastYear.load()
    dsMinLastYear.load()
    
    if wxData == 'era5':
        lat = dsMax.latitude.values
        lon = dsMax.longitude.values
        tmax = dsMax.mx2t
        tmin = dsMin.mn2t
        tmaxLastYear = dsMaxLastYear.mx2t
        tminLastYear = dsMinLastYear.mn2t
    elif wxData == 'cpc':
        lat = dsMax.lat.values
        lon = dsMax.lon.values
        tmax = dsMax.tmax
        tmin = dsMin.tmin
        tmaxLastYear = dsMaxLastYear.tmax
        tminLastYear = dsMinLastYear.tmin
    
    if len(gdd) == 0:
        gdd = np.zeros([len(lat), len(lon), len(range(years[0], years[1]+1))])
    if len(kdd) == 0:
        kdd = np.zeros([len(lat), len(lon), len(range(years[0], years[1]+1))])
    
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

with gzip.open('%s/kdd-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, years[0], years[1]), 'wb') as f:
    pickle.dump(kdd, f)

with gzip.open('%s/gdd-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, years[0], years[1]), 'wb') as f:
    pickle.dump(gdd, f)

with gzip.open('%s/gdd-kdd-lat-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
    pickle.dump(dsMax.lat.values, f)

with gzip.open('%s/gdd-kdd-lon-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
    pickle.dump(dsMax.lon.values, f)