import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import datetime
import geopy.distance
import xarray as xr
import cartopy.crs as ccrs

import warnings
warnings.filterwarnings('ignore')

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'

# low and high temps for gdd/kdd calcs, taken from Butler, et al, 2015, ERL
t_low = 9
t_high = 29

crop = sys.argv[1]
wxData = sys.argv[2]

yearRange = [1981, 2018]


# load gdd/kdd from cpc temperature data
with gzip.open('%s/kdd-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'rb') as f:
    kdd = pickle.load(f)
    if wxData == 'cpc': kdd = kdd[:,:,1:]

with gzip.open('%s/gdd-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'rb') as f:
    gdd = pickle.load(f)
    if wxData == 'cpc': gdd = gdd[:,:,1:]

tx95 = np.full(gdd.shape, np.nan)
txMean = np.full(gdd.shape, np.nan)
for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):
    with gzip.open('%s/tx95-%s-%s-%d.dat'%(dataDirDiscovery, wxData, crop, year), 'rb') as f:
        curTx95 = pickle.load(f)
        tx95[:, :, y] = curTx95

    with gzip.open('%s/txMean-%s-%s-%d.dat'%(dataDirDiscovery, wxData, crop, year), 'rb') as f:
        curTxMean = pickle.load(f)
        txMean[:, :, y] = curTxMean
        
with gzip.open('%s/gdd-kdd-lat-%s.dat'%(dataDirDiscovery, wxData), 'rb') as f:
    lat = pickle.load(f)

with gzip.open('%s/gdd-kdd-lon-%s.dat'%(dataDirDiscovery, wxData), 'rb') as f:
    lon = pickle.load(f)

# calculate gdd and kdd trends from already-loaded cpc tmax and tmin data
gddTrends = np.full([gdd.shape[0], gdd.shape[1]], np.nan)
kddTrends = np.full([kdd.shape[0], kdd.shape[1]], np.nan)

tx95Trends = np.full([tx95.shape[0], tx95.shape[1]], np.nan)
txMeanTrends = np.full([txMean.shape[0], txMean.shape[1]], np.nan)

print('calculating trends...')

for x in range(gddTrends.shape[0]):

    if x % 20 == 0:
        print('%.0f %% done...'%(x/gddTrends.shape[0]*100))

    for y in range(gddTrends.shape[1]):
        nn = np.where(~np.isnan(gdd[x, y, :]))[0]
        if len(nn) == gdd.shape[2]:
            X = sm.add_constant(range(gdd.shape[2]))
            mdl = sm.OLS(gdd[x, y, :], X).fit()
            gddTrends[x, y] = mdl.params[1]

        nn = np.where(~np.isnan(kdd[x, y, :]))[0]
        if len(nn) == kdd.shape[2]:
            X = sm.add_constant(range(kdd.shape[2]))
            mdl = sm.OLS(kdd[x, y, :], X).fit()
            kddTrends[x, y] = mdl.params[1]

        nn = np.where(~np.isnan(tx95[x, y, :]))[0]
        if len(nn) == tx95.shape[2]:
            X = sm.add_constant(range(tx95.shape[2]))
            mdl = sm.OLS(tx95[x, y, :], X).fit()
            tx95Trends[x, y] = mdl.params[1]

        nn = np.where(~np.isnan(txMean[x, y, :]))[0]
        if len(nn) == txMean.shape[2]:
            X = sm.add_constant(range(txMean.shape[2]))
            mdl = sm.OLS(txMean[x, y, :], X).fit()
            txMeanTrends[x, y] = mdl.params[1]

# if a grid cell has no gdd/kdds, trend will be exactly 0 - set to nan
kddTrends[kddTrends == 0] = np.nan
gddTrends[gddTrends == 0] = np.nan
tx95Trends[tx95Trends == 0] = np.nan
txMeanTrends[txMeanTrends == 0] = np.nan

with gzip.open('%s/kdd-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(kddTrends, f)

with gzip.open('%s/gdd-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(gddTrends, f)

with gzip.open('%s/tx95-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(tx95Trends, f)

with gzip.open('%s/txMean-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(txMeanTrends, f)
