# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import pickle, gzip
import sys, os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False
newFit = True

smoothingLen = 4

yearRange = [1981, 2018]

# load historical temp data for all plants in US and EU
fileNameTemp = 'entsoe-nuke-pp-tx-all.csv'
plantList = []
with open(fileNameTemp, 'r') as f:
    i = 0
    for line in f:
        if i >= 3:
            parts = line.split(',')
            plantList.append(parts[0])
        i += 1
plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,1:].copy()
plantMonthData = plantTxData[1,1:].copy()
plantDayData = plantTxData[2,1:].copy()
plantTxData = plantTxData[3:,1:].copy()

summerInd = np.where((plantMonthData == 7) | (plantMonthData == 8))[0]
plantMeanTemps = np.nanmean(plantTxData[:,summerInd], axis=1)

# load historical runoff data for all plants in US and EU
fileNameRunoff = 'entsoe-nuke-pp-runoff-all.csv'
plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
plantQsData = plantQsData[3:,1:].copy()

plantQsAnomData = []
for p in range(plantQsData.shape[0]):
    plantQsAnomData.append((plantQsData[p,:]-np.nanmean(plantQsData[p,:]))/np.nanstd(plantQsData[p,:]))
plantQsAnomData = np.array(plantQsAnomData)

pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('pPolyData.dat', 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]

pCapTx10 = []
pCapTx50 = []
pCapTx90 = []

pCapTxx10 = []
pCapTxx50 = []
pCapTxx90 = []

annualTx = []
annualTxx = []

warming = [0,1,2,3,4]

for w in range(len(warming)):
    pCapTx10.append([])
    pCapTx50.append([])
    pCapTx90.append([])
    
    pCapTxx10.append([])
    pCapTxx50.append([])
    pCapTxx90.append([])
    
    for p in range(len(plantList)):
        
        plantPcTx10 = []
        plantPcTx50 = []
        plantPcTx90 = []
        
        plantPcTxx10 = []
        plantPcTxx50 = []
        plantPcTxx90 = []
        
        curAnnualTx = []
        curAnnualTxx = []
        
        indTxMean = np.where((plantMonthData >= 7) & (plantMonthData <= 8))[0]
        txMean = np.nanmean(plantTxData[p, indTxMean])
        
        tx = plantTxData[p, :]
        qs = plantQsAnomData[p, :]
        
        for year in range(yearRange[0], yearRange[1]+1):

            ind = np.where((plantYearData == year) & (plantMonthData >= 7) & (plantMonthData <= 8))[0]
    #        ind = np.where((plantYearData == year))[0]
            
            curTx = tx[ind] + warming[w]
            curQs = qs[ind]
            
            nn = np.where(~np.isnan(curTx))[0]
            
            if len(nn) == 0:
                plantPcTx10.append(np.nan)
                plantPcTx50.append(np.nan)
                plantPcTx90.append(np.nan)
                
                plantPcTxx10.append(np.nan)
                plantPcTxx50.append(np.nan)
                plantPcTxx90.append(np.nan)
                
                if w==0:
                    curAnnualTx.append(np.nan)
                    curAnnualTxx.append(np.nan)
                continue
            
            curTx = curTx[nn]
            curQs = curQs[nn]
            
            indTxx = np.where(curTx == np.nanmax(curTx))[0][0]
            curTxx = curTx[indTxx]
            curQsTxx = curQs[indTxx]
            
            if w==0:
                curAnnualTx.append(np.nanmean(curTx))
                curAnnualTxx.append(curTxx)
            
            curPcPred10 = []
            curPcPred50 = []
            curPcPred90 = []
            
            for i in range(len(curTx)):
                
                t = curTx[i]
                q = curQs[i]
                
                curDayPc10 = pcModel10.predict([1, t, t**2, t**3, \
                                                     q, q**2, q**3, q**4, q**5, 0])[0]
                curDayPc50 = pcModel50.predict([1, t, t**2, t**3, \
                                                     q, q**2, q**3, q**4, q**5, 0])[0]
                curDayPc90 = pcModel90.predict([1, t, t**2, t**3, \
                                                     q, q**2, q**3, q**4, q**5, 0])[0]
                if curDayPc10 > 100: curDayPc10 = 100
                if curDayPc50 > 100: curDayPc50 = 100
                if curDayPc90 > 100: curDayPc90 = 100
                
                curPcPred10.append(curDayPc10)
                curPcPred50.append(curDayPc50)
                curPcPred90.append(curDayPc90)
            
            curPcPredTxx10 = pcModel10.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                     curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, 0])[0]
            curPcPredTxx50 = pcModel50.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                     curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, 0])[0]
            curPcPredTxx90 = pcModel90.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                     curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, 0])[0]
            if curPcPredTxx10 > 100: curPcPredTxx10 = 100
            if curPcPredTxx50 > 100: curPcPredTxx50 = 100
            if curPcPredTxx90 > 100: curPcPredTxx90 = 100
                        
            plantPcTx10.append(np.nanmean(curPcPred50))
            plantPcTx50.append(np.nanmean(curPcPred50))
            plantPcTx90.append(np.nanmean(curPcPred90))
            
            plantPcTxx10.append(curPcPredTxx10)
            plantPcTxx50.append(curPcPredTxx50)
            plantPcTxx90.append(curPcPredTxx90)
        
        if w==0:
            annualTx.append(np.array(curAnnualTx))
            annualTxx.append(np.array(curAnnualTxx))
        
        pCapTx10[w].append(np.array(plantPcTx10))
        pCapTx50[w].append(np.array(plantPcTx50))
        pCapTx90[w].append(np.array(plantPcTx90))
        
        pCapTxx10[w].append(plantPcTxx10)
        pCapTxx50[w].append(plantPcTxx50)
        pCapTxx90[w].append(plantPcTxx90)
            

