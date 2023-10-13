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
wind_var = sys.argv[3]

for year in range(yearRange[0], yearRange[1]+1):
    
    if not os.path.isfile('%s/hourly/%s_1000mb_hourly_%d.nc'%(dataDir, wind_var, year)):
        print('skipping %d: file doesnt exist!'%year)
        continue
    
#     if os.path.isfile('%s/daily/evaporation_%d.nc'%(dataDir, year)):
#         print('skipping %d: daily file already exists!'%year)
#         continue
    
    print('opening dataset for %d'%year)
    era5_wind = xr.open_dataset('%s/hourly/%s_1000mb_hourly_%d.nc'%(dataDir, wind_var, year), decode_cf=False)
    
    print('computing new times for %d'%year)
    dims = era5_wind.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in era5_wind.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    era5_wind['time'] = tDt
    
    
    scale = era5_wind[wind_var].attrs['scale_factor']
    offset = era5_wind[wind_var].attrs['add_offset']
    missing = era5_wind[wind_var].attrs['missing_value']

    ds_era5_wind = xr.Dataset()
    
    for month in np.arange(1, 13):
        print('processing month %d'%month)
        
        cur_era5_wind = era5_wind.sel(time = '%d-%d'%(year, month))
        
        print('scaling data for %d-%d'%(year, month))
        cur_era5_wind.where((cur_era5_wind != missing))
        cur_era5_wind = cur_era5_wind.astype(float) * scale + offset
        
        print('resampling wind data for %d-%d'%(year, month))
        cur_era5_wind = cur_era5_wind.resample(time='1D').mean()

        if month == 1:
            ds_era5_wind = cur_era5_wind
        else:
            ds_era5_wind = xr.concat([ds_era5_wind, cur_era5_wind], dim='time')

    print('saving daily cur_total_cloud netcdf for %d'%year)
    ds_era5_wind.to_netcdf('%s/daily/%s_1000mb_%d.nc'%(dataDir, wind_var, year), mode='w', format='NETCDF4')

        

print('done')