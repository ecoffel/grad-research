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

dataDir = 'E:/data/ecoffel/data/projects/ag-land-climate/CroplandPastureArea2000_Geotiff/CroplandPastureArea2000_Geotiff'

def roundTo2(x):
    return 2*round(x/2)

pasture = rio.open('%s/Pasture2000_5m.tif'%dataDir)
pastureData = pasture.read(1)

crop = rio.open('%s/Cropland2000_5m.tif'%dataDir)
cropData = crop.read(1)

latOld = np.linspace(pasture.bounds.bottom, pasture.bounds.top, pasture.shape[0])
lonOld = np.linspace(pasture.bounds.left, pasture.bounds.right, pasture.shape[1])

lon, lat = np.meshgrid(lonOld, latOld)

pastureInterp = interpolate.interp2d(lonOld, latOld, pastureData, kind='linear')
cropInterp = interpolate.interp2d(lonOld, latOld, cropData, kind='linear')

latNew = np.linspace(-90, 90, 90)
lonNew = np.linspace(0, 360, 180)
lonNew[lonNew > 180] -= 360

lon, lat = np.meshgrid(lonNew, latNew)
pastureRegrid = pastureInterp(lonNew, latNew)
pastureRegrid[pastureRegrid < 0] = np.nan

cropRegrid = cropInterp(lonNew, latNew)
cropRegrid[cropRegrid < 0] = np.nan

koppen = np.genfromtxt('koppen-classifications.txt', delimiter=',')
koppen = np.flipud(koppen)
koppen = np.roll(koppen, 90)
koppen[koppen == 0] = np.nan

koppenGroupsPCells = {1:[], 2:[], 3:[], 4:[]}
koppenGroupsNoPCells = {1:[], 2:[], 3:[], 4:[]}

koppenGroupsCCells = {1:[], 2:[], 3:[], 4:[]}
koppenGroupsNoCCells = {1:[], 2:[], 3:[], 4:[]}
for x in range(koppen.shape[0]):
    for y in range(koppen.shape[1]):
        if koppen[x,y] in [1,2,3,4]:
            if pastureRegrid[x,y] > .01:
                koppenGroupsPCells[koppen[x,y]].append((x,y))
            else:
                koppenGroupsNoPCells[koppen[x,y]].append((x,y))
            
            if cropRegrid[x,y] > .01:
                koppenGroupsCCells[koppen[x,y]].append((x,y))
            else:
                koppenGroupsNoCCells[koppen[x,y]].append((x,y))

# indexed by their lon
tData = {}
pData = {}

for k in [1,2,3,4]:
    print('loading t/p time series for k = %d...'%k)
    for c in range(len(koppenGroupsPCells[k])):
        curLat = int(roundTo2(latNew[koppenGroupsPCells[k][c][0]]))
        curLon = int(roundTo2(lonNew[koppenGroupsPCells[k][c][1]]))
        
        if curLon not in tData.keys():
            tData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-%d.txt'%(curLon), delimiter=',')
            pData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-%d.txt'%(curLon), delimiter=',')    
    
    for c in range(len(koppenGroupsNoPCells[k])):
        curLat = int(roundTo2(latNew[koppenGroupsNoPCells[k][c][0]]))
        curLon = int(roundTo2(lonNew[koppenGroupsNoPCells[k][c][1]]))
        
        if curLon not in tData.keys():
            tData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-%d.txt'%(curLon), delimiter=',')
            pData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-%d.txt'%(curLon), delimiter=',')    
    
    for c in range(len(koppenGroupsCCells[k])):
        curLat = int(roundTo2(latNew[koppenGroupsCCells[k][c][0]]))
        curLon = int(roundTo2(lonNew[koppenGroupsCCells[k][c][1]]))
        
        if curLon not in tData.keys():
            tData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-%d.txt'%(curLon), delimiter=',')
            pData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-%d.txt'%(curLon), delimiter=',')    
    
    for c in range(len(koppenGroupsNoCCells[k])):
        curLat = int(roundTo2(latNew[koppenGroupsNoCCells[k][c][0]]))
        curLon = int(roundTo2(lonNew[koppenGroupsNoCCells[k][c][1]]))
        
        if curLon not in tData.keys():
            tData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-%d.txt'%(curLon), delimiter=',')
            pData[curLon] = np.genfromtxt('E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-%d.txt'%(curLon), delimiter=',')    
        

