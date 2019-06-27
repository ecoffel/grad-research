# -*- coding: utf-8 -*-
"""
Created on Mon May 20 14:57:18 2019

@author: Ethan
"""


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
import statsmodels.api as sm
import el_load_global_plants
import pickle, gzip
import sys, os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


globalPlants = el_load_global_plants.loadGlobalPlants()

yearRange = [1981, 2018]

monthLen = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


if not os.path.isfile('aggregated-global-outages-hist-50.dat'):

    if not 'globalPCHist50' in locals():
        with gzip.open('E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-hist-10.dat', 'rb') as f:
            globalPCHist = pickle.load(f)
            globalPCHist10 = globalPCHist['globalPCHist10']
        
        with gzip.open('E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-hist-50.dat', 'rb') as f:
            globalPCHist = pickle.load(f)
            globalPCHist50 = globalPCHist['globalPCHist50']
            
        with gzip.open('E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-hist-90.dat', 'rb') as f:
            globalPCHist = pickle.load(f)
            globalPCHist90 = globalPCHist['globalPCHist90']
            
    yearlyOutagesHist10 = []
    yearlyOutagesHist50 = []
    yearlyOutagesHist90 = []
    
    print('calculating total capacity outage for historical')
    
    numPlants10 = 0
    numPlants50 = 0
    numPlants90 = 0
    
    # over all plants
    for p in range(globalPCHist50.shape[0]):
        
        if p % 25 == 0:
            print('plant %d...'%p)
        
        numYears = 0
        
        yearlyOutagesHistCurPlant10 = []
        yearlyOutagesHistCurPlant50 = []
        yearlyOutagesHistCurPlant90 = []
        
        plantHasData10 = False
        plantHasData50 = False
        plantHasData90 = False
        
        # calculate the total outage (MW) on each day of each year
        for year in range(globalPCHist50.shape[1]):
            yearlyOutagesHistCurYear10 = []
            yearlyOutagesHistCurYear50 = []
            yearlyOutagesHistCurYear90 = []
            
            numDays10 = 0
            numDays50 = 0
            numDays90 = 0

            for month in range(12):
                
                monthlyOutages10 = (100-np.array(globalPCHist10[p,year,month][:])) / 100.0
                numDays10 = len(np.where(~np.isnan(monthlyOutages10))[0])
                monthlyTotal10 = np.nansum(globalPlants['caps'][p] * monthlyOutages10 * 1e6)
                
                # divide by actual # of days in this month, then multiply by full summer (62 days)
                # this accounts for model/years where there are nans
                if numDays10 > 0:
                    monthlyTotal10 /= numDays10
                    monthlyTotal10 *= monthLen[month] * 24 * 3600
                    
                    yearlyOutagesHistCurYear10.append(monthlyTotal10)
                    
                
                monthlyOutages50 = (100-np.array(globalPCHist50[p,year,month][:])) / 100.0
                numDays50 = len(np.where(~np.isnan(monthlyOutages50))[0])
                monthlyTotal50 = np.nansum(globalPlants['caps'][p] * monthlyOutages50 * 1e6)
                
                if numDays50 > 0:
                    monthlyTotal50 /= numDays50
                    monthlyTotal50 *= monthLen[month] * 24 * 3600
                    
                    yearlyOutagesHistCurYear50.append(monthlyTotal50)
                    
                    
                    
                monthlyOutages90 = (100-np.array(globalPCHist90[p,year,month][:])) / 100.0
                numDays90 = len(np.where(~np.isnan(monthlyOutages90))[0])
                monthlyTotal90 = np.nansum(globalPlants['caps'][p] * monthlyOutages90 * 1e6)
                
                if numDays90 > 0:
                    monthlyTotal90 /= numDays90
                    monthlyTotal90 *= monthLen[month] * 24 * 3600
                    
                    yearlyOutagesHistCurYear90.append(monthlyTotal90)
            
            if len(yearlyOutagesHistCurYear10) == 12:
                yearlyOutagesHistCurPlant10.append(yearlyOutagesHistCurYear10)
                plantHasData10 = True
            else:
                yearlyOutagesHistCurPlant10.append([np.nan]*12)
                
            
            if len(yearlyOutagesHistCurYear50) == 12:
                yearlyOutagesHistCurPlant50.append(yearlyOutagesHistCurYear50)
                plantHasData50 = True
            else:
                yearlyOutagesHistCurPlant50.append([np.nan]*12)
                
            
            if len(yearlyOutagesHistCurYear90) == 12:
                yearlyOutagesHistCurPlant90.append(yearlyOutagesHistCurYear90)
                plantHasData90 = True
            else:
                yearlyOutagesHistCurPlant90.append([np.nan]*12)
        
        # divide by # of years to get total outage per year, if there is data
        if len(yearlyOutagesHistCurPlant10) > 0:
            yearlyOutagesHistCurPlant10 = np.array(yearlyOutagesHistCurPlant10)
            yearlyOutagesHistCurPlant10 = np.nanmean(yearlyOutagesHistCurPlant10, axis=0)
        
            if plantHasData10: numPlants10 += 1
        
            yearlyOutagesHist10.append(yearlyOutagesHistCurPlant10)
            
            
        if len(yearlyOutagesHistCurPlant50) > 0:
            yearlyOutagesHistCurPlant50 = np.array(yearlyOutagesHistCurPlant50)
            yearlyOutagesHistCurPlant50 = np.nanmean(yearlyOutagesHistCurPlant50, axis=0)
        
            if plantHasData50: numPlants50 += 1
        
            yearlyOutagesHist50.append(yearlyOutagesHistCurPlant50)
            
            
        if len(yearlyOutagesHistCurPlant90) > 0:
            yearlyOutagesHistCurPlant90 = np.array(yearlyOutagesHistCurPlant90)
            yearlyOutagesHistCurPlant90 = np.nanmean(yearlyOutagesHistCurPlant90, axis=0)
        
            if plantHasData90: numPlants90 += 1
        
            yearlyOutagesHist90.append(yearlyOutagesHistCurPlant90)
    
    yearlyOutagesHist10 = np.array(yearlyOutagesHist10)
    yearlyOutagesHist10 = (np.nansum(yearlyOutagesHist10, axis=0)/numPlants10)*yearlyOutagesHist10.shape[0]
    
    yearlyOutagesHist50 = np.array(yearlyOutagesHist50)
    yearlyOutagesHist50 = (np.nansum(yearlyOutagesHist50, axis=0)/numPlants50)*yearlyOutagesHist50.shape[0]
    
    yearlyOutagesHist90 = np.array(yearlyOutagesHist90)
    yearlyOutagesHist90 = (np.nansum(yearlyOutagesHist90, axis=0)/numPlants90)*yearlyOutagesHist90.shape[0]
    
    with gzip.open('aggregated-global-outages-hist-10.dat', 'wb') as f:
        pickle.dump(yearlyOutagesHist10, f)
        
    with gzip.open('aggregated-global-outages-hist-50.dat', 'wb') as f:
        pickle.dump(yearlyOutagesHist50, f)
        
    with gzip.open('aggregated-global-outages-hist-90.dat', 'wb') as f:
        pickle.dump(yearlyOutagesHist90, f)
