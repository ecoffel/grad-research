# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import scipy.stats as st
import pickle, gzip
import sys, os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

plotFigs = False
dumpData = True

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

yearRange = [1981, 2005]

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('%s/script-data/pPolyData-%s-pow2.dat'%(dataDirDiscovery, runoffData), 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]
    plantIds = pPolyData['plantIds']
    plantYears = pPolyData['plantYears']

baseTx = 27
baseQs = 0

dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), 'QS2T2':[(baseTx**2)*(baseQs**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})

basePred10 = np.nanmean(pcModel10.predict(dfpred))
basePred50 = np.nanmean(pcModel50.predict(dfpred))
basePred90 = np.nanmean(pcModel90.predict(dfpred))

if not os.path.isfile('%s/script-data/pc-at-txx-hist-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData)):
    
    print('building historical pc')
    print('loading historical tx')
    fileNameTemp = '%s/script-data/%s-pp-tx.csv'%(dataDirDiscovery, plantData)
    plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
    plantYearData = plantTxData[0,:].copy()
    plantMonthData = plantTxData[1,:].copy()
    plantDayData = plantTxData[2,:].copy()
    plantTxData = plantTxData[3:,:].copy()
    
    summerInd = np.where((plantMonthData == 7) | (plantMonthData == 8))[0]
    plantMeanTemps = np.nanmean(plantTxData[:,summerInd], axis=1)
    
    pCapTxx10 = np.zeros([plantTxData.shape[0], len(range(yearRange[0], yearRange[1]+1))])
    pCapTxx50 = np.zeros([plantTxData.shape[0], len(range(yearRange[0], yearRange[1]+1))])
    pCapTxx90 = np.zeros([plantTxData.shape[0], len(range(yearRange[0], yearRange[1]+1))])
    
    pCapTxMedian10 = np.zeros([plantTxData.shape[0], len(range(yearRange[0], yearRange[1]+1))])
    pCapTxMedian50 = np.zeros([plantTxData.shape[0], len(range(yearRange[0], yearRange[1]+1))])
    pCapTxMedian90 = np.zeros([plantTxData.shape[0], len(range(yearRange[0], yearRange[1]+1))])
    
    # load historical runoff data for all plants in US and EU
    fileNameRunoff = '%s/script-data/%s-pp-runoff-anom-gldas-1981-2005.csv'%(dataDirDiscovery, plantData)
    
    print('loading historical qs')
    plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
    plantQsData = plantQsData[3:,:]

    for y, year in enumerate(range(yearRange[0], yearRange[1]+1)):
    
        print('processing %d'%year)
    
        ind = np.where((plantYearData == year) & (plantMonthData >= 7) & (plantMonthData <= 8))[0]

        curTxx = np.full((plantTxData.shape[0]), np.nan)
        curQsTxx = np.full((plantTxData.shape[0]), np.nan)
        curTxMedian = np.full((plantTxData.shape[0]), np.nan)
        curQsTxMedian = np.full((plantTxData.shape[0]), np.nan)
        
        if len(ind) > 0:
        
            curTx = plantTxData[:, ind]
            curQs = plantQsData[:, ind]

            curQs[curQs < -5] = np.nan
            curQs[curQs > 5] = np.nan
            
            indTxx = np.full((curTx.shape[0], len(ind)), False)
            indMedian = np.full((curTx.shape[0], len(ind)), False)
            
            # ind of the txx day in this year for all plants
            for p in range(curTx.shape[0]):
                
                tmp = np.where(curTx[p,:] == np.nanmax(curTx[p,:]))[0]
                
                if len(tmp) > 0:
                    curTxx[p] = curTx[p, tmp[0]]
                    curQsTxx[p] = curQs[p, tmp[0]]
                
                tmp = np.where((abs(curTx[p,:]-np.nanmedian(curTx[p,:])) == min(abs(curTx[p,:]-np.nanmedian(curTx[p,:])))))[0]
                if len(tmp) > 0:
                    curTxMedian[p] = curTx[p, tmp[0]]
                    curQsTxMedian[p] = curQs[p, tmp[0]]
            
            
            indCompute = np.where((~np.isnan(curTxx)) & (~np.isnan(curQsTxx)) & (curTxx > baseTx))[0]
            indPlantIdsCompute = np.random.choice(len(plantIds), len(indCompute))
            
            dfpred = pd.DataFrame({'T1':curTxx[indCompute], 'T2':curTxx[indCompute]**2, \
                                     'QS1':curQsTxx[indCompute], 'QS2':curQsTxx[indCompute]**2, \
                                     'QST':curTxx[indCompute]*curQsTxx[indCompute], \
                                     'QS2T2':(curTxx[indCompute]**2)*(curQsTxx[indCompute]**2), \
                                     'PlantIds':plantIds[indPlantIdsCompute], 'PlantYears':plantYears[indPlantIdsCompute]})

            pCapTxx10[indCompute, y] = pcModel10.predict(dfpred) - basePred10
            pCapTxx50[indCompute, y] = pcModel50.predict(dfpred) - basePred50
            pCapTxx90[indCompute, y] = pcModel90.predict(dfpred) - basePred90
            
            
            
            indCompute = np.where((~np.isnan(curTxMedian)) & (~np.isnan(curQsTxMedian)) & (curTxMedian > baseTx))[0]
            indPlantIdsCompute = np.random.choice(len(plantIds), len(indCompute))
            
            dfpred = pd.DataFrame({'T1':curTxMedian[indCompute], 'T2':curTxMedian[indCompute]**2, \
                                     'QS1':curQsTxMedian[indCompute], 'QS2':curQsTxMedian[indCompute]**2, \
                                     'QST':curTxMedian[indCompute]*curQsTxMedian[indCompute], \
                                     'QS2T2':(curTxMedian[indCompute]**2)*(curQsTxMedian[indCompute]**2), \
                                     'PlantIds':plantIds[indPlantIdsCompute], 'PlantYears':plantYears[indPlantIdsCompute]})

            pCapTxMedian10[indCompute, y] = pcModel10.predict(dfpred) - basePred10
            pCapTxMedian50[indCompute, y] = pcModel50.predict(dfpred) - basePred50
            pCapTxMedian90[indCompute, y] = pcModel90.predict(dfpred) - basePred90
            
    # if positive, no heat realated outage so set to 0
    pCapTxx10[pCapTxx10 > 0] = 0
    pCapTxx50[pCapTxx50 > 0] = 0
    pCapTxx90[pCapTxx90 > 0] = 0
    
    pCapTxx10[pCapTxx10 < -100] = -100
    pCapTxx50[pCapTxx50 < -100] = -100
    pCapTxx90[pCapTxx90 < -100] = -100
    
    pCapTxMedian10[pCapTxMedian10 > 0] = 0
    pCapTxMedian50[pCapTxMedian50 > 0] = 0
    pCapTxMedian90[pCapTxMedian90 > 0] = 0
    
    pCapTxMedian10[pCapTxMedian10 < -100] = -100
    pCapTxMedian50[pCapTxMedian50 < -100] = -100
    pCapTxMedian90[pCapTxMedian90 < -100] = -100
    
    if dumpData:
        pcChg = {'pCapTxMedian10':pCapTxMedian10, \
                 'pCapTxMedian50':pCapTxMedian50, \
                 'pCapTxMedian90':pCapTxMedian90, \
                 'pCapTxx10':pCapTxx10, \
                 'pCapTxx50':pCapTxx50, \
                 'pCapTxx90':pCapTxx90}
        with open('%s/script-data/pc-at-txx-hist-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData), 'wb') as f:
            pickle.dump(pcChg, f)

sys.exit()

# load future mean warming data and recompute PC
pCapTxxFutMeanWarming10 = []
pCapTxxFutMeanWarming50 = []
pCapTxxFutMeanWarming90 = []

pCapTxMedianFutMeanWarming10 = []
pCapTxMedianFutMeanWarming50 = []
pCapTxMedianFutMeanWarming90 = []

nplants = -1

for w in range(1, 4+1):
    print('processing %dC...'%w)
    pCapTxxFutCurGMT10 = []
    pCapTxxFutCurGMT50 = []
    pCapTxxFutCurGMT90 = []
    
    pCapTxMedianFutCurGMT10 = []
    pCapTxMedianFutCurGMT50 = []
    pCapTxMedianFutCurGMT90 = []
    
    for m in range(len(models)):
        
        pCapTxxFutCurModel10 = []
        pCapTxxFutCurModel50 = []
        pCapTxxFutCurModel90 = []
        
        pCapTxMedianFutCurModel10 = []
        pCapTxMedianFutCurModel50 = []
        pCapTxMedianFutCurModel90 = []
        
        # load data for current model and warming level
        fileNameTemp = 'E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/%s-pp-%ddeg-tx-cmip5-%s.csv'%(plantData, w, models[m])
    
        if not os.path.isfile(fileNameTemp):
            # add a nan for each plant in current model
            filler = []
            for p in range(nplants):
                filler.append(np.nan)
            pCapTxxFutCurGMT10.append(filler)
            pCapTxxFutCurGMT50.append(filler)
            pCapTxxFutCurGMT90.append(filler)
            
            pCapTxMedianFutCurGMT10.append(filler)
            pCapTxMedianFutCurGMT50.append(filler)
            pCapTxMedianFutCurGMT90.append(filler)
            continue
    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0:
            # add a nan for each plant in current model
            filler = []
            for p in range(nplants):
                filler.append(np.nan)
            pCapTxxFutCurGMT10.append(filler)
            pCapTxxFutCurGMT50.append(filler)
            pCapTxxFutCurGMT90.append(filler)
            
            pCapTxMedianFutCurGMT10.append(filler)
            pCapTxMedianFutCurGMT50.append(filler)
            pCapTxMedianFutCurGMT90.append(filler)
            continue
        
        plantTxYearData = plantTxData[0,0:].copy()
        plantTxMonthData = plantTxData[1,0:].copy()
        plantTxDayData = plantTxData[2,0:].copy()
        plantTxData = plantTxData[3:,0:].copy()
        
        # set the number of plants using the first model/1C (this one has data)
        # this is done on first iter, and then when model/GMT combos have no data the filler
        # loops set the correct number of nans
        if nplants == -1 and plantTxData.shape[0] > 9000:
            nplants = plantTxData.shape[0]
        
        # load historical runoff data for all plants in US and EU
        fileNameRunoff = 'E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/%s-pp-%ddeg-runoff-raw-cmip5-%s.csv'%(plantData, w, models[m])
        fileNameRunoffDistFit = 'E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/%s-pp-%ddeg-runoff%s-cmip5-%s.csv'%(plantData, w, qstr, models[m])
        
        if os.path.isfile(fileNameRunoffDistFit):
            plantQsData = np.genfromtxt(fileNameRunoffDistFit, delimiter=',', skip_header=0)
        else:
            plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
            plantQsData = plantQsData[3:,:]
            
            print('calculating qs distfit anomalies for %s/%dC'%(models[m],w))
            plantQsAnomData = []
            dist = st.gamma
            for p in range(plantQsData.shape[0]):
                q = plantQsData[p,:]
                nn = np.where(~np.isnan(q))[0]
                if len(nn) > 10:
                    args = dist.fit(q[nn])
                    curQsStd = dist.std(*args)
                else:
                    curQsStd = np.nan
                plantQsAnomData.append((q-np.nanmean(q))/curQsStd)
            plantQsAnomData = np.array(plantQsAnomData)
            np.savetxt(fileNameRunoffDistFit, plantQsAnomData, delimiter=',')
            plantQsData = plantQsAnomData
        
#        plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
#        plantQsYearData = plantQsData[0,0:].copy()
#        plantQsMonthData = plantQsData[1,0:].copy()
#        plantQsDayData = plantQsData[2,0:].copy()
#        plantQsData = plantQsData[3:,0:].copy()
        
        
        # loop over all plants
        for p in range(plantTxData.shape[0]):
            
            plantPcTxx10 = []
            plantPcTxx50 = []
            plantPcTxx90 = []
            
            plantPcTxMedian10 = []
            plantPcTxMedian50 = []
            plantPcTxMedian90 = []
            
            # tx for current plant
            tx = plantTxData[p, :]
            qs = plantQsData[p, :]
            
            qs[qs < -4] = np.nan
            qs[qs > 4] = np.nan
            
            # loop over all years for current model/GMT anomaly
            for year in range(int(min(plantTxYearData)), int(max(plantTxYearData))+1):
        
                # tx for current year's summer
                ind = np.where((plantTxYearData == year) & (plantTxMonthData >= 7) & (plantTxMonthData <= 8))[0]
                
                curTx = tx[ind]
                curQs = qs[ind]
                
                nn = np.where(~np.isnan(curTx))[0]
                
                if len(nn) == 0:
                    plantPcTxMedian10.append(np.nan)
                    plantPcTxMedian50.append(np.nan)
                    plantPcTxMedian90.append(np.nan)
                    
                    plantPcTxx10.append(np.nan)
                    plantPcTxx50.append(np.nan)
                    plantPcTxx90.append(np.nan)
                    continue
                
                curTx = curTx[nn]
                curQs = curQs[nn]
                
                # ind of the txx day in this year
                indTxx = np.where(curTx == np.nanmax(curTx))[0][0]
                indTxMedian = indMedian = np.where((abs(curTx-np.nanmedian(curTx)) == min(abs(curTx-np.nanmedian(curTx)))))[0][0]
                
                curTxx = curTx[indTxx]
                curQsTxx = curQs[indTxx]
                
                curTxMedian = curTx[indTxMedian]
                curQsTxMedian = curQs[indTxMedian]
                
#                curPcPred10 = []
#                curPcPred50 = []
#                curPcPred90 = []
                
                if curTxx >= baseTx:
                    curPcPredTxx10 = pcModel10.predict([1, curTxx, curTxx**2, \
                                                             curQsTxx, curQsTxx**2, \
                                                             curTxx*curQsTxx, (curTxx**2)*(curQsTxx**2), \
                                                             0])[0] - basePred10
                    curPcPredTxx50 = pcModel50.predict([1, curTxx, curTxx**2, \
                                                             curQsTxx, curQsTxx**2, \
                                                             curTxx*curQsTxx, (curTxx**2)*(curQsTxx**2), \
                                                             0])[0] - basePred50
                    curPcPredTxx90 = pcModel90.predict([1, curTxx, curTxx**2, \
                                                             curQsTxx, curQsTxx**2, \
                                                             curTxx*curQsTxx, (curTxx**2)*(curQsTxx**2), \
                                                             0])[0] - basePred90
                else:
                    curPcPredTxx10 = 0
                    curPcPredTxx50 = 0
                    curPcPredTxx90 = 0
                
                if curPcPredTxx10 > 0: curPcPredTxx10 = 0
                if curPcPredTxx50 > 0: curPcPredTxx50 = 0
                if curPcPredTxx90 > 0: curPcPredTxx90 = 0
                
                if curPcPredTxx10 < -100: curPcPredTxx10 = -100
                if curPcPredTxx50 < -100: curPcPredTxx50 = -100
                if curPcPredTxx90 < -100: curPcPredTxx90 = -100
                     
                plantPcTxx10.append(curPcPredTxx10)
                plantPcTxx50.append(curPcPredTxx50)
                plantPcTxx90.append(curPcPredTxx90)
                
                
                if curTxMedian >= baseTx:
                    curPcPredTxMedian10 = pcModel10.predict([1, curTxMedian, curTxMedian**2, \
                                                             curQsTxMedian, curQsTxMedian**2, \
                                                             curTxMedian*curQsTxMedian, (curTxMedian**2)*(curQsTxMedian**2), \
                                                             0])[0] - basePred10
                    curPcPredTxMedian50 = pcModel50.predict([1, curTxMedian, curTxMedian**2, \
                                                             curQsTxMedian, curQsTxMedian**2, \
                                                             curTxMedian*curQsTxMedian, (curTxMedian**2)*(curQsTxMedian**2), \
                                                             0])[0] - basePred50
                    curPcPredTxMedian90 = pcModel90.predict([1, curTxMedian, curTxMedian**2, \
                                                             curQsTxMedian, curQsTxMedian**2, \
                                                             curTxMedian*curQsTxMedian, (curTxMedian**2)*(curQsTxMedian**2), \
                                                             0])[0] - basePred90
                else:
                    curPcPredTxMedian10 = 0
                    curPcPredTxMedian50 = 0
                    curPcPredTxMedian90 = 0
                
                if curPcPredTxMedian10 > 100: curPcPredTxMedian10 = 0
                if curPcPredTxMedian50 > 100: curPcPredTxMedian50 = 0
                if curPcPredTxMedian90 > 100: curPcPredTxMedian90 = 0
                
                if curPcPredTxMedian10 < -100: curPcPredTxMedian10 = -100
                if curPcPredTxMedian50 < -100: curPcPredTxMedian50 = -100
                if curPcPredTxMedian90 < -100: curPcPredTxMedian90 = -100
                     
                plantPcTxMedian10.append(curPcPredTxMedian10)
                plantPcTxMedian50.append(curPcPredTxMedian50)
                plantPcTxMedian90.append(curPcPredTxMedian90)
            
            pCapTxxFutCurModel10.append(plantPcTxx10)
            pCapTxxFutCurModel50.append(plantPcTxx50)
            pCapTxxFutCurModel90.append(plantPcTxx90)
            
            pCapTxMedianFutCurModel10.append(plantPcTxMedian10)
            pCapTxMedianFutCurModel50.append(plantPcTxMedian50)
            pCapTxMedianFutCurModel90.append(plantPcTxMedian90)
        
        pCapTxxFutCurGMT10.append(pCapTxxFutCurModel10)
        pCapTxxFutCurGMT50.append(pCapTxxFutCurModel50)
        pCapTxxFutCurGMT90.append(pCapTxxFutCurModel90)
        
        pCapTxMedianFutCurGMT10.append(pCapTxMedianFutCurModel10)
        pCapTxMedianFutCurGMT50.append(pCapTxMedianFutCurModel50)
        pCapTxMedianFutCurGMT90.append(pCapTxMedianFutCurModel90)
    
    pCapTxxFutCurGMT10 = np.array(pCapTxxFutCurGMT10)
    pCapTxxFutCurGMT50 = np.array(pCapTxxFutCurGMT50)
    pCapTxxFutCurGMT90 = np.array(pCapTxxFutCurGMT90)
    
    pCapTxMedianFutCurGMT10 = np.array(pCapTxMedianFutCurGMT10)
    pCapTxMedianFutCurGMT50 = np.array(pCapTxMedianFutCurGMT50)
    pCapTxMedianFutCurGMT90 = np.array(pCapTxMedianFutCurGMT90)
    
    if dumpData:
        pcChg = {'pCapTxMedianFutMeanWarming10':pCapTxMedianFutCurGMT10, \
                 'pCapTxMedianFutMeanWarming50':pCapTxMedianFutCurGMT50, \
                 'pCapTxMedianFutMeanWarming90':pCapTxMedianFutCurGMT90, \
                 'pCapTxxFutMeanWarming10':pCapTxxFutCurGMT10, \
                 'pCapTxxFutMeanWarming50':pCapTxxFutCurGMT50, \
                 'pCapTxxFutMeanWarming90':pCapTxxFutCurGMT90}
        with open('E:/data/ecoffel/data/projects/electricity/script-data/pc-change-fut-%s-%s-%s-gmt%d.dat'%(plantData, runoffData, qstr, w), 'wb') as f:
            pickle.dump(pcChg, f)
    
#    pCapTxxFutMeanWarming10.append(pCapTxxFutCurGMT10)
#    pCapTxxFutMeanWarming50.append(pCapTxxFutCurGMT50)
#    pCapTxxFutMeanWarming90.append(pCapTxxFutCurGMT90)
#    
#    pCapTxMedianFutMeanWarming10.append(pCapTxMedianFutCurGMT10)
#    pCapTxMedianFutMeanWarming50.append(pCapTxMedianFutCurGMT50)
#    pCapTxMedianFutMeanWarming90.append(pCapTxMedianFutCurGMT90)
sys.exit()

pCapTxxFutMeanWarming10 = np.array(pCapTxxFutMeanWarming10)
pCapTxxFutMeanWarming50 = np.array(pCapTxxFutMeanWarming50)
pCapTxxFutMeanWarming90 = np.array(pCapTxxFutMeanWarming90)

pCapTxMedianFutMeanWarming10 = np.array(pCapTxMedianFutMeanWarming10)
pCapTxMedianFutMeanWarming50 = np.array(pCapTxMedianFutMeanWarming50)
pCapTxMedianFutMeanWarming90 = np.array(pCapTxMedianFutMeanWarming90)



sys.exit()

xd = np.array(list(range(1981, 2018+1)))-1981+1

z = np.polyfit(xd, pcTxx10, 1)
histPolyTxx10 = np.poly1d(z)
z = np.polyfit(xd, pcTxx50, 1)
histPolyTxx50 = np.poly1d(z)
z = np.polyfit(xd, pcTxx90, 1)
histPolyTxx90 = np.poly1d(z)

xpos = np.array([65, 90, 115, 140])

plt.figure(figsize=(6,4))
plt.xlim([0, 155])
plt.ylim([91, 99])
plt.grid(True)

plt.plot(xd, histPolyTxx10(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8, label='90th Percentile')
plt.plot(xd, histPolyTxx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8, label='50th Percentile')
plt.plot(xd, histPolyTxx90(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8, label='10th Percentile')

plt.plot(xpos-5, \
         np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1), \
          'o', markersize=5, color=cmx.tab20(6))

plt.errorbar(xpos-5, \
             np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1), \
             yerr = [np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1)-np.nanmin(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1), \
                     np.nanmax(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1)-np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1)], \
             ecolor = cmx.tab20(6), elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos, \
         np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1), \
          'o', markersize=5, color='black')

