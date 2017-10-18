# -*- coding: utf-8 -*-
"""
Created on Mon Oct 16 17:25:30 2017

@author: Ethan
"""

# plot change in each rainy season change

import matplotlib.pyplot as plt
from ni_nileUtils import *
import scipy.stats as stats

stdMultiplier = 0.5

plt.figure(0, figsize=(10,10))

for region in [1, 2, 3, 4]:
    [prHistorical, models] = readModelData('data/r' + str(region) + '-pr-historical.csv')
    [prRcp85, models] = readModelData('data/r'  + str(region) + '-pr-rcp85.csv')
    
    months = list(range(1,13))
    
    futurePeriods = [[2020,2050],\
                     [2050,2080]]
    
    base = []
    future = []
    
    for i, futurePeriod in enumerate(futurePeriods):
        
        periodFuture = []
        
        # loop over all models
        for model in models:
            
            curBase = []
            curFuture = []
            
            for month in months:
                # get indices of all days in this month
                # current month in the selected future time period
                indRcp85 = numpy.where((prRcp85['Month'] == month) & (prRcp85['Year'] >= futurePeriod[0]) & (prRcp85['Year'] <= futurePeriod[1]))
                            
                # add all data for current month
                curFuture.append(prRcp85[model][indRcp85])
                
                if i == 0:
                    indHistorical = numpy.where(prHistorical['Month'] == month)
                    curBase.append(prHistorical[model][indHistorical])
            
            periodFuture.append(curFuture)
            if i == 0:
                base.append(curBase)
    
        future.append(periodFuture)        
        
        
    base = numpy.array(base)
    future = numpy.array(future)
    
    # mean across years
    baseMean = numpy.mean(base, axis=2)
    baseStd = numpy.std(base, axis=2)
    
    wChanges = [[], []]
    wChangesSig = [[], []]
    dChanges = [[], []]
    dChangesSig = [[], []]
    
    for month in months:
    
        dryBase = []
        wetBase = []
        
        month = month-1
        # models
        for model in range(future.shape[1]):
            dryBase.append(numpy.size(numpy.where(base[model, month] < (baseMean[model, month]-baseStd[model, month]*stdMultiplier))))
            wetBase.append(numpy.size(numpy.where(base[model, month] > (baseMean[model, month]+baseStd[model, month]*stdMultiplier))))
        
        dryBase = numpy.array(dryBase)
        wetBase = numpy.array(wetBase)
        
        wetFuture = []
        dryFuture = []
        
        for period in [0, 1]:
            pDry = []
            pWet = []
            # models
            for model in range(future.shape[1]):
                pDry.append(numpy.size(numpy.where(future[period, model, month] < (baseMean[model, month]-baseStd[model, month]*stdMultiplier))))
                pWet.append(numpy.size(numpy.where(future[period, model, month] > (baseMean[model, month]+baseStd[model, month]*stdMultiplier))))
            wetFuture.append(pWet)
            dryFuture.append(pDry)
        
        dryFuture = numpy.array(dryFuture)
        wetFuture = numpy.array(wetFuture)
        
        for period in [0, 1]:
            dChanges[period].append((numpy.mean(dryFuture[period])-numpy.mean(dryBase))/numpy.mean(dryBase)*100)
            wChanges[period].append((numpy.mean(wetFuture[period])-numpy.mean(wetBase))/numpy.mean(wetBase)*100)
            
            s, p = stats.ttest_ind(dryFuture[period], dryBase)
            dChangesSig[period].append(p)
            s, p = stats.ttest_ind(wetFuture[period], wetBase)
            wChangesSig[period].append(p)
            
    
    plt.subplot(2,2,region)
    plt.plot(list(range(-5,15)), [0]*20, '--k')
    p1, = plt.plot(months, wChanges[1], color='xkcd:green')
    p2, = plt.plot(months, dChanges[1], color='xkcd:orange')
    for month in months:
        if dChangesSig[1][month-1] < 0.05:
            plt.plot(month, dChanges[1][month-1], 'o', markerfacecolor='xkcd:orange', color='xkcd:orange', markersize=10)
        else:
            plt.plot(month, dChanges[1][month-1], 'o', markerfacecolor='none', color='xkcd:orange', markersize=10)
        
        if wChangesSig[1][month-1] < 0.05:
            plt.plot(month, wChanges[1][month-1], 'o', markerfacecolor='xkcd:green', color='xkcd:green', markersize=10)
        else:
            plt.plot(month, wChanges[1][month-1], 'o', markerfacecolor='none', color='xkcd:green', markersize=10)
            
    
    
    plt.xlabel('Month')
    plt.ylabel('Change (%)')
    plt.title('Region ' + str(region))
    plt.legend([p1,p2], ['Wet months', 'Dry months'])
    plt.ylim([-100, 200])
    plt.xlim([0.5, 12.5])
#plt.savefig('pr-variability.png', dpi=600)
    
    
            
        
        
        
