import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import pickle, gzip
import sys, os, re
import geopy.distance
import calendar 
import csv
import xarray as xr
import rasterio
import shapefile
import shapely.geometry as geometry
import datetime, calendar

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

startYear = 1981
endYear = 2005

ppLatLon = np.genfromtxt('%s/script-data/entsoe-nuke-pp-lat-lon.csv'%dataDirDiscovery, delimiter=',', skip_header=0)

tmaxNcepR2Ds = xr.open_mfdataset('/dartfs-hpc/rc/lab/C/CMIG/NCEP-DOE-R2/daily/tmax/tmax*.nc', decode_times=True, decode_cf=False, combine='by_coords')
add_offset = tmaxNcepR2Ds.tmax.attrs['add_offset']
scale_factor = tmaxNcepR2Ds.tmax.attrs['scale_factor']
missing_value = tmaxNcepR2Ds.tmax.attrs['missing_value']

startDate = datetime.datetime(1800, 1, 1, 0, 0, 0)
tDt = []
for t in tmaxNcepR2Ds.time:
    tDt.append(startDate+datetime.timedelta(hours=float(t.values)))
tmaxNcepR2Ds['time'] = tDt

tmaxNcepR2Ds = tmaxNcepR2Ds.where(tmaxNcepR2Ds != missing_value)
tmaxNcepR2Ds = tmaxNcepR2Ds.resample(time='1M').max()
tmaxNcepR2Ds = tmaxNcepR2Ds.where((tmaxNcepR2Ds['time.year'] >= startYear) & (tmaxNcepR2Ds['time.year'] <= endYear), drop=True)

tmaxNcepR2Ds = tmaxNcepR2Ds*scale_factor + add_offset

print('loading selected data')
tmaxNcepR2Ds.load()

tmaxNcepR2 = np.full([ppLatLon.shape[0]+2, (endYear-startYear+1)*12], np.nan)

print('selecting plant data')
for i, row in enumerate(ppLatLon):
    pId, pLat, pLon = row
    if pLon < 0: pLon += 360
    curTmax = tmaxNcepR2Ds.tmax.sel(lat=pLat, lon=pLon, method='nearest') - 273.15
    
    # set months on first loop
    if i == 0:
        tmaxNcepR2[0,:] = tmaxNcepR2Ds['time.year'].values
        tmaxNcepR2[1,:] = tmaxNcepR2Ds['time.month'].values
    tmaxNcepR2[i+2, :] = np.squeeze(curTmax.values)

np.savetxt('%s/script-data/entsoe-nuke-pp-tx-ncep-r2-%d-%d.csv'%(dataDirDiscovery, startYear, endYear), tmaxNcepR2, delimiter=',')

sys.exit()


