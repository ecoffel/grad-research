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

# area covering NE US
latRange = (35, 60)
lonRange = (275, 305)

decades = np.array([[2020,2029],\
                   [2030, 2039],\
                   [2040,2049],\
                   [2050,2059],\
                   [2060,2069],\
                   [2070,2079],\
                   [2080,2089],\
                   [2090,2099]])

models = ['bcc-csm2-mr', 'canesm5', 'mri-esm2-0']

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/CMIP6'
dataDirElevation = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/elevation'
dataDirMoose = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/moose-wet-bulb'

# read in moose locations into data frame
mooseLoc = pd.read_csv('%s/all_moose_locations.csv'%dataDirMoose)
mooseLoc['dateTimeLocal'] = pd.to_datetime(mooseLoc['dateTimeLocal'], format='%Y-%m-%d %H:%M:%S')

for model in models:
    print('loading hist %s/tasmax'%model)
    dsTasmaxHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/tasmax/*.nc'%(dataDir, model), combine='by_coords')
    dsTasmaxHist = dsTasmaxHist.where((dsTasmaxHist['time.year'] >= 1981) & (dsTasmaxHist['time.year'] <= 2015), drop=True)
    dsTasmaxHist = dsTasmaxHist.sel(lat=slice(*latRange), lon=slice(*lonRange))
    dsTasmaxHist.load()
    
    print('loading ssp3-7 %s/tasmax'%model)
    dsTasmaxSSP370 = xr.open_mfdataset('%s/%s/r1i1p1f1/ssp370/tasmax/*.nc'%(dataDir, model), combine='by_coords')
    dsTasmaxSSP370 = dsTasmaxSSP370.where((dsTasmaxSSP370['time.year'] <= 2100), drop=True)
    dsTasmaxSSP370 = dsTasmaxSSP370.sel(lat=slice(*latRange), lon=slice(*lonRange))
    dsTasmaxSSP370.load()

    print('loading hist %s/huss'%model)
    dsHussHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/huss/*.nc'%(dataDir, model), combine='by_coords')
    dsHussHist = dsHussHist.where((dsHussHist['time.year'] >= 1981) & (dsHussHist['time.year'] <= 2015), drop=True)
    dsHussHist = dsHussHist.sel(lat=slice(*latRange), lon=slice(*lonRange))
    dsHussHist.load()
    
    print('loading ssp3-7 %s/huss'%model)
    dsHussSSP370 = xr.open_mfdataset('%s/%s/r1i1p1f1/ssp370/huss/*.nc'%(dataDir, model), combine='by_coords')
    dsHussSSP370 = dsHussSSP370.where((dsHussSSP370['time.year'] <= 2100), drop=True)
    dsHussSSP370 = dsHussSSP370.sel(lat=slice(*latRange), lon=slice(*lonRange))
    dsHussSSP370.load()
    
    print('loading hist %s/psl'%model)
    dsPslHist = xr.open_mfdataset('%s/%s/r1i1p1f1/historical/psl/*.nc'%(dataDir, model), combine='by_coords')
    dsPslHist = dsPslHist.where((dsPslHist['time.year'] >= 1981) & (dsPslHist['time.year'] <= 2015), drop=True)
    dsPslHist = dsPslHist.sel(lat=slice(*latRange), lon=slice(*lonRange))
    dsPslHist.load()
    
    print('loading ssp3-7 %s/psl'%model)
    dsPslSSP370 = xr.open_mfdataset('%s/%s/r1i1p1f1/ssp370/psl/*.nc'%(dataDir, model), combine='by_coords')
    dsPslSSP370 = dsPslSSP370.where((dsPslSSP370['time.year'] <= 2100), drop=True)
    dsPslSSP370 = dsPslSSP370.sel(lat=slice(*latRange), lon=slice(*lonRange))
    dsPslSSP370.load()
    
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
            elevationMap = e['elevationMap']
    
    L = 0.00976 # lapse rate (K/m)
    cp = 1004.68506 # constant pressure specific heat (J/kg*K)
    g = 9.80665 # gravitational acceleration (m/s2)
    M = 0.02896968 # molar mass of dry air (kg/mol)
    R0 = 8.3144 # universal gas constant (J/mol*K)
    
    
    txHist = dsTasmaxHist.tasmax
    hussHist = dsHussHist.huss
    pslHist = dsPslHist.psl
    
    txSSP370 = dsTasmaxSSP370.tasmax
    hussSSP370 = dsHussSSP370.huss
    pslSSP370 = dsPslSSP370.psl
    
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
    
    print('calculating ssp370 surface pressure for %s'%model)
    pSurfSSP370 = pslSSP370 * (1 - (L*elevSubMap)/txSSP370)**((g*M)/(R0*L))
    
    # and now calculate wet bulb
    print('calculating historical wet bulb temperature for %s'%model)
    curTwHist = WetBulb.WetBulb(txHist.values-273.15, pSurfHist.values, hussHist.values)
    
    print('calculating ssp370 wet bulb temperature for %s'%model)
    curTwSSP370 = WetBulb.WetBulb(txSSP370.values-273.15, pSurfSSP370.values, hussSSP370.values)
    
    print('calculating monthly mean tw change')
    dsTwHist = xr.Dataset(
        {
            'tw':(('time', 'lat', 'lon'), curTwHist[0])
        },
        coords = {'time':txHist.time, 'lat':txHist.lat, 'lon':txHist.lon},
    )
    
    dsTwSSP370 = xr.Dataset(
        {
            'tw':(('time', 'lat', 'lon'), curTwSSP370[0])
        },
        coords = {'time':txSSP370.time, 'lat':txSSP370.lat, 'lon':txSSP370.lon},
    )
    
    dsTwDecadalChg = xr.Dataset(
        coords = {'lat':txSSP370.lat, 'lon':txSSP370.lon, 'month':np.arange(1,13)},
    )
    
    for d in range(decades.shape[0]):
        dsTwSSP370CurDec = dsTwSSP370.where((dsTwSSP370['time.year'] >= decades[d, 0]) & (dsTwSSP370['time.year'] <= decades[d, 1]), drop=True)
        dsChg = dsTwSSP370CurDec.resample(time='1M').mean().groupby('time.month').mean()-dsTwHist.resample(time='1M').mean().groupby('time.month').mean()
        dsTwDecadalChg['decade%d'%decades[d,0]] = dsChg.tw
    
    print('writing tw change netcdf file for %s'%model)
    dsTwDecadalChg.to_netcdf(path='%s/tw-chg-monthly/tw-chg-%s.nc'%(dataDirMoose, model), mode='w')
    
    
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
