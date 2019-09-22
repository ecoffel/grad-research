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
import statsmodels.api as sm
import scipy.stats as st
import el_load_global_plants
import el_find_best_runoff_dist
import gzip, pickle
import sys,os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'


models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

#gldas or grdc
runoffModel = 'grdc'
plantData = 'useu'

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
with gzip.open('E:/data/ecoffel/data/projects/electricity/script-data/pPolyData-%s-%s.dat'%(runoffModel, modelPower), 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]


histFileName10 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-10.dat'%(runoffModel, plantData, qsdist, modelPower)
histFileName50 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-50.dat'%(runoffModel, plantData, qsdist, modelPower)
histFileName90 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-90.dat'%(runoffModel, plantData, qsdist, modelPower)


if not os.path.isfile(histFileName10):
    
    # load historical temp data
    plantTxData = np.genfromtxt('E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-tx.csv'%plantData, delimiter=',', skip_header=0)
    plantYearData = plantTxData[0,:]
    plantMonthData = plantTxData[1,:]
    plantDayData = plantTxData[2,:]
    plantTxData = plantTxData[3:,:]
    
    # load historical runoff data and make dist-fitted anomalies if necessary
    if os.path.isfile('E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff%s-anom.csv'%(plantData, qsdist)):
        plantQsData = np.genfromtxt('E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff%s-anom.csv'%(plantData, qsdist), delimiter=',', skip_header=0)
    else:
        plantQsData = np.genfromtxt('E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff.csv'%plantData, delimiter=',', skip_header=0)
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
        np.savetxt('E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff%s-anom.csv'%(plantData, qsdist), plantQsData, delimiter=',')

    plantQsData[plantQsData < -4] = np.nan
    plantQsData[plantQsData > 4] = np.nan
    
    # generate historical global daily outage data    
    syswidePCHist10 = []
    syswidePCHist50 = []
    syswidePCHist90 = []
    
    basePred10 = pcModel10.predict([1, baseTx, baseTx**2, \
                                  baseQs, baseQs**2, \
                                  baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                  0])[0]
    basePred50 = pcModel50.predict([1, baseTx, baseTx**2, \
                                  baseQs, baseQs**2, \
                                  baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                  0])[0]
    basePred90 = pcModel90.predict([1, baseTx, baseTx**2, \
                                  baseQs, baseQs**2, \
                                  baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                  0])[0]
    
    print('computing historical systemwide PC...')
    # loop over all global plants
    for p in range(0, plantTxData.shape[0]):
        
        if p%500 == 0:
            print('processing historical plant %d...'%p)
        
        syswidePCHistCurPlant10 = []
        syswidePCHistCurPlant50 = []
        syswidePCHistCurPlant90 = []
        
        for year in range(1981, 2005+1):
            
            syswidePCHistCurYear10 = []
            syswidePCHistCurYear50 = []
            syswidePCHistCurYear90 = []
            
            for month in range(1,13):
            
                syswidePCHistCurMonth10 = []
                syswidePCHistCurMonth50 = []
                syswidePCHistCurMonth90 = []
                
                ind = np.where((plantYearData == year) & \
                               (plantMonthData == month))[0]
                
                # loop over all days in current year
                for day in range(len(ind)):
                    tx = plantTxData[p,ind[day]]
                    qs = plantQsData[p,ind[day]]
                    
                    if tx >= 20:
                        
                        # predict plant capacity for current historical day
                        pcPred10 = pcModel10.predict([1, tx, tx**2, \
                                                      qs, qs**2, \
                                                      tx*qs, (tx**2)*(qs**2), \
                                                      0])[0]
                        pcPred50 = pcModel50.predict([1, tx, tx**2, \
                                                      qs, qs**2, \
                                                      tx*qs, (tx**2)*(qs**2), \
                                                      0])[0]
                        pcPred90 = pcModel90.predict([1, tx, tx**2, \
                                                      qs, qs**2, \
                                                      tx*qs, (tx**2)*(qs**2), \
                                                      0])[0]
                    else:
                        pcPred10 = basePred10
                        pcPred50 = basePred50
                        pcPred90 = basePred90
                    
                    
                    if pcPred10 > 100: pcPred10 = basePred10
                    if pcPred50 > 100: pcPred50 = basePred50
                    if pcPred90 > 100: pcPred90 = basePred90
        
                    syswidePCHistCurMonth10.append(pcPred10)
                    syswidePCHistCurMonth50.append(pcPred50)
                    syswidePCHistCurMonth90.append(pcPred90)
                
                syswidePCHistCurYear10.append(syswidePCHistCurMonth10)
                syswidePCHistCurYear50.append(syswidePCHistCurMonth50)
                syswidePCHistCurYear90.append(syswidePCHistCurMonth90)
            
            syswidePCHistCurPlant10.append(syswidePCHistCurYear10)
            syswidePCHistCurPlant50.append(syswidePCHistCurYear50)
            syswidePCHistCurPlant90.append(syswidePCHistCurYear90)
        
        syswidePCHist10.append(syswidePCHistCurPlant10)
        syswidePCHist50.append(syswidePCHistCurPlant50)
        syswidePCHist90.append(syswidePCHistCurPlant90)
    
    syswidePCHist10 = np.array(syswidePCHist10)
    syswidePCHist50 = np.array(syswidePCHist50)
    syswidePCHist90 = np.array(syswidePCHist90)
    
    globalPC10 = {'globalPCHist10':np.array(syswidePCHist10)}
    globalPC50 = {'globalPCHist50':np.array(syswidePCHist50)}
    globalPC90 = {'globalPCHist90':np.array(syswidePCHist90)}
    
    print('writing gzip files...')
    
    with open(histFileName10, 'wb') as f:
        pickle.dump(globalPC10, f, protocol=4)
    with open(histFileName50, 'wb') as f:
        pickle.dump(globalPC50, f, protocol=4)
    with open(histFileName90, 'wb') as f:
        pickle.dump(globalPC90, f, protocol=4)

