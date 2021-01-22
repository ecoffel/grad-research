import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import sys, os
import datetime
import WetBulb

import warnings
warnings.filterwarnings('ignore')

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'

year = int(sys.argv[1])

tw = xr.open_dataset('%s/hourly/tw_%d.nc'%(dataDir, year))
tw.load()
tw = tw.rename({'__xarray_dataarray_variable__':'tw'})
tw.to_netcdf('%s/hourly/tw_%d_comp.nc'%(dataDir, year), encoding={'tw': {"dtype": "float32", "zlib": True, 'complevel':9}})