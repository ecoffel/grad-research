# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import el_temp_pp_model
import pickle
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

smoothingLen = 4

#regr, mdl = el_temp_pp_model.buildLinearTempPPModel()
if not 'pPoly3' in locals():
    zPoly3, pPoly3 = el_temp_pp_model.buildPolyTempPPModel('txSummer', 1000, 3)

#globalPlants = el_load_global_plants.loadGlobalPlants()

yearRange = [1981, 2018]
# load wx data for global plants
fileName = 'entsoe-nuke-pp-tx-era.csv'

plantList = []
with open(fileName, 'r') as f:
    i = 0
    for line in f:
        if i >= 3:
            parts = line.split(',')
            plantList.append(parts[0])
        i += 1
plantTxData = np.genfromtxt(fileName, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,1:].copy()
plantMonthData = plantTxData[1,1:].copy()
plantDayData = plantTxData[2,1:].copy()
plantTxData = plantTxData[3:,1:].copy()


# unpack polyfit coefs into lists
(p1,p2,p3,p4) = zip(*[(p[0], p[1], p[2], p[3]) for p in pPoly3])
p1 = np.array(p1)
p2 = np.array(p2)
p3 = np.array(p3)
p4 = np.array(p4)

pSel = p4

# find percentiles for quadratic coef
pPoly10 = np.percentile(pSel, 10)
pPoly50 = np.percentile(pSel, 50)
pPoly90 = np.percentile(pSel, 90)

indPoly10 = np.where(abs(pSel-pPoly10) == np.nanmin(abs(pSel-pPoly10)))[0]
indPoly50 = np.where(abs(pSel-pPoly50) == np.nanmin(abs(pSel-pPoly50)))[0]
indPoly90 = np.where(abs(pSel-pPoly90) == np.nanmin(abs(pSel-pPoly90)))[0]



xd = np.linspace(20, 50, 200)
yPolyAll = np.array([pPoly3[i](xd) for i in range(len(pPoly3))])
yPolyd10 = np.array(pPoly3[indPoly10[0]](xd))
yPolyd50 = np.array(pPoly3[indPoly50[0]](xd))
yPolyd90 = np.array(pPoly3[indPoly90[0]](xd))

plt.figure(figsize=(4,4))
plt.xlim([19, 51])
plt.ylim([75, 100])
plt.grid(True)

plt.plot(xd, yPolyAll.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)
p1 = plt.plot(xd, yPolyd10, '-', linewidth = 2.5, color = cmx.tab20(6), label='90th Percentile')
p2 = plt.plot(xd, yPolyd50, '-', linewidth = 2.5, color = [0, 0, 0], label='50th Percentile')
p3 = plt.plot(xd, yPolyd90, '-', linewidth = 2.5, color = cmx.tab20(0), label='10th Percentile')

plt.gca().set_xticks(range(20, 51, 5))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'})
leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-temp-regression-perc.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

pCapTx10 = []
pCapTx50 = []
pCapTx90 = []

pCapTxx10 = []
pCapTxx50 = []
pCapTxx90 = []

warming = [0,1,2,3,4]

for w in range(len(warming)):
    pCapTx10.append([])
    pCapTx50.append([])
    pCapTx90.append([])
    
    pCapTxx10.append([])
    pCapTxx50.append([])
    pCapTxx90.append([])
    
    for p in range(len(plantList)):
        pCapTx10[w].append([])    
        pCapTx50[w].append([])    
        pCapTx90[w].append([])    
        
        pCapTxx10[w].append([])    
        pCapTxx50[w].append([])    
        pCapTxx90[w].append([])    
        
        indTxMean = np.where((plantMonthData >= 7) & (plantMonthData <= 8))[0]
        txMean = np.nanmean(plantTxData[p, indTxMean])
        
        tx = plantTxData[p, :]
        
        txAvg = []
        for d in range(len(tx)):
            if d > (smoothingLen-1):
                txAvg.append(np.nanmean(tx[d-(smoothingLen-1):d+1]))
            else:
                txAvg.append(np.nan)
        txAvg = np.array(txAvg)
        
        for year in range(yearRange[0], yearRange[1]):
            ind = np.where((plantYearData == year) & (plantMonthData >= 7) & (plantMonthData <= 8))[0]
    #        ind = np.where((plantYearData == year))[0]
            
            curTxAvg = txAvg[ind] + warming[w]
            curTx = tx[ind] + warming[w]
            
            nn = np.where(~np.isnan(curTxAvg))[0]
            
            if len(nn) == 0:
                pCapTx10[w][p].append(np.nan)
                pCapTx10[w][p].append(np.nan)
                pCapTx10[w][p].append(np.nan)
                
                pCapTxx10[w][p].append(np.nan)
                pCapTxx10[w][p].append(np.nan)
                pCapTxx10[w][p].append(np.nan)
                continue
            
            curTxAvg = curTxAvg[nn]
            curTx = curTx[nn]
            curTxx = np.nanmax(curTx[nn])
            
            pCapTx10[w][p].append(np.nanmean(pPoly3[indPoly10[0]](curTx)))
            pCapTx50[w][p].append(np.nanmean(pPoly3[indPoly50[0]](curTx)))
            pCapTx90[w][p].append(np.nanmean(pPoly3[indPoly90[0]](curTx)))
            
            pCapTxx10[w][p].append(np.nanmean(pPoly3[indPoly10[0]](curTxx)))
            pCapTxx50[w][p].append(np.nanmean(pPoly3[indPoly50[0]](curTxx)))
            pCapTxx90[w][p].append(np.nanmean(pPoly3[indPoly90[0]](curTxx)))
            
    #        caps.append(np.nanmean(regr.predict(tx)))
    #        caps.append(np.nanmean(pPoly3(np.array(list(set(zip(tx)))))))
            
    

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

sys.exit()

pcTx10 = np.squeeze(np.nanmean(pCapTx10[0,:,:], axis=0))
pcTx50 = np.squeeze(np.nanmean(pCapTx50[0,:,:], axis=0))
pcTx90 = np.squeeze(np.nanmean(pCapTx90[0,:,:], axis=0))

pcTxx10 = np.squeeze(np.nanmean(pCapTxx10[0,:,:], axis=0))
pcTxx50 = np.squeeze(np.nanmean(pCapTxx50[0,:,:], axis=0))
pcTxx90 = np.squeeze(np.nanmean(pCapTxx90[0,:,:], axis=0))


xd = np.array(list(range(1981, 2018)))-1981+1

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
plt.ylim([93.5,96.5])
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