tMeans = {}
pMeans = {}

for k in [1,2,3,4]:
    
    tMeans[k] = {}
    tMeans[k]['pCover'] = []
    tMeans[k]['P'] = []
    tMeans[k]['noP'] = []
    tMeans[k]['cCover'] = []
    tMeans[k]['C'] = []
    tMeans[k]['noC'] = []
    
    pMeans[k] = {}
    pMeans[k]['pCover'] = []
    pMeans[k]['P'] = []
    pMeans[k]['noP'] = []
    pMeans[k]['cCover'] = []
    pMeans[k]['C'] = []
    pMeans[k]['noC'] = []
    
    pCells = koppenGroupsPCells[k]
    for p in range(len(pCells)):
        curLon = int(2*round(lonNew[pCells[p][1]]/2))
        curLatCoord = pCells[p][0]
        
        tMeans[k]['pCover'].append(pastureRegrid[pCells[p][0], pCells[p][1]])
        pMeans[k]['pCover'].append(pastureRegrid[pCells[p][0], pCells[p][1]])
        tMeans[k]['P'].append(np.nanmean(tData[curLon][:,curLatCoord]))
        pMeans[k]['P'].append(np.nanmean(pData[curLon][:,curLatCoord])*365)
    
    noPCells = koppenGroupsNoPCells[k]
    for p in range(len(noPCells)):
        curLon = int(2*round(lonNew[noPCells[p][1]]/2))
        curLatCoord = noPCells[p][0]
        
        tMeans[k]['noP'].append(np.nanmean(tData[curLon][:,curLatCoord]))
        pMeans[k]['noP'].append(np.nanmean(pData[curLon][:,curLatCoord])*365)
    
    cCells = koppenGroupsCCells[k]
    for p in range(len(cCells)):
        curLon = int(2*round(lonNew[cCells[p][1]]/2))
        curLatCoord = cCells[p][0]
        
        tMeans[k]['cCover'].append(cropRegrid[cCells[p][0], cCells[p][1]])
        pMeans[k]['cCover'].append(cropRegrid[cCells[p][0], cCells[p][1]])
        tMeans[k]['C'].append(np.nanmean(tData[curLon][:,curLatCoord]))
        pMeans[k]['C'].append(np.nanmean(pData[curLon][:,curLatCoord])*365)
    
    noCCells = koppenGroupsNoCCells[k]
    for p in range(len(noCCells)):
        curLon = int(2*round(lonNew[noCCells[p][1]]/2))
        curLatCoord = noCCells[p][0]
        
        tMeans[k]['noC'].append(np.nanmean(tData[curLon][:,curLatCoord]))
        pMeans[k]['noC'].append(np.nanmean(pData[curLon][:,curLatCoord])*365)
    #noPCells = koppenGroupsNoPCells[k]
    
for k in [1,2,3,4]:
    X = sm.add_constant(np.array(tMeans[k]['pCover']).reshape(-1,1))
    mdl = sm.OLS(np.array(tMeans[k]['P']).reshape(-1,1), X).fit()
    print('T/Pasture: coef = %.2f, p = %.2f'%(mdl.params[1], mdl.pvalues[1]))
    X = sm.add_constant(np.array(pMeans[k]['pCover']).reshape(-1,1))
    mdl = sm.OLS(np.array(pMeans[k]['P']).reshape(-1,1), X).fit()
    print('P/Pasture: coef = %.2f, p = %.2f'%(mdl.params[1], mdl.pvalues[1]))
    
    X = sm.add_constant(np.array(tMeans[k]['cCover']).reshape(-1,1))
    mdl = sm.OLS(np.array(tMeans[k]['C']).reshape(-1,1), X).fit()
    print('T/Crop: coef = %.2f, p = %.2f'%(mdl.params[1], mdl.pvalues[1]))
    X = sm.add_constant(np.array(pMeans[k]['cCover']).reshape(-1,1))
    mdl = sm.OLS(np.array(pMeans[k]['C']).reshape(-1,1), X).fit()
    print('P/Crop: coef = %.2f, p = %.2f'%(mdl.params[1], mdl.pvalues[1]))
    print()
        
