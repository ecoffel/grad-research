# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 15:42:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import os, sys
import datetime

tfile = 'mx2t'
tvar = 'mx2t'

years = [int(sys.argv[1]), int(sys.argv[2])]

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'

for year in range(years[0], years[1]+1):
    print('opening dataset for %d'%year)
    ds = xr.open_dataset('%s/hourly/%s_hourly_%d.nc'%(dataDir, tfile, year))

#     scale = ds[tvar].attrs['scale_factor']
#     offset = ds[tvar].attrs['add_offset']
#     missing = ds[tvar].attrs['missing_value']

#     dims = ds.dims
#     startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
#     tDt = []
    
#     print('computing new times for %d'%year)
#     for curTTime in ds.time:
#         delta = datetime.timedelta(hours=int(curTTime.values))
#         tDt.append(startingDate + delta)
#     ds['time'] = tDt
    
#     print('scaling data for %d'%year)
#     ds[tvar] = ds[tvar].astype(float) * scale + offset
    
    if tvar == 'mx2t':
        print('resampling tasmax data for %d'%year)
        tx = ds.resample(time='1D').max()
        print('saving tasmax netcdf for %d'%year)
        tx.to_netcdf('%s/daily/tasmax_%d.nc'%(dataDir, year), mode='w', encoding={'mx2t': {"dtype": "float32", "zlib": True, 'complevel':9}})

    elif tvar == 'mn2t':
        print('resampling tasmin data for %d'%year)
        tn = ds.resample(time='1D').min()
        print('saving tasmin netcdf for %d'%year)
        tn.to_netcdf('%s/daily/tasmin_%d.nc'%(dataDir, year), mode='w', encoding={'mn2t': {"dtype": "float32", "zlib": True, 'complevel':9}})
    
    elif tvar == 'tw':
        print('computing tw_max %d'%year)
        tw_max = ds.resample(time='1D').max()
        print('saving tasmin netcdf for %d'%year)
        tw_max.to_netcdf('%s/daily/tw_max_%d.nc'%(dataDir, year), mode='w', encoding={'tw': {"dtype": "float32", "zlib": True, 'complevel':9}})
        
        print('computing tw_min %d'%year)
        tw_min = ds.resample(time='1D').min()
        print('saving tasmin netcdf for %d'%year)
        tw_min.to_netcdf('%s/daily/tw_min_%d.nc'%(dataDir, year), mode='w', encoding={'tw': {"dtype": "float32", "zlib": True, 'complevel':9}})
        
        print('computing tw_mean %d'%year)
        tw_mean = ds.resample(time='1D').mean()
        print('saving tasmin netcdf for %d'%year)
        tw_mean.to_netcdf('%s/daily/tw_mean_%d.nc'%(dataDir, year), mode='w', encoding={'tw': {"dtype": "float32", "zlib": True, 'complevel':9}})
        

print('done')