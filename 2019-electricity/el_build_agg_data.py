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
import el_load_global_plants
import gzip, pickle
import sys,os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False
regenAggOutages = False


models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


globalPlants = el_load_global_plants.loadGlobalPlants()

plantTxData = np.genfromtxt('global-pp-tx-all.csv', delimiter=',', skip_header=0)
plantYearData = plantTxData[0,:]
plantMonthData = plantTxData[1,:]
plantDayData = plantTxData[2,:]
plantTxData = plantTxData[3:,:]

pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]

# generate historical global daily outage data    
syswidePCHist10 = []
syswidePCHist50 = []
syswidePCHist90 = []

print('computing historical systemwide PC...')
# loop over all global plants
for p in range(0, plantTxData.shape[0]):
    
    syswidePCHistCurPlant10 = []
    syswidePCHistCurPlant50 = []
    syswidePCHistCurPlant90 = []
    
    normCap = globalPlants['caps'][p]
    
    for year in range(1981, 2018+1):
        
        syswidePCHistCurYear10 = []
        syswidePCHistCurYear50 = []
        syswidePCHistCurYear90 = []
        
        ind = np.where((plantYearData==year) & ((plantMonthData == 7) | (plantMonthData == 8)))[0]
        
        # loop over all days in current year
        for day in range(len(ind)):
            tx = plantTxData[p,ind[day]]
            qs = 0#plantTxData[p,ind[day]]
            
            # predict plant capacity for current historical day
            pcPred10 = pcModel10.predict([1, tx, tx**2, tx**3, \
                                          qs, qs**2, qs**3, qs**4, qs**5, \
                                          tx*qs,
                                          0])
            pcPred50 = pcModel10.predict([1, tx, tx**2, tx**3, \
                                          qs, qs**2, qs**3, qs**4, qs**5, \
                                          tx*qs,
                                          0])
            pcPred90 = pcModel10.predict([1, tx, tx**2, tx**3, \
                                          qs, qs**2, qs**3, qs**4, qs**5, \
                                          tx*qs,
                                          0])
            
            syswidePCHistCurYear10.append(pcPred10)
            syswidePCHistCurYear50.append(pcPred50)
            syswidePCHistCurYear90.append(pcPred90)
        
        syswidePCHistCurPlant10.append(syswidePCHistCurYear10)
        syswidePCHistCurPlant50.append(syswidePCHistCurYear50)
        syswidePCHistCurPlant90.append(syswidePCHistCurYear90)
    
    syswidePCHist10.append(syswidePCHistCurPlant10)
    syswidePCHist50.append(syswidePCHistCurPlant50)
    syswidePCHist90.append(syswidePCHistCurPlant90)

syswidePCHist10 = np.array(syswidePCHist10)
syswidePCHist50 = np.array(syswidePCHist50)
syswidePCHist90 = np.array(syswidePCHist90)

globalPC = {'globalPCHist10':np.array(syswidePCHist10), \
            'globalPCHist50':np.array(syswidePCHist50), \
            'globalPCHist90':np.array(syswidePCHist90)}

with gzip.open('global-pc-future/global-pc-hist.dat', 'wb') as f:
    pickle.dump(globalPC, f)

# load future mean warming data and recompute PC
syswidePCFut10 = []
syswidePCFut50 = []
syswidePCFut90 = []

print('computing future systemwide PC...')
for w in range(1, 4+1):
    syswidePCFutCurGMT10 = []
    syswidePCFutCurGMT50 = []
    syswidePCFutCurGMT90 = []
    
    for m in range(len(models)):
        
        fileName = 'global-pc-future/global-pc-future-%ddeg-%s.dat'%(w, models[m])
        
        if os.path.isfile(fileName):
            continue
        
        print('processing %s/+%dC'%(models[m], w))
        
        syswidePCFutCurModel10 = []
        syswidePCFutCurModel50 = []
        syswidePCFutCurModel90 = []
        
        # load data for current model and warming level
        fileNameTemp = 'gmt-anomaly-temps/global-pp-%ddeg-tx-cmip5-%s.csv'%(w, models[m])
    
        if not os.path.isfile(fileNameTemp):
            continue
    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0:
            continue
        
        plantTxYearData = plantTxData[0,0:].copy()
        plantTxMonthData = plantTxData[1,0:].copy()
        plantTxDayData = plantTxData[2,0:].copy()
        plantTxData = plantTxData[3:,0:].copy()
        
        fileNameRunoff = 'gmt-anomaly-temps/global-pp-%ddeg-runoff-cmip5-%s.csv'%(w, models[m])
        
        plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
        plantQsYearData = plantQsData[0,0:].copy()
        plantQsMonthData = plantQsData[1,0:].copy()
        plantQsDayData = plantQsData[2,0:].copy()
        plantQsData = plantQsData[3:,0:].copy()
        
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
                ind = np.where((plantTxYearData == year) & (plantTxMonthData >= 7) & (plantTxMonthData <= 8))[0]
                
                if len(ind) == 0:
                    for day in range(62):    
                        syswidePCFutCurYear10.append(np.nan)
                        syswidePCFutCurYear50.append(np.nan)
                        syswidePCFutCurYear90.append(np.nan)
                else:
                    for day in range(len(ind)):
                        curTx = plantTxData[p, ind[day]]
                        curQs = plantQsData[p, ind[day]]
                    
                        pcPred10 = pcModel10.predict([1, curTx, curTx**2, curTx**3, \
                                                                 curQs, curQs**2, curQs**3, curQs**4, curQs**5, curTx*curQs, 0])[0]
                        pcPred50 = pcModel50.predict([1, curTx, curTx**2, curTx**3, \
                                                                 curQs, curQs**2, curQs**3, curQs**4, curQs**5, curTx*curQs, 0])[0]
                        pcPred90 = pcModel90.predict([1, curTx, curTx**2, curTx**3, \
                                                                 curQs, curQs**2, curQs**3, curQs**4, curQs**5, curTx*curQs, 0])[0]
                        
                        if pcPred10 > 100: pcPred10 = 100
                        if pcPred50 > 100: pcPred50 = 100
                        if pcPred90 > 100: pcPred90 = 100
                         
                        syswidePCFutCurYear10.append(pcPred10)
                        syswidePCFutCurYear50.append(pcPred50)
                        syswidePCFutCurYear90.append(pcPred90)
                    
                syswidePCFutCurPlant10.append(syswidePCFutCurYear10)
                syswidePCFutCurPlant50.append(syswidePCFutCurYear50)
                syswidePCFutCurPlant90.append(syswidePCFutCurYear90)
                
            syswidePCFutCurModel10.append(syswidePCFutCurPlant10)
            syswidePCFutCurModel50.append(syswidePCFutCurPlant50)
            syswidePCFutCurModel90.append(syswidePCFutCurPlant90)
        
        # convert to np array because each model may have different # elements 
        syswidePCFutCurGMT10.append(np.array(syswidePCFutCurModel10))
        syswidePCFutCurGMT50.append(np.array(syswidePCFutCurModel50))
        syswidePCFutCurGMT90.append(np.array(syswidePCFutCurModel90))

        globalPC = {'globalPCFut10':np.array(syswidePCFutCurModel10), \
                    'globalPCFut50':np.array(syswidePCFutCurModel50), \
                    'globalPCFut90':np.array(syswidePCFutCurModel90)}

        with gzip.open(fileName, 'wb') as f:
            pickle.dump(globalPC, f)