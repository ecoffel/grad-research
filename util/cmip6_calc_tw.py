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

# model = 'canesm5'
# model = 'kace-1-0-g'
model = 'bcc-esm1'

year = int(sys.argv[1])

dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/CMIP6'
dataDirElevation = '/home/edcoffel/drive/MAX-Filer/Research/Climate-01/Personal-F20/edcoffel-F20/data/elevation'

print('loading hist %s/tasmax'%model)
dsTasmaxHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/tasmax/tasmax_day*.nc'%(dataDir, model), combine='by_coords')
dsTasmaxHist = dsTasmaxHist.where((dsTasmaxHist['time.year'] == year), drop=True)
dsTasmaxHist.load()

print('loading hist %s/huss'%model)
if model == 'bcc-esm1':
    dsHussHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/hus/hus_day*.nc'%(dataDir, model), combine='by_coords')
    dsHussHist = dsHussHist.where((dsHussHist['time.year'] == year) & (dsHussHist['plev'] == 100000), drop=True)
    dsHussHist = dsHussHist.squeeze()
    dsHussHist = dsHussHist.rename({'hus':'huss'})
    dsHussHist.load()
else:
    dsHussHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/huss/huss_day*.nc'%(dataDir, model), combine='by_coords')
    dsHussHist = dsHussHist.where((dsHussHist['time.year'] == year), drop=True)
    dsHussHist.load()

print('loading hist %s/psl'%model)
dsPslHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/psl/psl_day*.nc'%(dataDir, model), combine='by_coords')
dsPslHist = dsPslHist.where((dsPslHist['time.year'] == year), drop=True)
dsPslHist.load()

# build elev map for this grid res
latPixels = dsTasmaxHist.lat.shape[0]
lonPixels = dsTasmaxHist.lon.shape[0]

if not os.path.isfile('%s/elevation-map-%d-%d.dat'%(dataDirElevation, latPixels, lonPixels)):
    print('building elevation map for %s/(%d, %d)'%(model, latPixels, lonPixels))
    elevLat, elevLon, elevationMap = ag_build_elevation_map.buildElevationMap(latPixels=latPixels, lonPixels=lonPixels)
else:
    with open('%s/elevation-map-%d-%d.dat'%(dataDirElevation, latPixels, lonPixels), 'rb') as f:
        e = pickle.load(f)
        elevLat = e['lat']
        elevLon = e['lon']

        if np.nanmax(dsTasmaxHist.lon > 300):
            elevLon[elevLon<0] += 360

        elevationMap = e['elevationMap']

L = 0.00976 # lapse rate (K/m)
cp = 1004.68506 # constant pressure specific heat (J/kg*K)
g = 9.80665 # gravitational acceleration (m/s2)
M = 0.02896968 # molar mass of dry air (kg/mol)
R0 = 8.3144 # universal gas constant (J/mol*K)

txHist = dsTasmaxHist.tasmax
hussHist = dsHussHist.huss
pslHist = dsPslHist.psl

# construct elevation subgrid that matches the grids of the cmip6 variables
elevSubMap = np.full([txHist.lat.values.shape[0], txHist.lon.values.shape[0]], np.nan)

print('calculating elevation sub grid for %s'%model)
for x, xlat in enumerate(txHist.lat.values):
    for y, ylon in enumerate(txHist.lon.values):
        elevX = np.where((abs(elevLat - xlat) == np.nanmin(abs(elevLat - xlat))))[0][0]
        elevY = np.where((abs(elevLon - ylon) == np.nanmin(abs(elevLon - ylon))))[0][0]

        elevSubMap[x, y] = elevationMap[elevX, elevY]

# calculate estimated surface pressure
print('calculating historical surface pressure for %s'%model)
pSurfHist = pslHist * (1 - (L*elevSubMap)/txHist)**((g*M)/(R0*L))

# and now calculate wet bulb
print('calculating historical wet bulb temperature for %s'%model)
curTwHist = np.full([dsTasmaxHist.time.size, latPixels, lonPixels], np.nan)
n = 0
n_total = np.where((elevSubMap.reshape([elevSubMap.size,1])>0))[0].size * dsTasmaxHist.time.size
for xlat in range(latPixels):
    for ylon in range(lonPixels):
        if elevSubMap[xlat, ylon] > 0:
            for t in range(dsTasmaxHist.time.size):
                if n % 1000 == 0:
                    print(n/n_total)

                cur_tx = np.array([txHist.values[t, xlat, ylon]-273.15])
                cur_p_surf = np.array([pSurfHist.values[t, xlat, ylon]])
                cur_huss = np.array([hussHist.values[t, xlat, ylon]])
                curTwHist[t, xlat, ylon] = WetBulb.WetBulb(cur_tx, cur_p_surf, cur_huss)
                n += 1

dsTwHist = xr.Dataset(
    {
        'tw':(('time', 'lat', 'lon'), curTwHist)
    },
    coords = {'time':txHist.time, 'lat':txHist.lat, 'lon':txHist.lon},
)

print('writing tw change netcdf file for %s'%model)
dsTwHist.to_netcdf(path='tw_daily_%s_%d.nc'%(model, year), mode='w')
#     dsTwHist.to_netcdf(path='%s/%s/r1i1p1f1/historical/tw/tw_daily.nc'%(dataDir, model), mode='w')
    
    
#     uniqueLatLongs = {}
    
#     tw = pd.DataFrame({'ID':[], 'TW':[]})
    
#     # loop over all moose locs to compute tw
#     for i in range(0,mooseLoc.shape[0]):
#         lat = mooseLoc['lat'][i]
#         long = mooseLoc['long'][i]
        
#         if (lat, long) in uniqueLatLongs.keys():
#             continue
#         else:
#             uniqueLatLongs[(lat, long)] = True
            
#         # find nearest elevation grid cell
#         elevX = np.where((abs(elevLat - lat) == np.nanmin(abs(elevLat - lat))))[0][0]
#         elevY = np.where((abs(elevLon - long) == np.nanmin(abs(elevLon - long))))[0][0]
        
#         # convert to 0-360 for referencing cmip6
#         if long < 0: long += 360
#         tx = dsTasmaxHist.tasmax.sel(lat=lat, lon=long, method='nearest')
#         huss = dsHussHist.huss.sel(lat=lat, lon=long, method='nearest')
#         psl = dsPslHist.psl.sel(lat=lat, lon=long, method='nearest')
        
#         print('computing slp for station %d'%i)
#         # convert to surface pressure using the mean altitude at this grid cell
#         pSurf = psl * (1 - (L*elevationMap[elevX, elevY])/tx)**((g*M)/(R0*L))
        
#         print('computing tw for station %d'%i)
#         curTw = WetBulb.WetBulb(tx.values-273.15, pSurf.values, huss.values)
#         tw.append({'ID':mooseLoc['pointID'][i], 'TW':curTw}, ignore_index=True)
#     sys.exit()
    
# sys.exit()
