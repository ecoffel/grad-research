import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import geopy.distance
import xarray as xr

txx = np.zeros([360, 720, len(range(1981, 2018+1))])
txxTrends = np.zeros([360, 720])
txxTrends[txxTrends == 0] = np.nan

maize = np.zeros([360, 720, len(range(1981, 2011+1))])
rice = np.zeros([360, 720, len(range(1981, 2011+1))])
soybean = np.zeros([360, 720, len(range(1981, 2011+1))])
wheat = np.zeros([360, 720, len(range(1981, 2011+1))])

for year in range(1981, 2011+1):
    print('loading tmax for %d'%year)
    dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%year, decode_cf=False)
    dsMax.load()
    curTxx = dsMax.tmax.max(dim='time')
    txx[:,:,year-1981] = curTxx.values
    
    maizeNc = xr.open_dataset('data/iizumi/maize/yield_%d.nc4'%year, decode_cf=False)
    maizeNc.load()
    maizeNc = maizeNc.rename({'var':'maize_yield'})
    maize[:, :, year-1981] = np.flipud(maizeNc.maize_yield.values)
txx[txx < -50] = np.nan
sys.exit()
for xlat in range(txxTrends.shape[0]):
    if xlat%50 == 0: print('%.1f%% complete'%(xlat/txxTrends.shape[0]*100))
    for ylon in range(txxTrends.shape[1]):
        nn = np.where(~np.isnan(txx[xlat, ylon, :]))[0]
        if nn.shape[0] == txx.shape[2]:
            X = sm.add_constant(range(txx.shape[2]))
            mdlT = sm.OLS(txx[xlat, ylon, :], X).fit()
            txxTrends[xlat, ylon] = mdlT.params[1]