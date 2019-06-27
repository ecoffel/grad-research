# -*- coding: utf-8 -*-
"""
Created on Wed Jun 26 15:19:34 2019

@author: Ethan
"""

import matplotlib.pyplot as plt 
import matplotlib.cm as cmx
import seaborn as sns
import numpy as np
import pandas as pd
import pickle, gzip
import sys, os
import el_load_global_plants

plotFigs = False


globalPlants = el_load_global_plants.loadGlobalPlants()


with gzip.open('demand-projections.dat', 'rb') as f:
    demData = pickle.load(f)    
    demHist = demData['demHist']
    demProj = demData['demProj']
    demMult = demData['demMult']
    demByMonth = demData['demByMonthHist']
    demByMonthFut = demData['demByMonthFut']



with gzip.open('pc-change-gmt-change.dat', 'rb') as f:    
    pcChg = pickle.load(f)
    
    pCapTxxFutMeanWarming10 = pcChg['pCapTxxFutMeanWarming10']
    pCapTxxFutMeanWarming50 = pcChg['pCapTxxFutMeanWarming50']
    pCapTxxFutMeanWarming90 = pcChg['pCapTxxFutMeanWarming90']
    
    pcTxx10 = pcChg['pcTxx10']
    pcTxx50 = pcChg['pcTxx50']
    pcTxx90 = pcChg['pcTxx90']

pcDiff10 = np.nanmean(pCapTxxFutMeanWarming10, axis=2) - np.nanmean(pcTxx10)
pcDiff50 = np.nanmean(pCapTxxFutMeanWarming50, axis=2) - np.nanmean(pcTxx50)
pcDiff90 = np.nanmean(pCapTxxFutMeanWarming90, axis=2) - np.nanmean(pcTxx90)

demDiff = np.nanmax(demProj, axis=2) - np.nanmax(demHist)
demDiffPct = 100*(np.nanmax(demProj, axis=2) - np.nanmax(demHist))/np.nanmax(demHist)

additionalGenGrowth10 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff10/100)) - np.nanmax(demHist))/demDiff)-100
additionalGenGrowth50 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff50/100)) - np.nanmax(demHist))/demDiff)-100
additionalGenGrowth90 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff90/100)) - np.nanmax(demHist))/demDiff)-100

additionalGen10 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff10/100)) - np.nanmax(demHist))/np.nanmax(demHist))
additionalGen50 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff50/100)) - np.nanmax(demHist))/np.nanmax(demHist))
additionalGen90 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff90/100)) - np.nanmax(demHist))/np.nanmax(demHist))



snsColors = sns.color_palette(["#3498db", "#e74c3c"])


plt.figure(figsize=(2,4))
plt.xlim([.5, 4.5])
plt.ylim([0, 24])
plt.grid(True, color=[.9,.9,.9])
plt.plot(range(1,5), np.nanmean(demDiffPct,axis=1), 'o', color = snsColors[0], label='Warming')
plt.plot(range(1,5), np.nanmean(additionalGen10,axis=1), 'o', color = snsColors[1], label='Warming & curtailment')

yax = np.arange(0, 25, 3)

plt.xticks(range(1,5))
plt.yticks(yax)
plt.ylabel('Generation growth (%)', fontname = 'Helvetica', fontsize=16)
plt.xlabel('GMT Change', fontname = 'Helvetica', fontsize=16)
plt.gca().set_xticklabels(['1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#leg = plt.legend(prop = {'size':12, 'family':'Helvetica'})
#leg.get_frame().set_linewidth(0.0)

ax2 = plt.twinx()
plt.ylim([0, 24])
plt.ylabel('Generation growth (GW)', fontname = 'Helvetica', fontsize=16)
plt.yticks(yax)
plt.gca().set_yticklabels([int(x) for x in np.round(yax/100 * np.nansum(globalPlants['caps']) / 1e3)])

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)



plt.figure(figsize=(2,4))
plt.grid(True, color=[.9,.9,.9])
plt.plot(range(1,5), np.nanmean(additionalGenGrowth10,axis=1))

plt.ylabel('Generation growth (%)', fontname = 'Helvetica', fontsize=16)
plt.xticks(range(1,5))





