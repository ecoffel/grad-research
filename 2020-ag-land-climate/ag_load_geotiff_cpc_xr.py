# -*- coding: utf-8 -*-
"""
Created on Thu Oct 10 10:01:10 2019

@author: Ethan
"""                                                                                                                                

import rasterio as rio
import matplotlib.pyplot as plt 
import numpy as np
from scipy import interpolate
import statsmodels.api as sm
import scipy.stats as st
import os, sys, pickle, gzip
import geopy.distance
import xarray as xr

dataDir = 'data/CroplandPastureArea2000_Geotiff/CroplandPastureArea2000_Geotiff'

pasture = rio.open('%s/Pasture2000_5m.tif'%dataDir)
pastureData = pasture.read(1)

crop = rio.open('%s/Cropland2000_5m.tif'%dataDir)
cropData = crop.read(1)

latOld = np.linspace(pasture.bounds.bottom, pasture.bounds.top, pasture.shape[0])
lonOld = np.linspace(pasture.bounds.left, pasture.bounds.right, pasture.shape[1])

pastureInterp = interpolate.interp2d(lonOld, latOld, pastureData, kind='linear')
cropInterp = interpolate.interp2d(lonOld, latOld, cropData, kind='linear')

latNew = np.linspace(90, -90, 360)
lonNew = np.linspace(-180, 180, 720)

pastureRegrid = pastureInterp(lonNew, latNew)
pastureRegrid[pastureRegrid < 0] = np.nan

cropRegrid = cropInterp(lonNew, latNew)
cropRegrid[cropRegrid < 0] = np.nan

with open('elevation-map.dat', 'rb') as f:
    elevationMap = pickle.load(f)

if not os.path.isfile('koppen-data.dat'):
    
    koppen = np.genfromtxt('data/koppen-classification/koppen_1901-2010.tsv', dtype=None, names=True, encoding='UTF-8')
    
    koppenGroupsPCells = {'A':[], 'B':[], 'C':[], 'D':[], 'E':[]}
    koppenGroupsNoPCells = {'A':[], 'B':[], 'C':[], 'D':[], 'E':[]}
    
    koppenGroupsCCells = {'A':[], 'B':[], 'C':[], 'D':[], 'E':[]}
    koppenGroupsNoCCells = {'A':[], 'B':[], 'C':[], 'D':[], 'E':[]}
    
    koppenGroupsFullPCells = {}
    koppenGroupsFullNoPCells = {}
    
    koppenGroupsFullCCells = {}
    koppenGroupsFullNoCCells = {}
    
    koppenLat = np.linspace(90, -90, 360)
    koppenLon = np.linspace(-180, 180, 720)
    
    koppenMap = np.zeros([len(koppenLat), len(koppenLon)])
    
    print('building koppen map...')
    for x in range(len(koppenLat)):
        
        if x % 50 == 0:
            print('%.0f%% complete'%((x/len(koppenLat)*100)))
        
        for y in range(len(koppenLon)):
            
            minDist = -1
            minDistInd = -1
            
            latInd = np.where((abs(koppen['latitude']-koppenLat[x]) <= 1))[0]
            
            for i in latInd:
                if abs(koppen['longitude'][i]-koppenLon[y]) > 1:
                    continue
                
                ptKoppen = (koppen['latitude'][i], koppen['longitude'][i])
                ptAg = (koppenLat[x], koppenLon[y])
                
                dist = geopy.distance.great_circle(ptKoppen, ptAg).km
                if minDist == -1 or dist < minDist:
                    minDist = dist
                    minDistInd = i
            
            if minDistInd != -1:
                classification = koppen['p1901_2010'][minDistInd]
                classificationInt = 0
                if classification in ['As', 'Aw', 'Am', 'Af']: 
                    classificationInt = 1
                elif classification in ['BSk', 'BWk', 'BSh']: 
                    classificationInt = 2
                elif classification in ['Cfb', 'Csb', 'Cfa', 'Csa', 'Cwa']:
                    classificationInt = 3
                elif classification in ['Dfb', 'Dfa', 'Dwc', 'Dwb']:
                    classificationInt = 4
                koppenMap[x,y] = classificationInt
            else:
                koppenMap[x,y] = np.nan
            
            if np.isnan(pastureRegrid[x,y]):
                continue
            
            if pastureRegrid[x,y] > 0.05:
                if classification in koppenGroupsFullPCells.keys():
                    koppenGroupsFullPCells[classification].append((x,y))
                else:
                    koppenGroupsFullPCells[classification] = [(x,y)]
            else:
                if classification in koppenGroupsFullNoPCells.keys():
                    koppenGroupsFullNoPCells[classification].append((x,y))
                else:
                    koppenGroupsFullNoPCells[classification] = [(x,y)]
            
            if cropRegrid[x,y] > 0.05:
                if classification in koppenGroupsFullCCells.keys():
                    koppenGroupsFullCCells[classification].append((x,y))
                else:
                    koppenGroupsFullCCells[classification] = [(x,y)]
            else:
                if classification in koppenGroupsFullNoCCells.keys():
                    koppenGroupsFullNoCCells[classification].append((x,y))
                else:
                    koppenGroupsFullNoCCells[classification] = [(x,y)]
            
            
            # skip if > 1000 m
            if elevationMap[x,y] > 500:
                continue
            
            if not np.isnan(koppenMap[x,y]) and koppenMap[x,y] != 0:
                if classification[0] in koppenGroupsPCells.keys():
                    if pastureRegrid[x,y] > 0.1:
                        koppenGroupsPCells[classification[0]].append((x,y))
                    else:
                        koppenGroupsNoPCells[classification[0]].append((x,y))
                    
                    if cropRegrid[x,y] > 0.1:
                        koppenGroupsCCells[classification[0]].append((x,y))
                    else:
                        koppenGroupsNoCCells[classification[0]].append((x,y))
    
    koppenData = {'koppenMap':koppenMap,\
                  'koppenGroupsPCells':koppenGroupsPCells, \
                  'koppenGroupsNoPCells':koppenGroupsNoPCells, \
                  'koppenGroupsCCells':koppenGroupsCCells, \
                  'koppenGroupsNoCCells':koppenGroupsNoCCells}
    with gzip.open('koppen-data.dat', 'wb') as f:
        pickle.dump(koppenData, f)
