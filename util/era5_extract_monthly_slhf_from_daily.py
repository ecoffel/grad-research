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
    
    if not os.path.isfile('%s/daily/slhf_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
    if os.path.isfile('%s/monthly/slhf_%d.nc'%(dataDir, year)):
        print('skipping %d: monthly file already exists!'%year)
        continue
    
    print('opening dataset for %d'%year)
    slhf = xr.open_dataset('%s/daily/slhf_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = slhf.dims
    startingDate = datetime.datetime(year, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in slhf.time:
        delta = datetime.timedelta(days=int(curTTime.values))
        tDt.append(startingDate + delta)
    slhf['time'] = tDt

    print('resampling slhf data for %d'%year)
    slhf = slhf.resample(time='1M').mean()
    
    print('saving monthly slhf netcdf for %d'%year)
    slhf.to_netcdf('%s/monthly/slhf_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')