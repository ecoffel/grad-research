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

plotFigs = True
dumpData = False

plantData = 'world'

# in gw
# coal, gas, oil, nuke, bioenergy
iea2017 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7]) / 24 / 365 * 1e3
iea2025 = np.array([9896.2, 6828.9, 763.2, 3088.7, 890.4]) / 24 / 365 * 1e3
iea2030 = np.array([10015.9, 7517.4, 675.7, 3252.7, 1056.9]) / 24 / 365 * 1e3
iea2035 = np.array([10172.0, 8265.5, 597.3, 3520.0, 1238.2]) / 24 / 365 * 1e3
iea2040 = np.array([10335.1, 9070.6, 527.2, 3725.8, 1427.3]) / 24 / 365 * 1e3

# coal, gas, oil, nuke, bioenergy
ieaSust2017 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7]) / 24 / 365 * 1e3
ieaSust2025 = np.array([7193, 6810, 604, 3302, 1039]) / 24 / 365 * 1e3
ieaSust2030 = np.array([4847, 6829, 413, 3887, 1324]) / 24 / 365 * 1e3
ieaSust2035 = np.array([3050, 6254, 274, 4534, 1646]) / 24 / 365 * 1e3
ieaSust2040 = np.array([1981, 5358, 197, 4960, 1967]) / 24 / 365 * 1e3

ieaNPSlope = (sum(iea2040)-sum(iea2017))/(2040-2017)
ieaSustSlope = (sum(ieaSust2040)-sum(ieaSust2017))/(2040-2017)

# mean years across models reaching 1,2,3,4 GMT
GMTyears = np.array([2022, 2041, 2061, 2080])

if plantData == 'world':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=True)
elif plantData == 'useu':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=False)

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

if not os.path.isfile('E:/data/ecoffel/data/projects/electricity/script-data/active-pp-inds-40-%s.dat'%plantData):
    
    livingPlants40 = np.zeros([len(range(1910,2100)), 1])
    livingPlantsInds40 = {}
    #livingPlants60 = np.zeros([len(range(1910,2100)), 1])
    
    for i, y in enumerate(range(1910, 2100)):
        
        curYearInds = []
        
        # every plants start date
        for p in range(len(yearsCom)):
            if y >= yearsCom[p] and y <= yearsCom[p] + 40:
                livingPlants40[i] += plantCaps[p]
                curYearInds.append(p)
    #        if y >= yearsCom[p] and y <= yearsCom[p] + 60:
    #            livingPlants60[i] += plantCaps[p]
        
        livingPlantsInds40[y] = np.array(curYearInds)
        
    if dumpData:
        with open('E:/data/ecoffel/data/projects/electricity/script-data/active-pp-inds-40-%s.dat'%plantData, 'wb') as f:
            pickle.dump(livingPlantsInds40, f)
        with open('E:/data/ecoffel/data/projects/electricity/script-data/active-pp-40-%s.dat'%plantData, 'wb') as f:
            pickle.dump(livingPlants40, f)
else:
    with open('E:/data/ecoffel/data/projects/electricity/script-data/active-pp-inds-40-%s.dat'%plantData, 'rb') as f:
        livingPlantsInds40 = pickle.load(f)
    with open('E:/data/ecoffel/data/projects/electricity/script-data/active-pp-40-%s.dat'%plantData, 'rb') as f:
        livingPlants40 = pickle.load(f)
    

snsColors = sns.color_palette(["#3498db", "#e74c3c", "#cd6ded"])

plt.figure(figsize=(5,4))
plt.xlim([1950,2100])
plt.ylim([0, 4500])
plt.grid(True, color=[.9,.9,.9])

plt.plot(yearsRange, livingPlants40, color=snsColors[1], lw=2, label='40 Year Lifespan')

# fill curve up to 2020
plt.fill_between(np.array(yearsRange[0:111]), livingPlants40[0:111,0], np.array([0]*(111)), facecolor=snsColors[1], alpha=.5, interpolate=True)

for g in range(GMTyears.shape[0]):
    yr = GMTyears[g]
    plt.plot([yr,yr], [0, 5000], '--k')

msize = 6

