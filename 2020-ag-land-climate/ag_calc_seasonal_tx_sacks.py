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


txData = []

for year in range(yearRange[0], yearRange[1]+1):
    print('loading year %d...'%year)
    curTxData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5-Land/monthly/2m_temperature_monthly_%d.nc'%year, decode_cf=False)
    curTxData.load()

    scale = curTxData.t2m.attrs['scale_factor']
    offset = curTxData.t2m.attrs['add_offset']
    missing = curTxData.t2m.attrs['missing_value']

    curTxData.where((curTxData != missing))
    curTxData = curTxData.astype(float) * scale + offset

    dims = curTxData.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in curTxData.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    curTxData['time'] = tDt

    if len(txData) == 0:
        txData = curTxData
    else:
        txData = xr.concat([txData, curTxData], dim='time')

print('extracting seasonal data...')
seasonalTx = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])
for xlat in range(len(tempLat)-1):

    if xlat % 25 == 0: 
        print('%.0f %%'%(xlat/len(tempLat)*100))

    for ylon in range(len(tempLon)):

        if ~np.isnan(sacksStart[xlat,ylon]) and ~np.isnan(sacksEnd[xlat,ylon]):
            startMonth = datetime.datetime.strptime('%d'%(sacksStart[xlat,ylon]), '%j').date().month
            endMonth = datetime.datetime.strptime('%d'%(sacksEnd[xlat,ylon]), '%j').date().month
            
            lat1 = tempLat[xlat]
            lat2 = tempLat[xlat]+(tempLat[1]-tempLat[0])
            lon1 = tempLon[ylon]
            lon2 = tempLon[ylon]+(tempLon[1]-tempLon[0])
            if lon2 > 360:
                lon2 -= 360
            if lon1 > 360:
                lon1 -= 360

            curTx = txData.t2m.sel(latitude=slice(lat1, lat2), longitude=slice(lon1, lon2)).mean(dim='latitude').mean(dim='longitude')

            for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if  startMonth > endMonth:
                    curYearTx = curTx.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                else:
                    curYearTx = curTx.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))

                seasonalTx[xlat, ylon, y] = np.nanmean(curYearTx.values)
    
with open('%s/seasonal-t-maize-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
    pickle.dump(seasonalTx, f)