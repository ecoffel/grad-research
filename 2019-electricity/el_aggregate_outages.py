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
import pickle
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


yearlyOutageAcc10 = []
yearlyOutageAcc50 = []
yearlyOutageAcc90 = []

yearlyOutageAccDaily10 = []
yearlyOutageAccDaily50 = []
yearlyOutageAccDaily90 = []

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

# sum across plants and convert to TWh by multiplying by 24
mean10 = np.nansum(yearlyOutageAcc10*24, axis=1)
mean50 = np.nansum(yearlyOutageAcc50*24, axis=1)
mean90 = np.nansum(yearlyOutageAcc90*24, axis=1)

# convert to GW/day by dividing by 62 days in Jul and Aug 
meanDaily10 = np.nansum(yearlyOutageAcc10/62*1e3, axis=1)
meanDaily50 = np.nansum(yearlyOutageAcc50/62*1e3, axis=1)
meanDaily90 = np.nansum(yearlyOutageAcc90/62*1e3, axis=1)

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

xd = np.array(list(range(1981, 2018+1)))-1981+1

z = np.polyfit(xd, mean10[0,:], 1)
histPolyTx10 = np.poly1d(z)
z = np.polyfit(xd, mean50[0,:], 1)
histPolyTx50 = np.poly1d(z)
z = np.polyfit(xd, mean90[0,:], 1)
histPolyTx90 = np.poly1d(z)

plt.figure(figsize=(4,4))
plt.xlim([0, 105])
plt.ylim([-30, 0])
plt.grid(True, alpha = 0.5)

plt.plot(xd, histPolyTx10(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8)
plt.plot(xd, histPolyTx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8)
plt.plot(xd, histPolyTx90(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8)

plt.plot([55, 70, 85, 100], \
         [np.nanmean(mean10[1,:]), \
          np.nanmean(mean10[2,:]), \
          np.nanmean(mean10[3,:]), \
          np.nanmean(mean10[4,:])], \
          'o', markersize=7, color=cmx.tab20(0), label='10th Percentile')

plt.plot([55, 70, 85, 100], \
         [np.nanmean(mean50[1,:]), \
          np.nanmean(mean50[2,:]), \
          np.nanmean(mean50[3,:]), \
          np.nanmean(mean50[4,:])], \
          'o', markersize=7, color='black', label='50th Percentile')

plt.plot([55, 70, 85, 100], \
         [np.nanmean(mean90[1,:]), \
          np.nanmean(mean90[2,:]), \
          np.nanmean(mean90[3,:]), \
          np.nanmean(mean90[4,:])], \
          'o', markersize=7, color=cmx.tab20(6), label='90th Percentile')

plt.plot([38,38], [-30, 0], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, 55, 70, 85, 100])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.ylabel('Summer total outage (TWh)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'upper right')
leg.get_frame().set_linewidth(0.0)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('accumulated-annual-summer-outage.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)






z = np.polyfit(xd, meanDaily10[0,:], 1)
histPolyTx10 = np.poly1d(z)
z = np.polyfit(xd, meanDaily50[0,:], 1)
histPolyTx50 = np.poly1d(z)
z = np.polyfit(xd, meanDaily90[0,:], 1)
histPolyTx90 = np.poly1d(z)

plt.figure(figsize=(4,4))
plt.xlim([0, 105])
plt.ylim([-25, 0])
plt.grid(True, alpha = 0.5)

plt.plot(xd, histPolyTx10(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8)
plt.plot(xd, histPolyTx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8)
plt.plot(xd, histPolyTx90(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8)

plt.plot([55, 70, 85, 100], \
         [np.nanmean(meanDaily10[1,:]), \
          np.nanmean(meanDaily10[2,:]), \
          np.nanmean(meanDaily10[3,:]), \
          np.nanmean(meanDaily10[4,:])], \
          'o', markersize=7, color=cmx.tab20(0), label='10th Percentile')

plt.plot([55, 70, 85, 100], \
         [np.nanmean(meanDaily50[1,:]), \
          np.nanmean(meanDaily50[2,:]), \
          np.nanmean(meanDaily50[3,:]), \
          np.nanmean(meanDaily50[4,:])], \
          'o', markersize=7, color='black', label='50th Percentile')

plt.plot([55, 70, 85, 100], \
         [np.nanmean(meanDaily90[1,:]), \
          np.nanmean(meanDaily90[2,:]), \
          np.nanmean(meanDaily90[3,:]), \
          np.nanmean(meanDaily90[4,:])], \
          'o', markersize=7, color=cmx.tab20(6), label='90th Percentile')

plt.plot([38,38], [-25, 0], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, 55, 70, 85, 100])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])
plt.gca().set_yticks(range(-25, 1, 5))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.ylabel('Summer daily outage (GW)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'upper right')
leg.get_frame().set_linewidth(0.0)


# create labels for 2nd y-axis
ax2 = plt.gca().twinx()
plt.gca().set_ylim([-25, 0])
plt.ylabel('# Average size power plants', fontname = 'Helvetica', fontsize=16)
plt.gca().set_yticks(np.arange(-20, 1, 5))
plantsLost = -1 * np.round(((np.arange(-20, 1, 5) * 1e3) / np.nanmean(globalPlants['caps'])))
plt.gca().set_yticklabels([int(x) for x in plantsLost])

for label in ax2.yaxis.get_majorticklabels():
    label.set_fontname('Helvetica')    
    label.set_fontsize(14)


#x0,x1 = ax2.get_xlim()
#y0,y1 = ax2.get_ylim()
#ax2.set_aspect(abs(x1-x0)/abs(y1-y0))
#
#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('daily-summer-outage.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



