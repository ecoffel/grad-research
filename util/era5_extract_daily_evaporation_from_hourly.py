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
    
    if not os.path.isfile('%s/evaporation_hourly_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
    if os.path.isfile('%s/daily/evaporation_%d.nc'%(dataDir, year)):
        print('skipping %d: daily file already exists!'%year)
        continue
    
    print('opening dataset for %d'%year)
    evap = xr.open_dataset('%s/evaporation_hourly_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = evap.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in evap.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    evap['time'] = tDt
    
    scale = evap.e.attrs['scale_factor']
    offset = evap.e.attrs['add_offset']
    missing = evap.e.attrs['missing_value']

    print('scaling data for %d'%year)
    evap.where((evap != missing))
    evap = evap.astype(float) * scale + offset
    
    print('resampling evaporation data for %d'%year)
    evap = evap.resample(time='1D').sum()
    
    print('saving daily evaporation netcdf for %d'%year)
    evap.to_netcdf('%s/daily/evaporation_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')