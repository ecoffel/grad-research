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

with gzip.open('global-pc-future/global-pc-hist.dat', 'rb') as f:
    globalPCHist = pickle.load(f)
    globalPCHist10 = globalPCHist['globalPCHist10']
    globalPCHist50 = globalPCHist['globalPCHist50']
    globalPCHist90 = globalPCHist['globalPCHist90']


if not os.path.isfile('aggregated-global-outages-hist.dat'):

    yearlyOutagesHist = []

    print('calculating total capacity outage for historical')
    
    # over all plants
    for p in range(globalPCHist10.shape[0]):
        plantTx1d = np.reshape(globalPCHist10[p,:,:], (globalPCHist10[p,:,:].shape[0]*globalPCHist10[p,:,:].shape[1]), order='C')
        
        numYears = 0
        yearlyOutagesHistCurPlant = 0
        
        # calculate the total outage (MW) on each day of each year
        for year in range(globalPCHist10.shape[1]):
            yearlyTotal = 0
            numDays = 0

            for day in range(globalPCHist10.shape[2]):
                outage = (100-globalPCHist10[p,year,day]) / 100.0
                
                if outage <= 1 and not np.isnan(globalPlants['caps'][p] * outage * 1/1e6):
                    yearlyTotal += globalPlants['caps'][p] * outage * 1/1e6
                    numDays += 1
            
            # divide by actual # of days in this year, then multiply by full summer (62 days)
            # this accounts for model/years where there are nans
            if numDays > 0:
                yearlyTotal /= numDays
                yearlyTotal *= 62
                
                yearlyOutagesHistCurPlant += yearlyTotal
                numYears += 1
        
        # divide by # of years to get total outage per year
        if numYears > 0:
            yearlyOutagesHistCurPlant /= numYears
        else:
            yearlyOutagesHistCurPlant = np.nan
            
        yearlyOutagesHist.append(yearlyOutagesHistCurPlant)
    
    yearlyOutagesHist = np.array(yearlyOutagesHist)
    
    with gzip.open('aggregated-global-outages-hist.dat', 'wb') as f:
        pickle.dump(yearlyOutagesHist, f)
else:
    
    with gzip.open('aggregated-global-outages-hist.dat', 'rb') as f:
        yearlyOutagesHist = pickle.load(f)

# calculate sum across plants 
outageSumHist = np.nansum(yearlyOutagesHist)

if not os.path.isfile('aggregated-global-outages-fut.dat'):
    yearlyOutagesFut = []
    
    for w in range(1,4+1):
        yearlyOutagesCurGMT = []
        
        for model in range(len(models)):
            yearlyOutagesCurModel = []
            
            fileName = 'global-pc-future/global-pc-future-%ddeg-%s.dat'%(w, models[model])
            
            if not os.path.isfile(fileName):
                continue
            
            with gzip.open(fileName, 'rb') as f:
                globalPC = pickle.load(f)
                
                globalPCFut10 = globalPC['globalPCFut10']
                globalPCFut50 = globalPC['globalPCFut50']
                globalPCFut90 = globalPC['globalPCFut90']
            
            print('calculating total capacity outage for %s/+%dC'%(models[model],w))
            
            # over all plants
            for p in range(globalPCFut10.shape[0]):                
                numYears = 0
                yearlyOutagesCurPlant = 0
                
                # calculate the total outage (MW) on each day of each year
                for year in range(globalPCFut10.shape[1]):
                    yearlyTotal = 0
                    numDays = 0
    
                    for day in range(globalPCFut50.shape[2]):
                        outage = (100-globalPCFut50[p,year,day]) / 100.0
                        
                        if outage <= 1 and not np.isnan(globalPlants['caps'][p] * outage * 1/1e6):
                            yearlyTotal += globalPlants['caps'][p] * outage * 1/1e6
                            numDays += 1
                    
                    # divide by actual # of days in this year, then multiply by full summer (62 days)
                    # this accounts for model/years where there are nans
                    if numDays == 62:
