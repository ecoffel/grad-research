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

yearRange = [1981, 2018]

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


# load historical temp data for all plants in US and EU
fileNamePlantLatLon = 'entsoe-nuke-lat-lon.csv'
plantList = np.genfromtxt(fileNamePlantLatLon, delimiter=',', skip_header=0)
plantList = plantList[:,0]


fileNameTemp = 'entsoe-nuke-pp-tx-all.csv'
plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,:].copy()
plantMonthData = plantTxData[1,:].copy()
plantDayData = plantTxData[2,:].copy()
plantTxData = plantTxData[3:,:].copy()

summerInd = np.where((plantMonthData == 7) | (plantMonthData == 8))[0]
plantMeanTemps = np.nanmean(plantTxData[:,summerInd], axis=1)

# load historical runoff data for all plants in US and EU
fileNameRunoff = 'entsoe-nuke-pp-runoff-anom-all.csv'
plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
plantQsAnomData = plantQsData[3:,:].copy()

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

for p in range(len(plantList)):
    
    plantPcTx10 = []
    plantPcTx50 = []
    plantPcTx90 = []
    
    plantPcTxx10 = []
    plantPcTxx50 = []
    plantPcTxx90 = []
    
    indTxMean = np.where((plantMonthData >= 7) & (plantMonthData <= 8))[0]
    txMean = np.nanmean(plantTxData[p, indTxMean])
    
    tx = plantTxData[p, :]
    qs = plantQsAnomData[p, :]
    
    for year in range(yearRange[0], yearRange[1]+1):

        ind = np.where((plantYearData == year) & (plantMonthData >= 7) & (plantMonthData <= 8))[0]
        
        curTx = tx[ind]
        curQs = qs[ind]
        
        nn = np.where(~np.isnan(curTx))[0]
        
        if len(nn) == 0:
            plantPcTx10.append(np.nan)
            plantPcTx50.append(np.nan)
            plantPcTx90.append(np.nan)
            
            plantPcTxx10.append(np.nan)
            plantPcTxx50.append(np.nan)
            plantPcTxx90.append(np.nan)
            
            continue
        
        curTx = curTx[nn]
        curQs = curQs[nn]
        
        # calculate 90th tx percentile in this year
        txPrc90 = np.nanpercentile(curTx, 90)
        
        # ind of the txx day in this year
        indTxx = np.where(curTx == np.nanmax(curTx))[0][0]
        
        # inds where tx is > 90th percentile in this year
        indTx90 = np.where(curTx > txPrc90)[0]
        
        curTxx = curTx[indTxx]
        curQsTxx = curQs[indTxx]
        
        curTxPrc90 = curTx[indTx90]
        curQsPrc90 = curQs[indTx90]
        
        curPcPred10 = []
        curPcPred50 = []
        curPcPred90 = []
        
        for i in range(len(curTxPrc90)):
            
            t = curTxPrc90[i]
            q = curQsPrc90[i]
            
            curDayPc10 = pcModel10.predict([1, t, t**2, t**3, \
                                                 q, q**2, q**3, q**4, q**5, q*t, plantList[p]])[0]
            curDayPc50 = pcModel50.predict([1, t, t**2, t**3, \
                                                 q, q**2, q**3, q**4, q**5, q*t, plantList[p]])[0]
            curDayPc90 = pcModel90.predict([1, t, t**2, t**3, \
                                                 q, q**2, q**3, q**4, q**5, q*t, plantList[p]])[0]
            if curDayPc10 > 100: curDayPc10 = 100
            if curDayPc50 > 100: curDayPc50 = 100
            if curDayPc90 > 100: curDayPc90 = 100
            
            curPcPred10.append(curDayPc10)
            curPcPred50.append(curDayPc50)
            curPcPred90.append(curDayPc90)
        
        curPcPredTxx10 = pcModel10.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                 curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, curTxx*curQsTxx, plantList[p]])[0]
        curPcPredTxx50 = pcModel50.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                 curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, curTxx*curQsTxx, plantList[p]])[0]
        curPcPredTxx90 = pcModel90.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                 curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, curTxx*curQsTxx, plantList[p]])[0]
        if curPcPredTxx10 > 100: curPcPredTxx10 = 100
        if curPcPredTxx50 > 100: curPcPredTxx50 = 100
        if curPcPredTxx90 > 100: curPcPredTxx90 = 100
                    
        plantPcTx10.append(np.nanmean(curPcPred50))
        plantPcTx50.append(np.nanmean(curPcPred50))
        plantPcTx90.append(np.nanmean(curPcPred90))
        
        plantPcTxx10.append(curPcPredTxx10)
        plantPcTxx50.append(curPcPredTxx50)
        plantPcTxx90.append(curPcPredTxx90)
    
    pCapTx10.append(np.array(plantPcTx10))
    pCapTx50.append(np.array(plantPcTx50))
    pCapTx90.append(np.array(plantPcTx90))
    
    pCapTxx10.append(plantPcTxx10)
    pCapTxx50.append(plantPcTxx50)
    pCapTxx90.append(plantPcTxx90)
            