plt.errorbar(xpos, \
             np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1), \
             yerr = [np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1)-np.nanmin(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1), \
                     np.nanmax(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1)-np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1)], \
             ecolor = 'black', elinewidth = 1, capsize = 3, fmt = 'none')


plt.plot(xpos+5, \
         np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1), \
          'o', markersize=5, color=cmx.tab20(0))

plt.errorbar(xpos+5, \
             np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1), \
             yerr = [np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1)-np.nanmin(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1), \
                     np.nanmax(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1)-np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1)], \
             ecolor = cmx.tab20(0), elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot([38,38], [88,100], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, xpos[0], xpos[1], xpos[2], xpos[3]])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

plt.yticks(range(91, 100, 2))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)


plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('pp-chg-hist-mean-warming.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

sys.exit()








plt.figure(figsize=(1,4))
plt.grid(True)

ychg = [np.nanmean(np.squeeze(pCapTxx50[0,:,32:]-pCapTxx50[0,:,0:5]), axis=1)]

medianprops = dict(linestyle='-', linewidth=2, color='black')
meanpointprops = dict(marker='D', markeredgecolor='black',
                      markerfacecolor='red', markersize=5)
bplot = plt.boxplot(ychg, showmeans=True, sym='.', patch_artist=True, \
                    medianprops=medianprops, meanprops=meanpointprops, zorder=0)

colors = ['lightgray']
for patch in bplot['boxes']:
    patch.set_facecolor([.75, .75, .75])

plt.plot([0,2], [0,0], '--', color='black')

plt.gca().set_xticks([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.ylabel('Plant capacity change (% pts)', fontname = 'Helvetica', fontsize=16)



if plotFigs:
    plt.savefig('hist-pp-chg-boxplot.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)




