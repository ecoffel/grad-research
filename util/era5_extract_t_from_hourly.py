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

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'

for year in range(1979, 2019):
    print('opening dataset for %d'%year)
    ds = xr.open_dataset('%s/tmax_hourly_%d.nc'%(dataDir, year), decode_cf=False)

    scale = ds.mx2t.attrs['scale_factor']
    offset = ds.mx2t.attrs['add_offset']
    missing = ds.mx2t.attrs['missing_value']

    dims = ds.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    
    print('computing new times for %d'%year)
    for curTTime in ds.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    ds['time'] = tDt
    
    print('scaling data for %d'%year)
    ds['mx2t'] = ds['mx2t'].astype(float) * scale + offset
    
    if not os.path.isfile('%s/daily/tasmax_%d.nc'%(dataDir, year)):
        print('resampling tasmax data for %d'%year)
        tx = ds.resample(time='1D').max()
        print('saving tasmax netcdf for %d'%year)
        tx.to_netcdf('%s/daily/tasmax_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

    if not os.path.isfile('%s/daily/tasmin_%d.nc'%(dataDir, year)):
        print('resampling tasmin data for %d'%year)
        tn = ds.resample(time='1D').min()
        print('saving tasmin netcdf for %d'%year)
        tn.to_netcdf('%s/daily/tasmin_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')
    
    if not os.path.isfile('%s/daily/tasmean_%d.nc'%(dataDir, year)):
        print('resampling tasmean data for %d'%year)
        tas = ds.resample(time='1D').mean()
        print('saving tasmean netcdf for %d'%year)
        tas.to_netcdf('%s/daily/tasmean_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')
#for xlat in range(dims['latitude']):
#    for ylon in range(dims['longitude']):
        

print('done')