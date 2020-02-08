import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import geopy.distance
import xarray as xr

import warnings
warnings.filterwarnings('ignore')

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'

txx = np.zeros([360, 720, len(range(1981, 2011+1))])
txxTrends = np.zeros([360, 720])
txxTrends[txxTrends == 0] = np.nan

tnn = np.zeros([360, 720, len(range(1981, 2011+1))])
tnnTrends = np.zeros([360, 720])
tnnTrends[txxTrends == 0] = np.nan


maize = np.zeros([360, 720, len(range(1981, 2011+1))])
maizeTrends = np.full([360, 720], np.nan)

rice = np.zeros([360, 720, len(range(1981, 2011+1))])
riceTrends = np.full([360, 720], np.nan)

soybean = np.zeros([360, 720, len(range(1981, 2011+1))])
soybeanTrends = np.full([360, 720], np.nan)

wheat = np.zeros([360, 720, len(range(1981, 2011+1))])
wheatTrends = np.full([360, 720], np.nan)

for year in range(1981, 2011+1):
    print('loading tmax for %d'%year)
    dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%year, decode_cf=False)
    dsMax.load()
    curTxx = dsMax.tmax.max(dim='time')
    txx[:,:,year-1981] = curTxx.values
    
    maizeNc = xr.open_dataset('%s/iizumi/maize/yield_%d.nc4'%(dataDirDiscovery, year), decode_cf=False)
    maizeNc.load()
    maizeNc = maizeNc.rename({'var':'maize_yield'})
    maize[:, :, year-1981] = np.flipud(maizeNc.maize_yield.values)
    
    soybeanNc = xr.open_dataset('%s/iizumi/soybean/yield_%d.nc4'%(dataDirDiscovery, year), decode_cf=False)
    soybeanNc.load()
    soybeanNc = soybeanNc.rename({'var':'soybean_yield'})
    soybean[:, :, year-1981] = np.flipud(soybeanNc.soybean_yield.values)
    
    riceNc = xr.open_dataset('%s/iizumi/rice/yield_%d.nc4'%(dataDirDiscovery, year), decode_cf=False)
    riceNc.load()
    riceNc = riceNc.rename({'var':'rice_yield'})
    rice[:, :, year-1981] = np.flipud(riceNc.rice_yield.values)
    
    wheatNc = xr.open_dataset('%s/iizumi/wheat/yield_%d.nc4'%(dataDirDiscovery, year), decode_cf=False)
    wheatNc.load()
    wheatNc = wheatNc.rename({'var':'wheat_yield'})
    wheat[:, :, year-1981] = np.flipud(wheatNc.wheat_yield.values)
    
txx[txx < -50] = np.nan
maize[maize < 0] = np.nan
soybean[soybean < 0] = np.nan
rice[rice < 0] = np.nan
wheat[wheat < 0] = np.nan

for xlat in range(txxTrends.shape[0]):
    if xlat%50 == 0: print('%.1f%% complete'%(xlat/txxTrends.shape[0]*100))
    for ylon in range(txxTrends.shape[1]):
        nn = np.where(~np.isnan(txx[xlat, ylon, :]))[0]
        if nn.shape[0] == txx.shape[2]:
            X = sm.add_constant(range(txx.shape[2]))
            mdlT = sm.OLS(txx[xlat, ylon, :], X).fit()
            txxTrends[xlat, ylon] = mdlT.params[1]
        
        nn = np.where(~np.isnan(maize[xlat, ylon, :]))[0]
        if nn.shape[0] == maize.shape[2]:
            X = sm.add_constant(range(maize.shape[2]))
            mdl = sm.OLS(maize[xlat, ylon, :], X).fit()
            maizeTrends[xlat, ylon] = mdl.params[1]
        
        nn = np.where(~np.isnan(soybean[xlat, ylon, :]))[0]
        if nn.shape[0] == soybean.shape[2]:
            X = sm.add_constant(range(soybean.shape[2]))
            mdl = sm.OLS(soybean[xlat, ylon, :], X).fit()
            soybeanTrends[xlat, ylon] = mdl.params[1]
            
        nn = np.where(~np.isnan(rice[xlat, ylon, :]))[0]
        if nn.shape[0] == rice.shape[2]:
            X = sm.add_constant(range(rice.shape[2]))
            mdl = sm.OLS(rice[xlat, ylon, :], X).fit()
            riceTrends[xlat, ylon] = mdl.params[1]
            
        nn = np.where(~np.isnan(wheat[xlat, ylon, :]))[0]
        if nn.shape[0] == wheat.shape[2]:
            X = sm.add_constant(range(wheat.shape[2]))
            mdl = sm.OLS(wheat[xlat, ylon, :], X).fit()
            wheatTrends[xlat, ylon] = mdl.params[1]

txxTrend1d = np.reshape(txxTrends, [txxTrends.size])
txxMean1d = np.reshape(np.nanmean(txx, axis=2), [txx.shape[0]*txx.shape[1]])

