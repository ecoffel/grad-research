# -*- coding: utf-8 -*-
"""
Created on Fri Jun 21 18:41:34 2019

@author: Ethan
"""


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
from scipy import stats
import pandas as pd
import statsmodels.api as sm
import scipy.stats as st
import el_load_global_plants
import gzip, pickle
import sys,os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'


models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

#gldas or grdc
runoffModel = 'grdc'
plantData = 'world'

modelPower = 'pow2'

# '-qdistfit' or ''
qsdist = '-qdistfit-gamma'

if plantData == 'world':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=True)
elif plantData == 'useu':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=False)

baseTx = 27
baseQs = 0


pcModel10 = []
pcModel50 = []
pcModel90 = []
plantIds = []
plantYears = []
with gzip.open('%s/script-data/pPolyData-%s-%s.dat'%(dataDirDiscovery, runoffModel, modelPower), 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]
    plantIds = pPolyData['plantIds']
    plantYears = pPolyData['plantYears']

histFileName10 = '%s/pc-future-%s/%s-pc-hist%s-%s-10.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, modelPower)
histFileName50 = '%s/pc-future-%s/%s-pc-hist%s-%s-50.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, modelPower)
histFileName90 = '%s/pc-future-%s/%s-pc-hist%s-%s-90.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, modelPower)


if not os.path.isfile(histFileName10):
    
    # load historical temp data
    print('loading historical temp data')
    plantTxData = np.genfromtxt('%s/script-data/%s-pp-tx.csv'%(dataDirDiscovery, plantData), delimiter=',', skip_header=0)
    plantYearData = plantTxData[0,:]
    plantMonthData = plantTxData[1,:]
    plantDayData = plantTxData[2,:]
    plantTxData = plantTxData[3:,:]
    
    # load historical runoff data and make dist-fitted anomalies if necessary
    print('loading historical runoff data')
    if os.path.isfile('%s/script-data/%s-pp-runoff%s-anom.csv'%(dataDirDiscovery, plantData, qsdist)):
        plantQsData = np.genfromtxt('%s/script-data/%s-pp-runoff%s-anom.csv'%(dataDirDiscovery, plantData, qsdist), delimiter=',', skip_header=0)
    else:
        plantQsData = np.genfromtxt('%s/script-data/%s-pp-runoff.csv'%(dataDirDiscovery, plantData), delimiter=',', skip_header=0)
        plantQsData = plantQsData[3:,:]
        
        print('calculating historical qs distfit anomalies')
        plantQsAnomData = []
        
        for p in range(plantQsData.shape[0]):
            if p%500 == 0:
                print('calculating qs anom for plant %d...'%p)
            q = plantQsData[p,:]
            nn = np.where(~np.isnan(q))[0]
            dist = st.gamma
            
            if len(nn) > 10:
                args = dist.fit(q[nn])
                curQsStd = dist.std(*args)
            else:
                curQsStd = np.nan
            plantQsAnomData.append((q-np.nanmean(q))/curQsStd)
        
        plantQsData = np.array(plantQsAnomData)
        plantQsData[plantQsData < -4] = np.nan
        plantQsData[plantQsData > 4] = np.nan
        np.savetxt('%s/%s-pp-runoff%s-anom.csv'%(dataDirDiscovery, plantData, qsdist), plantQsData, delimiter=',')

    plantQsData[plantQsData < -4] = np.nan
    plantQsData[plantQsData > 4] = np.nan
    
    # generate historical global daily outage data    
    syswidePCHist10 = np.zeros([plantTxData.shape[0], len(range(1981, 2005+1)), len(range(1,13)), 31])
    syswidePCHist50 = np.zeros([plantTxData.shape[0], len(range(1981, 2005+1)), len(range(1,13)), 31])
    syswidePCHist90 = np.zeros([plantTxData.shape[0], len(range(1981, 2005+1)), len(range(1,13)), 31])
    
    syswidePCHist10[syswidePCHist10 == 0] = np.nan
    syswidePCHist50[syswidePCHist50 == 0] = np.nan
    syswidePCHist90[syswidePCHist90 == 0] = np.nan
    
    dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})
    
    basePred10 = np.nanmean(pcModel10.predict(dfpred))
    basePred50 = np.nanmean(pcModel50.predict(dfpred))
    basePred90 = np.nanmean(pcModel90.predict(dfpred))
    
    print('computing historical systemwide PC...')
    # loop over all global plants
    for p in range(0, plantTxData.shape[0]):
        
        if p%50==0:
            print('processing historical plant %d of %d...'%(p, plantTxData.shape[0]))
        
        selPlantIds = np.random.choice(len(plantIds), 1)
        
        tx = plantTxData[p,:]
        qs = plantQsData[p,:]

        indTxAboveBase = np.where((tx > baseTx))[0]
        indPlantIds = np.random.choice(len(plantIds), len(indTxAboveBase))

        pcPred10 = np.zeros([len(tx)])
        pcPred10[pcPred10 == 0] = basePred10
        pcPred50 = np.zeros([len(tx)])
        pcPred50[pcPred50 == 0] = basePred50
        pcPred90 = np.zeros([len(tx)])
        pcPred90[pcPred90 == 0] = basePred90

        dfpred = pd.DataFrame({'T1':tx[indTxAboveBase], 'T2':tx[indTxAboveBase]**2, \
                                         'QS1':qs[indTxAboveBase], 'QS2':qs[indTxAboveBase]**2, \
                                         'QST':tx[indTxAboveBase]*qs[indTxAboveBase], \
                                         'PlantIds':plantIds[indPlantIds], \
                                         'PlantYears':plantYears[indPlantIds]})

        pcPred10[indTxAboveBase] = pcModel10.predict(dfpred)
        pcPred50[indTxAboveBase] = pcModel50.predict(dfpred)
        pcPred90[indTxAboveBase] = pcModel90.predict(dfpred)

        pcPred10[pcPred10 > 100] = basePred10
        pcPred50[pcPred50 > 100] = basePred50
        pcPred90[pcPred90 > 100] = basePred90

        for yearInd, year in enumerate(range(1981, 2005+1)):
            
            for monthInd, month in enumerate(range(1,13)):
            
                ind = np.where((plantYearData == year) & \
                               (plantMonthData == month))[0]
                
                syswidePCHist10[p, yearInd, monthInd, 0:len(ind)] = pcPred10[ind]
                syswidePCHist50[p, yearInd, monthInd, 0:len(ind)] = pcPred50[ind]
                syswidePCHist90[p, yearInd, monthInd, 0:len(ind)] = pcPred90[ind]

    globalPC10 = {'globalPCHist10':syswidePCHist10}
    globalPC50 = {'globalPCHist50':syswidePCHist50}
    globalPC90 = {'globalPCHist90':syswidePCHist90}
    
    print('writing gzip files...')
    
    with open(histFileName10, 'wb') as f:
        pickle.dump(globalPC10, f, protocol=4)
    with open(histFileName50, 'wb') as f:
        pickle.dump(globalPC50, f, protocol=4)
    with open(histFileName90, 'wb') as f:
        pickle.dump(globalPC90, f, protocol=4)

        
        