pCapTx10 = np.array(pCapTx10)
pCapTx50 = np.array(pCapTx50)
pCapTx90 = np.array(pCapTx90)

pCapTxx10 = np.array(pCapTxx10)
pCapTxx50 = np.array(pCapTxx50)
pCapTxx90 = np.array(pCapTxx90)

pcChg = {'pCapTx10':pCapTx10, 'pCapTx50':pCapTx50, 'pCapTx90':pCapTx90, \
         'pCapTxx10':pCapTxx10, 'pCapTxx50':pCapTxx50, 'pCapTxx90':pCapTxx90}
with open('plantPcChange.dat', 'wb') as f:
    pickle.dump(pcChg, f)


pcTx10 = np.squeeze(np.nanmean(pCapTx10[0,:,:], axis=0))
pcTx50 = np.squeeze(np.nanmean(pCapTx50[0,:,:], axis=0))
pcTx90 = np.squeeze(np.nanmean(pCapTx90[0,:,:], axis=0))

pcTxx10 = np.squeeze(np.nanmean(pCapTxx10[0,:,:], axis=0))
pcTxx50 = np.squeeze(np.nanmean(pCapTxx50[0,:,:], axis=0))
pcTxx90 = np.squeeze(np.nanmean(pCapTxx90[0,:,:], axis=0))

xd = np.array(list(range(1981, 2018+1)))-1981+1

z = np.polyfit(xd, pcTx10, 1)
histPolyTx10 = np.poly1d(z)
z = np.polyfit(xd, pcTx50, 1)
histPolyTx50 = np.poly1d(z)
z = np.polyfit(xd, pcTx90, 1)
histPolyTx90 = np.poly1d(z)

z = np.polyfit(xd, pcTxx10, 1)
histPolyTxx10 = np.poly1d(z)
z = np.polyfit(xd, pcTxx50, 1)
histPolyTxx50 = np.poly1d(z)
z = np.polyfit(xd, pcTxx90, 1)
histPolyTxx90 = np.poly1d(z)


plt.figure(figsize=(4,4))
plt.xlim([0, 105])
plt.ylim([93,96])
plt.grid(True)

plt.plot(xd, histPolyTxx10(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8)
p2 = plt.plot(xd, histPolyTxx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8, label='TXx')
plt.plot(xd, histPolyTxx90(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8)

plt.plot([55, 70, 85, 100], \
         [np.nanmean(np.nanmean(pCapTxx10[1,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx10[2,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx10[3,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx10[4,:,:], axis=1), axis=0)], \
          'o', markersize=7, color=cmx.tab20(6))

plt.plot([55, 70, 85, 100], \
         [np.nanmean(np.nanmean(pCapTxx50[1,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx50[2,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx50[3,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx50[4,:,:], axis=1), axis=0)], \
          'o', markersize=7, color='black')

plt.plot([55, 70, 85, 100], \
         [np.nanmean(np.nanmean(pCapTxx90[1,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx90[2,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx90[3,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx90[4,:,:], axis=1), axis=0)], \
          'o', markersize=7, color=cmx.tab20(0))

plt.plot([37,37], [90,100], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 37, 55, 70, 85, 100])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

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

sys.exit()











if plotFigs:
    plt.savefig('hist-pp-chg-over-time.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.figure(figsize=(1,4))
plt.grid(True)

ychg = [np.nanmean(np.squeeze(pCapTxx50[0,:,32:]-pCapTxx50[0,:,0:5]), axis=1)]

medianprops = dict(linestyle='-', linewidth=2, color='black')
meanpointprops = dict(marker='D', markeredgecolor='black',
                      markerfacecolor='red', markersize=5)
bplot = plt.boxplot(ychg, showmeans=True, sym='.', patch_artist=True, \
                    medianprops=medianprops, meanprops=meanpointprops, zorder=0)

colors = ['lightgray']
for patch in bplot['boxes']:
    patch.set_facecolor([.75, .75, .75])

plt.plot([0,2], [0,0], '--', color='black')

plt.gca().set_xticks([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.ylabel('Plant capacity change (% pts)', fontname = 'Helvetica', fontsize=16)



if plotFigs:
    plt.savefig('hist-pp-chg-boxplot.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)




