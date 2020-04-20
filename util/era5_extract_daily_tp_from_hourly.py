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
    
    if not os.path.isfile('%s/tp_hourly_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
    if os.path.isfile('%s/daily/tp_%d.nc'%(dataDir, year)):
        print('skipping %d: daily file already exists!'%year)
        continue
    
    print('opening dataset for %d'%year)
    tp = xr.open_dataset('%s/tp_hourly_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = tp.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in tp.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    tp['time'] = tDt
    
    scale = tp.tp.attrs['scale_factor']
    offset = tp.tp.attrs['add_offset']
    missing = tp.tp.attrs['missing_value']

    print('scaling data for %d'%year)
    tp.where((tp != missing))
    tp = tp.astype(float) * scale + offset
    
    print('resampling tp data for %d'%year)
    tp = tp.resample(time='1D').sum()
    
    print('saving daily tp netcdf for %d'%year)
    tp.to_netcdf('%s/daily/tp_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')