sys.exit()

# load future mean warming data and recompute PC
print('computing future systemwide PC...')
for w in range(1, 4+1):
        
    for m in range(len(models)):
        
        fileName = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-%ddeg-%s-%s.dat'%(runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName10 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-10-%ddeg-%s-%s.dat'%(runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName50 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-50-%ddeg-%s-%s.dat'%(runoffModel, plantData, qsdist, w, modelPower, models[m])
        fileName90 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-90-%ddeg-%s-%s.dat'%(runoffModel, plantData, qsdist, w, modelPower, models[m])
        
        if os.path.isfile(fileName10) or os.path.isfile(fileName):
            continue
        
        print('processing %s/+%dC'%(models[m], w))
        
        syswidePCFutCurModel10 = []
        syswidePCFutCurModel50 = []
        syswidePCFutCurModel90 = []
        
        # load data for current model and warming level
        fileNameTemp = 'E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/%s-pp-%ddeg-tx-cmip5-%s.csv'%(plantData, w, models[m])
    
        if not os.path.isfile(fileNameTemp):
            continue
    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0:
            continue
        
        plantTxYearData = plantTxData[0,0:].copy()
        plantTxMonthData = plantTxData[1,0:].copy()
        plantTxDayData = plantTxData[2,0:].copy()
        plantTxData = plantTxData[3:,0:].copy()
        
        
        fileNameRunoff = 'E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/%s-pp-%ddeg-runoff-raw-cmip5-%s.csv'%(plantData, w, models[m])
        fileNameRunoffDistfit = 'E:/data/ecoffel/data/projects/electricity/gmt-anomaly-temps/%s-pp-%ddeg-runoff%s-cmip5-%s.csv'%(plantData, w, qsdist, models[m])
        
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
        
        basePred10 = pcModel10.predict([1, baseTx, baseTx**2, \
                                      baseQs, baseQs**2, \
                                      baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                      0])[0]
        basePred50 = pcModel50.predict([1, baseTx, baseTx**2, \
                                      baseQs, baseQs**2, \
                                      baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                      0])[0]
        basePred90 = pcModel90.predict([1, baseTx, baseTx**2, \
                                      baseQs, baseQs**2, \
                                      baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                      0])[0]
        
        # loop over all plants
        for p in range(plantTxData.shape[0]):
            
            syswidePCFutCurPlant10 = []
            syswidePCFutCurPlant50 = []
            syswidePCFutCurPlant90 = []
            
            # loop over all years for current model/GMT anomaly
            for year in range(int(min(plantTxYearData)), int(max(plantTxYearData))+1):
        
                syswidePCFutCurYear10 = []
                syswidePCFutCurYear50 = []
                syswidePCFutCurYear90 = []
                
                # tx for current year's summer
                for month in range(1,13):
                    
                    syswidePCFutCurMonth10 = []
                    syswidePCFutCurMonth50 = []
                    syswidePCFutCurMonth90 = []
                
                    ind = np.where((plantTxYearData == year) & \
                                   (plantTxMonthData == month))[0]
                
                    if len(ind) == 0:
                        for day in range(62):    
                            syswidePCFutCurMonth10.append(np.nan)
                            syswidePCFutCurMonth50.append(np.nan)
                            syswidePCFutCurMonth90.append(np.nan)
                    else:
                        for day in range(len(ind)):
                            curTx = plantTxData[p, ind[day]]
                            curQs = plantQsData[p, ind[day]]
                        
                            if curTx >= 20:                                
                                # predict plant capacity for current historical day
                                pcPred10 = pcModel10.predict([1, curTx, curTx**2, \
                                                              curQs, curQs**2, \
                                                              curTx*curQs, (curTx**2)*(curQs**2), \
                                                              0])[0]
                                pcPred50 = pcModel50.predict([1, curTx, curTx**2, \
                                                              curQs, curQs**2, \
                                                              curTx*curQs, (curTx**2)*(curQs**2), \
                                                              0])[0]
                                pcPred90 = pcModel90.predict([1, curTx, curTx**2, \
                                                              curQs, curQs**2, \
                                                              curTx*curQs, (curTx**2)*(curQs**2), \
                                                              0])[0]
                                
                            else:
                                pcPred10 = basePred10
                                pcPred50 = basePred50
                                pcPred90 = basePred90
                                
                            if pcPred10 > 100: pcPred10 = basePred10
                            if pcPred50 > 100: pcPred50 = basePred50
                            if pcPred90 > 100: pcPred90 = basePred90
                            
                            syswidePCFutCurMonth10.append(pcPred10)
                            syswidePCFutCurMonth50.append(pcPred50)
                            syswidePCFutCurMonth90.append(pcPred90)
                        
                    syswidePCFutCurYear10.append(syswidePCFutCurMonth10)
                    syswidePCFutCurYear50.append(syswidePCFutCurMonth50)
                    syswidePCFutCurYear90.append(syswidePCFutCurMonth90)
                        
                syswidePCFutCurPlant10.append(syswidePCFutCurYear10)
                syswidePCFutCurPlant50.append(syswidePCFutCurYear50)
                syswidePCFutCurPlant90.append(syswidePCFutCurYear90)
                
            syswidePCFutCurModel10.append(syswidePCFutCurPlant10)
            syswidePCFutCurModel50.append(syswidePCFutCurPlant50)
            syswidePCFutCurModel90.append(syswidePCFutCurPlant90)

        globalPC10 = {'globalPCFut10':np.array(syswidePCFutCurModel10)}
        globalPC50 = {'globalPCFut50':np.array(syswidePCFutCurModel50)}
        globalPC90 = {'globalPCFut90':np.array(syswidePCFutCurModel90)}

        with open(fileName10, 'wb') as f:
            pickle.dump(globalPC10, f, protocol=4)
        with open(fileName50, 'wb') as f:
            pickle.dump(globalPC50, f, protocol=4)
        with open(fileName90, 'wb') as f:
            pickle.dump(globalPC90, f, protocol=4)
        
        