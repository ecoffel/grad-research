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

# model = 'bcc-csm2-mr'
model = sys.argv[1]
# model = 'kace-1-0-g'
# model = 'noresm2-lm'

year = int(sys.argv[2])

scenario = 'ssp245'

dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/CMIP6'
dataDirElevation = '/home/edcoffel/drive/MAX-Filer/Research/Climate-01/Personal-F20/edcoffel-F20/data/elevation'

print('loading hist %s/tasmax'%model)
dsTasmax = xr.open_mfdataset('%s/%s/r1i1p1f1/%s/tasmax/tasmax_day*.nc'%(dataDir, model, scenario), combine='by_coords')
dsTasmax = dsTasmax.where((dsTasmax['time.year'] == year), drop=True)
dsTasmax.load()

print('loading hist %s/huss'%model)
if model == 'bcc-esm1' or model == 'ipsl-cm6a-lr':
    dsHuss = xr.open_mfdataset('%s/%s/r1i1p1f1/%s/hus/hus_day*.nc'%(dataDir, model, scenario), combine='by_coords')
    dsHuss = dsHuss.where((dsHuss['time.year'] == year), drop=True)
    dsHuss = dsHuss.squeeze()
    dsHuss = dsHuss.rename({'hus':'huss'})
    dsHuss.load()
else:
    dsHuss = xr.open_mfdataset('%s/%s/r1i1p1f1/%s/huss/huss_day*.nc'%(dataDir, model, scenario), combine='by_coords')
    dsHuss = dsHuss.where((dsHuss['time.year'] == year), drop=True)
    dsHuss.load()

print('loading hist %s/psl'%model)
dsPsl = xr.open_mfdataset('%s/%s/r1i1p1f1/%s/psl/psl_day*.nc'%(dataDir, model, scenario), combine='by_coords')
dsPsl = dsPsl.where((dsPsl['time.year'] == year), drop=True)
dsPsl.load()


# build elev map for this grid res
latPixels = dsTasmax.lat.shape[0]
lonPixels = dsTasmax.lon.shape[0]

if not os.path.isfile('%s/elevation-map-%d-%d.dat'%(dataDirElevation, latPixels, lonPixels)):
    print('building elevation map for %s/(%d, %d)'%(model, latPixels, lonPixels))
    elevLat, elevLon, elevationMap = ag_build_elevation_map.buildElevationMap(latPixels=latPixels, lonPixels=lonPixels)
else:
    with open('%s/elevation-map-%d-%d.dat'%(dataDirElevation, latPixels, lonPixels), 'rb') as f:
        e = pickle.load(f)
        elevLat = e['lat']
        elevLon = e['lon']

        if np.nanmax(dsTasmax.lon > 300):
            elevLon[elevLon<0] += 360

        elevationMap = e['elevationMap']

L = 0.00976 # lapse rate (K/m)
cp = 1004.68506 # constant pressure specific heat (J/kg*K)
g = 9.80665 # gravitational acceleration (m/s2)
M = 0.02896968 # molar mass of dry air (kg/mol)
R0 = 8.3144 # universal gas constant (J/mol*K)

tx = dsTasmax.tasmax
huss = dsHuss.huss
psl = dsPsl.psl

# construct elevation subgrid that matches the grids of the cmip6 variables
elevSubMap = np.full([tx.lat.values.shape[0], tx.lon.values.shape[0]], np.nan)

print('calculating elevation sub grid for %s'%model)
for x, xlat in enumerate(tx.lat.values):
    for y, ylon in enumerate(tx.lon.values):
        elevX = np.where((abs(elevLat - xlat) == np.nanmin(abs(elevLat - xlat))))[0][0]
        elevY = np.where((abs(elevLon - ylon) == np.nanmin(abs(elevLon - ylon))))[0][0]

        elevSubMap[x, y] = elevationMap[elevX, elevY]

huss_values = np.full([dsHuss.time.size, dsHuss.lat.size, dsHuss.lon.size], np.nan)

# find huss for models with multiple levels
if model == 'bcc-esm1' or model == 'ipsl-cm6a-lr':
    for xlat in range(latPixels):
        for ylon in range(lonPixels):
            if elevSubMap[xlat, ylon] > 0:
                # mean over time, after this dim0 is plev
                cur_huss_mean = np.nanmean(huss.values[:, :, xlat, ylon], axis=0)
                
                #plev
                for p in range(cur_huss_mean.shape[0]):
                    if not np.isnan(cur_huss_mean[p]):
                        huss_values[:, xlat, ylon] = huss.values[:, p, xlat, ylon]
                        break
else:
    huss_values = huss.values

# calculate estimated surface pressure
print('calculating historical surface pressure for %s'%model)
pSurf = psl * (1 - (L*elevSubMap)/tx)**((g*M)/(R0*L))

# and now calculate wet bulb
print('calculating historical wet bulb temperature for %s'%model)
cur_tw = np.full([dsTasmax.time.size, latPixels, lonPixels], np.nan)
n = 0
n_total = np.where((elevSubMap.reshape([elevSubMap.size,1])>0))[0].size * dsTasmax.time.size
for xlat in range(latPixels):
    for ylon in range(lonPixels):
        if elevSubMap[xlat, ylon] > 0:
            for t in range(dsTasmax.time.size):
                if n % 1000 == 0:
                    print(n/n_total)

                cur_tx = np.array([tx.values[t, xlat, ylon]-273.15])
                cur_p_surf = np.array([pSurf.values[t, xlat, ylon]])
                cur_huss = np.array([huss_values[t, xlat, ylon]])
                
                cur_tw[t, xlat, ylon] = WetBulb.WetBulb(cur_tx, cur_p_surf, cur_huss)
                
                print(cur_tx, cur_p_surf, cur_huss, cur_tw[t,xlat,ylon])
                
                n += 1
    
dstw = xr.Dataset(
    {
        'tw':(('time', 'lat', 'lon'), cur_tw)
    },
    coords = {'time':tx.time, 'lat':tx.lat, 'lon':tx.lon},
)

print('writing tw change netcdf file for %s'%model)
dstw.to_netcdf(path='tw_daily_%s_%s_%d.nc'%(model, scenario, year), mode='w')
#     dstw.to_netcdf(path='%s/%s/r1i1p1f1/historical/tw/tw_daily.nc'%(dataDir, model), mode='w')
    
    
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
#         huss = dsHuss.huss.sel(lat=lat, lon=long, method='nearest')
#         psl = dsPsl.psl.sel(lat=lat, lon=long, method='nearest')
        
#         print('computing slp for station %d'%i)
#         # convert to surface pressure using the mean altitude at this grid cell
#         pSurf = psl * (1 - (L*elevationMap[elevX, elevY])/tx)**((g*M)/(R0*L))
        
#         print('computing tw for station %d'%i)
#         cur_tw = WetBulb.WetBulb(tx.values-273.15, pSurf.values, huss.values)
#         tw.append({'ID':mooseLoc['pointID'][i], 'TW':cur_tw}, ignore_index=True)
#     sys.exit()
    
# sys.exit()
