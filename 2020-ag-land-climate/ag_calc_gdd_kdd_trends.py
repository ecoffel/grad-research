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

yearRange = [1981, 2019]

sacksLat = np.linspace(90, -90, 360)
sacksLon = np.linspace(0, 360, 720)

# load gdd/kdd from cpc temperature data
if wxData == 'cpc':
    gdd = np.full([len(sacksLat), len(sacksLon), (yearRange[1]-yearRange[0]+1)], np.nan)
    kdd = np.full([len(sacksLat), len(sacksLon), (yearRange[1]-yearRange[0]+1)], np.nan)
elif wxData == 'era5':
    gdd = np.full([721, 1440, (yearRange[1]-yearRange[0]+1)], np.nan)
    kdd = np.full([721, 1440, (yearRange[1]-yearRange[0]+1)], np.nan)

for y, year in enumerate(np.arange(yearRange[0], yearRange[1]+1)):
    print('loading gdd/kdd data for %d'%year)
    with gzip.open('%s/kdd-%s-%s-%d.dat'%(dataDirDiscovery, wxData, crop, year), 'rb') as f:
        curKdd = pickle.load(f)
        kdd[:, :, y] = curKdd
        
    with gzip.open('%s/gdd-%s-%s-%d.dat'%(dataDirDiscovery, wxData, crop, year), 'rb') as f:
        curGdd = pickle.load(f)
        gdd[:, :, y] = curGdd
        
with gzip.open('%s/gdd-kdd-lat-%s.dat'%(dataDirDiscovery, wxData), 'rb') as f:
    lat = pickle.load(f)

with gzip.open('%s/gdd-kdd-lon-%s.dat'%(dataDirDiscovery, wxData), 'rb') as f:
    lon = pickle.load(f)

with open('%s/seasonal-et-maize-era5.dat'%(dataDirDiscovery), 'rb') as f:
    seasonalEvap = pickle.load(f)
with open('%s/seasonal-precip-maize-era5.dat'%(dataDirDiscovery), 'rb') as f:
    seasonalPrecip = pickle.load(f)
with open('%s/seasonal-sshf-maize-era5.dat'%(dataDirDiscovery), 'rb') as f:
    seasonalSshf = pickle.load(f)
with open('%s/seasonal-slhf-maize-era5.dat'%(dataDirDiscovery), 'rb') as f:
    seasonalSlhf = pickle.load(f)
with open('%s/seasonal-str-maize-era5.dat'%(dataDirDiscovery), 'rb') as f:
    seasonalStr = pickle.load(f)
with open('%s/seasonal-ssr-maize-era5.dat'%(dataDirDiscovery), 'rb') as f:
    seasonalSsr = pickle.load(f)
    
# calculate gdd and kdd trends from already-loaded cpc tmax and tmin data
gddTrends = np.full([gdd.shape[0], gdd.shape[1]], np.nan)
kddTrends = np.full([kdd.shape[0], kdd.shape[1]], np.nan)
evapTrends = np.full([seasonalEvap.shape[0], seasonalEvap.shape[1]], np.nan)
prTrends = np.full([seasonalPrecip.shape[0], seasonalEvap.shape[1]], np.nan)
sshfTrends = np.full([seasonalSshf.shape[0], seasonalSshf.shape[1]], np.nan)
slhfTrends = np.full([seasonalSlhf.shape[0], seasonalSlhf.shape[1]], np.nan)
strTrends = np.full([seasonalSlhf.shape[0], seasonalSlhf.shape[1]], np.nan)
ssrTrends = np.full([seasonalSlhf.shape[0], seasonalSlhf.shape[1]], np.nan)
netRadTrends = np.full([seasonalSlhf.shape[0], seasonalSlhf.shape[1]], np.nan)

print('computing gdd, kdd trends')

for x in range(gddTrends.shape[0]):
    if x % 50 == 0:
        print('%.0f %%'%(x/gddTrends.shape[0]*100))
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

