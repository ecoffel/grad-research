import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import datetime
from dateutil.relativedelta import relativedelta
from calendar import monthrange
import geopy.distance
import xarray as xr
import cartopy.crs as ccrs

import warnings
warnings.filterwarnings('ignore')

wxData = 'era5'

nrVarShort = 'str'
if nrVarShort == 'ssr':
    nrVar = 'surface_net_solar_radiation'
elif nrVarShort == 'str':
    nrVar = 'surface_net_thermal_radiation'

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

nrData = []

for year in range(yearRange[0], yearRange[1]+1):
    curNrData = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/ERA5-Land/monthly/%s_monthly_%d.nc'%(nrVar, year), decode_cf=False)
    curNrData.load()

    scale = curNrData[nrVarShort].attrs['scale_factor']
    offset = curNrData[nrVarShort].attrs['add_offset']
    missing = curNrData[nrVarShort].attrs['missing_value']

    curNrData.where((curNrData != missing))
    curNrData = curNrData.astype(float) * scale + offset
    
    dims = curNrData.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []

    for curTTime in curNrData.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    curNrData['time'] = tDt

    if len(nrData) == 0:
        nrData = curNrData
    else:
        nrData = xr.concat([nrData, curNrData], dim='time')

seasonalNr = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

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

            if nrVarShort == 'ssr':
                curNr = nrData.ssr.sel(latitude=slice(lat1, lat2), longitude=slice(lon1, lon2)).mean(dim='latitude').mean(dim='longitude')
            elif nrVarShort == 'str':
                curNr = nrData.str.sel(latitude=slice(lat1, lat2), longitude=slice(lon1, lon2)).mean(dim='latitude').mean(dim='longitude')

            for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                daysInMonths = []
                
                # in southern hemisphere when planting happens in fall and harvest happens in spring
                if  startMonth > endMonth:
                    curYearNr = curNr.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                    curMonths = np.concatenate([np.arange(startMonth, 12+1,1), np.arange(1,endMonth+1)])
                    for curM in curMonths:
                        if curM > endMonth:
                            daysInMonths.append(monthrange(year-1, curM)[1])
                        else:
                            daysInMonths.append(monthrange(year, curM)[1])
                else:
                    curYearNr = curNr.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))
                    for curM in range(startMonth, endMonth+1):
                        if curM > endMonth:
                            daysInMonths.append(monthrange(year-1, curM)[1])
                        else:
                            daysInMonths.append(monthrange(year, curM)[1])

                daysInMonths = np.array(daysInMonths)
                seasonalNr[xlat, ylon, y] = np.nansum([curYearNr.values[i]*daysInMonths[i] for i in range(len(curYearNr.values))])
                
with open('%s/seasonal-%s-maize-%s-correctedunits.dat'%(dataDirDiscovery, nrVarShort, wxData), 'wb') as f:
    pickle.dump(seasonalNr, f)