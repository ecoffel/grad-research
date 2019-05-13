# -*- coding: utf-8 -*-
"""
Created on Sat May 11 12:02:35 2019

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import pandas as pd
import sys
import os
from sklearn import linear_model
import statsmodels.api as sm
import matplotlib.pyplot as plt
import el_temp_pp_model
import el_load_global_plants

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'



plotFigs = False

regr, mdl = el_temp_pp_model.buildLinearTempPPModel()
#zPoly3, pPoly3 = el_temp_pp_model.buildPoly3TempPPModel()

#globalPlants = el_load_global_plants.loadGlobalPlants()

models = ['access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', \
          'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', \
          'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'inmcm4', \
          'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


yearRangeHist = [1981, 2018]
yearRange1 = [2020, 2050]
yearRange2 = [2050, 2080]
# load wx data for global plants

pcAnnualHist = []
pcSummerHist = []
pcTxxHist = []

pcAnnual1 = []
pcSummer1 = []
pcTxx1 = []

pcAnnual2 = []
pcSummer2 = []
pcTxx2 = []

annualTx = []





# load historical data ----------------------------------------------
fileNameHist = 'entsoe-nuke-pp-tx-era.csv'
plantTxDataHist = np.genfromtxt(fileNameHist, delimiter=',', skip_header=0)
plantYearDataHist = plantTxDataHist[0,1:].copy()
plantMonthDataHist = plantTxDataHist[1,1:].copy()
plantDayDataHist = plantTxDataHist[2,1:].copy()
plantTxDataHist = plantTxDataHist[3:,1:].copy()

pcAnnualHist = []
pcSummerHist = []
pcTxxHist = []


plantList = []
with open(fileNameHist, 'r') as f:
    i = 0
    for line in f:
        if i > 3:
            parts = line.split(',')
            plantList.append(i)
        i += 1

for p in range(len(plantList)):
    curPcAnnual = []
    curPcSummer = []
    curPcTxx = []
    
    indTxMean = np.where((plantMonthDataHist >= 7) & (plantMonthDataHist <= 8))[0]
    txMean = np.nanmean(plantTxDataHist[p, indTxMean])
    
    for year in range(yearRangeHist[0], yearRangeHist[1]):
        indSummer = np.where((plantYearDataHist == year) & (plantMonthDataHist >= 7) & (plantMonthDataHist <= 8))[0]
        indAnnual = np.where((plantYearDataHist == year))[0]
        
        txSummer = plantTxDataHist[p, indSummer]
        txAnnual = plantTxDataHist[p, indAnnual]
        txx = np.nanmax(txAnnual)
        
        nn = np.where(~np.isnan(txAnnual))[0]
        if len(nn) == 0:
            curPcAnnual.append(np.nan)
        else:
            curPcAnnual.append(np.nanmean(regr.predict(txAnnual[nn].reshape(-1, 1))))
#            curPcAnnual.append(np.nanmean(pPoly3(txAnnual[nn])))
        
        nn = np.where(~np.isnan(txSummer))[0]
        if len(nn) == 0:
            curPcSummer.append(np.nan)
        else:
            curPcSummer.append(np.nanmean(regr.predict(txSummer[nn].reshape(-1, 1))))
#            curPcSummer.append(np.nanmean(pPoly3(txSummer[nn])))
        
        if np.isnan(txx):
            curPcTxx.append(np.nan)
        else:
            curPcTxx.append(np.nanmean(regr.predict(txx.reshape(1, -1))))
#            curPcTxx.append(np.nanmean(pPoly3(txx)))
        
            
    pcAnnualHist.append(np.array(curPcAnnual))
    pcSummerHist.append(np.array(curPcSummer))
    pcTxxHist.append(np.array(curPcTxx))
    









# load future data --------------------------------------------------
for m in range(len(models)):
    fileName1 = 'future-temps/entnsoe-nuke-pp-rcp85-tx-cmip5-%s-%d-%d.csv'%(models[m], yearRange1[0], yearRange1[1])
    fileName2 = 'future-temps/entnsoe-nuke-pp-rcp85-tx-cmip5-%s-%d-%d.csv'%(models[m], yearRange2[0], yearRange2[1])

    if not os.path.isfile(fileName1) or not os.path.isfile(fileName2):
        continue

    
    plantTxData1 = np.genfromtxt(fileName1, delimiter=',', skip_header=0)
    plantYearData1 = plantTxData1[0,1:].copy()
    plantMonthData1 = plantTxData1[1,1:].copy()
    plantDayData1 = plantTxData1[2,1:].copy()
    plantTxData1 = plantTxData1[3:,1:].copy()
    
    plantTxData2 = np.genfromtxt(fileName2, delimiter=',', skip_header=0)
    plantYearData2 = plantTxData2[0,1:].copy()
    plantMonthData2 = plantTxData2[1,1:].copy()
    plantDayData2 = plantTxData2[2,1:].copy()
    plantTxData2 = plantTxData2[3:,1:].copy()
    
    pcAnnual1.append([])
    pcSummer1.append([])
    pcTxx1.append([])
    
    pcAnnual2.append([])
    pcSummer2.append([])
    pcTxx2.append([])
    annualTx.append([])
    
    for p in range(len(plantList)):
        curPcAnnual = []
        curPcSummer = []
        curPcTxx = []
        
        curAnnualTx = []
        
        indTxMean = np.where((plantMonthData1 >= 7) & (plantMonthData1 <= 8))[0]
        txMean = np.nanmean(plantTxData1[p, indTxMean])
        
        for year in range(yearRange1[0], yearRange1[1]):
            indSummer = np.where((plantYearData1 == year) & (plantMonthData1 >= 7) & (plantMonthData1 <= 8))[0]
            indAnnual = np.where((plantYearData1 == year))[0]
            
            txSummer = plantTxData1[p, indSummer]
            txAnnual = plantTxData1[p, indAnnual]
            txx = np.nanmax(txAnnual)
            
            curAnnualTx.append(txx)
            
            nn = np.where(~np.isnan(txAnnual))[0]   
            if len(nn) == 0:
                curPcAnnual.append(np.nan)
            else:
                curPcAnnual.append(np.nanmean(regr.predict(txAnnual[nn].reshape(-1, 1))))
    #            curPcAnnual.append(np.nanmean(pPoly3(txAnnual[nn])))
            
            nn = np.where(~np.isnan(txSummer))[0]
            if len(nn) == 0:
                curPcSummer.append(np.nan)
            else:
                curPcSummer.append(np.nanmean(regr.predict(txSummer[nn].reshape(-1, 1))))
    #            curPcSummer.append(np.nanmean(pPoly3(txSummer[nn])))
            
            if np.isnan(txx):
                curPcTxx.append(np.nan)
            else:
                curPcTxx.append(np.nanmean(regr.predict(txx.reshape(1, -1))))
    #            curPcTxx.append(np.nanmean(pPoly3(txx)))
            
            
                
        pcAnnual1[-1].append(np.array(curPcAnnual))
        pcSummer1[-1].append(np.array(curPcSummer))
        pcTxx1[-1].append(np.array(curPcTxx))
        
        annualTx[-1].append(np.array(curAnnualTx))
    
    
    # load data for 2050-2080 period ---------------------------------
    for p in range(len(plantList)):
        curPcAnnual = []
        curPcSummer = []
        curPcTxx = []
        
        curAnnualTx = []
        
        indTxMean = np.where((plantMonthData2 >= 7) & (plantMonthData2 <= 8))[0]
        txMean = np.nanmean(plantTxData2[p, indTxMean])
        
        for year in range(yearRange2[0], yearRange2[1]):
            indSummer = np.where((plantYearData2 == year) & (plantMonthData2 >= 7) & (plantMonthData2 <= 8))[0]
            indAnnual = np.where((plantYearData2 == year))[0]
            
            txSummer = plantTxData2[p, indSummer]
            txAnnual = plantTxData2[p, indAnnual]
            txx = np.nanmax(txAnnual)
            
            curAnnualTx.append(txx)
            
            nn = np.where(~np.isnan(txAnnual))[0]
            if len(nn) == 0:
                curPcAnnual.append(np.nan)
            else:
                curPcAnnual.append(np.nanmean(regr.predict(txAnnual[nn].reshape(-1, 1))))
    #            curPcAnnual.append(np.nanmean(pPoly3(txAnnual[nn])))
            
            nn = np.where(~np.isnan(txSummer))[0]
            if len(nn) == 0:
                curPcSummer.append(np.nan)
            else:
                curPcSummer.append(np.nanmean(regr.predict(txSummer[nn].reshape(-1, 1))))
    #            curPcSummer.append(np.nanmean(pPoly3(txSummer[nn])))
            
            if np.isnan(txx):
                curPcTxx.append(np.nan)
            else:
                curPcTxx.append(np.nanmean(regr.predict(txx.reshape(1, -1))))
    #            curPcTxx.append(np.nanmean(pPoly3(txx)))
                
            
                
        pcAnnual2[-1].append(np.array(curPcAnnual))
        pcSummer2[-1].append(np.array(curPcSummer))
        pcTxx2[-1].append(np.array(curPcTxx))
        
        annualTx[-1].append(np.array(curAnnualTx))
    


pcAnnualHist = np.array(pcAnnualHist)
pcSummerHist = np.array(pcSummerHist)
pcTxxHist = np.array(pcTxxHist)

pcAnnual1 = np.array(pcAnnual1)
pcSummer1 = np.array(pcSummer1)
pcTxx1 = np.array(pcTxx1)

pcAnnual2 = np.array(pcAnnual2)
pcSummer2 = np.array(pcSummer2)
pcTxx2 = np.array(pcTxx2)

annualTx = np.array(annualTx);


boxyPC = [np.nanmean(pcAnnualHist, axis=1), \
          np.nanmean(np.nanmean(pcAnnual1, axis=2), axis=1), \
          np.nanmean(np.nanmean(pcAnnual2, axis=2), axis=1), \
          np.nanmean(pcSummerHist, axis=1), \
          np.nanmean(np.nanmean(pcSummer1, axis=2), axis=1), \
          np.nanmean(np.nanmean(pcSummer2, axis=2), axis=1), \
          np.nanmean(pcTxxHist, axis=1), \
          np.nanmean(np.nanmean(pcTxx1, axis=2), axis=1), \
          np.nanmean(np.nanmean(pcTxx2, axis=2), axis=1)]

plt.figure(figsize=(4,5))
plt.grid(True)
medianprops = dict(linestyle='-', linewidth=2, color='black')
meanpointprops = dict(marker='D', markeredgecolor='black',
                      markerfacecolor='red')
bplot = plt.boxplot(boxyPC, positions = [.85, 1, 1.15, 1.85, 2, 2.15, 2.85, 3, 3.15], \
                    showmeans=True, widths=.1, sym='.', patch_artist=True, \
                    medianprops=medianprops, meanprops=meanpointprops, zorder=0)

colors = ['lightgray']
for patch in bplot['boxes']:
    patch.set_facecolor([.75, .75, .75])

plt.gca().set_xticks([1, 2, 3])
plt.gca().set_xticklabels(['Ann. mean', 'JJA mean', 'TXx'])


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

plt.savefig('pc-future-change.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)

    
    
    
    
    
    
    
    
    
    
    
    