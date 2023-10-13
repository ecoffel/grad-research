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
    
    if not os.path.isfile('%s/hourly/gph500_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
#     if os.path.isfile('%s/daily/evaporation_%d.nc'%(dataDir, year)):
#         print('skipping %d: daily file already exists!'%year)
#         continue
    
    print('opening dataset for %d'%year)
    gph500 = xr.open_dataset('%s/hourly/gph500_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = gph500.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in gph500.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    gph500['time'] = tDt
    
    
    scale = gph500.z.attrs['scale_factor']
    offset = gph500.z.attrs['add_offset']
    missing = gph500.z.attrs['missing_value']

    ds_gph500 = xr.Dataset()
    
    for month in np.arange(1, 13):
        print('processing month %d'%month)
        
        cur_gph500 = gph500.sel(time = '%d-%d'%(year, month))
        
        print('scaling data for %d-%d'%(year, month))
        cur_gph500.where((cur_gph500 != missing))
        cur_gph500 = cur_gph500.astype(float) * scale + offset
        
        print('resampling gph500 data for %d-%d'%(year, month))
        cur_gph500 = cur_gph500.resample(time='1D').mean()

        if month == 1:
            ds_gph500 = cur_gph500
        else:
            ds_gph500 = xr.concat([ds_gph500, cur_gph500], dim='time')

    print('saving daily gph500 netcdf for %d'%year)
    ds_gph500.to_netcdf('%s/daily/gph500_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')