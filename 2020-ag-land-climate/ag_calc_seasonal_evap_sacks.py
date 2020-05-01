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

yearRange = [1981, 2018]

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

evapData = []

for year in range(yearRange[0], yearRange[1]+1):
    curEvapData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5/monthly/evaporation_%d.nc'%year, decode_cf=False)
    curEvapData.load()

    dims = curEvapData.dims
    startingDate = datetime.datetime(year, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in curEvapData.time:
        delta = datetime.timedelta(days=int(curTTime.values))
        tDt.append(startingDate + delta)
    curEvapData['time'] = tDt

    if len(evapData) == 0:
        evapData = curEvapData
    else:
        evapData = xr.concat([evapData, curEvapData], dim='time')

seasonalEvap = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

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

            curEvap = evapData.e.sel(latitude=[lat1, lat2], longitude=[lon1, lon2]).mean(dim='latitude').mean(dim='longitude')

            for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if  startMonth > endMonth:
                    curYearEvap = curEvap.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                else:
                    curYearEvap = curEvap.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))

                seasonalEvap[xlat, ylon, y] = np.nansum(curYearEvap.values)

with open('%s/seasonal-evap-maize-%s.dat'%(dataDirDiscovery, wxData), 'wb') as f:
    pickle.dump(seasonalEvap, f)