maizeTrend1d = np.reshape(maizeTrends, [maizeTrends.size])
maizeMean1d = np.reshape(np.nanmean(maize, axis=2), [maize.shape[0]*maize.shape[1]])
maizeInd50p = np.where((maizeMean1d > np.nanpercentile(maizeMean1d, 50)))[0]
maizeInd25p = np.where((maizeMean1d > np.nanpercentile(maizeMean1d, 25)))[0]

x = maizeTrend1d[maizeInd50p]
y = txxTrend1d[maizeInd50p]
nn = np.where((~np.isnan(x)) & (~np.isnan(y)))[0]
X = sm.add_constant(x[nn])
mdlMaize = sm.RLM(y[nn], X).fit()

soybeanTrend1d = np.reshape(soybeanTrends, [soybeanTrends.size])
soybeanMean1d = np.reshape(np.nanmean(soybean, axis=2), [soybean.shape[0]*soybean.shape[1]])
soybeanInd50p = np.where((soybeanMean1d > np.nanpercentile(soybeanMean1d, 50)))[0]

x = soybeanTrend1d[soybeanInd50p]
y = txxTrend1d[soybeanInd50p]
nn = np.where((~np.isnan(x)) & (~np.isnan(y)))[0]
X = sm.add_constant(x[nn])
mdlSoybean = sm.RLM(y[nn], X).fit()

riceTrend1d = np.reshape(riceTrends, [riceTrends.size])
riceMean1d = np.reshape(np.nanmean(rice, axis=2), [rice.shape[0]*rice.shape[1]])
riceInd50p = np.where((riceMean1d > np.nanpercentile(riceMean1d, 50)))[0]

x = riceTrend1d[riceInd50p]
y = txxTrend1d[riceInd50p]
nn = np.where((~np.isnan(x)) & (~np.isnan(y)))[0]
X = sm.add_constant(x[nn])
mdlRice = sm.RLM(y[nn], X).fit()

wheatTrend1d = np.reshape(wheatTrends, [wheatTrends.size])
wheatMean1d = np.reshape(np.nanmean(wheat, axis=2), [wheat.shape[0]*wheat.shape[1]])
wheatInd50p = np.where((wheatMean1d > np.nanpercentile(wheatMean1d, 50)))[0]

x = wheatTrend1d[wheatInd50p]
y = txxTrend1d[wheatInd50p]
nn = np.where((~np.isnan(x)) & (~np.isnan(y)))[0]
X = sm.add_constant(x[nn])
mdlWheat = sm.RLM(y[nn], X).fit()


plt.figure(figsize=(4, 4))
plt.grid(True, color=[.9, .9, .9])

ci = mdlMaize.conf_int()
y = mdlMaize.params[1]
plt.plot(1, y, 'ok', ms=6)
plt.errorbar(np.array([1, 1]), np.array([y, y]), yerr = np.array([ci[1,1]-y, y-ci[1,0]]).T, lw=2, color='k', \
                 elinewidth = 2, capsize = 3, fmt = 'none')

ci = mdlSoybean.conf_int()
y = mdlSoybean.params[1]
plt.plot(2, y, 'ok', ms=6)
plt.errorbar(np.array([2, 2]), np.array([y, y]), yerr = np.array([ci[1,1]-y, y-ci[1,0]]).T, lw=2, color='k', \
                 elinewidth = 2, capsize = 3, fmt = 'none')

ci = mdlRice.conf_int()
y = mdlRice.params[1]
plt.plot(3, y, 'ok', ms=6)
plt.errorbar(np.array([3, 3]), np.array([y, y]), yerr = np.array([ci[1,1]-y, y-ci[1,0]]).T, lw=2, color='k', \
                 elinewidth = 2, capsize = 3, fmt = 'none')

ci = mdlWheat.conf_int()
y = mdlWheat.params[1]
plt.plot(4, y, 'ok', ms=6)
plt.errorbar(np.array([4, 4]), np.array([y, y]), yerr = np.array([ci[1,1]-y, y-ci[1,0]]).T, lw=2, color='k', \
                 elinewidth = 2, capsize = 3, fmt = 'none')

plt.plot([1,4], [0,0], '--k', lw=1)

plt.title('Txx trend vs. crop yield trend', fontname = 'Helvetica', fontsize=16)


plt.xticks([1, 2, 3, 4])
plt.gca().set_xticklabels(['Maize', 'Soybeans', 'Rice', 'Wheat'])

plt.ylabel('Txx trend per crop yield trend', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#plt.savefig('crop-txx-trend.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


ax = plt.axes(projection=ccrs.PlateCarree())
c = plt.contourf(lons,lats,np.clip(txxTrends*10, -1, 1), cmap=plt.cm.get_cmap('bwr'), vmin=-1, vmax=1, levels=np.linspace(-1, 1, 30))
cbar = plt.colorbar(c, orientation='horizontal')
cbar.set_ticks(np.arange(-1, 1.1, .2))
cbar.set_label('TXx trend ($\degree$C/decade)')
ax.coastlines()