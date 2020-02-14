


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

# load the sacks crop calendars

sacksStart = np.genfromtxt('%s/sacks/sacks-planting-end-%s.txt'%(dataDirDiscovery, crop), delimiter=',')
sacksStart[sacksStart<0] = np.nan
sacksEnd = np.genfromtxt('%s/sacks/sacks-harvest-start-%s.txt'%(dataDirDiscovery, crop), delimiter=',')
sacksEnd[sacksEnd<0] = np.nan

sacksStart = np.roll(sacksStart, int(sacksStart.shape[1]/2), axis=1)
sacksEnd = np.roll(sacksEnd, int(sacksEnd.shape[1]/2), axis=1)



# calculate gdd/kdd from cpc temperature data

gdd = np.zeros([360, 720, len(range(1981, 2011+1))])
kdd = np.zeros([360, 720, len(range(1981, 2011+1))])

for y, year in enumerate(range(1981, 2011+1)):
    print('processing year %d for %s...'%(year, crop))

    dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%year, decode_cf=False)
    dsMax.load()

    dims = dsMax.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in dsMax.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    dsMax['time'] = tDt
    
    dsMin = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmin/tmin.%d.nc'%year, decode_cf=False)
    dsMin.load()

    dims = dsMin.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in dsMin.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    dsMin['time'] = tDt
    
    
    # load previous year
    dsMaxLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%(year-1), decode_cf=False)
    dsMaxLastYear.load()

    dims = dsMaxLastYear.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in dsMaxLastYear.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    dsMaxLastYear['time'] = tDt
    
    dsMinLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmin/tmin.%d.nc'%(year-1), decode_cf=False)
    dsMinLastYear.load()

    dims = dsMinLastYear.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in dsMinLastYear.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    dsMinLastYear['time'] = tDt

    for xlat in range(len(dsMax.lat)):
        for ylon in range(len(dsMax.lon)):
            if ~np.isnan(sacksStart[xlat,ylon]) and ~np.isnan(sacksEnd[xlat,ylon]):
                
                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if sacksStart[xlat,ylon] > sacksEnd[xlat,ylon]:
                    curTmax = xr.concat([dsMaxLastYear.tmax[int(sacksStart[xlat, ylon]):, xlat, ylon], \
                                         dsMax.tmax[:int(sacksEnd[xlat, ylon]), xlat, ylon]], dim='time')
                    curTmin = xr.concat([dsMinLastYear.tmin[int(sacksStart[xlat, ylon]):, xlat, ylon], \
                                         dsMin.tmin[:int(sacksEnd[xlat, ylon]), xlat, ylon]], dim='time')
                else:
                    curTmax = dsMax.tmax[int(sacksStart[xlat, ylon]):int(sacksEnd[xlat, ylon]), xlat, ylon]
                    curTmin = dsMin.tmin[int(sacksStart[xlat, ylon]):int(sacksEnd[xlat, ylon]), xlat, ylon]
                
                curYearGdd = (curTmax.where(curTmax > t_low) + curTmin.where(curTmin > t_low))/2-t_low
                curYearGdd = curYearGdd.sum(dim='time')

                gdd[xlat, ylon, y] = curYearGdd.values

                curYearKdd = curTmax.where(curTmax > t_high)-t_high
                curYearKdd = curYearKdd.sum(dim='time')

                kdd[xlat, ylon, y] = curYearKdd.values

with gzip.open('%s/kdd-cpc-%s.dat'%(dataDirDiscovery, crop), 'wb') as f:
    pickle.dump(kdd, f)

with gzip.open('%s/gdd-cpc-%s.dat'%(dataDirDiscovery, crop), 'wb') as f:
    pickle.dump(gdd, f)

with gzip.open('%s/gdd-kdd-lat-cpc.dat'%dataDirDiscovery, 'wb') as f:
    pickle.dump(dsMax.lat.values, f)

with gzip.open('%s/gdd-kdd-lon-cpc.dat'%dataDirDiscovery, 'wb') as f:
    pickle.dump(dsMax.lon.values, f)