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

# in twh over a year
# coal, gas, oil, nuke, bioenergy
iea2017 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7])
iea2025 = np.array([9896.2, 6828.9, 763.2, 3088.7, 890.4])
iea2030 = np.array([10015.9, 7517.4, 675.7, 3252.7, 1056.9])
iea2035 = np.array([10172.0, 8265.5, 597.3, 3520.0, 1238.2])
iea2040 = np.array([10335.1, 9070.6, 527.2, 3725.8, 1427.3])

ieaSust2017 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7])
ieaSust2025 = np.array([7193, 6810, 604, 3302, 1039])
ieaSust2030 = np.array([4847, 6829, 413, 3887, 1324])
ieaSust2035 = np.array([3050, 6254, 274, 4534, 1646])
ieaSust2040 = np.array([1981, 5358, 197, 4960, 1967])

# convert to EJ
iea2017 *= 3600 * 1e12 / 1e18
iea2025 *= 3600 * 1e12 / 1e18
iea2030 *= 3600 * 1e12 / 1e18
iea2035 *= 3600 * 1e12 / 1e18
iea2040 *= 3600 * 1e12 / 1e18

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

additionalGenPctPt10 = additionalGen10-demDiffPct
additionalGenPctPt50 = additionalGen50-demDiffPct
additionalGenPctPt90 = additionalGen90-demDiffPct

additionalGenGrowth10[additionalGenGrowth10<0] = np.nan

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

xpos = np.arange(1,5)

plt.figure(figsize=(3,4))
plt.xlim([.25, 5.25])
plt.ylim([0, 24])
plt.grid(True, color=[.9,.9,.9])
for i in range(demDiffPct.shape[0]):
    pp = np.nanmean(demDiffPct[i,:])
    
    if i == 0:
        labelLine = 'Warming'
    else:
        labelLine = None
    
    plt.plot([0, xpos[i]+.4], [pp, pp], '--', color = 'black', label=labelLine)

ydata90 = np.nanmean(additionalGen90,axis=1)
ydata50 = np.nanmean(additionalGen50,axis=1)
ydata10 = np.nanmean(additionalGen10,axis=1)
for x in range(len(xpos)):
    
    if x == 0:
        label10 = '10th Percentile'
        label50 = '50th Percentile'
        label90 = '90th Percentile'
    else:
        label10 = None
        label50 = None
        label90 = None
    
    l1 = plt.plot(xpos[x]-.25, ydata90[x], marker='o', markersize=8, color = snsColors[0], label=label10)
    l2 = plt.plot(xpos[x], ydata50[x], marker='o', markersize=8, color = 'black', label=label50)
    l3 = plt.plot(xpos[x]+.25, ydata10[x], marker='o', markersize=8, color = snsColors[1], label=label90)

yax = np.arange(0, 25, 3)

plt.xticks(range(1,5))
plt.yticks(yax)
plt.ylabel('Warming-driven growth (%)', fontname = 'Helvetica', fontsize=16)
plt.xlabel('GMT Change', fontname = 'Helvetica', fontsize=16)
plt.gca().set_xticklabels(['1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)


leg = plt.legend(prop = {'size':9, 'family':'Helvetica'}, \
                 loc='lower right')
leg.get_frame().set_linewidth(0.0)

ax2 = plt.twinx()
plt.ylim([0, 24])
plt.ylabel('Warming-driven growth (GW)', fontname = 'Helvetica', fontsize=16)
plt.yticks(yax)
plt.gca().set_yticklabels([int(x) for x in np.round(yax/100 * np.nansum(globalPlants['caps']) / 1e3)])

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

if plotFigs:
    plt.savefig('gen-growth-warming-curtailment.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


ieaCurtailment = np.nansum(np.array([iea2017*np.nanmean(additionalGen50[0,:]/100), \
                                     iea2025*np.nanmean(additionalGen50[1,:]/100), \
                                     iea2030*np.nanmean(additionalGen50[1,:]/100), \
                                     iea2035*np.nanmean(additionalGen50[1,:]/100), \
                                     iea2040*np.nanmean(additionalGen50[2,:]/100)]), axis=1)

ieaCoal = np.array([iea2017[0], iea2025[0], iea2030[0], iea2035[0], iea2040[0]])
ieaGas = np.array([iea2017[1], iea2025[1], iea2030[1], iea2035[1], iea2040[1]]) 
ieaOil = np.array([iea2017[2], iea2025[2], iea2030[2], iea2035[2], iea2040[2]])
ieaNuke = np.array([iea2017[3], iea2025[3], iea2030[3], iea2035[3], iea2040[3]])
ieaBio = np.array([iea2017[4], iea2025[4], iea2030[4], iea2035[4], iea2040[4]])
ieaDates = np.array([2017, 2025, 2030, 2035, 2040])
ieaLegend = ['Coal', 'Gas', 'Oil', 'Nuke', 'Bio', 'Warming+\nCurtailment']

barW = 2

plt.figure(figsize=(4,4))
plt.grid(True, color=[.9,.9,.9], axis='y')

plt.bar(ieaDates, ieaCoal, width=barW, color='#f03b20')
plt.bar(ieaDates, ieaGas, bottom=ieaCoal, width=barW, color='#3182bd')
plt.bar(ieaDates, ieaOil, bottom=ieaCoal+ieaGas, width=barW, color='black')
plt.bar(ieaDates, ieaNuke, bottom=ieaCoal+ieaGas+ieaOil, width=barW, color='orange')
plt.bar(ieaDates, ieaBio, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke, width=barW, color='#56a619')
plt.bar(ieaDates, ieaCurtailment, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke+ieaBio, width=barW, color='#7c7d7a', hatch='/')

plt.xticks([2017, 2025, 2030, 2035, 2040])
plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Energy (EJ)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(ieaLegend, prop = {'size':11, 'family':'Helvetica'}, \
                 loc='right', bbox_to_anchor=(1.5, .5))
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('gen-growth-by-type.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()

#plt.figure(figsize=(2,4))
#plt.grid(True, color=[.9,.9,.9])
#plt.plot(range(1,5), np.nanmean(additionalGenGrowth50,axis=1))
#
#plt.ylabel('Generation growth (%)', fontname = 'Helvetica', fontsize=16)
#plt.xticks(range(1,5))