else:
    
    with gzip.open('aggregated-global-outages-hist-10.dat', 'rb') as f:
        yearlyOutagesHist10 = pickle.load(f)
        
    with gzip.open('aggregated-global-outages-hist-50.dat', 'rb') as f:
        yearlyOutagesHist50 = pickle.load(f)
        
    with gzip.open('aggregated-global-outages-hist-90.dat', 'rb') as f:
        yearlyOutagesHist90 = pickle.load(f)



if not os.path.isfile('aggregated-global-outages-fut10.dat'):
    print('processing future...')
    
    yearlyOutagesFut10 = []
    yearlyOutagesFut50 = []
    yearlyOutagesFut90 = []
    
    for w in range(1,4+1):
        yearlyOutagesCurGMT10 = []
        yearlyOutagesCurGMT50 = []
        yearlyOutagesCurGMT90 = []
        
        for model in range(len(models)):
            yearlyOutagesCurModel10 = []
            yearlyOutagesCurModel50 = []
            yearlyOutagesCurModel90 = []
            
            fileName = 'E:\data\ecoffel\data\projects\electricity\global-pc-future\global-pc-future-%ddeg-%s.dat'%(w, models[model])
            
            if not os.path.isfile(fileName):
                continue
            
            with gzip.open(fileName, 'rb') as f:
                globalPC = pickle.load(f)
                
                globalPCFut10 = globalPC['globalPCFut10']
                globalPCFut50 = globalPC['globalPCFut50']
                globalPCFut90 = globalPC['globalPCFut90']
            
            print('calculating total capacity outage for %s/+%dC'%(models[model],w))
            
            # num plants for current model with data
            numPlants10 = 0
            numPlants50 = 0
            numPlants90 = 0
            
            # over all plants
            for p in range(globalPCFut10.shape[0]):                
                yearlyOutagesCurPlant10 = []
                yearlyOutagesCurPlant50 = []
                yearlyOutagesCurPlant90 = []
                
                if p%100 == 0:
                    print('plant %d...'%p)
                
                plantHasData10 = False
                plantHasData50 = False
                plantHasData90 = False
                
                # calculate the total outage (MW) on each day of each year
                for year in range(globalPCFut10.shape[1]):
                    yearlyOutagesCurYear10 = []
                    yearlyOutagesCurYear50 = []
                    yearlyOutagesCurYear90 = []
                    
                    for month in range(12):
                
                        monthlyOutages10 = (100-np.array(globalPCFut10[p,year,month][:])) / 100.0
                        monthlyOutages50 = (100-np.array(globalPCFut50[p,year,month][:])) / 100.0
                        monthlyOutages90 = (100-np.array(globalPCFut90[p,year,month][:])) / 100.0
                        
                        indBadData10 = np.where((monthlyOutages10 < 0) | (monthlyOutages10 > 1))[0]
                        monthlyOutages10[indBadData10] = np.nan
                        
                        indBadData50 = np.where((monthlyOutages50 < 0) | (monthlyOutages50 > 1))[0]
                        monthlyOutages50[indBadData50] = np.nan
                        
                        indBadData90 = np.where((monthlyOutages90 < 0) | (monthlyOutages90 > 1))[0]
                        monthlyOutages90[indBadData90] = np.nan
                        
                        numDays10 = len(np.where(~np.isnan(monthlyOutages10))[0])
                        monthlyTotal10 = np.nansum(globalPlants['caps'][p] * monthlyOutages10 * 1e6)
                        
                        # divide by actual # of days in this month, then multiply by full summer (62 days)
                        # this accounts for model/years where there are nans
                        if numDays10 > 0:
                            monthlyTotal10 /= numDays10
                            monthlyTotal10 *= monthLen[month] * 24 * 3600                      
                            yearlyOutagesCurYear10.append(monthlyTotal10)
                        
                        numDays50 = len(np.where(~np.isnan(monthlyOutages50))[0])
                        monthlyTotal50 = np.nansum(globalPlants['caps'][p] * monthlyOutages50 * 1e6)
                        
                        if numDays50 > 0:
                            monthlyTotal50 /= numDays50
                            monthlyTotal50 *= monthLen[month] * 24 * 3600                            
                            yearlyOutagesCurYear50.append(monthlyTotal50)
                        
                        numDays90 = len(np.where(~np.isnan(monthlyOutages90))[0])
                        monthlyTotal90 = np.nansum(globalPlants['caps'][p] * monthlyOutages90 * 1e6)
                        
                        if numDays90 > 0:
                            monthlyTotal90 /= numDays90
                            monthlyTotal90 *= monthLen[month] * 24 * 3600
                            yearlyOutagesCurYear90.append(monthlyTotal90)
                        
                    
                    if len(yearlyOutagesCurYear10) == 12:
                        yearlyOutagesCurPlant10.append(yearlyOutagesCurYear10)
                        plantHasData10 = True
                    else:
                        yearlyOutagesCurPlant10.append([np.nan]*12)
                    
                    
                    if len(yearlyOutagesCurYear50) == 12:
                        yearlyOutagesCurPlant50.append(yearlyOutagesCurYear50)
                        plantHasData50 = True
                    else:
                        yearlyOutagesCurPlant50.append([np.nan]*12)
                    
                    
                    if len(yearlyOutagesCurYear90) == 12:
                        yearlyOutagesCurPlant90.append(yearlyOutagesCurYear90)
                        plantHasData90 = True
                    else:
                        yearlyOutagesCurPlant90.append([np.nan]*12)
                
                # divide by # of years to get total outage per year, if there is data
                if len(yearlyOutagesCurPlant10) > 0:
                    yearlyOutagesCurPlant10 = np.array(yearlyOutagesCurPlant10)
                    yearlyOutagesCurPlant10 = np.nanmean(yearlyOutagesCurPlant10, axis=0)
                    yearlyOutagesCurModel10.append(yearlyOutagesCurPlant10)                    
                    if plantHasData10: numPlants10 += 1
                
                
                if len(yearlyOutagesCurPlant50) > 0:
                    yearlyOutagesCurPlant50 = np.array(yearlyOutagesCurPlant50)
                    yearlyOutagesCurPlant50 = np.nanmean(yearlyOutagesCurPlant50, axis=0)
                    yearlyOutagesCurModel50.append(yearlyOutagesCurPlant50)                    
                    if plantHasData50: numPlants50 += 1
                    
                if len(yearlyOutagesCurPlant90) > 0:
                    yearlyOutagesCurPlant90 = np.array(yearlyOutagesCurPlant90)
                    yearlyOutagesCurPlant90 = np.nanmean(yearlyOutagesCurPlant90, axis=0)
                    yearlyOutagesCurModel90.append(yearlyOutagesCurPlant90)
                    if plantHasData90: numPlants90 += 1
                    
            
            # correct for # of plants
            yearlyOutagesCurModel10 = np.array(yearlyOutagesCurModel10)
            yearlyOutagesCurModel10 = (np.nansum(yearlyOutagesCurModel10, axis=0)/numPlants10)*yearlyOutagesCurModel10.shape[0]
            yearlyOutagesCurGMT10.append(yearlyOutagesCurModel10)
            
            yearlyOutagesCurModel50 = np.array(yearlyOutagesCurModel50)
            yearlyOutagesCurModel50 = (np.nansum(yearlyOutagesCurModel50, axis=0)/numPlants50)*yearlyOutagesCurModel50.shape[0]
            yearlyOutagesCurGMT50.append(yearlyOutagesCurModel50)
            
            yearlyOutagesCurModel90 = np.array(yearlyOutagesCurModel90)
            yearlyOutagesCurModel90 = (np.nansum(yearlyOutagesCurModel90, axis=0)/numPlants90)*yearlyOutagesCurModel90.shape[0]
            yearlyOutagesCurGMT90.append(yearlyOutagesCurModel90)
            
        yearlyOutagesFut10.append(np.array(yearlyOutagesCurGMT10))
        yearlyOutagesFut50.append(np.array(yearlyOutagesCurGMT50))
        yearlyOutagesFut90.append(np.array(yearlyOutagesCurGMT90))
        
    yearlyOutagesFut10 = np.array(yearlyOutagesFut10)
    yearlyOutagesFut50 = np.array(yearlyOutagesFut50)
    yearlyOutagesFut90 = np.array(yearlyOutagesFut90)
    
    with gzip.open('aggregated-global-outages-fut10.dat', 'wb') as f:
        pickle.dump(yearlyOutagesFut10, f)
    
    with gzip.open('aggregated-global-outages-fut50.dat', 'wb') as f:
        pickle.dump(yearlyOutagesFut50, f)
        
    with gzip.open('aggregated-global-outages-fut90.dat', 'wb') as f:
        pickle.dump(yearlyOutagesFut90, f)
        
