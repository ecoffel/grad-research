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

dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'

yearRange = [int(sys.argv[1]), int(sys.argv[2])]

for year in range(yearRange[0], yearRange[1]+1):
    
    if not os.path.isfile('%s/hourly/sp_hourly_%d.nc'%(dataDir, year)):
        print('skipping %s: file doesnt exist!'%('%s/sp_hourly_%d.nc'%(dataDir, year)))
        continue
    
#     if os.path.isfile('%s/daily/sp_%d.nc'%(dataDir, year)):
#         print('skipping %d: daily file already exists!'%year)
#         continue
    
    
    sp_daily = xr.Dataset()
    
    for month in range(1, 13):
        
        print('opening dataset for %d-%d'%(year,month))
        sp = xr.open_dataset('%s/hourly/sp_hourly_%d.nc'%(dataDir, year), decode_cf=False)

        print('computing new times for %d'%year)
        dims = sp.dims
        startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
        tDt = []
        for curTTime in sp.time:
            delta = datetime.timedelta(hours=int(curTTime.values))
            tDt.append(startingDate + delta)
        sp['time'] = tDt
        
        sp = sp.sel(time='%d-%02d'%(year, month))
        sp.load()

        scale = sp.sp.attrs['scale_factor']
        offset = sp.sp.attrs['add_offset']
        missing = sp.sp.attrs['missing_value']

        print('scaling data for %d'%year)
        sp.where((sp != missing))
        sp = sp.astype(float) * scale + offset

        print('resampling sp data for %d'%year)
        sp = sp.resample(time='1D').sum()

        if month > 1:
            sp_daily = xr.concat([sp_daily, sp], dim='time')
        else:
            sp_daily = sp
        
    print('saving daily sp netcdf for %d'%year)
    sp_daily.to_netcdf('%s/daily/sp_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')




print('done')