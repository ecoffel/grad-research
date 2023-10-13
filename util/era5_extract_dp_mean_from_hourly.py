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

dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'

yearRange = [int(sys.argv[1]), int(sys.argv[2])]

for year in range(yearRange[0], yearRange[1]+1):
    
    dp_daily = xr.Dataset()    
    
    for month in range(1, 13):
    
        print('opening dataset for %d-%d'%(year,month))
        dp = xr.open_dataset('%s/hourly/dp_hourly_%d.nc'%(dataDir, year), decode_cf=False)

        print('computing new times for %d'%year)
        dims = dp.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []
        for curTTime in dp.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        dp['time'] = tDt

        dp = dp.sel(time='%d-%02d'%(year, month))
        dp.load()
        
        scale = dp.d2m.attrs['scale_factor']
        offset = dp.d2m.attrs['add_offset']
        missing = dp.d2m.attrs['missing_value']

        print('scaling data for %d'%year)
        dp.where((dp != missing))
        dp = dp.astype(float) * scale + offset

        print('resampling dp data for %d'%year)
        dp = dp.resample(time='1D').mean()
        
        if month > 1:
            dp_daily = xr.concat([dp_daily, dp], dim='time')
        else:
            dp_daily = dp
        
    print('saving mean dp netcdf for %d'%year)
    dp_daily.to_netcdf('%s/daily/dp_mean_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')