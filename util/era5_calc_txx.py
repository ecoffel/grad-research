import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import sys, os
import datetime
import WetBulb

dirEra5 = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'
years = [1981, 2021]

mx2t = xr.open_mfdataset('%s/daily/tasmax_*.nc'%(dirEra5), combine='by_coords')
txx = mx2t.resample(time='1Y').max()
txx = txx.rename({'mx2t':'txx'})

txx.to_netcdf('%s/era5_txx.nc'%(dirEra5), encoding={'txx': {"dtype": "float32", "zlib": True, 'complevel':9}})