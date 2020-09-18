# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 15:42:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import os
import datetime

tfile = 'mn2t'
tvar = 'mn2t'

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'

for year in range(2019, 2019+1):
    print('opening dataset for %d'%year)
    ds = xr.open_dataset('%s/%s_hourly_%d.nc'%(dataDir, tfile, year), decode_cf=False)

    scale = ds[tvar].attrs['scale_factor']
    offset = ds[tvar].attrs['add_offset']
    missing = ds[tvar].attrs['missing_value']

    dims = ds.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    
    print('computing new times for %d'%year)
    for curTTime in ds.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    ds['time'] = tDt
    
    print('scaling data for %d'%year)
    ds[tvar] = ds[tvar].astype(float) * scale + offset
    
    if tvar == 'mx2t':
        print('resampling tasmax data for %d'%year)
        tx = ds.resample(time='1D').max()
        print('saving tasmax netcdf for %d'%year)
        tx.to_netcdf('%s/daily/tasmax_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

    elif tvar == 'mn2t':
        print('resampling tasmin data for %d'%year)
        tn = ds.resample(time='1D').min()
        print('saving tasmin netcdf for %d'%year)
        tn.to_netcdf('%s/daily/tasmin_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')
        

print('done')