# load future mean warming data and recompute PC
print('computing future systemwide PC...')
for w in range(1, 4+1):
        
    for m in range(len(models)):
        
        fileName = '%s/pc-future-%s/%s-pc-future%s-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName10 = '%s/pc-future-%s/%s-pc-future%s-10-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName50 = '%s/pc-future-%s/%s-pc-future%s-50-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName90 = '%s/pc-future-%s/%s-pc-future%s-90-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        
        if os.path.isfile(fileName10) and os.path.isfile(fileName50) and os.path.isfile(fileName90):
            continue
        
        print('processing %s/+%dC'%(models[m], w))
        
        syswidePCFutCurModel10 = []
        syswidePCFutCurModel50 = []
        syswidePCFutCurModel90 = []
        
        # load data for current model and warming level
        fileNameTemp = '%s/gmt-anomaly-temps/%s-pp-%ddeg-tx-cmip5-%s.csv'%(dataDirDiscovery, plantData, w, models[m])
    
        if not os.path.isfile(fileNameTemp):
            continue
    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0:
            continue
        
        plantTxYearData = plantTxData[0,0:].copy()
        plantTxMonthData = plantTxData[1,0:].copy()
        plantTxDayData = plantTxData[2,0:].copy()
        plantTxData = plantTxData[3:,0:].copy()
        
        
        fileNameRunoff = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-raw-cmip5-%s.csv'%(dataDirDiscovery, plantData, w, models[m])
        fileNameRunoffDistfit = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff%s-cmip5-%s.csv'%(dataDirDiscovery, plantData, w, qsdist, models[m])
        
        if os.path.isfile(fileNameRunoffDistfit):
            plantQsData = np.genfromtxt(fileNameRunoffDistfit, delimiter=',', skip_header=0)
        else:
            plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
            plantQsData = plantQsData[3:,:]
            
            print('calculating %s/+%dC qs distfit anomalies'%(models[m], w))
            plantQsAnomData = []
            dist = st.gamma
            for p in range(plantQsData.shape[0]):
                if p%500 == 0:
                    print('calculating qs anom for plant %d...'%p)
                q = plantQsData[p,:]
                nn = np.where(~np.isnan(q))[0]
                if len(nn) > 10:
                    args = dist.fit(q[nn])
                    curQsStd = dist.std(*args)
                else:
                    curQsStd = np.nan
                plantQsAnomData.append((q-np.nanmean(q))/curQsStd)
                
            plantQsData = np.array(plantQsAnomData)
            np.savetxt(fileNameRunoffDistfit, plantQsData, delimiter=',')
            
        plantQsData[plantQsData < -5] = np.nan
        plantQsData[plantQsData > 5] = np.nan
        
        print('calculating PC for %s/+%dC'%(models[m], w))
        
        dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})
    
        basePred10 = np.nanmean(pcModel10.predict(dfpred))
        basePred50 = np.nanmean(pcModel50.predict(dfpred))
        basePred90 = np.nanmean(pcModel90.predict(dfpred))
        
        syswidePCFutCurModel10 = np.zeros([plantTxData.shape[0], len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), \
                                           len(range(1,13)), 31])
        syswidePCFutCurModel50 = np.zeros([plantTxData.shape[0], len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), \
                                           len(range(1,13)), 31])
        syswidePCFutCurModel90 = np.zeros([plantTxData.shape[0], len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), \
                                           len(range(1,13)), 31])
        syswidePCFutCurModel10[syswidePCFutCurModel10 == 0] = np.nan
        syswidePCFutCurModel50[syswidePCFutCurModel50 == 0] = np.nan
        syswidePCFutCurModel90[syswidePCFutCurModel90 == 0] = np.nan
        
        
        # loop over all plants
        for p in range(plantTxData.shape[0]):
            
            if p % 500 == 0:
                print('processing future plant %d out of %d'%(p, plantTxData.shape[0]))
            
            selPlantIds = np.random.choice(len(plantIds), 1)
        
            tx = plantTxData[p,:]
            qs = plantQsData[p,:]

            indTxAboveBase = np.where((tx > baseTx))[0]
            indPlantIds = np.random.choice(len(plantIds), len(indTxAboveBase))

            pcPred10 = np.zeros([len(tx)])
            pcPred10[pcPred10 == 0] = basePred10
            pcPred50 = np.zeros([len(tx)])
            pcPred50[pcPred50 == 0] = basePred50
            pcPred90 = np.zeros([len(tx)])
            pcPred90[pcPred90 == 0] = basePred90

            dfpred = pd.DataFrame({'T1':tx[indTxAboveBase], 'T2':tx[indTxAboveBase]**2, \
                                             'QS1':qs[indTxAboveBase], 'QS2':qs[indTxAboveBase]**2, \
                                             'QST':tx[indTxAboveBase]*qs[indTxAboveBase], \
                                             'PlantIds':plantIds[indPlantIds], \
                                             'PlantYears':plantYears[indPlantIds]})

            pcPred10[indTxAboveBase] = pcModel10.predict(dfpred)
            pcPred50[indTxAboveBase] = pcModel50.predict(dfpred)
            pcPred90[indTxAboveBase] = pcModel90.predict(dfpred)

            pcPred10[pcPred10 > 100] = basePred10
            pcPred50[pcPred50 > 100] = basePred50
            pcPred90[pcPred90 > 100] = basePred90

            for yearInd, year in enumerate(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)):

                for monthInd, month in enumerate(range(1,13)):

                    ind = np.where((plantTxYearData == year) & \
                                   (plantTxMonthData == month))[0]

                    syswidePCFutCurModel10[p, yearInd, monthInd, 0:len(ind)] = pcPred10[ind]
                    syswidePCFutCurModel50[p, yearInd, monthInd, 0:len(ind)] = pcPred50[ind]
                    syswidePCFutCurModel90[p, yearInd, monthInd, 0:len(ind)] = pcPred90[ind]

        globalPC10 = {'globalPCFut10':syswidePCFutCurModel10}
        globalPC50 = {'globalPCFut50':syswidePCFutCurModel50}
        globalPC90 = {'globalPCFut90':syswidePCFutCurModel90}

        with open(fileName10, 'wb') as f:
            pickle.dump(globalPC10, f, protocol=4)
        with open(fileName50, 'wb') as f:
            pickle.dump(globalPC50, f, protocol=4)
        with open(fileName90, 'wb') as f:
            pickle.dump(globalPC90, f, protocol=4)
        