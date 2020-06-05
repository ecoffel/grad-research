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

# if we are running as job on discovery, send print output to a file
outputToFile = True

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

#gldas or grdc
runoffModel = 'grdc'
plantData = 'useu'

modelPower = 'pow2-noInteraction'

# '-anom-best-dist' or ''
qsdist = '-anom-best-dist'

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
    # these are mislabeled in dict for now (90 is 10, 10 is 90)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]
    plantIds = pPolyData['plantIds']
    plantYears = pPolyData['plantYears']
    plantCooling = pPolyData['plantCooling']
    plantFuel = pPolyData['plantFuel']
    plantAge = pPolyData['plantAge']

histFileName10 = '%s/pc-future-%s/%s-pc-hist-hourly-%s-10.dat'%(dataDirDiscovery, runoffModel, plantData, modelPower)
histFileName50 = '%s/pc-future-%s/%s-pc-hist-hourly-%s-50.dat'%(dataDirDiscovery, runoffModel, plantData, modelPower)
histFileName90 = '%s/pc-future-%s/%s-pc-hist-hourly-%s-90.dat'%(dataDirDiscovery, runoffModel, plantData, modelPower)

if not os.path.isfile(histFileName10):
    
    # load historical temp data
    if outputToFile:
        print('loading historical tx data', file=open('el_build_agg_data_output.txt', 'a'))
    else:
        print('loading historical tx data')
    
    plantTxData = np.genfromtxt('%s/script-data/%s-pp-tx.csv'%(dataDirDiscovery, plantData), delimiter=',', skip_header=0)
    plantYearData = plantTxData[0,:]
    plantMonthData = plantTxData[1,:]
    plantDayData = plantTxData[2,:]
    plantTxData = plantTxData[3:,:]
    
    plantTnData = np.genfromtxt('%s/script-data/%s-pp-tn.csv'%(dataDirDiscovery, plantData), delimiter=',', skip_header=0)
    plantTnData = plantTnData[3:,:]
    
    # load historical runoff data and make dist-fitted anomalies if necessary
    if outputToFile:
        print('loading historical runoff data', file=open('el_build_agg_data_output.txt', 'a'))
    else:
        print('loading historical runoff data')
    
    plantQsData = np.genfromtxt('%s/script-data/%s-pp-runoff-anom-gldas-1981-2005.csv'%(dataDirDiscovery, plantData), delimiter=',', skip_header=0)
    plantQsData = plantQsData[3:,:]
        
    plantQsData[plantQsData < -5] = np.nan
    plantQsData[plantQsData > 5] = np.nan
    
    # generate historical global daily outage data    
    syswidePCHist10 = np.full([plantTxData.shape[0], len(range(1981, 2005+1)), len(range(1,13)), 31, 24], np.nan)
    syswidePCHist50 = np.full([plantTxData.shape[0], len(range(1981, 2005+1)), len(range(1,13)), 31, 24], np.nan)
    syswidePCHist90 = np.full([plantTxData.shape[0], len(range(1981, 2005+1)), len(range(1,13)), 31, 24], np.nan)
    
    dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), 'QS2T2':[(baseTx**2)*(baseQs**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears, 'PlantCooling':plantCooling, 'PlantFuel':plantFuel, 'PlantAge':plantAge})
    
    basePred10 = np.nanmean(pcModel10.predict(dfpred))
    basePred50 = np.nanmean(pcModel50.predict(dfpred))
    basePred90 = np.nanmean(pcModel90.predict(dfpred))
    
    if outputToFile:
        print('computing historical systemwide PC...', file=open('el_build_agg_data_output.txt', 'a'))
    else:
        print('computing historical systemwide PC...')
    
    # loop over all global plants
    for p in range(0, plantTxData.shape[0]):
        
        if p%100==0:
            if outputToFile:
                print('processing historical plant %d of %d...'%(p, plantTxData.shape[0]), file=open('el_build_agg_data_output.txt', 'a'))
            else:
                print('processing historical plant %d of %d...'%(p, plantTxData.shape[0]))
        
        selPlantIds = np.random.choice(len(plantIds), 1)
        
        tx = plantTxData[p,:]
        tn = plantTnData[p,:]
        qs = plantQsData[p,:]

        txHourly = np.full([tx.shape[0], 24], np.nan)
        qsHourly = np.full([qs.shape[0], 24], np.nan)

        for d in range(1, tx.shape[0]):
            qsHourly[d, :] = [qs[d]]*24
            # set daily min
            txHourly[d, 0] = tn[d]

            # set daily max
            txHourly[d, 12] = tx[d]

            # interpolate 1st half of day
            txHourly[d, 1:12] = np.linspace(txHourly[d, 0], txHourly[d, 12], 11)

            if d < txHourly.shape[0]-1:
                # interpolate down to next day's min
                txHourly[d, 13:24] = np.linspace(txHourly[d, 12], tn[d+1], 11)
            else:
                # if today is the final day, go back down to today's min
                txHourly[d, 13:24] = np.linspace(txHourly[d, 12], tn[d], 11)

        txHourly = np.reshape(txHourly, [txHourly.size])
        qsHourly = np.reshape(qsHourly, [qsHourly.size])
        
        indTxAboveBase = np.where((txHourly > baseTx))[0]
        indPlantIds = np.random.choice(len(plantIds), len(indTxAboveBase))

        pcPred10 = np.full([len(txHourly)], basePred10)
        pcPred50 = np.full([len(txHourly)], basePred50)
        pcPred90 = np.full([len(txHourly)], basePred90)

        dfpred = pd.DataFrame({'T1':txHourly[indTxAboveBase], 'T2':txHourly[indTxAboveBase]**2, \
                                         'QS1':qsHourly[indTxAboveBase], 'QS2':qsHourly[indTxAboveBase]**2, \
                                         'QST':txHourly[indTxAboveBase]*qsHourly[indTxAboveBase], \
                                         'QS2T2':(txHourly[indTxAboveBase]**2)*(qsHourly[indTxAboveBase]**2), \
                                         'PlantIds':plantIds[indPlantIds], \
                                         'PlantYears':plantYears[indPlantIds], 'PlantCooling':plantCooling[indPlantIds], \
                                         'PlantFuel':plantFuel[indPlantIds], 'PlantAge':plantAge[indPlantIds]})

        pcPred10[indTxAboveBase] = pcModel10.predict(dfpred)
        pcPred50[indTxAboveBase] = pcModel50.predict(dfpred)
        pcPred90[indTxAboveBase] = pcModel90.predict(dfpred)

        pcPred10[pcPred10 > 100] = basePred10
        pcPred50[pcPred50 > 100] = basePred50
        pcPred90[pcPred90 > 100] = basePred90

        pcPred10 = np.reshape(pcPred10, [tx.shape[0], 24])
        pcPred50 = np.reshape(pcPred50, [tx.shape[0], 24])
        pcPred90 = np.reshape(pcPred90, [tx.shape[0], 24])
        
        for yearInd, year in enumerate(range(1981, 2005+1)):
            
            for monthInd, month in enumerate(range(1,13)):
            
                ind = np.where((plantYearData == year) & \
                               (plantMonthData == month))[0]
                
                syswidePCHist10[p, yearInd, monthInd, 0:len(ind), :] = pcPred10[ind, :]
                syswidePCHist50[p, yearInd, monthInd, 0:len(ind), :] = pcPred50[ind, :]
                syswidePCHist90[p, yearInd, monthInd, 0:len(ind), :] = pcPred90[ind, :]

    globalPC10 = {'globalPCHist10':syswidePCHist10}
    globalPC50 = {'globalPCHist50':syswidePCHist50}
    globalPC90 = {'globalPCHist90':syswidePCHist90}
    
    if outputToFile:
        print('writing files...', file=open('el_build_agg_data_output.txt', 'a'))
    else:
        print('writing files...')
    
    with open(histFileName10, 'wb') as f:
        pickle.dump(globalPC10, f, protocol=4)
    with open(histFileName50, 'wb') as f:
        pickle.dump(globalPC50, f, protocol=4)
    with open(histFileName90, 'wb') as f:
        pickle.dump(globalPC90, f, protocol=4)

        
