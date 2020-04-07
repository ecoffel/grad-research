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

yearRange = [1981, 2018]

# load the sacks crop calendars
sacksMaizeStart = np.genfromtxt('%s/sacks/sacks-planting-end-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeStart[sacksMaizeStart<0] = np.nan
sacksMaizeEnd = np.genfromtxt('%s/sacks/sacks-harvest-start-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeEnd[sacksMaizeEnd<0] = np.nan

sacksMaizeStart = np.roll(sacksMaizeStart, int(sacksMaizeStart.shape[1]/2), axis=1)
sacksMaizeEnd = np.roll(sacksMaizeEnd, int(sacksMaizeEnd.shape[1]/2), axis=1)

with gzip.open('%s/gdd-kdd-lat-cpc.dat'%dataDirDiscovery, 'rb') as f:
    tempLat = pickle.load(f)

with gzip.open('%s/gdd-kdd-lon-cpc.dat'%dataDirDiscovery, 'rb') as f:
    tempLon = pickle.load(f)

gpcp = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/GPCP/precip.mon.mean.nc', decode_cf=False)
gpcp.load()

dims = gpcp.dims
startingDate = datetime.datetime(1800, 1, 1, 0, 0, 0)
tDt = []

for curTTime in gpcp.time:
    delta = datetime.timedelta(days=int(curTTime.values))
    tDt.append(startingDate + delta)
gpcp['time'] = tDt

    
if os.path.isfile('%s/seasonal-precip-maize-gpcp.dat'%dataDirDiscovery):
    with gzip.open('%s/seasonal-precip-maize-gpcp.dat'%dataDirDiscovery, 'rb') as f:
        seasonalPrecip = pickle.load(f)
else:
    seasonalPrecip = np.zeros([len(tempLat), len(tempLon), len(range(yearRange[0], yearRange[1]+1))])

    for xlat in range(len(tempLat)):
        if xlat % 25 == 0: 
            print('%.0f %%'%(xlat/len(tempLat)*100))
        for ylon in range(len(tempLon)):

            if ~np.isnan(sacksMaizeStart[xlat,ylon]) and ~np.isnan(sacksMaizeEnd[xlat,ylon]):
                startMonth = datetime.datetime.strptime('%d'%(sacksMaizeStart[xlat,ylon]), '%j').date().month
                endMonth = datetime.datetime.strptime('%d'%(sacksMaizeEnd[xlat,ylon]), '%j').date().month

                curPr = gpcp.precip.sel(lat=tempLat[xlat], lon=tempLon[ylon], method='nearest')

                for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):

                    # in southern hemisphere when planting happens in fall and harvest happens in spring
                    if  startMonth > endMonth:
                        curYearPr = curPr.sel(time=slice('%d-%d'%(year-1, startMonth), '%d-%d'%(year, endMonth)))
                    else:
                        curYearPr = curPr.sel(time=slice('%d-%d'%(year, startMonth), '%d-%d'%(year, endMonth)))

                    seasonalPrecip[xlat, ylon, y] = np.nansum(curYearPr.values)
        
    with gzip.open('%s/seasonal-precip-maize-gpcp.dat'%dataDirDiscovery, 'wb') as f:
        pickle.dump(seasonalPrecip, f)