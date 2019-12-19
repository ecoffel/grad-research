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

tmax20CRDs = xr.open_mfdataset('/dartfs-hpc/rc/lab/C/CMIG/20CR/tmax/tmax*.nc', decode_times=True, decode_cf=False, combine='by_coords')

startDate = datetime.datetime(1800, 1, 1, 0, 0, 0)
tDt = []
for t in tmax20CRDs.time:
    tDt.append(startDate+datetime.timedelta(hours=float(t.values)))
tmax20CRDs['time'] = tDt

tmax20CRDs = tmax20CRDs.resample(time='1M').max()
tmax20CRDs = tmax20CRDs.where((tmax20CRDs['time.year'] < startYear) | (tmax20CRDs['time.year'] > endYear), drop=True)

print('loading selected data')
tmax20CRDs.load()

tmax20CR = np.full([ppLatLon.shape[0]+2, 51*12], np.nan)

print('selecting plant data')
for i, row in enumerate(ppLatLon):
    pId, pLat, pLon = row
    if pLon < 0: pLon += 360
    curTmax = tmax20CRDs.tmax.sel(lat=pLat, lon=pLon, method='nearest') - 273.15
    
    # set months on first loop
    if i == 0:
        tmax20CR[0,:] = tmax20CRDs['time.year'].values
        tmax20CR[1,:] = tmax20CRDs['time.month'].values
    tmax20CR[i+2, :] = curTmax

np.savetxt('%s/script-data/entsoe-nuke-pp-tx-20cr-%d-%d.csv'%(dataDirDiscovery, startYear, endYear), tmax20CR, delimiter=',')

sys.exit()


