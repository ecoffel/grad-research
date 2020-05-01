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
    
    if not os.path.isfile('%s/daily/evaporation_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
    if os.path.isfile('%s/monthly/evaporation_%d.nc'%(dataDir, year)):
        print('skipping %d: monthly file already exists!'%year)
        continue
    
    print('opening dataset for %d'%year)
    evap = xr.open_dataset('%s/daily/evaporation_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = evap.dims
    startingDate = datetime.datetime(year, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in evap.time:
        delta = datetime.timedelta(days=int(curTTime.values))
        tDt.append(startingDate + delta)
    evap['time'] = tDt

    print('resampling evaporation data for %d'%year)
    evap = evap.resample(time='1M').sum()
    
    print('saving monthly evaporation netcdf for %d'%year)
    evap.to_netcdf('%s/monthly/evaporation_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')