#!/usr/bin/env python
# coding: utf-8

# In[1]:


# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 15:42:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import pandas as pd
import glob
import os, sys
import datetime
import pickle

import WetBulb

import warnings
warnings.filterwarnings('ignore')

sys.path.append('../2020-ag-land-climate')
import ag_build_elevation_map

member = 1
year = int(sys.argv[1])

dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/CMIP6'
dataDirLens = '/home/edcoffel/drive/MAX-Filer/Research/Climate-01/Data-edcoffel-F20/LENS/daily/atm'
dataDirElevation = '/home/edcoffel/drive/MAX-Filer/Research/Climate-01/Personal-F20/edcoffel-F20/data/elevation'

L = 0.00976 # lapse rate (K/m)
cp = 1004.68506 # constant pressure specific heat (J/kg*K)
g = 9.80665 # gravitational acceleration (m/s2)
M = 0.02896968 # molar mass of dry air (kg/mol)
R0 = 8.3144 # universal gas constant (J/mol*K)

tasmax = xr.open_mfdataset('%s/TASMAX/HIST-RCP85/tasmax_day_CESM1-CAM5_historical_rcp85_r%di1p1_*.nc'%(dataDirLens, member))

if member > 35:
    print('loading q')
    q_hist = xr.open_mfdataset(f'%s/QBOT/HIST/b.e11.B20TRC5CNBDRD.f09_g16.{(101-36+member):03}.cam.h1.QBOT.*.nc'%(dataDirLens))
    q_fut = xr.open_mfdataset(f'%s/QBOT/RCP85/b.e11.BRCP85C5CNBDRD.f09_g16.{(101-36+member):03}.cam.h1.QBOT.*.nc'%(dataDirLens))
    
    print('loading slp')
    slp_hist = xr.open_mfdataset(f'%s/SLP/HIST/b.e11.B20TRC5CNBDRD.f09_g16.{(101-36+member):03}.cam.h1.PSL.*.nc'%(dataDirLens))
    slp_fut = xr.open_mfdataset(f'%s/SLP/RCP85/b.e11.BRCP85C5CNBDRD.f09_g16.{(101-36+member):03}.cam.h1.PSL.*.nc'%(dataDirLens))
else:
    q_hist = xr.open_mfdataset(f'%s/QBOT/HIST/b.e11.B20TRC5CNBDRD.f09_g16.{member:03}.cam.h1.QBOT.*.nc'%(dataDirLens))
    q_fut = xr.open_mfdataset(f'%s/QBOT/RCP85/b.e11.BRCP85C5CNBDRD.f09_g16.{member:03}.cam.h1.QBOT.*.nc'%(dataDirLens))
    
    slp_hist = xr.open_mfdataset(f'%s/SLP/HIST/b.e11.B20TRC5CNBDRD.f09_g16.{member:03}.cam.h1.PSL.*.nc'%(dataDirLens))
    slp_fut = xr.open_mfdataset(f'%s/SLP/RCP85/b.e11.BRCP85C5CNBDRD.f09_g16.{member:03}.cam.h1.PSL.*.nc'%(dataDirLens))

# q_fut = xr.open_mfdataset(f'%s/QBOT/RCP85/b.e11.BRCP85C5CNBDRD.f09_g16.{member:03}.cam.h1.QBOT.20060101-20801231.nc'%(dataDirLens))

tasmax = tasmax.sel(time=slice('%d-01-01'%year, '%d-12-31'%year))

if year <= 2005:
    q = q_hist.sel(time=slice('%d-01-01'%year, '%d-12-31'%year))    
    slp = slp_hist.sel(time=slice('%d-01-01'%year, '%d-12-31'%year))
else:
    q = q_fut.sel(time=slice('%d-01-01'%year, '%d-12-31'%year))
    slp = slp_fut.sel(time=slice('%d-01-01'%year, '%d-12-31'%year))

# build elev map for this grid res
latPixels = tasmax.lat.shape[0]
lonPixels = tasmax.lon.shape[0]

if not os.path.isfile('%s/elevation-map-%d-%d.dat'%(dataDirElevation, latPixels, lonPixels)):
    print('building elevation map for %s/(%d, %d)'%(model, latPixels, lonPixels))
    elevLat, elevLon, elevationMap = ag_build_elevation_map.buildElevationMap(latPixels=latPixels, lonPixels=lonPixels)
else:
    with open('%s/elevation-map-%d-%d.dat'%(dataDirElevation, latPixels, lonPixels), 'rb') as f:
        e = pickle.load(f)
        elevLat = e['lat']
        elevLon = e['lon']

        if np.nanmax(tasmax.lon > 300):
            elevLon[elevLon<0] += 360

        elevationMap = e['elevationMap']

txHist = tasmax.tasmax
hussHist = q.QBOT
pslHist = slp.PSL

print('loading all data')
txHist.load()
hussHist.load()
pslHist.load()

# construct elevation subgrid that matches the grids of the cmip6 variables
elevSubMap = np.full([txHist.lat.values.shape[0], txHist.lon.values.shape[0]], np.nan)

print('calculating elevation sub grid')
for x, xlat in enumerate(txHist.lat.values):
    for y, ylon in enumerate(txHist.lon.values):
        elevX = np.where((abs(elevLat - xlat) == np.nanmin(abs(elevLat - xlat))))[0][0]
        elevY = np.where((abs(elevLon - ylon) == np.nanmin(abs(elevLon - ylon))))[0][0]

        elevSubMap[x, y] = elevationMap[elevX, elevY]

elevSubMap_da = xr.DataArray(elevSubMap, dims=['lat', 'lon'])

time_dim = pd.date_range("%d-01-01"%year, "%d-12-31"%year, freq="D")
time_dim_no_leap = time_dim[~((time_dim.month == 2) & (time_dim.day == 29))]

txHist['time']=time_dim_no_leap
pslHist['time']=time_dim_no_leap

# calculate estimated surface pressure
print('calculating historical surface pressure')
pSurfHist = pslHist * (1 - (L*elevSubMap_da)/txHist)**((g*M)/(R0*L))

# and now calculate wet bulb
print('calculating historical wet bulb temperature')
curTwHist = np.full([txHist.time.size, latPixels, lonPixels], np.nan)
n = 0
n_total = np.where((elevSubMap.reshape([elevSubMap.size,1])>0))[0].size * txHist.time.size
for xlat in range(latPixels):
    for ylon in range(lonPixels):
        if elevSubMap[xlat, ylon] > 0:
            for t in range(txHist.time.size):

                cur_tx = np.array([txHist.values[t, xlat, ylon]-273.15])
                cur_p_surf = np.array([pSurfHist.values[t, xlat, ylon]])
                cur_huss = np.array([hussHist[t, xlat, ylon]])
                
                curTwHist[t, xlat, ylon] = WetBulb.WetBulb(cur_tx, cur_p_surf, cur_huss)
                
                if n % 10000 == 0:
                    print(n/n_total*100, 'tw = %.2f'%curTwHist[t, xlat, ylon])

                
                n += 1


# Create a DataArray from the numpy array
# Assuming curTwHist has shape (time, lat, lon)
# time_dim = pd.date_range("1981-01-01", "2020-12-31", freq="D")

tw_da = xr.DataArray(
    curTwHist,
    coords={
        'time': txHist['time'],
        'lat': txHist['lat'],
        'lon': txHist['lon']
    },
    dims=['time', 'lat', 'lon']
)

# Save to a NetCDF file
tw_da.to_netcdf("tw_lens_%d_%d.nc"%(member, year))