pCapTx10 = np.array(pCapTx10)
pCapTx50 = np.array(pCapTx50)
pCapTx90 = np.array(pCapTx90)

pCapTxx10 = np.array(pCapTxx10)
pCapTxx50 = np.array(pCapTxx50)
pCapTxx90 = np.array(pCapTxx90)

#pcChg = {'pCapTx10':pCapTx10, 'pCapTx50':pCapTx50, 'pCapTx90':pCapTx90, \
#         'pCapTxx10':pCapTxx10, 'pCapTxx50':pCapTxx50, 'pCapTxx90':pCapTxx90}
#with open('plantPcChange.dat', 'wb') as f:
#    pickle.dump(pcChg, f)

pcTxx10 = np.squeeze(np.nanmean(pCapTxx10, axis=0))
pcTxx50 = np.squeeze(np.nanmean(pCapTxx50, axis=0))
pcTxx90 = np.squeeze(np.nanmean(pCapTxx90, axis=0))





# load future mean warming data and recompute PC
pCapTxxFutMeanWarming10 = []
pCapTxxFutMeanWarming50 = []
pCapTxxFutMeanWarming90 = []

for w in range(1, 4+1):
    pCapTxxFutCurGMT10 = []
    pCapTxxFutCurGMT50 = []
    pCapTxxFutCurGMT90 = []
    
    for m in range(len(models)):
        
        pCapTxxFutCurModel10 = []
        pCapTxxFutCurModel50 = []
        pCapTxxFutCurModel90 = []
        
        # load data for current model and warming level
        fileNameTemp = 'gmt-anomaly-temps/us-eu-pp-%ddeg-tx-cmip5-%s.csv'%(w, models[m])
    
        if not os.path.isfile(fileNameTemp):
            # add a nan for each plant in current model
            filler = []
            for p in range(90):
                filler.append(np.nan)
            pCapTxxFutCurGMT10.append(filler)
            pCapTxxFutCurGMT50.append(filler)
            pCapTxxFutCurGMT90.append(filler)
            continue
    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        if len(plantTxData) == 0:
            # add a nan for each plant in current model
            filler = []
            for p in range(90):
                filler.append(np.nan)
            pCapTxxFutCurGMT10.append(filler)
            pCapTxxFutCurGMT50.append(filler)
            pCapTxxFutCurGMT90.append(filler)
            continue
        
        plantTxYearData = plantTxData[0,0:].copy()
        plantTxMonthData = plantTxData[1,0:].copy()
        plantTxDayData = plantTxData[2,0:].copy()
        plantTxData = plantTxData[3:,0:].copy()
        
        fileNameRunoff = 'gmt-anomaly-temps/us-eu-pp-%ddeg-runoff-cmip5-%s.csv'%(w, models[m])
        
        plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
        plantQsYearData = plantQsData[0,0:].copy()
        plantQsMonthData = plantQsData[1,0:].copy()
        plantQsDayData = plantQsData[2,0:].copy()
        plantQsData = plantQsData[3:,0:].copy()
        
        # loop over all plants
        for p in range(plantTxData.shape[0]):
            
            plantPcTxx10 = []
            plantPcTxx50 = []
            plantPcTxx90 = []
            
            # tx for current plant
            tx = plantTxData[p, :]
            qs = plantQsAnomData[p, :]
            
            # loop over all years for current model/GMT anomaly
            for year in range(int(min(plantTxYearData)), int(max(plantTxYearData))+1):
        
                # tx for current year's summer
                ind = np.where((plantTxYearData == year) & (plantTxMonthData >= 7) & (plantTxMonthData <= 8))[0]
                
                curTx = tx[ind]
                curQs = qs[ind]
                
                nn = np.where(~np.isnan(curTx))[0]
                
                if len(nn) == 0:
                    plantPcTx10.append(np.nan)
                    plantPcTx50.append(np.nan)
                    plantPcTx90.append(np.nan)
                    
                    plantPcTxx10.append(np.nan)
                    plantPcTxx50.append(np.nan)
                    plantPcTxx90.append(np.nan)
                    continue
                
                curTx = curTx[nn]
                curQs = curQs[nn]
                
                # ind of the txx day in this year
                indTxx = np.where(curTx == np.nanmax(curTx))[0][0]
                
                curTxx = curTx[indTxx]
                curQsTxx = curQs[indTxx]
                
                curPcPred10 = []
                curPcPred50 = []
                curPcPred90 = []
                
                curPcPredTxx10 = pcModel10.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                         curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, curTxx*curQsTxx, plantList[p]])[0]
                curPcPredTxx50 = pcModel50.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                         curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, curTxx*curQsTxx, plantList[p]])[0]
                curPcPredTxx90 = pcModel90.predict([1, curTxx, curTxx**2, curTxx**3, \
                                                         curQsTxx, curQsTxx**2, curQsTxx**3, curQsTxx**4, curQsTxx**5, curTxx*curQsTxx, plantList[p]])[0]
                
                if curPcPredTxx10 > 100: curPcPredTxx10 = 100
                if curPcPredTxx50 > 100: curPcPredTxx50 = 100
                if curPcPredTxx90 > 100: curPcPredTxx90 = 100
                     
                plantPcTxx10.append(curPcPredTxx10)
                plantPcTxx50.append(curPcPredTxx50)
                plantPcTxx90.append(curPcPredTxx90)
            
            pCapTxxFutCurModel10.append(np.nanmean(plantPcTxx10))
            pCapTxxFutCurModel50.append(np.nanmean(plantPcTxx50))
            pCapTxxFutCurModel90.append(np.nanmean(plantPcTxx90))
        
        pCapTxxFutCurGMT10.append(pCapTxxFutCurModel10)
        pCapTxxFutCurGMT50.append(pCapTxxFutCurModel50)
        pCapTxxFutCurGMT90.append(pCapTxxFutCurModel90)
    
    pCapTxxFutMeanWarming10.append(pCapTxxFutCurGMT10)
    pCapTxxFutMeanWarming50.append(pCapTxxFutCurGMT50)
    pCapTxxFutMeanWarming90.append(pCapTxxFutCurGMT90)


