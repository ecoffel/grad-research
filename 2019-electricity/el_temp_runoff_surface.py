# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 15:40:40 2019

@author: Ethan
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn import linear_model
import statsmodels.api as sm
import el_build_temp_pp_model
import gzip, pickle

plotFigs = False

tempVar = 'txSummer'
qsVar = 'qsGrdcAnomSummer'

# load historical weather data for plants to compute mean temps 
# to display on bootstrap temp curve
fileName = 'E:/data/ecoffel/data/projects/electricity/script-data/entsoe-nuke-pp-tx.csv'
plantTxData = np.genfromtxt(fileName, delimiter=',', skip_header=0)
plantYearData = plantTxData[0,:].copy()
plantMonthData = plantTxData[1,:].copy()
plantDayData = plantTxData[2,:].copy()
plantTxData = plantTxData[3:,:].copy()


fileName = 'E:/data/ecoffel/data/projects/electricity/script-data/entsoe-nuke-pp-runoff-qdistfit-gamma.csv'
plantQsData = np.genfromtxt(fileName, delimiter=',', skip_header=0)


summerInd = np.where((plantMonthData == 7) | (plantMonthData == 8))[0]
plantMeanTemps = np.nanmean(plantTxData[:,summerInd], axis=1)
plantMeanRunoff = np.nanmean(plantQsData[:,summerInd], axis=1)

with gzip.open('E:/data/ecoffel/data/projects/electricity/script-data/ppFutureTxQsData.dat', 'rb') as f:
    ppFutureData = pickle.load(f)
    txHist = np.nanmean(np.nanmean(ppFutureData['txMonthlyMax'][:,[6,7]]))
    qsHist = np.nanmean(np.nanmean(ppFutureData['qsAnomMonthlyMean'][:,[6,7]]))
    tx2 = np.nanmean(np.nanmean(np.nanmean(ppFutureData['txMonthlyMaxFutGMT'][1,:,:,[6,7]])))
    tx4 = np.nanmean(np.nanmean(np.nanmean(ppFutureData['txMonthlyMaxFutGMT'][3,:,:,[6,7]])))
    qs2 = np.nanmean(np.nanmean(np.nanmean(ppFutureData['qsMonthlyMeanFutGMT'][1,:,:,[6,7]])))
    qs4 = np.nanmean(np.nanmean(np.nanmean(ppFutureData['qsMonthlyMeanFutGMT'][3,:,:,[6,7]])))

histPDF = []

qsrange = np.linspace(-4, 4.1, 25)
txrange = np.linspace(27, 51, 25)

for qs in qsrange:
    pdfrow = []
    for t in txrange:
        ind = np.where((plantTxData >= t-.5) & (plantTxData <= t+.5) & \
                       (plantQsData >= qs-.25) & (plantQsData <= qs+.25))[0]
        if len(ind) > 0:
            pdfrow.append(1)
        else:
            pdfrow.append(0)
    histPDF.append(pdfrow)
histPDF = np.array(histPDF)


models = el_build_temp_pp_model.buildNonlinearTempQsPPModel(tempVar, qsVar, 100)

yds = []

for m in range(len(models)):
    # current contour surface for this model
    curCont = []
    
    for q in range(len(qsrange)):
        
        yd = []    
        for t in range(len(txrange)):
            
            if histPDF[q,t] == 1:
                yd.append(models[m].predict([1, txrange[t], txrange[t]**2, \
                                            qsrange[q], qsrange[q]**2, \
                                            qsrange[q]*txrange[t], (qsrange[q]**2)*(txrange[t]**2), 0])[0])
            else:
                yd.append(np.nan)
        curCont.append(yd)
        
    yds.append(curCont)

yds = np.array(yds)
yds = np.squeeze(np.nanmedian(yds, axis=0))
yds[yds<75] = 75

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

                               
plt.contourf(txrange, qsrange, yds, levels=np.arange(85,100,.5), cmap = 'Reds_r')
cb = plt.colorbar()
cb.set_ticks(range(85,100,2))
plt.xlim([27,50])
plt.ylim([-4,4])
plt.plot([27, 50], [np.nanmean(plantMeanRunoff), np.nanmean(plantMeanRunoff)], '-k', lw=2)
plt.plot([txHist, txHist], [-4, 4], '-k', lw=2)

#for q in range(len(qsrange)):
#    for t in range(len(txrange)):
#        if histPDF[q, t] == 1:
#            plt.plot(txrange[t], qsrange[q], 'ok', markersize=1)

#plt.plot(txHist, qsHist, '+k', markersize=20, mew=4, lw=2)
plt.plot(tx2, qs2, '+k', markersize=20, mew=4, lw=2, color='#ffb835')
plt.plot(tx4, qs4, '+k', markersize=20, mew=4, lw=2, color=snsColors[1])

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Runoff anomaly (SD)', fontname = 'Helvetica', fontsize=16)
cb.set_label('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)
for tick in cb.ax.yaxis.get_ticklabels():
    tick.set_fontname('Helvetica')    
    tick.set_fontsize(14)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-%s-%s-regression-contour.eps'%(tempVar,qsVar), format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()


