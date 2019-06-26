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

plantQsData = np.genfromtxt('global-pp-runoff-anom-all.csv', delimiter=',', skip_header=0)
plantQsData = plantQsData[3:,:]

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
    
    if p%50 == 0:
        print('processing historical plant %d...'%p)
    
    syswidePCHistCurPlant10 = []
    syswidePCHistCurPlant50 = []
    syswidePCHistCurPlant90 = []
    
    for year in range(1981, 2018+1):
        
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
                    pcPred10 = pcModel10.predict([1, tx, tx**2, tx**3, \
                                                  qs, qs**2, qs**3, qs**4, qs**5, \
                                                  tx*qs,
                                                  0])[0]
                    pcPred50 = pcModel10.predict([1, tx, tx**2, tx**3, \
                                                  qs, qs**2, qs**3, qs**4, qs**5, \
                                                  tx*qs,
                                                  0])[0]
                    pcPred90 = pcModel10.predict([1, tx, tx**2, tx**3, \
                                                  qs, qs**2, qs**3, qs**4, qs**5, \
                                                  tx*qs,
                                                  0])[0]
                else:
                    pcPred10 = 100
                    pcPred50 = 100
                    pcPred90 = 100
                
                
                if pcPred10 > 100: pcPred10 = 100
                if pcPred50 > 100: pcPred50 = 100
                if pcPred90 > 100: pcPred90 = 100
    
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

with gzip.open('E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-hist-10.dat', 'wb') as f:
    pickle.dump(globalPC10, f)
with gzip.open('E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-hist-50.dat', 'wb') as f:
    pickle.dump(globalPC50, f)
with gzip.open('E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-hist-90.dat', 'wb') as f:
    pickle.dump(globalPC90, f)

# load future mean warming data and recompute PC
print('computing future systemwide PC...')
for w in range(1, 4+1):
        
    for m in range(len(models)):
        
        fileName = 'E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-future-%ddeg-%s.dat'%(w, models[m])
        
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
                                pcPred10 = pcModel10.predict([1, curTx, curTx**2, curTx**3, \
                                                                         curQs, curQs**2, curQs**3, curQs**4, curQs**5, curTx*curQs, 0])[0]
                                pcPred50 = pcModel50.predict([1, curTx, curTx**2, curTx**3, \
                                                                         curQs, curQs**2, curQs**3, curQs**4, curQs**5, curTx*curQs, 0])[0]
                                pcPred90 = pcModel90.predict([1, curTx, curTx**2, curTx**3, \
                                                                         curQs, curQs**2, curQs**3, curQs**4, curQs**5, curTx*curQs, 0])[0]
                            else:
                                pcPred10 = 100
                                pcPred50 = 100
                                pcPred90 = 100
                                
                            if pcPred10 > 100: pcPred10 = 100
                            if pcPred50 > 100: pcPred50 = 100
                            if pcPred90 > 100: pcPred90 = 100
                            
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

        globalPC = {'globalPCFut10':np.array(syswidePCFutCurModel10), \
                    'globalPCFut50':np.array(syswidePCFutCurModel50), \
                    'globalPCFut90':np.array(syswidePCFutCurModel90)}

        with gzip.open(fileName, 'wb') as f:
            pickle.dump(globalPC, f)