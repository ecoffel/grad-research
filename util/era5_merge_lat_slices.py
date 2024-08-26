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

y = int(sys.argv[1])

daily_mean = False

for year in range(y,y+1):
    print('merging', year)
    # Calculate VPD
    vpd = xr.open_mfdataset(f'{dirERA5}/hourly/vpd/vpd_{year}_*.nc')

    vpd = vpd.rename({'__xarray_dataarray_variable__':'vpd'})

    if daily_mean:
        vpd_daily_mean = vpd.resample(time='1D').mean()
        print('writing netcdf for', year)
        vpd_daily_mean.to_netcdf(f'{dirERA5}/daily/vpd_daily_mean_{year}.nc')
        del vpd, vpd_daily_mean
    else:
        vpd_hours = vpd.sel(time=vpd['time'].dt.hour.isin(range(10, 17)))
        dates = vpd_hours['time'].dt.floor('D')
        vpd_10_4_mean = vpd_hours.groupby(dates).mean(dim='time').rename({'floor':'date'})
        vpd_10_4_mean.to_netcdf(f'{dirERA5}/daily/vpd_10am_4pm_mean_{year}.nc')
        del vpd, vpd_hours, dates, vpd_10_4_mean
