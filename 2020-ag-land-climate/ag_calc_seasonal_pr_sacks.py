import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import datetime
from dateutil.relativedelta import relativedelta
import geopy.distance
import xarray as xr
import cartopy.crs as ccrs

import warnings
warnings.filterwarnings('ignore')

wxData = 'era5'

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'

if wxData == '20cr':
    yearRange = [1970, 2015]
else:
    yearRange = [1981, 2019]

sacksMaizeNc = xr.open_dataset('%s/sacks/Maize.crop.calendar.fill.nc'%dataDirDiscovery)
sacksStart = sacksMaizeNc['plant'].values + 1
sacksStart = np.roll(sacksStart, -int(sacksStart.shape[1]/2), axis=1)
sacksStart[sacksStart < 0] = np.nan
sacksEnd = sacksMaizeNc['harvest'].values + 1
sacksEnd = np.roll(sacksEnd, -int(sacksEnd.shape[1]/2), axis=1)
sacksEnd[sacksEnd < 0] = np.nan

sacksLat = np.linspace(90, -90, 360)
sacksLon = np.linspace(0, 360, 720)

with gzip.open('%s/gdd-kdd-lat-cpc.dat'%dataDirDiscovery, 'rb') as f:
    tempLat = pickle.load(f)

with gzip.open('%s/gdd-kdd-lon-cpc.dat'%dataDirDiscovery, 'rb') as f:
    tempLon = pickle.load(f)

if wxData == 'gpcp':
    prData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/GPCP/precip.mon.mean.nc', decode_cf=False)
    prData.load()

    dims = prData.dims
    startingDate = datetime.datetime(1800, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in prData.time:
        delta = datetime.timedelta(days=int(curTTime.values))
        tDt.append(startingDate + delta)
    prData['time'] = tDt
elif wxData == 'era5':
    
    prData = []
    
    for year in range(yearRange[0], yearRange[1]+1):
        curPrData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5-Land/monthly/total_precipitation_monthly_%d.nc'%year, decode_cf=False)
        curPrData.load()

        scale = curPrData.tp.attrs['scale_factor']
        offset = curPrData.tp.attrs['add_offset']
        missing = curPrData.tp.attrs['missing_value']
        
        curPrData.where((curPrData != missing))
        curPrData = curPrData.astype(float) * scale + offset
        
        dims = curPrData.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in curPrData.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        curPrData['time'] = tDt
        
        if len(prData) == 0:
            prData = curPrData
        else:
            prData = xr.concat([prData, curPrData], dim='time')
elif wxData == '20cr':
    prData = []
    
    for year in range(yearRange[0], yearRange[1]+1):
        curPrData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/20CR/precip/prate.%d.nc'%year, decode_cf=False)
        curPrData.load()

        dims = curPrData.dims
        startingDate = datetime.datetime(1800, 1, 1, 0, 0, 0)
        tDt = []

        for curTTime in curPrData.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        curPrData['time'] = tDt
        
        curPrData = curPrData.resample(time='1M').sum()
        
        if len(prData) == 0:
            prData = curPrData
        else:
            prData = xr.concat([prData, curPrData], dim='time')
    
seasonalPrecip = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
for xlat in range(len(tempLat)-1):

    if xlat % 25 == 0: 
        print('%.0f %%'%(xlat/len(tempLat)*100))

    for ylon in range(len(tempLon)):

        if ~np.isnan(sacksStart[xlat,ylon]) and ~np.isnan(sacksEnd[xlat,ylon]):
            startMonth = datetime.datetime.strptime('%d'%(sacksStart[xlat,ylon]), '%j').date().month
            endMonth = datetime.datetime.strptime('%d'%(sacksEnd[xlat,ylon]), '%j').date().month

            if wxData == 'gpcp':
                curPr = prData.precip.sel(lat=tempLat[xlat], lon=tempLon[ylon], method='nearest')
            elif wxData == 'era5':
                lat1 = tempLat[xlat]
                lat2 = tempLat[xlat]+(tempLat[1]-tempLat[0])
                lon1 = tempLon[ylon]
                lon2 = tempLon[ylon]+(tempLon[1]-tempLon[0])
                if lon2 > 360:
                    lon2 -= 360
                if lon1 > 360:
                    lon1 -= 360
                
                # this is in m/month
                curPr = prData.tp.sel(latitude=slice(lat1, lat2), longitude=slice(lon1, lon2)).mean(dim='latitude').mean(dim='longitude')
            elif wxData == '20cr':
                lat1 = tempLat[xlat]
                lat2 = tempLat[xlat]+(tempLat[1]-tempLat[0])
                lon1 = tempLon[ylon]
                lon2 = tempLon[ylon]+(tempLon[1]-tempLon[0])
                if lon2 > 360:
                    lon2 -= 360
                if lon1 > 360:
                    lon1 -= 360
                
                curPr = prData.prate.sel(lat=lat1, lon=lon1, method='nearest')
                
            for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if  startMonth > endMonth:
                    curYearPr = curPr.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                else:
                    curYearPr = curPr.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))

                seasonalPrecip[xlat, ylon, y] = np.nansum(curYearPr.values)
    
with open('%s/seasonal-precip-maize-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
    pickle.dump(seasonalPrecip, f)