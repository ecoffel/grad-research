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
    
    if not os.path.isfile('%s/sshf_hourly_%d.nc'%(dataDir, year)):
        print('skipping %s: file doesnt exist!'%('%s/sshf_hourly_%d.nc'%(dataDir, year)))
        continue
    
    if os.path.isfile('%s/daily/sshf_%d.nc'%(dataDir, year)):
        print('skipping %d: daily file already exists!'%year)
        continue
    
    print('opening dataset for %d'%year)
    sshf = xr.open_dataset('%s/sshf_hourly_%d.nc'%(dataDir, year), decode_cf=False)

    print('computing new times for %d'%year)
    dims = sshf.dims
    startingDate = datetime.datetime(1900, 1, 1, 0, 0, 0)
    tDt = []
    for curTTime in sshf.time:
        delta = datetime.timedelta(hours=int(curTTime.values))
        tDt.append(startingDate + delta)
    sshf['time'] = tDt
    
    scale = sshf.sshf.attrs['scale_factor']
    offset = sshf.sshf.attrs['add_offset']
    missing = sshf.sshf.attrs['missing_value']

    print('scaling data for %d'%year)
    sshf.where((sshf != missing))
    sshf = sshf.astype(float) * scale + offset
    
    print('resampling sshf data for %d'%year)
    sshf = sshf.resample(time='1D').mean()
    
    print('saving daily sshf netcdf for %d'%year)
    sshf.to_netcdf('%s/daily/sshf_%d.nc'%(dataDir, year), mode='w', format='NETCDF4')

        

print('done')