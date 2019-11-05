# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 15:42:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import os
import datetime

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'

for year in range(1979, 2019):
    print('opening dataset for %d'%year)
    dsMax = xr.open_dataset('%s/tmax_hourly_%d.nc'%(dataDir, year), decode_cf=False)
    dsMin = xr.open_dataset('%s/tmin_hourly_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = dsMax.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in dsMax.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    dsMax['time'] = tDt
    
    dims = dsMin.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in dsMin.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    dsMin['time'] = tDt
    
    scale = dsMax.mx2t.attrs['scale_factor']
    offset = dsMax.mx2t.attrs['add_offset']
    missing = dsMax.mx2t.attrs['missing_value']

    print('scaling data for %d'%year)
    dsMax.where((dsMax != missing))
    dsMin.where((dsMin != missing))
    dsMax = dsMax.astype(float) * scale + offset
    dsMin = dsMin.astype(float) * scale + offset
    
    print('resampling mx2t data for %d'%year)
    dsMax = dsMax.resample(time='1D').mean()
    
    print('resampling mn2t data for %d'%year)
    dsMin = dsMin.resample(time='1D').mean()
    
    print('calculating tasmean for %d'%year)
    dsMean = (dsMax['mx2t'] + dsMin['mn2t']) / 2.0 - 273.15
    
    print('saving tasmean netcdf for %d'%year)
    dsMean.to_netcdf('%s/daily/tasmean_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')