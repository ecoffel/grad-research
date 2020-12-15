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

dirChirts = '/dartfs-hpc/rc/lab/C/CMIG/CHIRTS'
urlChirts = 'http://data.chc.ucsb.edu/products/CHIRTSdaily/v1.0/global_tifs_p05/%s'%chirtsVar

years = range(1983, 2017)
months = range(1, 12+1)

for year in years:
    
    if not os.path.isdir('%s/%s/%d'%(dirChirts, chirtsVar, year)):
        os.mkdir('%s/%s/%d'%(dirChirts, chirtsVar, year))
    
    for month in months:
        for day in range(1, calendar.monthrange(year, month)[1]+1):
            
            filename = '%s.%d.%02d.%02d.tif'%(chirtsVar, year, month, day)
            remote_filepath = '%s/%d/%s'%(urlChirts, year, filename)
            local_dir = '%s/%s/%d/'%(dirChirts, chirtsVar, year)
            local_filepath = '%s/%s/%d/%s'%(dirChirts, chirtsVar, year, filename)
            
            if not os.path.isfile(local_filepath):
                cmd = 'wget -P %s %s'%(local_dir, remote_filepath)
                print(cmd)
                os.system(cmd)
            