#                        yearlyTotal /= numDays
#                        yearlyTotal *= 62
                        
                        yearlyOutagesCurPlant += yearlyTotal
                        numYears += 1
                
                # divide by # of years to get total outage per year
                if numYears > 0:
                    yearlyOutagesCurPlant /= numYears
                else:
                    yearlyOutagesCurPlant = np.nan
                    
                yearlyOutagesCurModel.append(yearlyOutagesCurPlant)
                
            yearlyOutagesCurGMT.append(yearlyOutagesCurModel)
            
        yearlyOutagesFut.append(np.array(yearlyOutagesCurGMT))
    
    yearlyOutagesFut = np.array(yearlyOutagesFut)
    
    with gzip.open('aggregated-global-outages-fut.dat', 'wb') as f:
        pickle.dump(yearlyOutagesFut, f)
        
else:
    
    with gzip.open('aggregated-global-outages-fut.dat', 'rb') as f:
        yearlyOutagesFut = pickle.load(f)



# calculate sum across plants for each GMT scenario/model
outageSumFut = []
for w in range(0, 4):
    outageSumFutCurGMT = []
    for model in range(yearlyOutagesFut[w].shape[0]):
        outageSumFutCurModel = []
        for plant in range(yearlyOutagesFut[w].shape[1]):
            outageSumFutCurModel.append(np.nansum(yearlyOutagesFut[w][model,plant]))
        
        outageSumFutCurGMT.append(outageSumFutCurModel)
    outageSumFut.append(np.array(outageSumFutCurGMT))
outageSumFut = np.array(outageSumFut)
        

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

#xd = np.array(list(range(1981, 2018+1)))-1981+1

#z = np.polyfit(xd, mean10[0,:], 1)
#histPolyTx10 = np.poly1d(z)
#z = np.polyfit(xd, mean50[0,:], 1)
#histPolyTx50 = np.poly1d(z)
#z = np.polyfit(xd, mean90[0,:], 1)
#histPolyTx90 = np.poly1d(z)

xpos = [1, 3, 4, 5, 6]
                               
plt.figure(figsize=(4,4))
plt.xlim([0, 7])
#plt.ylim([-30, 0])
plt.grid(True, alpha = 0.5)

plt.plot(xpos[0], outageSumHist, 'o', markersize=5, color='black', label='Historical')

plt.plot(xpos[1], np.nanmean(np.nansum(outageSumFut[0],axis=1)), 'o', markersize=5, color=snsColors[0], label='+ 1$\degree$C')
plt.errorbar(xpos[1], \
             np.nanmean(np.nansum(outageSumFut[0],axis=1)), \
             yerr = np.nanstd(np.nansum(outageSumFut[0],axis=1)), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[2], np.nanmean(np.nansum(outageSumFut[1],axis=1)), 'o', markersize=5, color=snsColors[0], label='+ 2$\degree$C')
plt.errorbar(xpos[2], \
             np.nanmean(np.nansum(outageSumFut[1],axis=1)), \
             yerr = np.nanstd(np.nansum(outageSumFut[1],axis=1)), \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[3], np.nanmean(np.nansum(outageSumFut[2],axis=1)), 'o', markersize=5, color=snsColors[1], label='+ 3$\degree$C')
plt.errorbar(xpos[3], \
             np.nanmean(np.nansum(outageSumFut[2],axis=1)), \
             yerr = np.nanstd(np.nansum(outageSumFut[2],axis=1)), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos[4], np.nanmean(np.nansum(outageSumFut[3],axis=1)), 'o', markersize=5, color=snsColors[1], label='+ 4$\degree$C')
plt.errorbar(xpos[4], \
             np.nanmean(np.nansum(outageSumFut[3],axis=1)), \
             yerr = np.nanstd(np.nansum(outageSumFut[3],axis=1)), \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')


plt.gca().set_xticks([1, 3, 4, 5, 6])
plt.gca().set_xticklabels(['1981-2018', '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.ylabel('Summer US-EU outage (TW)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'})
leg.get_frame().set_linewidth(0.0)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('accumulated-annual-summer-outage.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)