else:
    
    with gzip.open('aggregated-global-outages-fut10.dat', 'rb') as f:
        yearlyOutagesFut10 = pickle.load(f)
    with gzip.open('aggregated-global-outages-fut50.dat', 'rb') as f:
        yearlyOutagesFut50 = pickle.load(f)
    with gzip.open('aggregated-global-outages-fut90.dat', 'rb') as f:
        yearlyOutagesFut90 = pickle.load(f)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])

#xd = np.array(list(range(1981, 2018+1)))-1981+1

#z = np.polyfit(xd, mean10[0,:], 1)
#histPolyTx10 = np.poly1d(z)
#z = np.polyfit(xd, mean50[0,:], 1)
#histPolyTx50 = np.poly1d(z)
#z = np.polyfit(xd, mean90[0,:], 1)
#histPolyTx90 = np.poly1d(z)

sys.exit()

totalEnergy = np.nansum(globalPlants['caps'])*30*24*3600*1e6/1e18

pctEnergyGrid = np.round(np.array([0, .025, .05, .075, .1, .125, .15, .175])/totalEnergy*100,decimals=1)

xpos = np.arange(1,13)
                               
plt.figure(figsize=(4,4))
#plt.xlim([0, 7])
plt.ylim([0, .18])
plt.grid(True, alpha = 0.25)
plt.gca().set_axisbelow(True)

