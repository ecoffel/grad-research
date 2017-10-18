# -*- coding: utf-8 -*-
"""
Created on Mon Oct 16 17:25:30 2017

@author: Ethan
"""

# plot change in each rainy season change

import matplotlib.pyplot as plt
from ni_nileUtils import *
import scipy.stats as stats

stdMultiplier = 1

plt.figure(0, figsize=(10,10))

for region in [1, 2, 3, 4]:
    [tempHistorical, models] = readModelData('data/r' + str(region) + '-temp-historical.csv')
    [tempRcp85, models] = readModelData('data/r'  + str(region) + '-temp-rcp85.csv')
    
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
                indRcp85 = numpy.where((tempRcp85['Month'] == month) & (tempRcp85['Year'] >= futurePeriod[0]) & (tempRcp85['Year'] <= futurePeriod[1]))
                            
                # add all data for current month
                curFuture.append(tempRcp85[model][indRcp85])
                
                if i == 0:
                    indHistorical = numpy.where(tempHistorical['Month'] == month)
                    curBase.append(tempHistorical[model][indHistorical])
            
            periodFuture.append(curFuture)
            if i == 0:
                base.append(curBase)
    
        future.append(periodFuture)        
        
        
    base = numpy.array(base)
    future = numpy.array(future)
    
    # mean across years
    baseMean = numpy.mean(base, axis=2)
    baseStd = numpy.std(base, axis=2)
    
    coolChanges = [[], []]
    coolChangesSig = [[], []]
    hotChanges = [[], []]
    hotChangesSig = [[], []]
    
    for month in months:
    
        hotBase = []
        coolBase = []
        
        month = month-1
        # models
        for model in range(future.shape[1]):
            coolBase.append(numpy.size(numpy.where(base[model, month] < (baseMean[model, month]-baseStd[model, month]*stdMultiplier))))
            hotBase.append(numpy.size(numpy.where(base[model, month] > (baseMean[model, month]+baseStd[model, month]*stdMultiplier))))
        
        hotBase = numpy.array(hotBase)
        coolBase = numpy.array(coolBase)
        
        coolFuture = []
        hotFuture = []
        
        for period in [0, 1]:
            pHot = []
            pCool = []
            # models
            for model in range(future.shape[1]):
                pCool.append(numpy.size(numpy.where(future[period, model, month] < (baseMean[model, month]-baseStd[model, month]*stdMultiplier))))
                pHot.append(numpy.size(numpy.where(future[period, model, month] > (baseMean[model, month]+baseStd[model, month]*stdMultiplier))))
            coolFuture.append(pCool)
            hotFuture.append(pHot)
        
        hotFuture = numpy.array(hotFuture)
        coolFuture = numpy.array(coolFuture)
        
        for period in [0, 1]:
            hotChanges[period].append((numpy.mean(hotFuture[period])-numpy.mean(hotBase))/numpy.mean(hotBase)*100)
            coolChanges[period].append((numpy.mean(coolFuture[period])-numpy.mean(coolBase))/numpy.mean(coolBase)*100)
            
            s, p = stats.ttest_ind(hotFuture[period], hotBase)
            hotChangesSig[period].append(p)
            s, p = stats.ttest_ind(coolFuture[period], coolBase)
            coolChangesSig[period].append(p)
            
    
    plt.subplot(2,2,region)
    plt.plot(list(range(-5,15)), [0]*20, '--k')
    p1, = plt.plot(months, coolChanges[1], color='xkcd:sky blue')
    p2, = plt.plot(months, hotChanges[1], color='xkcd:red')
    for month in months:
        if hotChangesSig[1][month-1] < 0.05:
            plt.plot(month, hotChanges[1][month-1], 'o', markerfacecolor='xkcd:red', color='xkcd:red', markersize=10)
        else:
            plt.plot(month, hotChanges[1][month-1], 'o', markerfacecolor='none', color='xkcd:red', markersize=10)
        
        if coolChangesSig[1][month-1] < 0.05:
            plt.plot(month, coolChanges[1][month-1], 'o', markerfacecolor='xkcd:sky blue', color='xkcd:sky blue', markersize=10)
        else:
            plt.plot(month, coolChanges[1][month-1], 'o', markerfacecolor='none', color='xkcd:sky blue', markersize=10)
            
    
    
    plt.xlabel('Month')
    plt.ylabel('Change (%)')
    plt.title('Region ' + str(region))
    plt.legend([p1,p2], ['Cool months', 'Hot months'])
    plt.ylim([-120, 600])
    plt.xlim([0.5, 12.5])
#plt.savefig('pr-variability.png', dpi=600)
    
    
            
        
        
        
