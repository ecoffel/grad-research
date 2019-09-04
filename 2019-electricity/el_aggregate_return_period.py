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


models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


#gldas or grdc
runoffModel = 'grdc'
plantData = 'useu'

percentile = 50

#plantTxData = np.genfromtxt('E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-tx.csv'%plantData, delimiter=',', skip_header=0)
#plantYearData = plantTxData[0,:]
#plantMonthData = plantTxData[1,:]
#plantDayData = plantTxData[2,:]
#plantTxData = plantTxData[3:,:]

yearRange = [1981, 2018]

returnPeriods = np.array([50, 30, 10, 5, 1, .5, .1])
returnPeriodsPrc = 1/returnPeriods * (62.0/100.0)
returnPeriodLabels = ['50', '30', '10', '5', '1', '1/2', '1/10']


if not os.path.isfile('E:/data/ecoffel/data/projects/electricity/script-data/plant-percentiles-%d-%s-%s.dat'%(percentile, runoffModel, plantData)):
    
    
    if plantData == 'world':
        globalPlants = el_load_global_plants.loadGlobalPlants(world=True)
    elif plantData == 'useu':
        globalPlants = el_load_global_plants.loadGlobalPlants(world=False)

    
    histFileName = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist-%d.dat'%(runoffModel, plantData, percentile)
    
    print('calculating percentiles for historical')
    try:
        with gzip.open(histFileName, 'rb') as f:
            syswidePCHist = pickle.load(f)
            syswidePCHist = syswidePCHist['globalPCHist%d'%percentile]
    except:
        with open(histFileName, 'rb') as f:
            syswidePCHist = pickle.load(f)
            syswidePCHist = syswidePCHist['globalPCHist%d'%percentile]
        
        
    plantPercentilesHist = []
    for p in range(syswidePCHist.shape[0]):
        plantTx1d = []
        for year in range(syswidePCHist.shape[1]):
            for month in range(6,7+1):
                for day in range(len(syswidePCHist[p,year,month])):
                    plantTx1d.append(syswidePCHist[p,year,month][day])
        plantTx1d = np.array(plantTx1d)
        plantPercentilesHist.append(np.nanpercentile(plantTx1d, returnPeriodsPrc))
    plantPercentilesHist = np.array(plantPercentilesHist)
    plantPercentilesHist = np.nanmean(plantPercentilesHist, axis=0)
    
    plantPercentilesFut = []
    
    # these are the percentile scores under warming for different mean plant capacities

    for w in range(1,4+1):
        plantPercentilesFutCurGMT = []
    #    futPercentileScoresCurGMT = []
        
        for model in range(len(models)):
            plantPercentilesFutCurModel = []
    #        futPercentileScoresCurModel = []
            
            if plantData == 'useu':        
                fileName = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future-%ddeg-%s.dat'%(runoffModel, plantData, w, models[model])
            elif plantData == 'world':
                fileName = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future-%d-%ddeg-%s.dat'%(runoffModel, plantData, percentile, w, models[model])
    
    
            if not os.path.isfile(fileName):
                filler = []
                for p in range(syswidePCHist.shape[0]):
                    filler.append([np.nan]*len(returnPeriodsPrc))
                plantPercentilesFutCurGMT.append(filler)
                continue
            
            print('calculating percentiles for %s/+%dC'%(models[model],w))
            
            try:
                with gzip.open(fileName, 'rb') as f:
                    globalPC = pickle.load(f)
                    
    #                globalPCFut10 = globalPC['globalPCFut10']
                    globalPCFut = globalPC['globalPCFut%d'%percentile]
    #                globalPCFut90 = globalPC['globalPCFut90']
            except:
                with open(fileName, 'rb') as f:
                    globalPC = pickle.load(f)
                    
    #                globalPCFut10 = globalPC['globalPCFut10']
                    globalPCFut = globalPC['globalPCFut%d'%percentile]
    #                globalPCFut90 = globalPC['globalPCFut90']
            
            for p in range(syswidePCHist.shape[0]):
                plantTx1d = []
                for year in range(globalPCFut.shape[1]):
                    for month in range(6,7+1):
                        for day in range(len(globalPCFut[p,year,month])):
                            plantTx1d.append(globalPCFut[p,year,month][day])
                plantTx1d = np.array(plantTx1d)
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
    
    with gzip.open('E:/data/ecoffel/data/projects/electricity/script-data/plant-percentiles-%d-%s-%s.dat'%(percentile, runoffModel, plantData), 'wb') as f:
        plantPercentiles = {'plantPercentilesHist':plantPercentilesHist, \
                            'plantPercentilesFut':plantPercentilesFut}
        pickle.dump(plantPercentiles, f)
    
else:
    
    with gzip.open('E:/data/ecoffel/data/projects/electricity/script-data/plant-percentiles-%d-%s-%s.dat'%(percentile, runoffModel, plantData), 'rb') as f:
        plantPercentiles = pickle.load(f)
        plantPercentilesHist = plantPercentiles['plantPercentilesHist']
        plantPercentilesFut = plantPercentiles['plantPercentilesFut']

sys.exit()
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
plt.ylim([88,97])
#plt.xlim([-3.1, 3.1])
plt.grid(True, color=[.9,.9,.9])

plt.plot([5, 5], [80, 100], '--k', lw=1)

plt.plot(xpos, plantPercentilesHist, 'ko', markersize=5, label='Historical')
plt.plot(xpos+.15, np.nanmean(plantPercentilesFut[1,:,:], axis=0), 'o', markersize=5, color='#ffb835', label='+ 2$\degree$C')
plt.errorbar(xpos+.15, \
             np.nanmean(plantPercentilesFut[1,:,:], axis=0), \
             yerr = np.nanstd(plantPercentilesFut[1,:,:], axis=0), \
             ecolor = '#ffb835', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos-.15, np.nanmean(plantPercentilesFut[3,:,:], axis=0), 'o', markersize=5, color=snsColors[1], label='+ 4$\degree$C')
plt.errorbar(xpos-.15, \
             np.nanmean(plantPercentilesFut[3,:,:], axis=0), \
             yerr = np.nanstd(plantPercentilesFut[3,:,:], axis=0), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.yticks(np.arange(88,97,1))

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



