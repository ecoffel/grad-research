import rasterio as rio
import matplotlib.pyplot as plt 
from matplotlib.colors import Normalize
import numpy as np
import numpy.matlib
from scipy import interpolate
import statsmodels.api as sm
import statsmodels.formula.api as smf
import scipy.stats as st
import scipy
import os, sys, pickle, gzip
import datetime
import geopy.distance
import xarray as xr
import pandas as pd
import geopandas as gpd
import shapely.geometry
import cartopy
import cartopy.crs as ccrs
from cartopy.io.shapereader import Reader
from cartopy.feature import ShapelyFeature
import cartopy.feature as cfeature
import itertools
import random
import metpy
from metpy.plots import USCOUNTIES

import warnings
warnings.filterwarnings('ignore')

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/ag-land-climate'

rebuildPointModels = True
reproject = False


crop = 'Maize'
wxData = 'cpc'

yieldDataOld = True

oldStr = 'new'
if yieldDataOld:
    oldStr = 'old'

    

def findConsec(data):
    # find longest consequtative sequence of years with yield data
    ptMax = (-1, -1)
    ptCur = (-1, -1)
    for i, val in enumerate(data):
        # start sequence
        if ~np.isnan(val) and ptCur[0] == -1:
            ptCur = (i, -1)
        #end sequence
        elif (np.isnan(val) and ptCur[0] >= 0):
            ptCur = (ptCur[0], i)
            if ptCur[1]-ptCur[0] > ptMax[1]-ptMax[0] or ptMax == (-1, -1):
                ptMax = ptCur
            ptCur = (-1, -1)
        # reached end of sequence
        elif i >= len(data)-1 and ptCur[0] >= 0:
            ptCur = (ptCur[0], i)
            if ptCur[1]-ptCur[0] > ptMax[1]-ptMax[0] or ptMax == (-1, -1):
                ptMax = ptCur
    return ptMax


tempYearRange = [1981, 2018]
if yieldDataOld:
    yieldYearRange = [1981, 2008]
else:
    yieldYearRange = [1981, 2013]

yearRange = np.intersect1d(np.arange(tempYearRange[0], tempYearRange[1]+1), np.arange(yieldYearRange[0], yieldYearRange[1]+1))