else:
    with gzip.open('koppen-data.dat', 'rb') as f:
        koppenData = pickle.load(f)
        
        koppenMap = koppenData['koppenMap']
        koppenGroupsPCells = koppenData['koppenGroupsPCells']
        koppenGroupsNoPCells = koppenData['koppenGroupsNoPCells']
        koppenGroupsCCells = koppenData['koppenGroupsCCells']
        koppenGroupsNoCCells = koppenData['koppenGroupsNoCCells']

#totalC = 0
#for k in koppenGroupsFullCCells.keys():
#    totalC += len(koppenGroupsFullCCells[k])
#        
#for k in koppenGroupsCCells.keys():
#    if k in koppenGroupsNoCCells.keys():
#        filteredC = len(koppenGroupsCCells[k])+len(koppenGroupsNoCCells[k])
#        if filteredC > 0:
#            curPerc = len(koppenGroupsCCells[k])/filteredC
#        else:
#            curPerc = np.nan
#        print('%s: %.2f, %.2f'%(k, len(koppenGroupsCCells[k])/totalC, curPerc))

if not os.path.isfile('t-means-max-min.dat'):

    tMeans = {'A':{}, 'B':{}, 'C':{}, 'D':{}, 'E':{}}
    
    for k in koppenGroupsPCells.keys():
        
        pCells = koppenGroupsPCells[k]
        cCells = koppenGroupsCCells[k]
        noPCells = koppenGroupsNoPCells[k]
        noCCells = koppenGroupsNoCCells[k]
        
        selLatsPCells = []
        selLonsPCells = []    
        for p in range(len(pCells)):
            selLonsPCells.append(lonNew[pCells[p][1]])
            selLatsPCells.append(latNew[pCells[p][0]])
        selLonsPCells = np.array(selLonsPCells)
        selLatsPCells = np.array(selLatsPCells)
        
        selLatsCCells = []
        selLonsCCells = []    
        for p in range(len(cCells)):
            selLonsCCells.append(lonNew[cCells[p][1]])
            selLatsCCells.append(latNew[cCells[p][0]])
        selLatsCCells = np.array(selLatsCCells)
        selLonsCCells = np.array(selLonsCCells)
        
        selLatsNoPCells = []
        selLonsNoPCells = []    
        for p in range(len(noPCells)):
            selLonsNoPCells.append(lonNew[noPCells[p][1]])
            selLatsNoPCells.append(latNew[noPCells[p][0]])
        selLonsNoPCells = np.array(selLonsNoPCells)
        selLatsNoPCells = np.array(selLatsNoPCells)
        
        selLatsNoCCells = []
        selLonsNoCCells = []    
        for p in range(len(noCCells)):
            selLonsNoCCells.append(lonNew[noCCells[p][1]])
            selLatsNoCCells.append(latNew[noCCells[p][0]])
        selLatsNoCCells = np.array(selLatsNoCCells)
        selLonsNoCCells = np.array(selLonsNoCCells)
        
        tMeans[k]['pLat'] = selLatsPCells
        tMeans[k]['noPLat'] = selLatsNoPCells
        tMeans[k]['pLon'] = selLonsPCells
        tMeans[k]['noPLon'] = selLonsNoPCells
        tMeans[k]['pCover'] = np.zeros([len(selLonsPCells),1])
        tMeans[k]['PMax'] = np.zeros([len(selLatsPCells), len(range(1979, 2018+1))])
        tMeans[k]['PMin'] = np.zeros([len(selLatsPCells), len(range(1979, 2018+1))])
        tMeans[k]['noPMax'] = np.zeros([len(selLatsNoPCells), len(range(1979, 2018+1))])
        tMeans[k]['noPMin'] = np.zeros([len(selLatsNoPCells), len(range(1979, 2018+1))])
        
        tMeans[k]['cLat'] = selLatsCCells
        tMeans[k]['noCLat'] = selLatsNoCCells
        tMeans[k]['cLon'] = selLonsCCells
        tMeans[k]['noCLon'] = selLonsNoCCells
        tMeans[k]['cCover'] = np.zeros([len(selLatsCCells),1])
        tMeans[k]['CMax'] = np.zeros([len(selLatsCCells), len(range(1979, 2018+1))])
        tMeans[k]['CMin'] = np.zeros([len(selLatsCCells), len(range(1979, 2018+1))])
        tMeans[k]['noCMax'] = np.zeros([len(selLatsNoCCells), len(range(1979, 2018+1))])
        tMeans[k]['noCMin'] = np.zeros([len(selLatsNoCCells), len(range(1979, 2018+1))])
    
    for year in range(1979, 2018+1):
        
        print('loading %d...'%year)
        dsMax = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmax/tmax.%d.nc'%year, decode_times=False, decode_cf=False)
        dsMax.load()
        
        dsMin = xr.open_dataset('/dartfs-hpc/rc/lab/C/CMIG/CPC/tmin/tmin.%d.nc'%year, decode_times=False, decode_cf=False)
        dsMin.load()
        
        for k in koppenGroupsPCells.keys():
            
            print('processing t & p for k = %s...'%k)
            
            pCells = koppenGroupsPCells[k]
            cCells = koppenGroupsCCells[k]
            noPCells = koppenGroupsNoPCells[k]
            noCCells = koppenGroupsNoCCells[k]
            
            # the range of lat values with crops in current koppen zone
            pLatRange = []
            cLatRange = []
            
            for p in range(len(tMeans[k]['pLat'])):
                ttmp = dsMax.tmax.sel(lat=tMeans[k]['pLat'][p], lon=tMeans[k]['pLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.max(dim='time', skipna=True)
                tMeans[k]['PMax'][p, year-1979] = float(ttmp.values)
                
                ttmp = dsMin.tmin.sel(lat=tMeans[k]['pLat'][p], lon=tMeans[k]['pLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.min(dim='time', skipna=True)
                tMeans[k]['PMin'][p, year-1979] = float(ttmp.values)
                
                if year == 1979:
                    tMeans[k]['pCover'][p] = pastureRegrid[pCells[p][0], pCells[p][1]]
                
            for p in range(len(tMeans[k]['cLat'])):
                ttmp = dsMax.tmax.sel(lat=tMeans[k]['cLat'][p], lon=tMeans[k]['cLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.max(dim='time', skipna=True)
                tMeans[k]['CMax'][p, year-1979] = float(ttmp.values)
                
                ttmp = dsMin.tmin.sel(lat=tMeans[k]['cLat'][p], lon=tMeans[k]['cLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.min(dim='time', skipna=True)
                tMeans[k]['CMin'][p, year-1979] = float(ttmp.values)
                
                if year == 1979:
                    tMeans[k]['cCover'][p] = cropRegrid[cCells[p][0], cCells[p][1]]
            
            for p in range(len(tMeans[k]['noCLat'])):
                ttmp = dsMax.tmax.sel(lat=tMeans[k]['noCLat'][p], lon=tMeans[k]['noCLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.max(dim='time', skipna=True)
                tMeans[k]['noCMax'][p, year-1979] = float(ttmp.values)
                
                ttmp = dsMin.tmin.sel(lat=tMeans[k]['noCLat'][p], lon=tMeans[k]['noCLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.min(dim='time', skipna=True)
                tMeans[k]['noCMin'][p, year-1979] = float(ttmp.values)
                    
            for p in range(len(tMeans[k]['noPLat'])):
                ttmp = dsMax.tmax.sel(lat=tMeans[k]['noPLat'][p], lon=tMeans[k]['noPLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.max(dim='time', skipna=True)
                tMeans[k]['noPMax'][p, year-1979] = float(ttmp.values)
                
                ttmp = dsMin.tmin.sel(lat=tMeans[k]['noPLat'][p], lon=tMeans[k]['noPLon'][p], method='nearest').dropna(dim='time')
                ttmp = ttmp.min(dim='time', skipna=True)
                tMeans[k]['noPMin'][p, year-1979] = float(ttmp.values)
        
            tMeans[k]['PMax'][tMeans[k]['PMax'] < -100] = np.nan
            tMeans[k]['CMax'][tMeans[k]['CMax'] < -100] = np.nan
            tMeans[k]['noPMax'][tMeans[k]['noPMax'] < -100] = np.nan
            tMeans[k]['noCMax'][tMeans[k]['noCMax'] < -100] = np.nan
            
            tMeans[k]['PMin'][tMeans[k]['PMin'] < -100] = np.nan
            tMeans[k]['CMin'][tMeans[k]['CMin'] < -100] = np.nan
            tMeans[k]['noPMin'][tMeans[k]['noPMin'] < -100] = np.nan
            tMeans[k]['noCMin'][tMeans[k]['noCMin'] < -100] = np.nan
    
    with gzip.open('t-means-max-min.dat', 'wb') as f:
        pickle.dump(tMeans, f)
else:    
    print('loading t means')
    with gzip.open('t-means-max-min.dat', 'rb') as f:
        tMeans = pickle.load(f)

        
tTrends = {'A':{}, 'B':{}, 'C':{}, 'D':{}}

for k in ['A', 'B', 'C', 'D']:
    
    tTrends[k]['slopesPMax'] = []
    tTrends[k]['slopesPMaxInd'] = []
    tTrends[k]['slopesPMin'] = []
    tTrends[k]['slopesPMinInd'] = []
    tTrends[k]['pCoverMax'] = []
    tTrends[k]['pCoverMin'] = []
    for p in range(tMeans[k]['pLat'].shape[0]):
        nn = np.where(~np.isnan(tMeans[k]['PMax'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['PMax'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['PMax'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesPMax'].append(tSlope*10)
            tTrends[k]['slopesPMaxInd'].append(p)
            tTrends[k]['pCoverMax'].append(tMeans[k]['pCover'][p])
        
        nn = np.where(~np.isnan(tMeans[k]['PMin'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['PMin'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['PMin'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesPMin'].append(tSlope*10)
            tTrends[k]['slopesPMinInd'].append(p)
            tTrends[k]['pCoverMin'].append(tMeans[k]['pCover'][p])
    tTrends[k]['slopesPMax'] = np.array(tTrends[k]['slopesPMax'])
    tTrends[k]['slopesPMaxInd'] = np.array(tTrends[k]['slopesPMaxInd'])
    tTrends[k]['pCoverMax'] = np.array(tTrends[k]['pCoverMax'])
    tTrends[k]['slopesPMin'] = np.array(tTrends[k]['slopesPMin'])
    tTrends[k]['slopesPMinInd'] = np.array(tTrends[k]['slopesPMinInd'])
    tTrends[k]['pCoverMin'] = np.array(tTrends[k]['pCoverMin'])
    
    tTrends[k]['slopesCMax'] = []
    tTrends[k]['slopesCMaxInd'] = []
    tTrends[k]['cCoverMax'] = []
    tTrends[k]['slopesCMin'] = []
    tTrends[k]['slopesCMinInd'] = []
    tTrends[k]['cCoverMin'] = []
    for p in range(tMeans[k]['cLat'].shape[0]):
        nn = np.where(~np.isnan(tMeans[k]['CMax'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['CMax'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['CMax'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesCMax'].append(tSlope*10)
            tTrends[k]['slopesCMaxInd'].append(p)
            tTrends[k]['cCoverMax'].append(tMeans[k]['cCover'][p])
            
        nn = np.where(~np.isnan(tMeans[k]['CMin'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['CMin'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['CMin'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesCMin'].append(tSlope*10)
            tTrends[k]['slopesCMinInd'].append(p)
            tTrends[k]['cCoverMin'].append(tMeans[k]['cCover'][p])
    tTrends[k]['slopesCMax'] = np.array(tTrends[k]['slopesCMax'])
    tTrends[k]['slopesCMaxInd'] = np.array(tTrends[k]['slopesCMaxInd'])
    tTrends[k]['cCoverMax'] = np.array(tTrends[k]['cCoverMax'])
    tTrends[k]['slopesCMin'] = np.array(tTrends[k]['slopesCMin'])
    tTrends[k]['slopesCMinInd'] = np.array(tTrends[k]['slopesCMinInd'])
    tTrends[k]['cCoverMin'] = np.array(tTrends[k]['cCoverMin'])
    
    
    tTrends[k]['slopesNoCMax'] = []
    tTrends[k]['slopesNoCMaxInd'] = []
    tTrends[k]['slopesNoCMin'] = []
    tTrends[k]['slopesNoCMinInd'] = []
    for p in range(len(tMeans[k]['noCLat'])):
        nn = np.where(~np.isnan(tMeans[k]['noCMax'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['noCMax'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['noCMax'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesNoCMax'].append(tSlope*10)
            tTrends[k]['slopesNoCMaxInd'].append(p)
        nn = np.where(~np.isnan(tMeans[k]['noCMin'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['noCMin'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['noCMin'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesNoCMin'].append(tSlope*10)
            tTrends[k]['slopesNoCMinInd'].append(p)
    tTrends[k]['slopesNoCMax'] = np.array(tTrends[k]['slopesNoCMax'])
    tTrends[k]['slopesNoCMaxInd'] = np.array(tTrends[k]['slopesNoCMaxInd'])
    tTrends[k]['slopesNoCMin'] = np.array(tTrends[k]['slopesNoCMin'])
    tTrends[k]['slopesNoCMinInd'] = np.array(tTrends[k]['slopesNoCMinInd'])
    
    tTrends[k]['slopesNoPMax'] = []
    tTrends[k]['slopesNoPMaxInd'] = []
    tTrends[k]['slopesNoPMin'] = []
    tTrends[k]['slopesNoPMinInd'] = []
    for p in range(tMeans[k]['noPLat'].shape[0]):
        nn = np.where(~np.isnan(tMeans[k]['noPMax'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['noPMax'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['noPMax'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesNoPMax'].append(tSlope*10)
            tTrends[k]['slopesNoPMaxInd'].append(p)
        nn = np.where(~np.isnan(tMeans[k]['noPMin'][p,:]))[0]
        if len(nn) > 5:
            X = sm.add_constant(range(len(tMeans[k]['noPMin'][p,nn])))
            mdlT = sm.OLS(tMeans[k]['noPMin'][p,nn].reshape(-1,1), X).fit()
            tSlope = mdlT.params[1]
            tTrends[k]['slopesNoPMin'].append(tSlope*10)
            tTrends[k]['slopesNoPMinInd'].append(p)
    tTrends[k]['slopesNoPMax'] = np.array(tTrends[k]['slopesNoPMax'])
    tTrends[k]['slopesNoPMaxInd'] = np.array(tTrends[k]['slopesNoPMaxInd'])
    tTrends[k]['slopesNoPMin'] = np.array(tTrends[k]['slopesNoPMin'])
    tTrends[k]['slopesNoPMinInd'] = np.array(tTrends[k]['slopesNoPMinInd'])

kModels = {'A':{}, 'B':{}, 'C':{}, 'D':{}}
    
totalPCells = len(tTrends['A']['slopesPMax']) + len(tTrends['B']['slopesPMax']) + len(tTrends['C']['slopesPMax']) + \
              len(tTrends['D']['slopesPMax'])
totalCCells = len(tTrends['A']['slopesCMax']) + len(tTrends['B']['slopesCMax']) + len(tTrends['C']['slopesCMax']) + \
              len(tTrends['D']['slopesCMax'])
#
#allPCover = np.concatenate((tMeans['A']['pCover'], tMeans['B']['pCover'], tMeans['C']['pCover'], \
#                            tMeans['D']['pCover']))
#allCCover = np.concatenate((tMeans['A']['cCover'], tMeans['B']['cCover'], tMeans['C']['cCover'], \
#                            tMeans['D']['cCover']))
#allP = np.concatenate((tMeans['A']['P'], tMeans['B']['P'], tMeans['C']['P'], \
#                            tMeans['D']['P']))
#allC = np.concatenate((tMeans['A']['C'], tMeans['B']['C'], tMeans['C']['C'], \
#                            tMeans['D']['C']))
#    
#nn = np.where((~np.isnan(allP)) & (~np.isnan(allPCover)))[0]
#X = sm.add_constant(allPCover[nn].reshape(-1,1))
#mdl = sm.OLS(allP[nn].reshape(-1,1), X).fit()
#print('All: T/Pasture: interc = %.2f, coef = %.2f, p = %.2f'%(mdl.params[0], mdl.params[1], mdl.pvalues[1]))
#
#nn = np.where((~np.isnan(allC)) & (~np.isnan(allCCover)))[0]
#X = sm.add_constant(allCCover[nn].reshape(-1,1))
#mdl = sm.OLS(allC[nn].reshape(-1,1), X).fit()
#print('All: T/Crop: interc = %.2f, coef = %.2f, p = %.2f'%(mdl.params[0], mdl.params[1], mdl.pvalues[1]))
#print()

cCutoff = 0.25

for k in ['A', 'B', 'C', 'D']:
    print('%s: %.2f total P'%(k, len(tTrends[k]['slopesPMax'])/totalPCells))
    print('%s: %.2f total C'%(k, len(tTrends[k]['slopesCMax'])/totalCCells))
    
    if not 'tPMax' in kModels[k].keys():
        nn = np.where((~np.isnan(tTrends[k]['slopesPMax'])) & (~np.isnan(tTrends[k]['pCoverMax'])) & (tTrends[k]['pCoverMax'] > cCutoff))[0]
        if len(tTrends[k]['slopesPMax'][nn]) > 5:
            X = sm.add_constant(np.array(tTrends[k]['pCoverMax'][nn]).reshape(-1,1))
            mdl = sm.RLM(np.array(tTrends[k]['slopesPMax'][nn]).reshape(-1,1), X).fit()
            kModels[k]['tPMax'] = mdl
    print('%s: TMax/Pasture: interc = %.2f, coef = %.2f, p = %.2f'%(k, kModels[k]['tPMax'].params[0], kModels[k]['tPMax'].params[1], kModels[k]['tPMax'].pvalues[1]))
    
    if not 'tPMin' in kModels[k].keys():
        nn = np.where((~np.isnan(tTrends[k]['slopesPMin'])) & (~np.isnan(tTrends[k]['pCoverMin'])) & (tTrends[k]['pCoverMin'] > cCutoff))[0]
        if len(tTrends[k]['slopesPMin'][nn]) > 5:
            X = sm.add_constant(np.array(tTrends[k]['pCoverMin'][nn]).reshape(-1,1))
            mdl = sm.RLM(np.array(tTrends[k]['slopesPMin'][nn]).reshape(-1,1), X).fit()
            kModels[k]['tPMin'] = mdl
    print('%s: TMin/Pasture: interc = %.2f, coef = %.2f, p = %.2f'%(k, kModels[k]['tPMin'].params[0], kModels[k]['tPMin'].params[1], kModels[k]['tPMin'].pvalues[1]))
    
    if not 'tCMax' in kModels[k].keys():
        nn = np.where((~np.isnan(tTrends[k]['slopesCMax'])) & (~np.isnan(tTrends[k]['cCoverMax'])) & (tTrends[k]['cCoverMax'] > cCutoff))[0]
        if len(tTrends[k]['slopesCMax'][nn]) > 5:
            X = sm.add_constant(np.array(tTrends[k]['cCoverMax'][nn]).reshape(-1,1))
            mdl = sm.RLM(np.array(tTrends[k]['slopesCMax'][nn]).reshape(-1,1), X).fit()
            kModels[k]['tCMax'] = mdl
    print('%s: TMax/Crop: interc = %.2f, coef = %.2f, p = %.2f'%(k, kModels[k]['tCMax'].params[0], kModels[k]['tCMax'].params[1], kModels[k]['tCMax'].pvalues[1]))
    
    if not 'tCMin' in kModels[k].keys():
        nn = np.where((~np.isnan(tTrends[k]['slopesCMin'])) & (~np.isnan(tTrends[k]['cCoverMin'])) & (tTrends[k]['cCoverMin'] > cCutoff))[0]
        if len(tTrends[k]['slopesCMin'][nn]) > 5:
            X = sm.add_constant(np.array(tTrends[k]['cCoverMin'][nn]).reshape(-1,1))
            mdl = sm.RLM(np.array(tTrends[k]['slopesCMin'][nn]).reshape(-1,1), X).fit()
            kModels[k]['tCMin'] = mdl
    print('%s: TMin/Crop: interc = %.2f, coef = %.2f, p = %.2f'%(k, kModels[k]['tCMin'].params[0], kModels[k]['tCMin'].params[1], kModels[k]['tCMin'].pvalues[1]))
    
    print()

with open('k-models-rlm.dat', 'wb') as f:
    pickle.dump(kModels, f)
    
    
dist = st.norm
for i, k in enumerate(['A', 'B', 'C', 'D']):
    
    pPerc = tMeans[k]['PMax'].shape[0]/totalPCells*100
    cPerc = tMeans[k]['CMax'].shape[0]/totalCCells*100
    
    t = np.nanmean(tMeans[k]['CMax'], axis=1)
    nn = np.where(~np.isnan(t))[0]
    paramsDistC = dist.fit(t[nn])
    argDistC = paramsDistC[:-2]
    locDistC = paramsDistC[-2]
    scaleDistC = paramsDistC[-1]
    
    t = np.nanmean(tMeans[k]['noCMax'], axis=1)
    nn = np.where(~np.isnan(t))[0]
    paramsDistNoC = dist.fit(t[nn])
    argDistNoC = paramsDistNoC[:-2]
    locDistNoC = paramsDistNoC[-2]
    scaleDistNoC = paramsDistNoC[-1]
    
    if len(tMeans[k]['noCMax']) == 0 or len(tMeans[k]['CMax']) == 0:
        continue
    
    x = np.linspace(np.nanmin(np.concatenate((np.nanmean(tMeans[k]['noCMax'], axis=1), np.nanmean(tMeans[k]['CMax'], axis=1)))), \
                    np.nanmax(np.concatenate((np.nanmean(tMeans[k]['noCMax'], axis=1), np.nanmean(tMeans[k]['CMax'], axis=1)))), 50)
    
    pdfDistNoC = dist.pdf(x, loc=locDistNoC, scale=scaleDistNoC, *argDistNoC)
    pdfDistC = dist.pdf(x, loc=locDistC, scale=scaleDistC, *argDistC)
    
    
    xMaxC = np.where((pdfDistC == np.nanmax(pdfDistC)))[0]
    xMaxNoC = np.where((pdfDistNoC == np.nanmax(pdfDistNoC)))[0]
    
    nnC = np.where(~np.isnan(pdfDistC))[0]
    nnNoC = np.where(~np.isnan(pdfDistNoC))[0]
    
    if len(nnC) > 5 and len(nnNoC) > 5:
        plt.figure(figsize=(4, 4))
        plt.grid(True, color=[.9, .9, .9])
        
        plt.plot(x, pdfDistC, 'g', lw=2, label='Cropland')
        plt.plot(x, pdfDistNoC, 'm', lw=2, label='No crop')
        
        plt.plot([x[xMaxC], x[xMaxC]], [0, np.nanmax(pdfDistC)], '--g', lw=2)
        plt.plot([x[xMaxNoC], x[xMaxNoC]], [0, np.nanmax(pdfDistNoC)], '--m', lw=2)
        
        plt.title('Classification: %s (%.1f%% total)'%(k, cPerc), fontname = 'Helvetica', fontsize=16)
        plt.legend(markerscale=2, prop = {'size':10, 'family':'Helvetica'}, frameon=False)
        
        plt.xlabel('Temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
        plt.ylabel('Density', fontname = 'Helvetica', fontsize=16)
        
        for tick in plt.gca().xaxis.get_major_ticks():
            tick.label.set_fontname('Helvetica')
            tick.label.set_fontsize(14)
        for tick in plt.gca().yaxis.get_major_ticks():
            tick.label.set_fontname('Helvetica')    
            tick.label.set_fontsize(14)

        
#        plt.savefig('koppen-t-crop-%s.eps'%k, format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
    plt.show()

    
    

dist = st.norm
for i, k in enumerate(['A', 'B', 'C', 'D']):
    
    pPerc = tMeans[k]['PMax'].shape[0]/totalPCells*100
    cPerc = tMeans[k]['CMax'].shape[0]/totalCCells*100
    
    t = tTrends[k]['slopesCMax']
    nn = np.where(~np.isnan(t))[0]
    paramsDistC = dist.fit(t[nn])
    argDistC = paramsDistC[:-2]
    locDistC = paramsDistC[-2]
    scaleDistC = paramsDistC[-1]
    
    t = tTrends[k]['slopesNoCMax']
    nn = np.where(~np.isnan(t))[0]
    paramsDistNoC = dist.fit(t[nn])
    argDistNoC = paramsDistNoC[:-2]
    locDistNoC = paramsDistNoC[-2]
    scaleDistNoC = paramsDistNoC[-1]
    
    if len(tTrends[k]['slopesNoCMax']) == 0 or len(tTrends[k]['slopesCMax']) == 0:
        continue
    
    x = np.linspace(np.nanmin(np.concatenate((tTrends[k]['slopesNoCMax'], tTrends[k]['slopesCMax']))), \
                    np.nanmax(np.concatenate((tTrends[k]['slopesNoCMax'], tTrends[k]['slopesCMax']))), 50)
    
    pdfDistNoC = dist.pdf(x, loc=locDistNoC, scale=scaleDistNoC, *argDistNoC)
    pdfDistC = dist.pdf(x, loc=locDistC, scale=scaleDistC, *argDistC)
    
    
    xMaxC = np.where((pdfDistC == np.nanmax(pdfDistC)))[0]
    xMaxNoC = np.where((pdfDistNoC == np.nanmax(pdfDistNoC)))[0]
    
    nnC = np.where(~np.isnan(pdfDistC))[0]
    nnNoC = np.where(~np.isnan(pdfDistNoC))[0]
    
    if len(nnC) > 5 and len(nnNoC) > 5:
        plt.figure(figsize=(4, 4))
        plt.grid(True, color=[.9, .9, .9])
        
        plt.plot(x, pdfDistC, 'g', lw=2, label='Cropland')
        plt.plot(x, pdfDistNoC, 'm', lw=2, label='No crop')
        
        plt.plot([x[xMaxC], x[xMaxC]], [0, np.nanmax(pdfDistC)], '--g', lw=2)
        plt.plot([x[xMaxNoC], x[xMaxNoC]], [0, np.nanmax(pdfDistNoC)], '--m', lw=2)
        
        plt.title('Classification: %s (%.1f%% total)'%(k, cPerc), fontname = 'Helvetica', fontsize=16)
        plt.legend(markerscale=2, prop = {'size':10, 'family':'Helvetica'}, frameon=False)
        
        plt.xlabel('Temperature trend ($\degree$C/decade)', fontname = 'Helvetica', fontsize=16)
        plt.ylabel('Density', fontname = 'Helvetica', fontsize=16)
        
        for tick in plt.gca().xaxis.get_major_ticks():
            tick.label.set_fontname('Helvetica')
            tick.label.set_fontsize(14)
        for tick in plt.gca().yaxis.get_major_ticks():
            tick.label.set_fontname('Helvetica')    
            tick.label.set_fontsize(14)

        
#        plt.savefig('koppen-t-crop-%s.eps'%k, format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
    plt.show()
    

    
    
sys.exit()
    
#for i, k in enumerate(koppenGroupsPCells.keys()):
#    
#    paramsDistP = dist.fit(tMeans[k]['P'])
#    argDistP = paramsDistP[:-2]
#    locDistP = paramsDistP[-2]
#    scaleDistP = paramsDistP[-1]
#    
#    paramsDistNoP = dist.fit(tMeans[k]['noP'])
#    argDistNoP = paramsDistNoP[:-2]
#    locDistNoP = paramsDistNoP[-2]
#    scaleDistNoP = paramsDistNoP[-1]
#    
#    if len(tMeans[k]['noP']) == 0 or len(tMeans[k]['P']) == 0:
#        continue
#    
#    x = np.linspace(np.nanmin(np.concatenate((tMeans[k]['noP'], tMeans[k]['P']))), \
#                    np.nanmax(np.concatenate((tMeans[k]['noP'], tMeans[k]['P']))), 50)
#    
#    pdfDistNoP = dist.pdf(x, loc=locDistNoP, scale=scaleDistNoP, *argDistNoP)
#    pdfDistP = dist.pdf(x, loc=locDistP, scale=scaleDistP, *argDistP)
#    
#    
#    xMaxP = np.where((pdfDistP == np.nanmax(pdfDistP)))[0]
#    xMaxNoP = np.where((pdfDistNoP == np.nanmax(pdfDistNoP)))[0]
#    
#    nnP = np.where(~np.isnan(pdfDistP))[0]
#    nnNoP = np.where(~np.isnan(pdfDistNoP))[0]
#    
#    if len(nnP) > 5 and len(nnNoP) > 5:
#        plt.figure(figsize=(4, 4))
#        plt.grid(True, color=[.9, .9, .9])
#        
#        plt.plot(x, pdfDistP, 'g', lw=2, label='Pasture')
#        plt.plot(x, pdfDistNoP, 'm', lw=2, label='Not pasture')
#        
#        plt.plot([x[xMaxP], x[xMaxP]], [0, np.nanmax(pdfDistP)], '--g', lw=2)
#        plt.plot([x[xMaxNoP], x[xMaxNoP]], [0, np.nanmax(pdfDistNoP)], '--m', lw=2)
#        
#        plt.title('Classification: %s (%.1f%% total)'%(k, cPerc), fontname = 'Helvetica', fontsize=16)
#        plt.legend(markerscale=2, prop = {'size':10, 'family':'Helvetica'}, frameon=False)
#        
#        plt.xlabel('Temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
#        plt.ylabel('Density', fontname = 'Helvetica', fontsize=16)
#        
#        for tick in plt.gca().xaxis.get_major_ticks():
#            tick.label.set_fontname('Helvetica')
#            tick.label.set_fontsize(14)
#        for tick in plt.gca().yaxis.get_major_ticks():
#            tick.label.set_fontname('Helvetica')    
#            tick.label.set_fontsize(14)
#
#        
#        plt.savefig('koppen-t-pasture-%s.eps'%k, format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
#    plt.show()
    
    

plt.figure(figsize=(4, 4))
plt.grid(True, color=[.9, .9, .9])

xs = np.linspace(0,1,10)

colors = ['r', 'm', 'g', 'b']
xpos = [.95, .98, 1.01, 1.04]
for i, k in enumerate(['A', 'B', 'C', 'D']):
    if i == 0:
        plt.plot(xpos[i], np.nanmean(tMeans[k]['noC']), 'ok', ms=6, label='No crops', mfc=colors[i])
    else:
        plt.plot(xpos[i], np.nanmean(tMeans[k]['noC']), 'ok', ms=6, mfc=colors[i])
    plt.errorbar(xpos[i], np.nanmean(tMeans[k]['noC']), yerr = np.nanstd(tMeans[k]['noC']), lw=2, color=colors[i], \
                 elinewidth = 1, capsize = 3, fmt = 'none')
    
    
    if len(tMeans[k]['C']) > 5:
        ys = []
        for x in xs:
            ys.append(kModels[k]['tC'].predict([1, x]))
        
        plt.plot(xpos[i]+xs, ys, '--', label='Region %s'%k, color=colors[i])

plt.title('T vs. Cropland Fraction', fontname = 'Helvetica', fontsize=16)
plt.legend(markerscale=2, prop = {'size':12, 'family':'Helvetica'}, frameon=False, \
           bbox_to_anchor=(1, .65))

plt.xticks([1, 1.2, 1.4, 1.6, 1.8, 2])
plt.gca().set_xticklabels([0, .2, .4, .6, .8, 1])

plt.xlabel('Cropland fraction', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)







plt.figure(figsize=(4, 4))
plt.grid(True, color=[.9, .9, .9])

xs = np.linspace(0,1,10)

colors = ['r', 'm', 'g', 'b']
xpos = [.95, .98, 1.01, 1.04]
for i, k in enumerate(['A', 'B', 'C', 'D']):
    if i == 0:
        plt.plot(xpos[i], np.nanmean(tMeans[k]['noP']), 'ok', ms=6, label='No pasture', mfc=colors[i])
    else:
        plt.plot(xpos[i], np.nanmean(tMeans[k]['noP']), 'ok', ms=6, mfc=colors[i])
    plt.errorbar(xpos[i], np.nanmean(tMeans[k]['noP']), yerr = np.nanstd(tMeans[k]['noP']), lw=2, color=colors[i], \
                 elinewidth = 1, capsize = 3, fmt = 'none')
    
    
    if len(tMeans[k]['P']) > 5:
        ys = []
        for x in xs:
            ys.append(kModels[k]['tP'].predict([1, x]))
        
        plt.plot(xpos[i]+xs, ys, '--', label='Region %s'%k, color=colors[i])

plt.title('T vs. Pasture Fraction', fontname = 'Helvetica', fontsize=16)
plt.legend(markerscale=2, prop = {'size':12, 'family':'Helvetica'}, frameon=False, \
           bbox_to_anchor=(1, .65))

plt.xticks([1, 1.2, 1.4, 1.6, 1.8, 2])
plt.gca().set_xticklabels([0, .2, .4, .6, .8, 1])

plt.xlabel('Pasture fraction', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)



sys.exit()

plt.savefig('t-cropland-regression.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.imshow(koppen)
plt.title('Koppen classification', fontname = 'Helvetica', fontsize=16)
cb = plt.colorbar(orientation='horizontal')
cb.set_ticks([1,2,3,4,5])
cb.set_ticklabels(['A', 'B', 'C', 'D', 'E'])
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off
plt.tick_params(
    axis='y',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    left=False,      # ticks along the bottom edge are off
    right=False,         # ticks along the top edge are off
    labelleft=False) # labels along the bottom edge are off
plt.savefig('koppen-map.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)


plt.imshow(cropRegrid)
plt.title('Cropland fraction', fontname = 'Helvetica', fontsize=16)
cb = plt.colorbar(orientation='horizontal')
cb.set_ticks([0, .25, .5, .75, 1])
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off
plt.tick_params(
    axis='y',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    left=False,      # ticks along the bottom edge are off
    right=False,         # ticks along the top edge are off
    labelleft=False) # labels along the bottom edge are off
plt.savefig('crop-frac-map.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.imshow(pastureRegrid)
plt.title('Pasture fraction', fontname = 'Helvetica', fontsize=16)
cb = plt.colorbar(orientation='horizontal')
cb.set_ticks([0, .25, .5, .75, 1])
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off
plt.tick_params(
    axis='y',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    left=False,      # ticks along the bottom edge are off
    right=False,         # ticks along the top edge are off
    labelleft=False) # labels along the bottom edge are off


























#        sacksInds = []
#        growingMaize = False
#        growingSoybeans = False
#        growingRice = False
#        growingWheat = False
#        for i in dayNumbers:
#            if np.isnan(i): continue
#        
#            if i == sacksCal['start_maize'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingMaize = True
#            elif growingMaize and i == sacksCal['end_maize'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingMaize = False
#                
#            if i == sacksCal['start_soybeans'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingSoybeans = True
#            elif growingSoybeans and i == sacksCal['end_soybeans'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingSoybeans = False
#                
#            if i == sacksCal['start_rice'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingRice = True
#            elif growingRice and i == sacksCal['end_rice'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingRice = False
#                
#            if i == sacksCal['start_wheat'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingWheat = True
#            elif growingWheat and i == sacksCal['end_wheat'][cCells[p][0]*4, cCells[p][1]*4]:
#                growingWheat = False
#            if growingMaize or growingSoybeans or growingRice or growingWheat: sacksInds.append(int(i))
#        sacksInds = np.array(sacksInds)
#        
#        if sacksInds.shape[0] == 0: continue