import xarray as xr
import pandas as pd
import numpy as np

import cartopy
import cartopy.crs as ccrs
import matplotlib.pyplot as plt

import glob
import sys
import os
import datetime
import calendar
import rasterio
import pickle

chirtsVar = 'HeatIndex'

# dirChirts = '/dartfs-hpc/rc/lab/C/CMIG/CHIRTS'
dirChirts = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/CHIRTS'
urlChirts = 'http://data.chc.ucsb.edu/products/CHIRTSdaily/v1.0/global_tifs_p05/%s'%chirtsVar

years = range(1983,2017)
months = range(1,13)

# to monthly netcdf

chirts_lat = np.linspace(70, -60, 2600)
chirts_lon = np.linspace(0, 360, 7200)

for year in years:
    
    local_dir = '%s/%s/%d'%(dirChirts, chirtsVar, year)
    output_dir = '%s/%s/netcdf'%(dirChirts, chirtsVar)
    
    for month in months:
        
        output_netcdf_file = '%s/hi_%d_%02d.nc'%(output_dir, year, month)
        if os.path.isfile(output_netcdf_file):
            continue
        
        cur_month_len = calendar.monthrange(year, month)[1]
        
        tmax_cur_month = np.full([chirts_lat.shape[0], chirts_lon.shape[0], cur_month_len], np.nan)
        
        error = False
        
        print('loading %d/%d...'%(year, month))
        for d, day in enumerate(range(1, cur_month_len+1)):
            
            filename = '%s.%d.%02d.%02d.tif'%(chirtsVar, year, month, day)
            remote_filepath = '%s/%d/%s'%(urlChirts, year, filename)
            local_filepath = '%s/%s/%d/%s'%(dirChirts, chirtsVar, year, filename)
            
            if not os.path.isfile(local_filepath):
                print('ERROR: skipping %d/%d, data not complete'%(year, month))
                error = True
                break
            
            tmax_tif = rasterio.open(local_filepath)
            tmax_tif_data = tmax_tif.read(1)
            tmax_tif_data[tmax_tif_data<-1000] = np.nan
            tmax_tif_data = np.roll(tmax_tif_data, -int(tmax_tif_data.shape[1]/2), axis=1)
            
            tmax_cur_month[:, :, d] = tmax_tif_data
        
        if not error:
            tmax_cur_month_ds = xr.Dataset(
            {
                "hi": (["lat", "lon", "time"], tmax_cur_month),
            },
            coords={
                "lat":chirts_lat,
                "lon":chirts_lon,
                "time": pd.date_range(start="%d-%02d-01"%(year, month), periods=cur_month_len)
            },)

            tmax_cur_month_ds.attrs["units"] = "degC"
            tmax_cur_month_ds.attrs["name"] = "CHIRTS-HEAT-INDEX"

            print('writing netcdf for %d/%d...'%(year, month))
            tmax_cur_month_ds.to_netcdf(output_netcdf_file)
        