# load future mean warming data and recompute PC
if outputToFile:
    print('computing future systemwide PC...', file=open('el_build_agg_data_output.txt', 'a'))
else:
    print('computing future systemwide PC...')
for w in range(1, 4+1):
        
    for m in range(len(models)):
        
        fileName = '%s/pc-future-%s/%s-pc-future%s-%ddeg-%s-%s-preIndRef.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName10 = '%s/pc-future-%s/%s-pc-future%s-10-%ddeg-%s-%s-preIndRef.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName50 = '%s/pc-future-%s/%s-pc-future%s-50-%ddeg-%s-%s-preIndRef.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName90 = '%s/pc-future-%s/%s-pc-future%s-90-%ddeg-%s-%s-preIndRef.dat'%(dataDirDiscovery, runoffModel, plantData, qsdist, w, modelPower, models[m])
        
        if os.path.isfile(fileName10) and os.path.isfile(fileName50) and os.path.isfile(fileName90):
            continue
        
        if outputToFile:
            print('processing %s/+%dC'%(models[m], w), file=open('el_build_agg_data_output.txt', 'a'))
        else:
            print('processing %s/+%dC'%(models[m], w))
        
        syswidePCFutCurModel10 = []
        syswidePCFutCurModel50 = []
        syswidePCFutCurModel90 = []
        
        # load data for current model and warming level
        fileNameTx = '%s/gmt-anomaly-temps/%s-pp-%ddeg-tx-cmip5-%s-preIndRef.csv'%(dataDirDiscovery, plantData, w, models[m])
        fileNameTn = '%s/gmt-anomaly-temps/%s-pp-%ddeg-tn-cmip5-%s-preIndRef.csv'%(dataDirDiscovery, plantData, w, models[m])
    
        if not os.path.isfile(fileNameTx) or not os.path.isfile(fileNameTn):
            if outputToFile:
                print("temp data doesn't exist: %s"%fileNameTx, file=open('el_build_agg_data_output.txt', 'a'))
            else:
                print("temp data doesn't exist: %s"%fileNameTx)
            continue
    
        plantTxData = np.genfromtxt(fileNameTx, delimiter=',', skip_header=0)
        plantTnData = np.genfromtxt(fileNameTn, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0 or len(plantTnData) == 0:
            if outputToFile:
                print("temp file empty: %s"%fileNameTx, file=open('el_build_agg_data_output.txt', 'a'))
            else:
                print("temp file empty: %s"%fileNameTx)
            continue
        
        plantTxYearData = plantTxData[0,0:].copy()
        plantTxMonthData = plantTxData[1,0:].copy()
        plantTxDayData = plantTxData[2,0:].copy()
        plantTxData = plantTxData[3:,0:].copy()
        
        plantTnData = plantTnData[3:,0:].copy()
        
        fileNameRunoff = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-anom-best-dist-cmip5-%s-preIndRef.csv'%(dataDirDiscovery, plantData, w, models[m])

        if not os.path.isfile(fileNameRunoff):
            if outputToFile:
                print("runoff file doesn't exist: %s"%fileNameRunoff, file=open('el_build_agg_data_output.txt', 'a'))
            else:
                print("runoff file doesn't exist: %s"%fileNameRunoff)
            continue
        
        plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
        plantQsData = plantQsData[3:,:]
        
        if len(plantQsData) == 0:
            if outputToFile:
                print("runoff file empty: %s"%fileNameRunoff, file=open('el_build_agg_data_output.txt', 'a'))
            else:
                print("runoff file empty: %s"%fileNameRunoff)
            continue
            
        plantQsData[plantQsData < -5] = np.nan
        plantQsData[plantQsData > 5] = np.nan
        
        if outputToFile:
            print('calculating PC for %s/+%dC'%(models[m], w), file=open('el_build_agg_data_output.txt', 'a'))
        else:
            print('calculating PC for %s/+%dC'%(models[m], w))
        
        dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), 'QS2T2':[(baseTx**2)*(baseQs**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears, 'PlantCooling':plantCooling, 'PlantFuel':plantFuel, 'PlantAge':plantAge})
    
        basePred10 = np.nanmean(pcModel10.predict(dfpred))
        basePred50 = np.nanmean(pcModel50.predict(dfpred))
        basePred90 = np.nanmean(pcModel90.predict(dfpred))
        
        syswidePCFutCurModel10 = np.full([plantTxData.shape[0], len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), \
                                           len(range(1,13)), 31, 24], np.nan)
        syswidePCFutCurModel50 = np.full([plantTxData.shape[0], len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), \
                                           len(range(1,13)), 31, 24], np.nan)
        syswidePCFutCurModel90 = np.full([plantTxData.shape[0], len(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)), \
                                           len(range(1,13)), 31, 24], np.nan)
        
        
        # loop over all plants
        for p in range(plantTxData.shape[0]):
            
            if p % 500 == 0:
                if outputToFile:
                    print('processing future plant %d out of %d'%(p, plantTxData.shape[0]), file=open('el_build_agg_data_output.txt', 'a'))
                else:
                    print('processing future plant %d out of %d'%(p, plantTxData.shape[0]))
            
            selPlantIds = np.random.choice(len(plantIds), 1)
        
            tx = plantTxData[p,:]
            tn = plantTnData[p,:]
            qs = plantQsData[p,:]

            txHourly = np.full([tx.shape[0], 24], np.nan)
            qsHourly = np.full([qs.shape[0], 24], np.nan)

            for d in range(1, tx.shape[0]):
                qsHourly[d, :] = [qs[d]]*24
                # set daily min
                txHourly[d, 0] = tn[d]

                # set daily max
                txHourly[d, 12] = tx[d]

                # interpolate 1st half of day
                txHourly[d, 1:12] = np.linspace(txHourly[d, 0], txHourly[d, 12], 11)

                if d < txHourly.shape[0]-1:
                    # interpolate down to next day's min
                    txHourly[d, 13:24] = np.linspace(txHourly[d, 12], tn[d+1], 11)
                else:
                    # if today is the final day, go back down to today's min
                    txHourly[d, 13:24] = np.linspace(txHourly[d, 12], tn[d], 11)

            txHourly = np.reshape(txHourly, [txHourly.size])
            qsHourly = np.reshape(qsHourly, [qsHourly.size])


            indTxAboveBase = np.where((txHourly > baseTx))[0]
            indPlantIds = np.random.choice(len(plantIds), len(indTxAboveBase))

            pcPred10 = np.full([len(txHourly)], basePred10)
            pcPred50 = np.full([len(txHourly)], basePred50)
            pcPred90 = np.full([len(txHourly)], basePred90)

            dfpred = pd.DataFrame({'T1':txHourly[indTxAboveBase], 'T2':txHourly[indTxAboveBase]**2, \
                                             'QS1':qsHourly[indTxAboveBase], 'QS2':qsHourly[indTxAboveBase]**2, \
                                             'QST':txHourly[indTxAboveBase]*qsHourly[indTxAboveBase], \
                                             'QS2T2':(txHourly[indTxAboveBase]**2)*(qsHourly[indTxAboveBase]**2), \
                                             'PlantIds':plantIds[indPlantIds], \
                                             'PlantYears':plantYears[indPlantIds], 'PlantCooling':plantCooling[indPlantIds], \
                                             'PlantFuel':plantFuel[indPlantIds], 'PlantAge':plantAge[indPlantIds]})

            pcPred10[indTxAboveBase] = pcModel10.predict(dfpred)
            pcPred50[indTxAboveBase] = pcModel50.predict(dfpred)
            pcPred90[indTxAboveBase] = pcModel90.predict(dfpred)

            pcPred10[pcPred10 > 100] = basePred10
            pcPred50[pcPred50 > 100] = basePred50
            pcPred90[pcPred90 > 100] = basePred90
            
            pcPred10 = np.reshape(pcPred10, [tx.shape[0], 24])
            pcPred50 = np.reshape(pcPred50, [tx.shape[0], 24])
            pcPred90 = np.reshape(pcPred90, [tx.shape[0], 24])

            for yearInd, year in enumerate(range(int(min(plantTxYearData)), int(max(plantTxYearData))+1)):

                for monthInd, month in enumerate(range(1,13)):

                    ind = np.where((plantTxYearData == year) & \
                                   (plantTxMonthData == month))[0]

                    syswidePCFutCurModel10[p, yearInd, monthInd, 0:len(ind), :] = pcPred10[ind, :]
                    syswidePCFutCurModel50[p, yearInd, monthInd, 0:len(ind), :] = pcPred50[ind, :]
                    syswidePCFutCurModel90[p, yearInd, monthInd, 0:len(ind), :] = pcPred90[ind, :]

        globalPC10 = {'globalPCFut10':syswidePCFutCurModel10}
        globalPC50 = {'globalPCFut50':syswidePCFutCurModel50}
        globalPC90 = {'globalPCFut90':syswidePCFutCurModel90}

        if outputToFile:
            print('writing files...', file=open('el_build_agg_data_output.txt', 'a'))
        else:
            print('writing files...')
        with open(fileName10, 'wb') as f:
            pickle.dump(globalPC10, f, protocol=4)
        with open(fileName50, 'wb') as f:
            pickle.dump(globalPC50, f, protocol=4)
        with open(fileName90, 'wb') as f:
            pickle.dump(globalPC90, f, protocol=4)
        