


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

years = [int(sys.argv[3]), int(sys.argv[4])]

# load the sacks crop calendars
sacksMaizeStart = np.genfromtxt('%s/sacks/sacks-planting-end-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeStart[sacksMaizeStart<0] = np.nan
sacksMaizeEnd = np.genfromtxt('%s/sacks/sacks-harvest-start-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeEnd[sacksMaizeEnd<0] = np.nan

sacksMaizeStart = np.roll(sacksMaizeStart, int(sacksMaizeStart.shape[1]/2), axis=1)
sacksMaizeEnd = np.roll(sacksMaizeEnd, int(sacksMaizeEnd.shape[1]/2), axis=1)

# load the sacks crop calendars
sacksLat = np.linspace(90, -90, 360)
sacksLon = np.linspace(0, 360, 720)

# calculate tx95 and txx from cpc temperature data
tx95 = [] #np.zeros([360, 720, len(range(years[0]-1, years[1]+1))])
txMean = [] #np.zeros([360, 720, len(range(years[0]-1, years[1]+1))])

for y, year in enumerate(range(years[0], years[1]+1)):
    print('year %d for %s...'%(year, crop))

    if wxData == 'cpc':
        dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%year, decode_cf=False)
        dims = dsMax.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMax.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMax['time'] = tDt
        
        # load previous year
        dsMaxLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%(year-1), decode_cf=False)
        
        dims = dsMaxLastYear.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMaxLastYear.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMaxLastYear['time'] = tDt
        
        
    elif wxData == 'era5':
        dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/tasmax_%d.nc'%year, decode_cf=False)
        dims = dsMax.dims
        startingDate = datetime.datetime(year, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMax.time:
            delta = datetime.timedelta(days=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMax['time'] = tDt
        dsMax['mx2t'] = dsMax['mx2t'] - 273.15
        
        # load previous year
        dsMaxLastYear = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/daily/tasmax_%d.nc'%(year-1), decode_cf=False)
        
        dims = dsMaxLastYear.dims
        startingDate = datetime.datetime(year-1, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in dsMaxLastYear.time:
            delta = datetime.timedelta(days=int(curTTime.values))
            tDt.append(startingDate + delta)
        dsMaxLastYear['time'] = tDt
        dsMaxLastYear['mx2t'] = dsMaxLastYear['mx2t'] - 273.15
    
    print('loading...')
    dsMax.load()
    dsMaxLastYear.load()
    
    if wxData == 'era5':
        lat = dsMax.latitude.values
        lon = dsMax.longitude.values
        tmax = dsMax.mx2t
        tmaxLastYear = dsMaxLastYear.mx2t
    elif wxData == 'cpc':
        lat = dsMax.lat.values
        lon = dsMax.lon.values
        tmax = dsMax.tmax
        tmaxLastYear = dsMaxLastYear.tmax
        missing_value = dsMax.tmax.attrs['missing_value']
    
    if len(tx95) == 0:
        tx95 = np.zeros([len(lat), len(lon)])
    if len(txMean) == 0:
        txMean = np.zeros([len(lat), len(lon)])
    
    for xlat in range(len(lat)):
        
        if xlat % 25 == 0:
            print('processing... %.0f %% complete'%(xlat/len(lat)*100))
        
        for ylon in range(len(lon)):
            
            sacksNearestX = np.where((abs(sacksLat-lat[xlat]) == np.nanmin(abs(sacksLat-lat[xlat]))))[0][0]
            sacksNearestY = np.where((abs(sacksLon-lon[ylon]) == np.nanmin(abs(sacksLon-lon[ylon]))))[0][0]
            
            growingSeasonLen = 0

            if ~np.isnan(sacksMaizeStart[sacksNearestX,sacksNearestY]) and ~np.isnan(sacksMaizeEnd[sacksNearestX,sacksNearestY]):
                
                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if sacksMaizeStart[sacksNearestX,sacksNearestY] > sacksMaizeEnd[sacksNearestX,sacksNearestY]:
                    curTmax = xr.concat([tmaxLastYear[int(sacksMaizeStart[sacksNearestX,sacksNearestY]):, xlat, ylon], \
                                         tmax[:int(sacksMaizeEnd[sacksNearestX,sacksNearestY]), xlat, ylon]], dim='time')
                else:
                    curTmax = tmax[int(sacksMaizeStart[sacksNearestX,sacksNearestY]):int(sacksMaizeEnd[sacksNearestX,sacksNearestY]), xlat, ylon]
                
                if wxData == 'cpc':
                    curTmax.values[curTmax.values == missing_value] = np.nan
                
                # calc seasonal gdd/kdd
                curYearTx95 = np.nanpercentile(curTmax.values, 95)
                curYearTxMean = np.nanmean(curTmax.values)
                
                tx95[xlat, ylon] = curYearTx95
                
                txMean[xlat, ylon] = curYearTxMean
    
    with gzip.open('%s/tx95-%s-%s-%d.dat'%(dataDirDiscovery, wxData, crop, year), 'wb') as f:
        pickle.dump(tx95, f)

    with gzip.open('%s/txMean-%s-%s-%d.dat'%(dataDirDiscovery, wxData, crop, year), 'wb') as f:
        pickle.dump(txMean, f)
    
    if not os.path.isfile('%s/gdd-kdd-lat-%s.dat'%(dataDirDiscovery, wxData)):
        with gzip.open('%s/gdd-kdd-lat-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
            pickle.dump(lat, f)

    if not os.path.isfile('%s/gdd-kdd-lon-%s.dat'%(dataDirDiscovery, wxData)):
        with gzip.open('%s/gdd-kdd-lon-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
            pickle.dump(lon, f)