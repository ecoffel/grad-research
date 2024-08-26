import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import glob
import sys, os
import datetime
import WetBulb

import warnings
warnings.filterwarnings('ignore')

# dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ERA5'
dataDir = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'

yearRange = [int(sys.argv[1]), int(sys.argv[2])]

chunk_size = 100

def spec_humidity(dp, sp):
    """Calculates SH automatically from the dewpt. Returns in g/kg"""
    # Declaring constants
    e0 = 6.113 # saturation vapor pressure in hPa
    # e0 and Pressure have to be in same units
    c_water = 5423 # L/R for water in Kelvin
    T0 = 273.15 # Kelvin

    # saturation vapor not required, uncomment to calculate it (units in hPa becuase of e0)
    #sat_vapor = self.e0 * np.exp((self.c * (self.temp -self.T0))/(self.temp * self.T0)) 

    #calculating specific humidity, q directly from dew point temperature
    #using equation 4.24, Pg 96 Practical Meteorolgy (Roland Stull)
    q = (622 * e0 * np.exp(c_water * (dp - T0)/(dp * T0)))/sp # g/kg 
    # 622 is the ratio of Rd/Rv in g/kg
    return q


for year in range(yearRange[0], yearRange[1]+1):
    print('opening mx2t datasets for %d'%year)
    mx2t = xr.open_dataset('%s/hourly/mx2t_hourly_%d.nc'%(dataDir, year))
#     mx2t = mx2t.sel(time='%d-07-01'%year)
#     mx2t.load()

    print('opening sp datasets for %d'%year)
    sp = xr.open_dataset('%s/hourly/sp_hourly_%d.nc'%(dataDir, year))
#     sp = sp.sel(time='%d-07-01'%year)
#     sp.load()

    print('opening dp2t datasets for %d'%year)
    dp2t = xr.open_dataset('%s/hourly/dp_hourly_%d.nc'%(dataDir, year)) # UPDATE THIS!!
#     dp2t = dp2t.sel(time='%d-07-01'%year)
#     dp2t.load()

    
    print('building dask chunks')
    dask_mx2t = mx2t.mx2t.chunk({'time':chunk_size, 'latitude':chunk_size, 'longitude':chunk_size})
    dask_sp = sp.sp.chunk({'time':chunk_size, 'latitude':chunk_size, 'longitude':chunk_size})
    dask_dp2t = dp2t.d2m.chunk({'time':chunk_size, 'latitude':chunk_size, 'longitude':chunk_size})

    print('computing specific hum')
    q=spec_humidity(dask_dp2t, dask_sp/100)
#     q.compute()

    dask_q = q.chunk({'time':chunk_size, 'latitude':chunk_size, 'longitude':chunk_size})/1000

#     dask_mx2t.load()
#     dask_sp.load()
#     dask_q.load()
    
    print('computing tw')
    tw = xr.apply_ufunc(WetBulb.WetBulb,
                            dask_mx2t-273.15, dask_sp, dask_q,
                            dask='parallelized',
#                             vectorize=True,
                            input_core_dims=None,
#                             output_core_dims=[['latitude'], ['longitude'], ['time']],
#                             output_sizes={'latitude':dask_mx2t.latitude.size, 'longitude':dask_mx2t.longitude.size, 'time':dask_mx2t.time.size},
                            output_dtypes=[dask_q.dtype],
                            )


    
#     tw = tw.compute()
    tw_ds = xr.Dataset()
    tw_ds['tw'] = tw
    
    print('writing netcdf')
    tw_ds.to_netcdf('%s/hourly/tw_%d.nc'%(dataDir, year), encoding={'tw': {"dtype": "float32", "zlib": True, 'complevel':9}})