# load the sacks crop calendars
sacksMaizeStart = np.genfromtxt('%s/sacks/sacks-planting-end-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeStart[sacksMaizeStart<0] = np.nan
sacksMaizeEnd = np.genfromtxt('%s/sacks/sacks-harvest-start-Maize.txt'%dataDirDiscovery, delimiter=',')
sacksMaizeEnd[sacksMaizeEnd<0] = np.nan

sacksMaizeStart = np.roll(sacksMaizeStart, int(sacksMaizeStart.shape[1]/2), axis=1)
sacksMaizeEnd = np.roll(sacksMaizeEnd, int(sacksMaizeEnd.shape[1]/2), axis=1)

sacksLat = np.linspace(90, -90, 360)
sacksLon = np.linspace(0, 360, 720)


# load gdd/kdd from cpc temperature data
with gzip.open('%s/kdd-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, tempYearRange[0], tempYearRange[1]), 'rb') as f:
    kdd = pickle.load(f)
    if wxData == 'cpc': kdd = kdd[:,:,1:]

with gzip.open('%s/gdd-%s-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, tempYearRange[0], tempYearRange[1]), 'rb') as f:
    gdd = pickle.load(f)
    if wxData == 'cpc': gdd = gdd[:,:,1:]
    
with gzip.open('%s/gdd-kdd-lat-%s.dat'%(dataDirDiscovery, wxData), 'rb') as f:
    tempLat = pickle.load(f)

with gzip.open('%s/gdd-kdd-lon-%s.dat'%(dataDirDiscovery, wxData), 'rb') as f:
    tempLon = pickle.load(f)


maizeYield = []
for year in range(yieldYearRange[0],yieldYearRange[1]+1):
    
    if yieldDataOld:
        curMaizeYield = xr.open_dataset('%s/deepak/Maize_yield/Maize_areaweightedyield_%d.nc'%(dataDirDiscovery, year), decode_cf=False)
    else:
        curMaizeYield = xr.open_dataset('%s/deepak/Maize_yield_1970_2013/Maize_areaweightedyield_%d_ver12b.nc'%(dataDirDiscovery, year), decode_cf=False)
    
    curMaizeYield['time'] = [year]
    if len(maizeYield) == 0:
        maizeYield = curMaizeYield
    else:
        maizeYield = xr.concat([maizeYield, curMaizeYield], dim='time')
    
maizeYield.load()

# flip latitude axis so top is +90
if not yieldDataOld:
    latDeepak = np.flipud(maizeYield.latitude.values)
else:
    latDeepak = maizeYield.latitude.values
lonDeepak = np.roll(maizeYield.longitude.values, int(len(maizeYield.longitude)/2), axis=0)
lonDeepak[lonDeepak<0] += 360
maizeYield['Data'] = maizeYield.Data.transpose('latitude', 'longitude', 'time', 'level')
if not yieldDataOld:
    data = np.roll(np.flip(maizeYield['Data'], axis=0), int(len(lonDeepak)/2), axis=1)
else:
    data = np.roll(maizeYield['Data'], int(len(lonDeepak)/2), axis=1)

maizeYield['latitude'] = latDeepak
maizeYield['longitude'] = lonDeepak
maizeYield['Data'] = (('latitude', 'longitude', 'time'), np.squeeze(data))

kdd = kdd[:, :, 0:maizeYield.Data.shape[2]]
gdd = gdd[:, :, 0:maizeYield.Data.shape[2]]

if wxData == 'cpc':
    with gzip.open('%s/seasonal-precip-maize-gpcp.dat'%dataDirDiscovery, 'rb') as f:
        seasonalPrecip = pickle.load(f)
elif wxData == 'era5':
    with gzip.open('%s/seasonal-precip-maize-era5.dat'%dataDirDiscovery, 'rb') as f:
        seasonalPrecip = pickle.load(f)

# calculate gdd and kdd trends from already-loaded cpc tmax and tmin data
with gzip.open('%s/kdd-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, tempYearRange[0], tempYearRange[1]), 'rb') as f:
    kddTrends = pickle.load(f)

with gzip.open('%s/gdd-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, tempYearRange[0], tempYearRange[1]), 'rb') as f:
    gddTrends = pickle.load(f)

with gzip.open('%s/tx95-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, tempYearRange[0], tempYearRange[1]), 'rb') as f:
    tx95Trends = pickle.load(f)

with gzip.open('%s/txMean-%s-trends-%s-%d-%d.dat'%(dataDirDiscovery, wxData, crop, tempYearRange[0], tempYearRange[1]), 'rb') as f:
    txMeanTrends = pickle.load(f)
    

if os.path.isfile('%s/global-point-model-data-kdd-only-%s-%s-%s.dat'%(dataDirDiscovery, wxData, crop, oldStr)) and not rebuildPointModels:
    with open('%s/global-point-model-data-kdd-only-%s-%s-%s.dat'%(dataDirDiscovery, wxData, crop, oldStr), 'rb') as f:
        print('loading saved point model data...')
        modelData = pickle.load(f)
        
        pointModelsKDD = modelData['pointModelsKDD']
        
        print('loaded %s'%('%s/global-point-model-data-%s-%s-%s.dat'%(dataDirDiscovery, wxData, crop, oldStr)))
else:
    minCropYears = 20

    pointModelsKDD = {}
    pointModelsTx95 = {}

    for xlat in range(0, len(latDeepak)):

        if xlat % 10 == 0: print('%.0f %%'%(xlat/len(latDeepak)*100))

        pointModelsKDD[xlat] = {}
        pointModelsTx95[xlat] = {}

        for ylon in range(0, len(lonDeepak)):

            y = maizeYield.Data.values[xlat, ylon, :]
            ptMaxDeepak = findConsec(y)

            lat1 = latDeepak[xlat]
            lat2 = latDeepak[xlat] + (latDeepak[1]-latDeepak[0])

            lon1 = lonDeepak[ylon]
            lon2 = lonDeepak[ylon] + (lonDeepak[1]-lonDeepak[0])

            if ptMaxDeepak[1]-ptMaxDeepak[0]+1 >= minCropYears:

                indLat = [np.where(abs(tempLat-lat1) == np.nanmin(abs(tempLat-lat1)))[0][0],
                           np.where(abs(tempLat-lat2) == np.nanmin(abs(tempLat-lat2)))[0][0]]
                indLon = [np.where(abs(tempLon-lon1) == np.nanmin(abs(tempLon-lon1)))[0][0],
                           np.where(abs(tempLon-lon2) == np.nanmin(abs(tempLon-lon2)))[0][0]]

                indLatRange = np.arange(indLat[0], indLat[1]+1)
                indLonRange = np.arange(indLon[0], indLon[1]+1)

                k = np.nanmean(kdd[indLatRange, :, :], axis=0)
                k = np.nanmean(k[indLonRange, :], axis=0)

                g = np.nanmean(gdd[indLatRange, :, :], axis=0)
                g = np.nanmean(g[indLonRange, :], axis=0)
                
                indLatPr = [np.where(abs(sacksLat-lat1) == np.nanmin(abs(sacksLat-lat1)))[0][0],
                           np.where(abs(sacksLat-lat2) == np.nanmin(abs(sacksLat-lat2)))[0][0]]
                indLonPr = [np.where(abs(sacksLon-lon1) == np.nanmin(abs(sacksLon-lon1)))[0][0],
                           np.where(abs(sacksLon-lon2) == np.nanmin(abs(sacksLon-lon2)))[0][0]]

                indLatPrRange = np.arange(indLatPr[0], indLatPr[1]+1)
                indLonPrRange = np.arange(indLonPr[0], indLonPr[1]+1)

                p = np.nanmean(seasonalPrecip[indLatPrRange, :, :], axis=0)
                p = np.nanmean(p[indLonPrRange, :], axis=0)
                
                g = g[ptMaxDeepak[0]:ptMaxDeepak[1]]
                k = k[ptMaxDeepak[0]:ptMaxDeepak[1]]
                p = p[ptMaxDeepak[0]:ptMaxDeepak[1]]
                y = y[ptMaxDeepak[0]:ptMaxDeepak[1]]
                
                if len(np.where(np.isnan(k))[0]) == 0 and \
                    len(np.where(np.isnan(g))[0]) == 0 and \
                    len(np.where(np.isnan(p))[0]) == 0 and \
                    len(np.where(np.isnan(y))[0]) == 0 and \
                    len(np.where(np.isnan(curTx95))[0]) == 0:
                    
                    g = scipy.signal.detrend(g)
                    k = scipy.signal.detrend(k)
                    p = scipy.signal.detrend(p)
                    y = scipy.signal.detrend(y)
                else:
                    continue

                if len(np.where((np.isnan(k)) | (k == 0))[0]) == 0 and \
                    len(np.where((np.isnan(g)) | (g == 0))[0]) == 0 and \
                    len(np.where((np.isnan(p)) | (p == 0))[0]) == 0:

                    data = {'GDD':g, \
                            'KDD':k, \
                            'Pr':p, \
                            'Yield':y}

                    df = pd.DataFrame(data, \
                                      columns=['GDD', 'KDD', 'Pr', \
                                               'Yield'])

                    mdl = smf.ols(formula='Yield ~ KDD', data=df).fit()
                    pointModelsKDD[xlat][ylon] = mdl
                

    with open('%s/global-point-model-data-kdd-only-%s-%s-%s.dat'%(dataDirDiscovery, wxData, crop, oldStr), 'wb') as f:
        modelData = {'pointModelsKDD':pointModelsKDD}
        pickle.dump(modelData, f)

if os.path.isfile('%s/global-yield-projections-trendMethod-%s-%s-%s'%(dataDirDiscovery, crop, wxData, oldStr)) and not reproject:
    
    with open('%s/global-yield-projections-trendMethod-%s-%s'%(dataDirDiscovery, crop, wxData), 'rb') as f:
        globalYieldProj = pickle.load(f)
        yieldProj = globalYieldProj['yieldProj']
        globalKddChg = globalYieldProj['globalKddChg']
        globalGddChg = globalYieldProj['globalGddChg']
        globalPrChg = globalYieldProj['globalPrChg']
    
    print('loaded %s'%('%s/global-yield-projections-trendMethod-%s-%s-%s'%(dataDirDiscovery, crop, wxData, oldDataStr)))
else:
    # project climate-related yield change with point models

    leaveOutN = 100
    
    yieldProj = np.full([len(latDeepak), len(lonDeepak), leaveOutN], np.nan)
    globalKddChg = np.full([len(latDeepak), len(lonDeepak), leaveOutN], np.nan)
    globalGddChg = np.full([len(latDeepak), len(lonDeepak), leaveOutN], np.nan)
    globalPrChg = np.full([len(latDeepak), len(lonDeepak), leaveOutN], np.nan)


    for xlat in range(len(latDeepak)):

        if xlat % 10 == 0:
            print('%.0f %%'%(xlat/len(latDeepak)*100))

        if xlat not in pointModelsKDD.keys():
            continue

        for ylon in range(len(lonDeepak)):

            if ylon not in pointModelsKDD[xlat].keys():
                continue

            lat1 = latDeepak[xlat]
            lat2 = latDeepak[xlat] + (latDeepak[1]-latDeepak[0])

            lon1 = lonDeepak[ylon]
            lon2 = lonDeepak[ylon] + (lonDeepak[1]-lonDeepak[0])

            indLat = [np.where(abs(tempLat-lat1) == np.nanmin(abs(tempLat-lat1)))[0][0],
                       np.where(abs(tempLat-lat2) == np.nanmin(abs(tempLat-lat2)))[0][0]]
            indLon = [np.where(abs(tempLon-lon1) == np.nanmin(abs(tempLon-lon1)))[0][0],
                       np.where(abs(tempLon-lon2) == np.nanmin(abs(tempLon-lon2)))[0][0]]

            indLatRange = np.arange(indLat[0], indLat[1]+1)
            indLonRange = np.arange(indLon[0], indLon[1]+1)

            indLatPr = [np.where(abs(sacksLat-lat1) == np.nanmin(abs(sacksLat-lat1)))[0][0],
                       np.where(abs(sacksLat-lat2) == np.nanmin(abs(sacksLat-lat2)))[0][0]]
            indLonPr = [np.where(abs(sacksLon-lon1) == np.nanmin(abs(sacksLon-lon1)))[0][0],
                       np.where(abs(sacksLon-lon2) == np.nanmin(abs(sacksLon-lon2)))[0][0]]

            indLatPrRange = np.arange(indLatPr[0], indLatPr[1]+1)
            indLonPrRange = np.arange(indLonPr[0], indLonPr[1]+1)

            curProjChg = []

            curKddStarts = []
            curKddEnds = []
            curGddStarts = []
            curGddEnds = []
            curPrStarts = []
            curPrEnds = []

            curKdd = np.nanmean(kdd[indLatRange, :, :], axis=0)
            curKdd = np.nanmean(curKdd[indLonRange, :], axis=0)
            
            curGdd = np.nanmean(gdd[indLatRange, :, :], axis=0)
            curGdd = np.nanmean(curGdd[indLonRange, :], axis=0)
            
            curPr = np.nanmean(seasonalPrecip[indLatPrRange, :, :], axis=0)
            curPr = np.nanmean(curPr[indLonPrRange, :], axis=0)

            gddStartLeaveOut = []
            gddEndLeaveOut = []
            
            kddStartLeaveOut = []
            kddEndLeaveOut = []
            
            prStartLeaveOut = []
            prEndLeaveOut = []
            
            for n in range(leaveOutN):
            
                inds = np.arange(0, len(curKdd))
                inds = random.sample(set(inds), len(inds)-1)
                inds.sort()
            
                X = sm.add_constant(range(len(curKdd[inds])))
                curKddMdl = sm.OLS(curKdd[inds], X).fit()
                curKddInt = curKddMdl.params[0]
                curKddTrend = curKddMdl.params[1]

                X = sm.add_constant(range(len(curGdd[inds])))
                curGddMdl = sm.OLS(curGdd[inds], X).fit()
                curGddInt = curGddMdl.params[0]
                curGddTrend = curGddMdl.params[1]

                X = sm.add_constant(range(len(curPr[inds])))
                curPrMdl = sm.OLS(curPr[inds], X).fit()
                curPrInt = curPrMdl.params[0]
                curPrTrend = curPrMdl.params[1]

                gddStartLeaveOut.append(curGddInt)
                kddStartLeaveOut.append(curKddInt)
                prStartLeaveOut.append(curPrInt)
                
                gddEndLeaveOut.append((curGddInt+curGddTrend*(2020-1979)))
                kddEndLeaveOut.append((curKddInt+curKddTrend*(2020-1979)))
                prEndLeaveOut.append((curPrInt+curPrTrend*(2020-1979)))
                
            dataStart = {'GDD':gddStartLeaveOut, \
                    'KDD':kddStartLeaveOut, \
                    'Pr':prStartLeaveOut}
            dataEnd = {'GDD':gddEndLeaveOut, \
                    'KDD':kddEndLeaveOut, \
                    'Pr':prEndLeaveOut}

            dfStart = pd.DataFrame(dataStart, columns=['GDD', 'KDD', 'Pr'])
            dfEnd = pd.DataFrame(dataEnd, columns=['GDD', 'KDD', 'Pr'])

            curProjStarts = pointModelsKDD[xlat][ylon].predict(dfStart).values
            curProjEnds = pointModelsKDD[xlat][ylon].predict(dfEnd).values

            curProjChg = ((curProjEnds-curProjStarts)/np.nanmean(maizeYield.Data.values[xlat, ylon, :]))*100
            curProjChg[curProjChg < -100] = np.nan
            curProjChg[curProjChg > 100] = np.nan

            globalKddChg[xlat, ylon, :] = dfEnd['KDD'].values-dfStart['KDD'].values
            globalGddChg[xlat, ylon, :] = dfEnd['GDD'].values-dfStart['GDD'].values
            globalPrChg[xlat, ylon, :] = dfEnd['Pr'].values-dfStart['Pr'].values

            tval, pval = scipy.stats.ttest_1samp(curProjChg, 0)
            if pval <= 0.05:
                yieldProj[xlat, ylon, :] = curProjChg
            
    with open('%s/global-yield-projections-trendMethod-%s-%s-%s'%(dataDirDiscovery, crop, wxData, oldStr), 'wb') as f:
        globalYieldProj = {'yieldProj':yieldProj, \
                           'globalKddChg':globalKddChg, \
                           'globalGddChg':globalGddChg, \
                           'globalPrChg':globalPrChg}
        pickle.dump(globalYieldProj, f)