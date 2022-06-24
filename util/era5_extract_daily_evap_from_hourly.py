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

# dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'
dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'

yearRange = [int(sys.argv[1]), int(sys.argv[2])]

for year in range(yearRange[0], yearRange[1]+1):
    
    if not os.path.isfile('%s/hourly/evaporation_hourly_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
#     if os.path.isfile('%s/daily/evaporation_%d.nc'%(dataDir, year)):
#         print('skipping %d: daily file already exists!'%year)
#         continue
    
    print('opening dataset for %d'%year)
    evap = xr.open_dataset('%s/hourly/evaporation_hourly_%d.nc'%(dataDir, year), decode_cf=False)

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

    ds_evap = xr.Dataset()
    
    for month in np.arange(1, 13):
        print('processing month %d'%month)
        
        cur_evap = evap.sel(time = '%d-%d'%(year, month))
        
        print('scaling data for %d-%d'%(year, month))
        cur_evap.where((cur_evap != missing))
        cur_evap = cur_evap.astype(float) * scale + offset
        
        print('resampling evaporation data for %d-%d'%(year, month))
        cur_evap = cur_evap.resample(time='1D').sum()

        if month == 1:
            ds_evap = cur_evap
        else:
            ds_evap = xr.concat([ds_evap, cur_evap], dim='time')
        
    print('saving daily evaporation netcdf for %d'%year)
    ds_evap.to_netcdf('%s/daily/evaporation_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')