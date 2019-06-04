# -*- coding: utf-8 -*-
"""
Created on Mon May 20 14:57:18 2019

@author: Ethan
"""


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
import statsmodels.api as sm
import el_temp_pp_model
import el_load_global_plants
import gzip, pickle
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False
regenAggOutages = True

globalPlants = el_load_global_plants.loadGlobalPlants()
globalWx = el_load_global_plants.loadGlobalWx(wxdata='all')

plantList = globalWx['plantList']
plantYearData = globalWx['plantYearData']
plantMonthData = globalWx['plantMonthData']
plantDayData = globalWx['plantDayData']
plantTxData = globalWx['plantTxData']

pPolyData = {}
with open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)

eData = {}
with open('eData.dat', 'rb') as f:
    eData = pickle.load(f)

yearRange = [1981, 2018]

returnPeriods = np.array([50, 30, 10, 5, 1, .5, .1])
returnPeriodsPrc = 1 / returnPeriods
returnPeriodLabels = ['50', '30', '10', '5', '1', '1/2', '1/10']


if not regenAggOutages:
    if not 'syswidePC' in locals():
        syswidePC = {}
        syswidePC10 = []
        syswidePC50 = []
        syswidePC90 = []
        with gzip.open('syswidePC.dat', 'rb') as f:
            syswidePC = pickle.load(f)
            syswidePC10 = syswidePC['syswidePC10']
            syswidePC50 = syswidePC['syswidePC50']
            syswidePC90 = syswidePC['syswidePC90']
else:
    warming = [0, 1, 2, 3, 4]
    
    for w in range(len(warming)):
        syswidePC10.append([])
        syswidePC50.append([])
        syswidePC90.append([])
        
        for p in range(0, plantTxData.shape[0]):
            
            normCap = globalPlants['caps'][p]
            
            syswidePC10[w].append([])
            syswidePC50[w].append([])
            syswidePC90[w].append([])
            
            for year in range(1981, 2018+1):
                ind = np.where((plantYearData==year) & ((plantMonthData == 7) | (plantMonthData == 8)))[0]
                
                syswidePC10[w][-1].extend(pPolyData['pPoly3'][pPolyData['indPoly10'][0]](plantTxData[p,ind]+warming[w]))
                syswidePC50[w][-1].extend(pPolyData['pPoly3'][pPolyData['indPoly50'][0]](plantTxData[p,ind]+warming[w]))
                syswidePC90[w][-1].extend(pPolyData['pPoly3'][pPolyData['indPoly90'][0]](plantTxData[p,ind]+warming[w]))
    
    
    syswidePC = {'syswidePC10':np.array(syswidePC10), \
                  'syswidePC50':np.array(syswidePC50), \
                  'syswidePC90':np.array(syswidePC90)}
    
    with gzip.open('syswidePC.dat', 'wb') as f:
        pickle.dump(syswidePC, f)

plantPercentiles = []
for w in range(syswidePC10.shape[0]):
    plantPercentiles.append([])
    for p in range(syswidePC10.shape[1]):
        plantPercentiles[w].append(np.nanpercentile(syswidePC50[w,p,:], returnPeriodsPrc))
plantPercentiles = np.array(plantPercentiles)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])


plt.figure(figsize=(4,4))
#plt.ylim([0,100])
#plt.xlim([-3.1, 3.1])
plt.grid(True, alpha = 0.5)

plt.plot(np.nanmean(plantPercentiles[0,:,:],axis=0).T, 'ko', markersize=7, label='Historical')

#plt.plot(np.nanmean(plantPercentiles[1,:,:],axis=0).T, 'o', markersize=7, color=snsColors[0], label='1$\degree$C')
plt.plot(np.nanmean(plantPercentiles[2,:,:],axis=0).T, 'o', markersize=7, color=cmx.tab20(0), label='+ 2$\degree$C')
#plt.plot(np.nanmean(plantPercentiles[3,:,:],axis=0).T, 'o', markersize=7, color=snsColors[2], label='3$\degree$C')
plt.plot(np.nanmean(plantPercentiles[4,:,:],axis=0).T, 'o', markersize=7, color=cmx.tab20(6), label='+ 4$\degree$C')

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Return period (years)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'})
leg.get_frame().set_linewidth(0.0)
    

plt.gca().set_xticks(range(len(returnPeriods)))
plt.gca().set_xticklabels(returnPeriodLabels)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))


if plotFigs:
    plt.savefig('system-wide-pc-return-period.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



