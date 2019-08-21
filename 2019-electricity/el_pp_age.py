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

np.random.seed(19680801)

plotFigs = False

# mean years across models reaching 1,2,3,4 GMT
GMTyears = np.array([2022, 2041, 2061, 2080])

globalPlants = el_load_global_plants.loadGlobalPlants()

yearsCom = globalPlants['yearCom']
plantCaps = globalPlants['caps'] / 1e3
ind = np.where(~np.isnan(yearsCom))
yearsCom = yearsCom[ind]

yearsComHist = np.histogram(yearsCom, bins = range(1910,2020,10))
yearsComFutX1 = yearsComHist[1] + 40
yearsComFutX2 = yearsComHist[1] + 80
yearsComFutY = yearsComHist[0]

#plt.figure(figsize=(4,4))
#plt.plot(yearsComHist[1][1:],yearsComHist[0], 'k')
#plt.plot(yearsComFutX1[1:],yearsComFutY, 'r')
#plt.plot(yearsComFutX2[1:],yearsComFutY, 'magenta')

yearsRange = range(1910,2100)
livingPlants40 = np.zeros([len(range(1910,2100)), 1])
livingPlants80 = np.zeros([len(range(1910,2100)), 1])

for i, y in enumerate(range(1910, 2100)):
    # every plants start date
    for p in range(len(yearsCom)):
        if y >= yearsCom[p] and y <= yearsCom[p] + 40:
            livingPlants40[i] += plantCaps[p]
        if y >= yearsCom[p] and y <= yearsCom[p] + 80:
            livingPlants80[i] += plantCaps[p]

snsColors = sns.color_palette(["#3498db", "#e74c3c", "#cd6ded"])

plt.figure(figsize=(5,2))
plt.xlim([1950,2100])
plt.ylim([0, 1400])
plt.grid(True, color=[.9,.9,.9])

plt.plot(yearsRange, livingPlants40, color=snsColors[1], lw=2, label='40 Year\nLifespan')

# fill curve up to 2020
plt.fill_between(np.array(yearsRange[0:111]), livingPlants40[0:111,0], np.array([0]*(111)), facecolor=snsColors[1], alpha=.5, interpolate=True)

for g in range(GMTyears.shape[0]):
    yr = GMTyears[g]
    plt.plot([yr,yr], [0, 5000], '--k')

plt.ylabel('Capacity (GW)',fontname = 'Helvetica', fontsize=16)
plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)

plt.xticks([1950, 1980, 2010, 2040, 2070, 2100])
plt.yticks(np.arange(0,1400,300))
    
for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':11, 'family':'Helvetica'}, loc = 'upper left')
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('plant-lifespan-40.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)




plt.figure(figsize=(5,2))
plt.xlim([1950,2100])
plt.ylim([0, 1400])
plt.grid(True, color=[.9,.9,.9])

plt.plot(yearsRange, livingPlants80, color=snsColors[2], lw=2, label='80 Year\nLifespan')

# fill curve up to 2020
plt.fill_between(np.array(yearsRange[0:111]), livingPlants80[0:111,0], np.array([0]*(111)), facecolor=snsColors[2], alpha=.5, interpolate=True)

for g in range(GMTyears.shape[0]):
    yr = GMTyears[g]
    plt.plot([yr,yr], [0, 5000], '--k')

plt.ylabel('Capacity (GW)',fontname = 'Helvetica', fontsize=16)
plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)

plt.xticks([1950, 1980, 2010, 2040, 2070, 2100])
plt.yticks(np.arange(0,1400,300))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':11, 'family':'Helvetica'}, loc = 'upper left')
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('plant-lifespan-80.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)


sys.exit()

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
plt.ylabel('Warming-driven gen growth (%)', fontname = 'Helvetica', fontsize=16)
plt.xlabel('GMT Change', fontname = 'Helvetica', fontsize=16)
plt.gca().set_xticklabels(['1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#leg = plt.legend(prop = {'size':11, 'family':'Helvetica'}, loc = 'lower right')
#leg.get_frame().set_linewidth(0.0)

ax2 = plt.twinx()
plt.ylim([0, 24])
plt.ylabel('Warming-driven gen growth (GW)', fontname = 'Helvetica', fontsize=16)
plt.yticks(yax)
plt.gca().set_yticklabels([int(x) for x in np.round(yax/100 * np.nansum(globalPlants['caps']) / 1e3)])

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)
#