pCapTxxFutMeanWarming10 = np.array(pCapTxxFutMeanWarming10)
pCapTxxFutMeanWarming50 = np.array(pCapTxxFutMeanWarming50)
pCapTxxFutMeanWarming90 = np.array(pCapTxxFutMeanWarming90)


xd = np.array(list(range(1981, 2018+1)))-1981+1

z = np.polyfit(xd, pcTxx10, 1)
histPolyTxx10 = np.poly1d(z)
z = np.polyfit(xd, pcTxx50, 1)
histPolyTxx50 = np.poly1d(z)
z = np.polyfit(xd, pcTxx90, 1)
histPolyTxx90 = np.poly1d(z)

xpos = np.array([65, 90, 115, 140])

plt.figure(figsize=(6,4))
plt.xlim([0, 155])
plt.ylim([91, 99])
plt.grid(True)

plt.plot(xd, histPolyTxx10(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8, label='90th Percentile')
plt.plot(xd, histPolyTxx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8, label='50th Percentile')
plt.plot(xd, histPolyTxx90(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8, label='10th Percentile')

plt.plot(xpos-5, \
         np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1), \
          'o', markersize=5, color=cmx.tab20(6))

plt.errorbar(xpos-5, \
             np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1), \
             yerr = [np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1)-np.nanmin(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1), \
                     np.nanmax(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1)-np.nanmean(np.nanmean(pCapTxxFutMeanWarming10,axis=2),axis=1)], \
             ecolor = cmx.tab20(6), elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos, \
         np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1), \
          'o', markersize=5, color='black')

plt.errorbar(xpos, \
             np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1), \
             yerr = [np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1)-np.nanmin(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1), \
                     np.nanmax(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1)-np.nanmean(np.nanmean(pCapTxxFutMeanWarming50,axis=2),axis=1)], \
             ecolor = 'black', elinewidth = 1, capsize = 3, fmt = 'none')


plt.plot(xpos+5, \
         np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1), \
          'o', markersize=5, color=cmx.tab20(0))

plt.errorbar(xpos+5, \
             np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1), \
             yerr = [np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1)-np.nanmin(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1), \
                     np.nanmax(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1)-np.nanmean(np.nanmean(pCapTxxFutMeanWarming90,axis=2),axis=1)], \
             ecolor = cmx.tab20(0), elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot([38,38], [88,100], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, xpos[0], xpos[1], xpos[2], xpos[3]])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

plt.yticks(range(91, 100, 2))

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

if plotFigs:
    plt.savefig('pp-chg-hist-mean-warming.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

sys.exit()








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




