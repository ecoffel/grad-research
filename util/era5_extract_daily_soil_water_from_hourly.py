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
dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5-Land'

yearRange = [int(sys.argv[1]), int(sys.argv[2])]

sw_layer = 3

# for year in range(yearRange[0], yearRange[1]+1):
    
#     for month in range(1,13):
#         if not os.path.isfile('%s/hourly/volumetric_soil_water_layer_1_hourly_%d_%d.nc'%(dataDir, year, month)):
#             print('skipping %s: file doesnt exist!'%('%s/hourly/volumetric_soil_water_layer_1_hourly_%d_%d.nc'%(dataDir, year, month)))
#             continue

#         print('opening dataset for %d'%year)
#         sm = xr.open_dataset('%s/hourly/volumetric_soil_water_layer_1_hourly_%d_%d.nc'%(dataDir, year, month), mask_and_scale=True)


#     #     print('computing new times for %d'%year)
#     #     dims = slhf.dims
#     #     startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
#     #     tDt = []
#     #     for curTTime in slhf.time:
#     #         delta = datetime.timedelta(hours=int(curTTime.values))
#     #         tDt.append(startingDate + delta)
#     #     slhf['time'] = tDt

#     #     scale = sm.swvl1.attrs['scale_factor']
#     #     offset = sm.swvl1.attrs['add_offset']
#     #     missing = sm.swvl1.attrs['missing_value']

#     #     print('scaling data for %d'%year)
#     #     sm.where((sm != missing))
#     #     sm = sm.astype(float) * scale + offset

#         print('resampling sm data for %d'%year)
#         sm = sm.resample(time='1D').mean()

#         print('saving daily sm netcdf for %d'%year)
#         sm.to_netcdf('%s/daily/sm_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')


# First, resample each month and save to a new file
for year in range(yearRange[0], yearRange[1]+1):
    for month in range(1,13):
        if not os.path.isfile('%s/hourly/volumetric_soil_water_layer_%d_hourly_%d_%d.nc'%(dataDir, sw_layer, year, month)):
            print('skipping %s: file doesnt exist!'%('%s/hourly/volumetric_soil_water_layer_%d_hourly_%d_%d.nc'%(dataDir, sw_layer, year, month)))
            continue

        print('opening dataset for %d-%02d'%(year, month))
        sm = xr.open_dataset('%s/hourly/volumetric_soil_water_layer_%d_hourly_%d_%d.nc'%(dataDir, sw_layer, year, month), mask_and_scale=True)
        
        print('resampling sm data for %d-%02d'%(year, month))
        sm = sm.resample(time='1D').mean()
        
        print('saving daily sm netcdf for %d-%02d'%(year, month))
        sm.to_netcdf('%s/daily/sm_layer_%d_%d_%02d.nc'%(dataDir, sw_layer, year, month), mode='w', format='NETCDF4')


for year in range(yearRange[0], yearRange[1]+1):
    # Next, load the resampled files and concatenate them
    ds_list = []

    for month in range(1,13):
        if not os.path.isfile('%s/daily/sm_layer_%d_%d_%02d.nc'%(dataDir, sw_layer, year, month)):
            print('skipping %s: file doesnt exist!'%('%s/daily/sm_layer_%d_%d_%02d.nc'%(dataDir, sw_layer, year, month)))
            continue

        print('opening resampled dataset for %d-%02d'%(year, month))
        sm = xr.open_dataset('%s/daily/sm_layer_%d_%d_%02d.nc'%(dataDir, sw_layer, year, month), mask_and_scale=True)

        ds_list.append(sm)

    print('concatenating datasets')
    sm_all = xr.concat(ds_list, dim='time')

    print('saving daily sm netcdf for all years')
    sm_all.to_netcdf('%s/daily/sm_layer_%d_%d.nc'%(dataDir, sw_layer, year), mode='w', format='NETCDF4')


print('done')