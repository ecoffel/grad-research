# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 15:42:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import sys, os
import datetime

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'

yearRange = [int(sys.argv[1]), int(sys.argv[2])]

for year in range(yearRange[0], yearRange[1]+1):
    
    if not os.path.isfile('%s/sp_hourly_%d.nc'%(dataDir, year)):
        print('skipping %s: file doesnt exist!'%('%s/sp_hourly_%d.nc'%(dataDir, year)))
        continue
    
    if os.path.isfile('%s/daily/sp_%d.nc'%(dataDir, year)):
        print('skipping %d: daily file already exists!'%year)
        continue
    
    print('opening dataset for %d'%year)
    sp = xr.open_dataset('%s/sp_hourly_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = sp.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in sp.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    sp['time'] = tDt
    
    scale = sp.sp.attrs['scale_factor']
    offset = sp.sp.attrs['add_offset']
    missing = sp.sp.attrs['missing_value']

    print('scaling data for %d'%year)
    sp.where((sp != missing))
    sp = sp.astype(float) * scale + offset
    
    print('resampling sp data for %d'%year)
    sp = sp.resample(time='1D').sum()
    
    print('saving daily sp netcdf for %d'%year)
    sp.to_netcdf('%s/daily/sp_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')