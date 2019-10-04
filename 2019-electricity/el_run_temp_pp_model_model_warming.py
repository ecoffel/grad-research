# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import scipy.stats as st
import pickle, gzip
import sys, os


#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False
dumpData = True

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

qstr = '-qdistfit-gamma'

yearRange = [1981, 2005]
decades = np.array([[2020,2029],\
                   [2030, 2039],\
                   [2040,2049],\
                   [2050,2059],\
                   [2060,2069],\
                   [2070,2079],\
                   [2080,2089]])

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('E:/data/ecoffel/data/projects/electricity/script-data/pPolyData-%s-pow2.dat'%runoffData, 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]

baseTx = 27
baseQs = 0

basePred10 = pcModel10.predict([1, baseTx, baseTx**2, \
                                  baseQs, baseQs**2, \
                                  baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                                  0])[0]
basePred50 = pcModel50.predict([1, baseTx, baseTx**2, \
                              baseQs, baseQs**2, \
                              baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                              0])[0]
basePred90 = pcModel90.predict([1, baseTx, baseTx**2, \
                              baseQs, baseQs**2, \
                              baseTx*baseQs, (baseTx**2)*(baseQs**2), \
                              0])[0]



#fileNameTemp = 'E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-tx.csv'%plantData
#plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
#plantYearData = plantTxData[0,:].copy()
#plantMonthData = plantTxData[1,:].copy()
#plantDayData = plantTxData[2,:].copy()
#plantTxData = plantTxData[3:,:].copy()

#summerInd = np.where((plantMonthData == 7) | (plantMonthData == 8))[0]
#plantMeanTemps = np.nanmean(plantTxData[:,summerInd], axis=1)

# load historical runoff data for all plants in US and EU
fileNameRunoff = 'E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff.csv'%plantData
fileNameRunoffDistFit = 'E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff%s.csv'%(plantData, qstr)
fileNameRunoffMeansDistFit = 'E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff-means%s.csv'%(plantData, qstr)
fileNameRunoffStdsDistFit = 'E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-runoff-stds%s.csv'%(plantData, qstr)

if os.path.isfile(fileNameRunoffDistFit):
#    plantQsData = np.genfromtxt(fileNameRunoffDistFit, delimiter=',', skip_header=0)
    plantQsMeans = np.genfromtxt(fileNameRunoffMeansDistFit, delimiter=',', skip_header=0)
    plantQsStds = np.genfromtxt(fileNameRunoffStdsDistFit, delimiter=',', skip_header=0)
    
else:
    plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)
    plantQsData = plantQsData[3:,:]
    
    plantQsMeans = []
    plantQsStds = []
    
    print('calculating historical qs distfit anomalies')
    plantQsAnomData = []
    dist = st.gamma
    for p in range(plantQsData.shape[0]):
        if p%1000 == 0:
            print('plant %d...'%p)
        q = plantQsData[p,:]
        nn = np.where(~np.isnan(q))[0]
        if len(nn) > 10:
            args = dist.fit(q[nn])
            curQsStd = dist.std(*args)
        else:
            curQsStd = np.nan
        plantQsAnomData.append((q-np.nanmean(q))/curQsStd)
        plantQsMeans.append(np.nanmean(q))
        plantQsStds.append(curQsStd)
    plantQsAnomData = np.array(plantQsAnomData)
    plantQsMeans = np.array(plantQsMeans)
    plantQsStds = np.array(plantQsStds)
    
    np.savetxt(fileNameRunoffDistFit, plantQsAnomData, delimiter=',')
    np.savetxt(fileNameRunoffMeansDistFit, plantQsMeans, delimiter=',')
    np.savetxt(fileNameRunoffStdsDistFit, plantQsStds, delimiter=',')
    plantQsData = plantQsAnomData
    

# load historical pc for txx days
with open('E:/data/ecoffel/data/projects/electricity/script-data/pc-change-hist-%s-%s-%s.dat'%(plantData, runoffData, qstr), 'rb') as f:
    pcChg = pickle.load(f)


plantPcTxx10 = []
plantPcTxx50 = []
plantPcTxx90 = []

