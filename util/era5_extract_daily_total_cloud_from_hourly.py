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
    
    if not os.path.isfile('%s/hourly/total_cloud_%d.nc'%(dataDir, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
#     if os.path.isfile('%s/daily/evaporation_%d.nc'%(dataDir, year)):
#         print('skipping %d: daily file already exists!'%year)
#         continue
    
    print('opening dataset for %d'%year)
    total_cloud = xr.open_dataset('%s/hourly/total_cloud_%d.nc'%(dataDir, year), decode_cf=False)
    
    print('computing new times for %d'%year)
    dims = total_cloud.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in total_cloud.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    total_cloud['time'] = tDt
    
    
    scale = total_cloud.tcc.attrs['scale_factor']
    offset = total_cloud.tcc.attrs['add_offset']
    missing = total_cloud.tcc.attrs['missing_value']

    ds_total_cloud = xr.Dataset()
    
    for month in np.arange(1, 13):
        print('processing month %d'%month)
        
        cur_total_cloud = total_cloud.sel(time = '%d-%d'%(year, month))
        
        print('scaling data for %d-%d'%(year, month))
        cur_total_cloud.where((cur_total_cloud != missing))
        cur_total_cloud = cur_total_cloud.astype(float) * scale + offset
        
        print('resampling gph500 data for %d-%d'%(year, month))
        cur_total_cloud = cur_total_cloud.resample(time='1D').mean()

        if month == 1:
            ds_total_cloud = cur_total_cloud
        else:
            ds_total_cloud = xr.concat([ds_total_cloud, cur_total_cloud], dim='time')

    print('saving daily cur_total_cloud netcdf for %d'%year)
    ds_total_cloud.to_netcdf('%s/daily/total_cloud_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')