# plot iea capacities
plt.plot([2017], sum(iea2017), 'ok', markersize=msize)
p1 = plt.plot([2025], sum(iea2025), 'ok', markerfacecolor=snsColors[1], markersize=msize, label='IEA New Policies')
plt.plot([2030], sum(iea2030), 'ok', markerfacecolor=snsColors[1], markersize=msize)
plt.plot([2035], sum(iea2035), 'ok', markerfacecolor=snsColors[1], markersize=msize)
plt.plot([2040], sum(iea2040), 'ok', markerfacecolor=snsColors[1], markersize=msize)
plt.plot(np.arange(2042,2101,1), [sum(iea2040)+ieaNPSlope*(y-2040) for y in range(2042,2101,1)], '--', color=snsColors[1], lw=2)

#plt.plot([2017], sum(ieaSust2017), 'ok', markerfacecolor=snsColors[0], markersize=5)
p2 = plt.plot([2025], sum(ieaSust2025), 'ok', markerfacecolor=snsColors[0], markersize=msize, label='IEA Sustainable')
plt.plot([2030], sum(ieaSust2030), 'ok', markerfacecolor=snsColors[0], markersize=msize)
plt.plot([2035], sum(ieaSust2035), 'ok', markerfacecolor=snsColors[0], markersize=msize)
plt.plot([2040], sum(ieaSust2040), 'ok', markerfacecolor=snsColors[0], markersize=msize)
plt.plot(np.arange(2042,2101,1), [sum(ieaSust2040)+ieaSustSlope*(y-2040) for y in range(2042,2101,1)], '--', color=snsColors[0], lw=2)

p2 = plt.plot([2025], sum(iea2017), 'ok', markerfacecolor='gray', markersize=msize, label='Constant')
plt.plot([2030], sum(iea2017), 'ok', markerfacecolor='gray', markersize=msize)
plt.plot([2035], sum(iea2017), 'ok', markerfacecolor='gray', markersize=msize)
plt.plot([2040], sum(iea2017), 'ok', markerfacecolor='gray', markersize=msize)
plt.plot([2042, 2100], [sum(iea2017), sum(iea2017)], '--', color='gray', lw=2)

plt.ylabel('Capacity (GW)',fontname = 'Helvetica', fontsize=16)
plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)

plt.xticks([1950, 1980, 2010, 2040, 2070, 2100])
plt.yticks(np.arange(0,4500,1000))
    
for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':10, 'family':'Helvetica'}, loc = 'upper left')
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('plant-lifespan-40.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)


plt.show()
sys.exit()

plt.figure(figsize=(5,2))
plt.xlim([1950,2100])
plt.ylim([0, 3500])
plt.grid(True, color=[.9,.9,.9])

plt.plot(yearsRange, livingPlants60, color=snsColors[2], lw=2, label='60 Year\nLifespan')

# fill curve up to 2020
plt.fill_between(np.array(yearsRange[0:111]), livingPlants60[0:111,0], np.array([0]*(111)), facecolor=snsColors[2], alpha=.5, interpolate=True)

for g in range(GMTyears.shape[0]):
    yr = GMTyears[g]
    plt.plot([yr,yr], [0, 5000], '--k')


# plot iea capacities
plt.plot([2017], sum(iea2017), 'ok', markersize=5)
plt.plot([2025], sum(iea2025), 'ok', markerfacecolor=snsColors[1], markersize=5)
plt.plot([2030], sum(iea2030), 'ok', markerfacecolor=snsColors[1], markersize=5)
plt.plot([2035], sum(iea2035), 'ok', markerfacecolor=snsColors[1], markersize=5)
plt.plot([2040], sum(iea2040), 'ok', markerfacecolor=snsColors[1], markersize=5)

#plt.plot([2017], sum(ieaSust2017), 'ok', markerfacecolor=snsColors[0], markersize=5)
plt.plot([2025], sum(ieaSust2025), 'ok', markerfacecolor=snsColors[0], markersize=5)
plt.plot([2030], sum(ieaSust2030), 'ok', markerfacecolor=snsColors[0], markersize=5)
plt.plot([2035], sum(ieaSust2035), 'ok', markerfacecolor=snsColors[0], markersize=5)
plt.plot([2040], sum(ieaSust2040), 'ok', markerfacecolor=snsColors[0], markersize=5)


plt.ylabel('Capacity (GW)',fontname = 'Helvetica', fontsize=16)
plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)

plt.xticks([1950, 1980, 2010, 2040, 2070, 2100])
plt.yticks(np.arange(0,3500,1000))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':11, 'family':'Helvetica'}, loc = 'upper left')
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('plant-lifespan-60.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)



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




