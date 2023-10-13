import xarray as xr
import xesmf as xe
import numpy as np
import matplotlib.pyplot as plt
import scipy
import statsmodels.api as sm
import cartopy
import cartopy.crs as ccrs
import glob
import sys
import datetime

dirERA5 = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'


year = int(sys.argv[1])

sshf = xr.open_dataset('%s/daily/sshf_%d.nc'%(dirERA5, year))

slhf = xr.open_dataset('%s/daily/slhf_%d.nc'%(dirERA5, year)) # UPDATE THIS!!


print('calc q for %d'%year)
ef = (slhf.slhf / (slhf.slhf+sshf.sshf))

da_ef = xr.DataArray(data   = ef, 
                      dims   = ['time', 'latitude', 'longitude'],
                      coords = {'time':sshf.time, 'latitude':sshf.latitude, 'longitude':sshf.longitude},
                      attrs  = {'units'     : 'fraction'
                        })
ds_ef = xr.Dataset()
ds_ef['ef'] = da_ef


print('saving netcdf...')
ds_ef.to_netcdf('%s/daily/ef_%d.nc'%(dirERA5, year))
