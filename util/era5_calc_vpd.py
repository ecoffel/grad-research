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
l1 = float(sys.argv[2])
l2 = float(sys.argv[3])

import xarray as xr

def calculate_vpd(dew_point_temp, mean_temp):
    """
    Calculate the Vapor Pressure Deficit (VPD) without adjusting for surface pressure.

    Parameters:
    - dew_point_temp: Dew point temperature in degrees Celsius.
    - mean_temp: Mean temperature in degrees Celsius.

    Returns:
    - VPD in hPa.
    """
    # Constants
    A = 6.112  # hPa
    B = 17.67
    C = 243.5  # °C

    es = A * np.exp((B * mean_temp) / (C + mean_temp))
    
    # Calculate actual vapor pressure for dew point temperature (ea)
    ea = A * np.exp((B * dew_point_temp) / (C + dew_point_temp))
    
    
    # Calculate VPD
    vpd = es - ea

    return vpd

# Load your data (adjust paths and variable names as needed)
ds_temp = xr.open_dataset(f'{dirERA5}/hourly/2m_temp_hourly_{year}.nc').sel(latitude=slice(l1,l2))
ds_dpt = xr.open_dataset(f'{dirERA5}/hourly/dp_hourly_{year}.nc').sel(latitude=slice(l1,l2))


# Calculate VPD
vpd = calculate_vpd(ds_dpt['d2m']-273.15, ds_temp['t2m']-273.15)


# Save the VPD data to a new netCDF file
vpd.to_netcdf(f'{dirERA5}/hourly/vpd/vpd_{year}_{l1}_{l2}.nc')