plt.plot(xpos, yearlyOutagesHist50, '-', lw=2, color='black', label='Historical')
plt.plot(xpos, np.nanmean(yearlyOutagesFut50[1],axis=0), '-', lw=2, color=snsColors[0], label='+ 2$\degree$C')
plt.plot(xpos, np.nanmean(yearlyOutagesFut50[3],axis=0), '-', lw=2, color=snsColors[1], label='+ 4$\degree$C')


plt.fill_between(xpos, yearlyOutagesHist50, [0]*12, facecolor='black', alpha=.5, interpolate=True)
plt.fill_between(xpos, yearlyOutagesHist50, np.nanmean(yearlyOutagesFut50[1],axis=0), facecolor=snsColors[0], alpha=.5, interpolate=True)
plt.fill_between(xpos, np.nanmean(yearlyOutagesFut50[1],axis=0), np.nanmean(yearlyOutagesFut50[3],axis=0), facecolor=snsColors[1], alpha=.5, interpolate=True)

plt.xticks(xpos)
plt.yticks([0, .025, .05, .075, .1, .125, .15, .175])
plt.xlabel('Month', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Monthly US-EU outage (EJ)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':11, 'family':'Helvetica'})
leg.get_frame().set_linewidth(0.0)
    
ax2 = plt.gca().twinx()
plt.ylim([0, .18])
plt.yticks([0, .025, .05, .075, .1, .125, .15, .175])
plt.gca().set_yticklabels(pctEnergyGrid)
plt.ylabel('% of US-EU electricity capacity', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('accumulated-monthly-outage.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)


xpos = np.array([1, 3, 4, 5, 6])

plt.figure(figsize=(5,4))
plt.xlim([0, 7])
plt.ylim([.55, 1.175])
plt.grid(True, color=[.9,.9,.9])

plt.plot(xpos[0]-.15, np.nansum(yearlyOutagesHist10), 'o', markersize=5, color=snsColors[1])
plt.plot(xpos[0], np.nansum(yearlyOutagesHist50), 'o', markersize=5, color='black')
plt.plot(xpos[0]+.15, np.nansum(yearlyOutagesHist90), 'o', markersize=5, color=snsColors[0])

plt.plot(xpos[1]-.15, np.nanmean(np.nansum(yearlyOutagesFut10[0], axis=1)), 'o', markersize=5, color=snsColors[1])
plt.errorbar(xpos[1]-.15, \
             np.nanmean(np.nansum(yearlyOutagesFut10[0], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[0], axis=1)), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[1], np.nanmean(np.nansum(yearlyOutagesFut50[0], axis=1)), 'o', markersize=5, color='black')
plt.errorbar(xpos[1], \
             np.nanmean(np.nansum(yearlyOutagesFut50[0], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[0], axis=1)), \
             ecolor = 'black', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[1]+.15, np.nanmean(np.nansum(yearlyOutagesFut90[0], axis=1)), 'o', markersize=5, color=snsColors[0])
plt.errorbar(xpos[1]+.15, \
             np.nanmean(np.nansum(yearlyOutagesFut90[0], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut90[0], axis=1)), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')



plt.plot(xpos[2]-.15, np.nanmean(np.nansum(yearlyOutagesFut10[1], axis=1)), 'o', markersize=5, color=snsColors[1])
plt.errorbar(xpos[2]-.15, \
             np.nanmean(np.nansum(yearlyOutagesFut10[1], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[1], axis=1)), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[2], np.nanmean(np.nansum(yearlyOutagesFut50[1], axis=1)), 'o', markersize=5, color='black')
plt.errorbar(xpos[2], \
             np.nanmean(np.nansum(yearlyOutagesFut50[1], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[1], axis=1)), \
             ecolor = 'black', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[2]+.15, np.nanmean(np.nansum(yearlyOutagesFut90[1], axis=1)), 'o', markersize=5, color=snsColors[0])
plt.errorbar(xpos[2]+.15, \
             np.nanmean(np.nansum(yearlyOutagesFut90[1], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut90[1], axis=1)), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')



plt.plot(xpos[3]-.15, np.nanmean(np.nansum(yearlyOutagesFut10[2], axis=1)), 'o', markersize=5, color=snsColors[1])
plt.errorbar(xpos[3]-.15, \
             np.nanmean(np.nansum(yearlyOutagesFut10[2], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[2], axis=1)), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[3], np.nanmean(np.nansum(yearlyOutagesFut50[2], axis=1)), 'o', markersize=5, color='black')
plt.errorbar(xpos[3], \
             np.nanmean(np.nansum(yearlyOutagesFut50[2], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[2], axis=1)), \
             ecolor = 'black', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[3]+.15, np.nanmean(np.nansum(yearlyOutagesFut90[2], axis=1)), 'o', markersize=5, color=snsColors[0])
plt.errorbar(xpos[3]+.15, \
             np.nanmean(np.nansum(yearlyOutagesFut90[2], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut90[2], axis=1)), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')



plt.plot(xpos[4]-.15, np.nanmean(np.nansum(yearlyOutagesFut10[3], axis=1)), 'o', markersize=5, color=snsColors[1], label='90th Percentile')
plt.errorbar(xpos[4]-.15, \
             np.nanmean(np.nansum(yearlyOutagesFut10[3], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[3], axis=1)), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[4], np.nanmean(np.nansum(yearlyOutagesFut50[3], axis=1)), 'o', markersize=5, color='black', label='50th Percentile')
plt.errorbar(xpos[4], \
             np.nanmean(np.nansum(yearlyOutagesFut50[3], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut10[3], axis=1)), \
             ecolor = 'black', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[4]+.15, np.nanmean(np.nansum(yearlyOutagesFut90[3], axis=1)), 'o', markersize=5, color=snsColors[0], label='10th Percentile')
plt.errorbar(xpos[4]+.15, \
             np.nanmean(np.nansum(yearlyOutagesFut90[3], axis=1)), \
             yerr = np.nanstd(np.nansum(yearlyOutagesFut90[3], axis=1)), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')



plt.ylabel('Annual US-EU outage (EJ)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks([1, 3, 4, 5, 6])
plt.gca().set_xticklabels(['1981-2018', '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])


for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'upper left')
leg.get_frame().set_linewidth(0.0)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('accumulated-annual-outage.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)