print('computing pr, evap, sshf, slhf, netrad trends')
for x in range(seasonalSlhf.shape[0]):
    
    if x % 50 == 0:
        print('%.0f %%'%(x/seasonalSlhf.shape[0]*100))
    
    for y in range(seasonalSlhf.shape[1]):
        
        nn = np.where(~np.isnan(seasonalPrecip[x, y, :]))[0]
        if len(nn) == seasonalPrecip.shape[2]:
            X = sm.add_constant(range(seasonalPrecip.shape[2]))
            mdl = sm.OLS(seasonalPrecip[x, y, :], X).fit()
            prTrends[x, y] = mdl.params[1]
        
        nn = np.where(~np.isnan(seasonalEvap[x, y, :]))[0]
        if len(nn) == seasonalEvap.shape[2]:
            X = sm.add_constant(range(seasonalEvap.shape[2]))
            mdl = sm.OLS(seasonalEvap[x, y, :], X).fit()
            evapTrends[x, y] = mdl.params[1]

        nn = np.where(~np.isnan(seasonalSshf[x, y, :]))[0]
        if len(nn) == seasonalSshf.shape[2]:
            X = sm.add_constant(range(seasonalSshf.shape[2]))
            mdl = sm.OLS(seasonalSshf[x, y, :], X).fit()
            sshfTrends[x, y] = mdl.params[1]

        nn = np.where(~np.isnan(seasonalSlhf[x, y, :]))[0]
        if len(nn) == seasonalSlhf.shape[2]:
            X = sm.add_constant(range(seasonalSlhf.shape[2]))
            mdl = sm.OLS(seasonalSlhf[x, y, :], X).fit()
            slhfTrends[x, y] = mdl.params[1]
        
        rnet = np.squeeze(seasonalStr[x, y, :] + seasonalSsr[x, y, :])
        nn = np.where(~np.isnan(rnet))[0]
        if len(nn) == len(rnet):
            X = sm.add_constant(range(len(rnet)))
            mdl = sm.OLS(rnet, X).fit()
            netRadTrends[x, y] = mdl.params[1]
            
        nn = np.where(~np.isnan(seasonalStr[x, y, :]))[0]
        if len(nn) == seasonalStr.shape[2]:
            X = sm.add_constant(range(seasonalStr.shape[2]))
            mdl = sm.OLS(seasonalStr[x, y, :], X).fit()
            strTrends[x, y] = mdl.params[1]
            
        nn = np.where(~np.isnan(seasonalSsr[x, y, :]))[0]
        if len(nn) == seasonalSsr.shape[2]:
            X = sm.add_constant(range(seasonalSsr.shape[2]))
            mdl = sm.OLS(seasonalSsr[x, y, :], X).fit()
            ssrTrends[x, y] = mdl.params[1]

# if a grid cell has no gdd/kdds, trend will be exactly 0 - set to nan
kddTrends[kddTrends == 0] = np.nan
gddTrends[gddTrends == 0] = np.nan
prTrends[evapTrends == 0] = np.nan
evapTrends[evapTrends == 0] = np.nan
sshfTrends[sshfTrends == 0] = np.nan
slhfTrends[slhfTrends == 0] = np.nan
netRadTrends[netRadTrends == 0] = np.nan
strTrends[netRadTrends == 0] = np.nan
ssrTrends[netRadTrends == 0] = np.nan

with open('%s/kdd-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(kddTrends, f)

with open('%s/gdd-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(gddTrends, f)

with open('%s/evap-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(evapTrends, f)
    
with open('%s/pr-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(prTrends, f)

with open('%s/sshf-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(sshfTrends, f)

with open('%s/slhf-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(slhfTrends, f)

with open('%s/netrad-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(netRadTrends, f)

with open('%s/str-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(strTrends, f)
    
with open('%s/ssr-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, yearRange[0], yearRange[1]), 'wb') as f:
    pickle.dump(ssrTrends, f)
