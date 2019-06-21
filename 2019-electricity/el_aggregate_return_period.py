# -*- coding: utf-8 -*-
"""
Created on Mon May 20 14:57:18 2019

@author: Ethan
"""


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
from scipy import stats
import statsmodels.api as sm
import el_build_temp_pp_model
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
globalWx = el_load_global_plants.loadGlobalWx(wxdata='all')

plantList = globalWx['plantList']
plantYearData = globalWx['plantYearData']
plantMonthData = globalWx['plantMonthData']
plantDayData = globalWx['plantDayData']
plantTxData = globalWx['plantTxData']

pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]


eData = {}
with open('eData.dat', 'rb') as f:
    eData = pickle.load(f)

yearRange = [1981, 2018]

returnPeriods = np.array([50, 30, 10, 5, 1, .5, .1])
returnPeriodsPrc = 1/returnPeriods * (62.0/100.0)
returnPeriodLabels = ['50', '30', '10', '5', '1', '1/2', '1/10']


if regenAggOutages:
    if not os.path.isfile('global-pc-future/global-pc-hist.dat'):
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
    else:
        with gzip.open('global-pc-future/global-pc-hist.dat', 'rb') as f:
            globalPCHist = pickle.load(f)
            syswidePCHist10 = globalPCHist['globalPCHist10']
            syswidePCHist50 = globalPCHist['globalPCHist50']
            syswidePCHist90 = globalPCHist['globalPCHist90']
            
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
        

print('calculating percentiles for historical')
with gzip.open('global-pc-future/global-pc-hist.dat', 'rb') as f:
    globalPCHist = pickle.load(f)
    
    syswidePCHist10 = globalPCHist['globalPCHist10']
    syswidePCHist50 = globalPCHist['globalPCHist50']
    syswidePCHist90 = globalPCHist['globalPCHist90']
    
plantPercentilesHist = []
for p in range(syswidePCHist10.shape[0]):
    plantTx1d = np.reshape(syswidePCHist10[p,:,:], (syswidePCHist10[p,:,:].shape[0]*syswidePCHist10[p,:,:].shape[1]), order='C')
    plantPercentilesHist.append(np.nanpercentile(plantTx1d, returnPeriodsPrc))
plantPercentilesHist = np.array(plantPercentilesHist)
plantPercentilesHist = np.nanmean(plantPercentilesHist, axis=0)

plantPercentilesFut = []

# these are the percentile scores under warming for different mean plant capacities
#futPercentileLevels = np.arange(90,96,1)
#futPercentileScores = []

for w in range(1,4+1):
    plantPercentilesFutCurGMT = []
#    futPercentileScoresCurGMT = []
    
    for model in range(len(models)):
        plantPercentilesFutCurModel = []
#        futPercentileScoresCurModel = []
        
        fileName = 'global-pc-future/global-pc-future-%ddeg-%s.dat'%(w, models[model])
        
        if not os.path.isfile(fileName):
            filler = []
            for p in range(syswidePCHist10.shape[0]):
                filler.append([np.nan]*len(returnPeriodsPrc))
            plantPercentilesFutCurGMT.append(filler)
            continue
        
        print('calculating percentiles for %s/+%dC'%(models[model],w))
        
        with gzip.open(fileName, 'rb') as f:
            globalPC = pickle.load(f)
            
            globalPCFut10 = globalPC['globalPCFut10']
            globalPCFut50 = globalPC['globalPCFut50']
            globalPCFut90 = globalPC['globalPCFut90']
        
        for p in range(syswidePCHist10.shape[0]):
            plantTx1d = np.reshape(globalPCFut10[p,:,:], (globalPCFut10[p,:,:].shape[0]*globalPCFut10[p,:,:].shape[1]), order='C')
            plantPercentilesFutCurModel.append(np.nanpercentile(plantTx1d, returnPeriodsPrc))
            
            # calc future prctile scores for mean plant capacity levels 
#            plantPercLevels = []
#            for percLevel in futPercentileLevels:
#                plantPercLevels.append(stats.percentileofscore(plantTx1d, percLevel))
#            futPercentileScoresCurModel.append(plantPercLevels)
#        
        plantPercentilesFutCurGMT.append(plantPercentilesFutCurModel)
#        futPercentileScoresCurGMT.append(futPercentileScoresCurModel)
    
    plantPercentilesFut.append(plantPercentilesFutCurGMT)
#    futPercentileScores.append(futPercentileScoresCurGMT)
    
plantPercentilesFut = np.array(plantPercentilesFut)
plantPercentilesFut = np.nanmean(plantPercentilesFut, axis=2)

## convert perc score into return period
#futPercentileScores = np.array(futPercentileScores)
#futPercentileScores = futPercentileScores/100.0
#
#futReturnPeriods = 1/futPercentileScores/62.0
#futReturnPeriods[np.isinf(futReturnPeriods)] = np.nan
#futReturnPeriods = np.nanmean(np.nanmean(futReturnPeriods, axis=2), axis=1)


#percLabels = ['']
#for i in range(futReturnPeriods.shape[1]):
#    percLabels.append('%.0f/%.0f'%(np.nanmean(futReturnPeriods[1,i]), \
#                                        np.nanmean(futReturnPeriods[3,i])))
#percLabels.append('')

ppDiff = []
for w in range(plantPercentilesFut.shape[0]):
    ppDiffCurModel = []
    for m in range(plantPercentilesFut.shape[1]):
        ppFut = plantPercentilesFut[w,m,:]
        ppDiffCurModel.append(ppFut-plantPercentilesHist)
    ppDiff.append(ppDiffCurModel)
ppDiff = np.array(ppDiff)

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

xpos = np.arange(1,len(returnPeriods)+1)

plt.figure(figsize=(4,4))
plt.ylim([87,97])
#plt.xlim([-3.1, 3.1])
plt.grid(True, alpha = 0.5)

plt.plot([5, 5], [80, 100], '--k', lw=1)

plt.plot(xpos, plantPercentilesHist, 'ko', markersize=5, label='Historical')
plt.plot(xpos+.15, np.nanmean(plantPercentilesFut[1,:,:], axis=0), 'o', markersize=5, color=snsColors[0], label='+ 2$\degree$C')
plt.errorbar(xpos+.15, \
             np.nanmean(plantPercentilesFut[1,:,:], axis=0), \
             yerr = np.nanstd(plantPercentilesFut[1,:,:], axis=0), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos-.15, np.nanmean(plantPercentilesFut[3,:,:], axis=0), 'o', markersize=5, color=snsColors[1], label='+ 4$\degree$C')
plt.errorbar(xpos-.15, \
             np.nanmean(plantPercentilesFut[3,:,:], axis=0), \
             yerr = np.nanstd(plantPercentilesFut[3,:,:], axis=0), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.yticks(np.arange(87,97,1))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Return period (years)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks(xpos)
plt.gca().set_xticklabels(returnPeriodLabels)
    
leg = plt.legend(prop = {'size':12, 'family':'Helvetica'})
leg.get_frame().set_linewidth(0.0)

## create 2nd y axis
#ax2 = plt.gca().twinx()
#plt.ylim([89,96])
#plt.yticks(np.arange(89,97,1))
#plt.gca().set_yticklabels(percLabels)
#plt.ylabel('Future return period (years)', fontname = 'Helvetica', fontsize=16)
#
#for tick in ax2.yaxis.get_major_ticks():
#    tick.label2.set_fontname('Helvetica')    
#    tick.label2.set_fontsize(14)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('system-wide-pc-return-period.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



