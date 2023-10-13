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


sp = xr.open_dataset('%s/daily/sp_%d.nc'%(dirERA5, year))
#     sp = sp.sel(time='%d-07-01'%year)
#     sp.load()

dp2t = xr.open_dataset('%s/daily/dp_mean_%d.nc'%(dirERA5, year)) # UPDATE THIS!!
#     dp2t = dp2t.sel(time='%d-07-01'%year)
#     dp2t.load()


print('calc q for %d'%year)
q = spec_humidity(dp2t.d2m, sp.sp/100)


da_q = xr.DataArray(data   = q, 
                      dims   = ['time', 'latitude', 'longitude'],
                      coords = {'time':sp.time, 'latitude':sp.latitude, 'longitude':sp.longitude},
                      attrs  = {'units'     : 'kg/kg'
                        })
ds_q = xr.Dataset()
ds_q['q'] = da_q


print('saving netcdf...')
ds_q.to_netcdf('%s/daily/huss_%d.nc'%(dirERA5, year))
