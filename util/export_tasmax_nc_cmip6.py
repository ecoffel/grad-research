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
dataDirMoose = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/moose-wet-bulb'

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

    # build elev map for this grid res
    latPixels = dsTasmaxHist.lat.shape[0]
    lonPixels = dsTasmaxHist.lon.shape[0]
    
    txHist = dsTasmaxHist.tasmax
    txSSP370 = dsTasmaxSSP370.tasmax
    
    print('calculating monthly mean tw change')
    dsTasmaxHist = xr.Dataset(
        {
            'tasmax':(('time', 'lat', 'lon'), txHist.values)
        },
        coords = {'time':txHist.time, 'lat':txHist.lat, 'lon':txHist.lon},
    )
    
    dsTasmaxSSP370 = xr.Dataset(
        {
            'tasmax':(('time', 'lat', 'lon'), txSSP370.values)
        },
        coords = {'time':txSSP370.time, 'lat':txSSP370.lat, 'lon':txSSP370.lon},
    )
    
    dsTasmaxDecadalChg = xr.Dataset(
        coords = {'lat':txSSP370.lat, 'lon':txSSP370.lon, 'month':np.arange(1,13)},
    )
    
    for d in range(decades.shape[0]):
        dsTasmaxSSP370CurDec = dsTasmaxSSP370.where((dsTasmaxSSP370['time.year'] >= decades[d, 0]) & (dsTasmaxSSP370['time.year'] <= decades[d, 1]), drop=True)
        dsChg = dsTasmaxSSP370CurDec.resample(time='1M').mean().groupby('time.month').mean()-dsTasmaxHist.resample(time='1M').mean().groupby('time.month').mean()
        dsTasmaxDecadalChg['decade%d'%decades[d,0]] = dsChg.tasmax
    
    print('writing tasmax change netcdf file for %s'%model)
    dsTasmaxDecadalChg.to_netcdf(path='%s/tasmax-chg-monthly/tasmax-chg-%s.nc'%(dataDirMoose, model), mode='w')
    
    