for m in range(len(models)):
    
    plantPcTxx10CurModel = []
    plantPcTxx50CurModel = []
    plantPcTxx90CurModel = []
    
    for d in range(decades.shape[0]):
    
        print('processing %s/%d...'%(models[m], decades[d,0]))
        
        fileNameTemp = 'E:/data/ecoffel/data/projects/electricity/future-temps/%s-pp-rcp85-txx-cmip5-%s-%d-%d.csv'%(plantData, models[m], decades[d,0], decades[d,1])    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        
        fileNameRunoff = 'E:/data/ecoffel/data/projects/electricity/future-temps/%s-pp-rcp85-runoff-at-txx-cmip5-%s-%d-%d.csv'%(plantData, models[m], decades[d,0], decades[d,1])        
        plantQsData = np.genfromtxt(fileNameRunoff, delimiter=',', skip_header=0)

        plantPcTxx10CurDecade = []
        plantPcTxx50CurDecade = []
        plantPcTxx90CurDecade = []

        for p in range(plantTxData.shape[0]):
                        
            plantPcTxx10CurPlant = []
            plantPcTxx50CurPlant = []
            plantPcTxx90CurPlant = []    
            
            tx = plantTxData[p, :]
            # calc runoff anom for this plant based on previously loaded historical stats
            qs = (plantQsData[p, :]-plantQsMeans[p])/plantQsStds[p]
            
            qs[qs < -5] = np.nan
            qs[qs > 5] = np.nan
            
            for y in range(tx.shape[0]):
        
                # txx value and corresponding qs for current year
                curTxx = tx[y]
                curQsTxx = qs[y]
                
                if np.isnan(curTxx) or np.isnan(curQsTxx):
                    plantPcTxx10CurPlant.append(np.nan)
                    plantPcTxx50CurPlant.append(np.nan)
                    plantPcTxx90CurPlant.append(np.nan)
                    continue
                
                if curTxx > baseTx:
                    curPcPredTxx10 = pcModel10.predict([1, curTxx, curTxx**2, \
                                                             curQsTxx, curQsTxx**2, \
                                                             curTxx*curQsTxx, (curTxx**2)*(curQsTxx**2), 0])[0] - basePred10
                    curPcPredTxx50 = pcModel50.predict([1, curTxx, curTxx**2, \
                                                             curQsTxx, curQsTxx**2, \
                                                             curTxx*curQsTxx, (curTxx**2)*(curQsTxx**2), 0])[0] - basePred50
                    curPcPredTxx90 = pcModel90.predict([1, curTxx, curTxx**2, \
                                                             curQsTxx, curQsTxx**2, \
                                                             curTxx*curQsTxx, (curTxx**2)*(curQsTxx**2), 0])[0] - basePred90
                else:
                    curPcPredTxx10 = 0
                    curPcPredTxx50 = 0
                    curPcPredTxx90 = 0
                    
                if curPcPredTxx10 > 100: curPcPredTxx10 = 0
                if curPcPredTxx50 > 100: curPcPredTxx50 = 0
                if curPcPredTxx90 > 100: curPcPredTxx90 = 0
                
                if curPcPredTxx10 < -100: curPcPredTxx10 = -100
                if curPcPredTxx50 < -100: curPcPredTxx50 = -100
                if curPcPredTxx90 < -100: curPcPredTxx90 = -100
                
                plantPcTxx10CurPlant.append(curPcPredTxx10)
                plantPcTxx50CurPlant.append(curPcPredTxx50)
                plantPcTxx90CurPlant.append(curPcPredTxx90)
            
            plantPcTxx10CurDecade.append(plantPcTxx10CurPlant)
            plantPcTxx50CurDecade.append(plantPcTxx50CurPlant)
            plantPcTxx90CurDecade.append(plantPcTxx90CurPlant)
        
        plantPcTxx10CurModel.append(plantPcTxx10CurDecade)
        plantPcTxx50CurModel.append(plantPcTxx50CurDecade)
        plantPcTxx90CurModel.append(plantPcTxx90CurDecade)
    
    plantPcTxx10.append(plantPcTxx10CurModel)
    plantPcTxx50.append(plantPcTxx50CurModel)
    plantPcTxx90.append(plantPcTxx90CurModel)

plantPcTxx10 = np.array(plantPcTxx10)
plantPcTxx50 = np.array(plantPcTxx50)
plantPcTxx90 = np.array(plantPcTxx90)

if dumpData:
    pcChg = {'pCapTxxFutRcp8510':plantPcTxx10, \
             'pCapTxxFutRcp8550':plantPcTxx50, \
             'pCapTxxFutRcp8590':plantPcTxx90}
    with open('E:/data/ecoffel/data/projects/electricity/script-data/pc-change-fut-%s-%s-%s-rcp85.dat'%(plantData, runoffData, qstr), 'wb') as f:
        pickle.dump(pcChg, f)












sys.exit()

#pcChg = {'pCapTx10':pCapTx10, 'pCapTx50':pCapTx50, 'pCapTx90':pCapTx90, \
#         'pCapTxx10':pCapTxx10, 'pCapTxx50':pCapTxx50, 'pCapTxx90':pCapTxx90}
#with open('plantPcChange.dat', 'wb') as f:
#    pickle.dump(pcChg, f)


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

plt.plot([38,38], [90,100], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, 55, 70, 85, 100])
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







