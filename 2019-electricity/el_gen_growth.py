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

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

plotFigs = True

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

qstr = '-qdistfit-gamma'

decades = np.array([[2020,2029],\
                   [2030, 2039],\
                   [2040,2049],\
                   [2050,2059],\
                   [2060,2069],\
                   [2070,2079],\
                   [2080,2089]])

# these plants are in the same order as the ones loaded from the lat/lon csv
globalPlants = el_load_global_plants.loadGlobalPlants(world=True)

with open('%s/script-data/active-pp-inds-40-%s.dat'%(dataDirDiscovery, plantData), 'rb') as f:
    livingPlantsInds40 = pickle.load(f)

avgPlantSize = np.nanmean(globalPlants['caps'][livingPlantsInds40[2018]])/1e3

#fileNamePlantLatLon = 'E:/data/ecoffel/data/projects/electricity/script-data/%s-pp-lat-lon.csv'%plantData
#plantLatLon = np.genfromtxt(fileNamePlantLatLon, delimiter=',', skip_header=0)


# in twh over a year
# coal, gas, oil, nuke, bioenergy
iea2017 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7])
iea2025 = np.array([9896.2, 6828.9, 763.2, 3088.7, 890.4])
iea2030 = np.array([10015.9, 7517.4, 675.7, 3252.7, 1056.9])
iea2035 = np.array([10172.0, 8265.5, 597.3, 3520.0, 1238.2])
iea2040 = np.array([10335.1, 9070.6, 527.2, 3725.8, 1427.3])

ieaSust2017 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7])
ieaSust2025 = np.array([7193.0, 6810.0, 604.0, 3302.0, 1039.0])
ieaSust2030 = np.array([4847.0, 6829.0, 413.0, 3887.0, 1324.0])
ieaSust2035 = np.array([3050.0, 6254.0, 274.0, 4534.0, 1646.0])
ieaSust2040 = np.array([1981.0, 5358.0, 197.0, 4960.0, 1967.0])



# convert to EJ
iea2017EJ = iea2017 * 3600 * 1e12 / 1e18
iea2025EJ = iea2025 * 3600 * 1e12 / 1e18
iea2030EJ = iea2030 * 3600 * 1e12 / 1e18
iea2035EJ = iea2035 * 3600 * 1e12 / 1e18
iea2040EJ = iea2040 * 3600 * 1e12 / 1e18

ieaSust2017EJ = iea2017 * 3600 * 1e12 / 1e18
ieaSust2025EJ = iea2025 * 3600 * 1e12 / 1e18
ieaSust2030EJ = iea2030 * 3600 * 1e12 / 1e18
ieaSust2035EJ = iea2035 * 3600 * 1e12 / 1e18
ieaSust2040EJ = iea2040 * 3600 * 1e12 / 1e18


#  convert to MW
iea2017MW = iea2017 * 1e6 / 365 / 24
iea2025MW = iea2025 * 1e6 / 365 / 24
iea2030MW = iea2030 * 1e6 / 365 / 24
iea2035MW = iea2035 * 1e6 / 365 / 24
iea2040MW = iea2040 * 1e6 / 365 / 24

ieaNPSlope = (sum(iea2040MW)-sum(iea2017MW))/(2040-2017)

ieaSust2017MW = ieaSust2017 * 1e6 / 365 / 24
ieaSust2025MW = ieaSust2025 * 1e6 / 365 / 24 
ieaSust2030MW = ieaSust2030 * 1e6 / 365 / 24 
ieaSust2035MW = ieaSust2035 * 1e6 / 365 / 24 
ieaSust2040MW = ieaSust2040 * 1e6 / 365 / 24 

ieaSustSlope = (sum(ieaSust2040MW)-sum(ieaSust2017MW))/(2040-2017)

globalPlantsCapsSust = np.zeros([len(globalPlants['caps']), 1])
globalPlantsNP = np.zeros([len(globalPlants['caps']), 1])

# update plant capacities to match IEA growth slopes for NP and Sust scenarios
for y in range(2018, 2090):
    
    gpSustNew = np.zeros([len(globalPlants['caps']), 1])
    for p in range(len(globalPlants['caps'])):
        if p not in livingPlantsInds40[2018]:
            gpSustNew[p] = np.nan
            continue
        else:
            c = globalPlants['caps'][p]
            gpSustNew[p] = (c + (ieaSustSlope*(y-2018)*(c/np.nansum(globalPlants['caps'][livingPlantsInds40[2018]]))))
    

    gpNPNew = np.zeros([len(globalPlants['caps']), 1])
    for p in range(len(globalPlants['caps'])):
        if p not in livingPlantsInds40[2018]:
            gpNPNew[p] = np.nan
            continue
        else:
            c = globalPlants['caps'][p]
            gpNPNew[p] = (c + (ieaNPSlope*(y-2018)*(c/np.nansum(globalPlants['caps'][livingPlantsInds40[2018]]))))
    
    if y == 2018:
        globalPlantsCapsSust = gpSustNew.copy()
        globalPlantsCapsNP = gpNPNew.copy()
    else:
        globalPlantsCapsSust = np.concatenate((globalPlantsCapsSust, np.array(gpSustNew)), axis=1) 
        globalPlantsCapsNP = np.concatenate((globalPlantsCapsNP, np.array(gpNPNew)), axis=1) 


with open('%s/script-data/pc-change-hist-%s-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData, qstr), 'rb') as f:
    pcChgHist = pickle.load(f)

    pcTxx10 = pcChgHist['pCapTxx10']
    pcTxx50 = pcChgHist['pCapTxx50']
    pcTxx90 = pcChgHist['pCapTxx90']
    

with gzip.open('%s/script-data/demand-projections.dat'%dataDirDiscovery, 'rb') as f:
    demData = pickle.load(f)    
    demHist = demData['demHist']
    demProj = demData['demProj']
    demMult = demData['demMult']
    demByMonth = demData['demByMonthHist']
    demByMonthFut = demData['demByMonthFut']

outagesHist10 = []
outagesHist50 = []
outagesHist90 = []
for p in livingPlantsInds40[2018]:
    plantCap = globalPlants['caps'][p]
    outagesHist10.append(plantCap*np.nanmean(pcTxx10[p])/100.0)
    outagesHist50.append(plantCap*np.nanmean(pcTxx50[p])/100.0)
    outagesHist90.append(plantCap*np.nanmean(pcTxx90[p])/100.0)
outagesHist10 = np.array(outagesHist10)/1e3
outagesHist50 = np.array(outagesHist50)/1e3
outagesHist90 = np.array(outagesHist90)/1e3


with open('%s/script-data/pc-change-fut-%s-%s-%s-rcp85.dat'%(dataDirDiscovery, plantData, runoffData, qstr), 'rb') as f:
    pcChgFut = pickle.load(f)
    pCapTxxFutRcp85_10 = pcChgFut['pCapTxxFutRcp8510']
    pCapTxxFutRcp85_50 = pcChgFut['pCapTxxFutRcp8550']
    pCapTxxFutRcp85_90 = pcChgFut['pCapTxxFutRcp8590']


if os.path.isfile('%s/script-data/pc-change-scenarios-rcp85-%s-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData, qstr)):
    with open('%s/script-data/pc-change-scenarios-rcp85-%s-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData, qstr), 'rb') as f:
        outageScenarios = pickle.load(f)
else:
    outagesFutRcp85_const_10 = []
    outagesFutRcp85_const_50 = []
    outagesFutRcp85_const_90 = []
    
    outagesFutRcp85_40yr_10 = []
    outagesFutRcp85_40yr_50 = []
    outagesFutRcp85_40yr_90 = []
    
    outagesFutRcp85_sust_10 = []
    outagesFutRcp85_sust_50 = []
    outagesFutRcp85_sust_90 = []
    
    outagesFutRcp85_np_10 = []
    outagesFutRcp85_np_50 = []
    outagesFutRcp85_np_90 = []
    
    for m in range(0, pCapTxxFutRcp85_50.shape[0]):
        
        print('processing %s...'%models[m])
        
        outagesFutModel_const_10 = []
        outagesFutModel_const_50 = []
        outagesFutModel_const_90 = []
        
        outagesFutModel_40yr_10 = []
        outagesFutModel_40yr_50 = []
        outagesFutModel_40yr_90 = []
        
        outagesFutModel_sust_10 = []
        outagesFutModel_sust_50 = []
        outagesFutModel_sust_90 = []
        
        outagesFutModel_np_10 = []
        outagesFutModel_np_50 = []
        outagesFutModel_np_90 = []
        
        for d in range(pCapTxxFutRcp85_50.shape[1]):
            outagesFutDecade_const_10 = []
            outagesFutDecade_const_50 = []
            outagesFutDecade_const_90 = []
            
            outagesFutDecade_40yr_10 = []
            outagesFutDecade_40yr_50 = []
            outagesFutDecade_40yr_90 = []
            
            outagesFutDecade_sust_10 = []
            outagesFutDecade_sust_50 = []
            outagesFutDecade_sust_90 = []
            
            outagesFutDecade_np_10 = []
            outagesFutDecade_np_50 = []
            outagesFutDecade_np_90 = []
        
            for p in range(pCapTxxFutRcp85_10.shape[2]):#range(len(pCapTxxFutMeanWarming50[w,m])):
                
                lifespan40Scenario = 2020+((d*10)+5)
                constantScenario = 2018
                
                # constant scenario
                if p not in livingPlantsInds40[constantScenario]:
                    outagesFutDecade_const_10.append(np.nan)
                    outagesFutDecade_const_50.append(np.nan)
                    outagesFutDecade_const_90.append(np.nan)
                else:
                    plantCap = globalPlants['caps'][p]
                    outagesFutDecade_const_10.append(plantCap*np.nanmean(pCapTxxFutRcp85_10[m,d,p,:])/100.0)
                    outagesFutDecade_const_50.append(plantCap*np.nanmean(pCapTxxFutRcp85_50[m,d,p,:])/100.0)
                    outagesFutDecade_const_90.append(plantCap*np.nanmean(pCapTxxFutRcp85_90[m,d,p,:])/100.0)
                
                # 40yr scenario
                if p not in livingPlantsInds40[lifespan40Scenario]:
                    outagesFutDecade_40yr_10.append(np.nan)
                    outagesFutDecade_40yr_50.append(np.nan)
                    outagesFutDecade_40yr_90.append(np.nan)
                else:
                    plantCap = globalPlants['caps'][p]
                    outagesFutDecade_40yr_10.append(plantCap*np.nanmean(pCapTxxFutRcp85_10[m,d,p,:])/100.0)
                    outagesFutDecade_40yr_50.append(plantCap*np.nanmean(pCapTxxFutRcp85_50[m,d,p,:])/100.0)
                    outagesFutDecade_40yr_90.append(plantCap*np.nanmean(pCapTxxFutRcp85_90[m,d,p,:])/100.0)
                
                # sust scenario
                if p not in livingPlantsInds40[constantScenario]:
                    outagesFutDecade_sust_10.append(np.nan)
                    outagesFutDecade_sust_50.append(np.nan)
                    outagesFutDecade_sust_90.append(np.nan)
                else:
                    plantCap = np.nanmean(globalPlantsCapsSust[p,2+(d*10):2+(d*10)+9])
                    outagesFutDecade_sust_10.append(plantCap*np.nanmean(pCapTxxFutRcp85_10[m,d,p,:])/100.0)
                    outagesFutDecade_sust_50.append(plantCap*np.nanmean(pCapTxxFutRcp85_50[m,d,p,:])/100.0)
                    outagesFutDecade_sust_90.append(plantCap*np.nanmean(pCapTxxFutRcp85_90[m,d,p,:])/100.0)
                
                # np scenario
                if p not in livingPlantsInds40[constantScenario]:
                    outagesFutDecade_np_10.append(np.nan)
                    outagesFutDecade_np_50.append(np.nan)
                    outagesFutDecade_np_90.append(np.nan)
                else:
                    plantCap = np.nanmean(globalPlantsCapsNP[p,2+(d*10):2+(d*10)+9])
                    outagesFutDecade_np_10.append(plantCap*np.nanmean(pCapTxxFutRcp85_10[m,d,p,:])/100.0)
                    outagesFutDecade_np_50.append(plantCap*np.nanmean(pCapTxxFutRcp85_50[m,d,p,:])/100.0)
                    outagesFutDecade_np_90.append(plantCap*np.nanmean(pCapTxxFutRcp85_90[m,d,p,:])/100.0)
                
            outagesFutModel_const_10.append(outagesFutDecade_const_10)
            outagesFutModel_const_50.append(outagesFutDecade_const_50)
            outagesFutModel_const_90.append(outagesFutDecade_const_90)
            
            outagesFutModel_40yr_10.append(outagesFutDecade_40yr_10)
            outagesFutModel_40yr_50.append(outagesFutDecade_40yr_50)
            outagesFutModel_40yr_90.append(outagesFutDecade_40yr_90)
            
            outagesFutModel_sust_10.append(outagesFutDecade_sust_10)
            outagesFutModel_sust_50.append(outagesFutDecade_sust_50)
            outagesFutModel_sust_90.append(outagesFutDecade_sust_90)
            
            outagesFutModel_np_10.append(outagesFutDecade_np_10)
            outagesFutModel_np_50.append(outagesFutDecade_np_50)
            outagesFutModel_np_90.append(outagesFutDecade_np_90)
            
        outagesFutRcp85_const_10.append(outagesFutModel_const_10)
        outagesFutRcp85_const_50.append(outagesFutModel_const_50)
        outagesFutRcp85_const_90.append(outagesFutModel_const_90)
        
        outagesFutRcp85_40yr_10.append(outagesFutModel_40yr_10)
        outagesFutRcp85_40yr_50.append(outagesFutModel_40yr_50)
        outagesFutRcp85_40yr_90.append(outagesFutModel_40yr_90)
        
        outagesFutRcp85_sust_10.append(outagesFutModel_sust_10)
        outagesFutRcp85_sust_50.append(outagesFutModel_sust_50)
        outagesFutRcp85_sust_90.append(outagesFutModel_sust_90)
        
        outagesFutRcp85_np_10.append(outagesFutModel_np_10)
        outagesFutRcp85_np_50.append(outagesFutModel_np_50)
        outagesFutRcp85_np_90.append(outagesFutModel_np_90)
    
    outagesFutRcp85_const_10 = np.array(outagesFutRcp85_const_10)
    outagesFutRcp85_const_50 = np.array(outagesFutRcp85_const_50)
    outagesFutRcp85_const_90 = np.array(outagesFutRcp85_const_90)
    
    outagesFutRcp85_40yr_10 = np.array(outagesFutRcp85_40yr_10)
    outagesFutRcp85_40yr_50 = np.array(outagesFutRcp85_40yr_50)
    outagesFutRcp85_40yr_90 = np.array(outagesFutRcp85_40yr_90)
    
    outagesFutRcp85_sust_10 = np.array(outagesFutRcp85_sust_10)
    outagesFutRcp85_sust_50 = np.array(outagesFutRcp85_sust_50)
    outagesFutRcp85_sust_90 = np.array(outagesFutRcp85_sust_90)
    
    outagesFutRcp85_np_10 = np.array(outagesFutRcp85_np_10)
    outagesFutRcp85_np_50 = np.array(outagesFutRcp85_np_50)
    outagesFutRcp85_np_90 = np.array(outagesFutRcp85_np_90)
    
    
    outageScenarios = {'const10':outagesFutRcp85_const_10/1e3,\
                       'const50':outagesFutRcp85_const_50/1e3,\
                       'const90':outagesFutRcp85_const_90/1e3,\
                       '40yr10':outagesFutRcp85_40yr_10/1e3,\
                       '40yr50':outagesFutRcp85_40yr_50/1e3,\
                       '40yr90':outagesFutRcp85_40yr_90/1e3,\
                       'sust10':outagesFutRcp85_sust_10/1e3,\
                       'sust50':outagesFutRcp85_sust_50/1e3,\
                       'sust90':outagesFutRcp85_sust_90/1e3,\
                       'np10':outagesFutRcp85_np_10/1e3,\
                       'np50':outagesFutRcp85_np_50/1e3,\
                       'np90':outagesFutRcp85_np_90/1e3}
    
    with open('%s/script-data/pc-change-scenarios-rcp85-%s-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData, qstr), 'wb') as f:
        pickle.dump(outageScenarios, f)





snsColors = sns.color_palette(["#3498db", "#e74c3c"])


decadesToShow = [d[0]+5 for d in decades]
yaxis1Ticks = np.arange(-175,1,25)
yaxis2Ticks = [int(-x) for x in yaxis1Ticks/avgPlantSize]

plt.figure(figsize=(6,4))
plt.ylim([-190, 0])
plt.xlim([2016,2087])
plt.grid(True, color=[.9,.9,.9])


yPtHist = np.nanmean([np.nansum(outagesHist10), np.nansum(outagesHist90)])
pHist = plt.plot(2018, \
         yPtHist, \
          'o', markersize=6, color='k', label='Historical')
yerrHist = np.zeros([2,1])
yerrHist[0,0] = yPtHist-np.nansum(outagesHist90)
yerrHist[1,0] = np.nansum(outagesHist10)-yPtHist
plt.errorbar(2018, \
             yPtHist, \
             yerr = yerrHist, \
             ecolor = 'k', elinewidth = 1, capsize = 3, fmt = 'none')


plt.fill_between(decadesToShow[0:2], np.nanmean(np.nansum(outageScenarios['40yr10'][:,0:2,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['40yr90'][:,0:2,:], axis=2), axis=0), \
                                           facecolor='#56a619', alpha=.5, interpolate=True)
                                           
plt.fill_between(decadesToShow[2:], np.nanmean(np.nansum(outageScenarios['40yr10'][:,2:,:], axis=2), axis=0), \
                 np.nanmean(np.nansum(outageScenarios['40yr90'][:,2:,:], axis=2), axis=0), \
                 facecolor='#56a619', alpha=.5, interpolate=True)
outageMean40yr = (outageScenarios['40yr10']+outageScenarios['40yr90'])/2.0
plt.plot(decadesToShow[0:2], np.nanmean(np.nansum(outageMean40yr[:,0:2,:], axis=2), axis=0), '-k', color='#56a619', lw=2)
plt.plot(decadesToShow[2:], np.nanmean(np.nansum(outageMean40yr[:,2:,:], axis=2), axis=0), '-k', color='#56a619', lw=2)
plt.plot([2025, 2085], [np.nanmean(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=0)), \
                        np.nanmean(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=0))], \
                        '--k', color='#56a619', lw=1)
yPt40yr2040 = np.nanmean(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=0))
p40Yr = plt.plot(2043, \
         yPt40yr2040, \
          'ok', markersize=6, markerfacecolor='#56a619', label='40 Year\nLifespan')
yerr40yr = np.zeros([2,1])
yerr40yr[0,0] = np.nanmean(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=0))-np.nanmin(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=1))
yerr40yr[1,0] = np.nanmax(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=1))-np.nanmean(np.nanmean(np.nansum(outageMean40yr[:,1:3,:], axis=2), axis=0))
plt.errorbar(2043, \
             yPt40yr2040, \
             yerr = yerr40yr, \
             ecolor = '#56a619', elinewidth = 1, capsize = 3, fmt = 'none')



plt.fill_between(decadesToShow[0:2], np.nanmean(np.nansum(outageScenarios['sust10'][:,0:2,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['sust90'][:,0:2,:], axis=2), axis=0), \
                                           facecolor=snsColors[0], alpha=.5, interpolate=True)
plt.fill_between(decadesToShow[2:], np.nanmean(np.nansum(outageScenarios['sust10'][:,2:,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['sust90'][:,2:,:], axis=2), axis=0), \
                                           facecolor=snsColors[0], alpha=.5, interpolate=True)
outageMeanSust = (outageScenarios['sust10']+outageScenarios['sust90'])/2.0
plt.plot(decadesToShow[0:2], np.nanmean(np.nansum(outageMeanSust[:,0:2,:], axis=2), axis=0), '-k', color=snsColors[0], lw=2)
plt.plot(decadesToShow[2:], np.nanmean(np.nansum(outageMeanSust[:,2:,:], axis=2), axis=0), '-k', color=snsColors[0], lw=2)
plt.plot([2025, 2085], [np.nanmean(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=0)), \
                        np.nanmean(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=0))], \
                        '--k', color=snsColors[0], lw=1)
yPtSust2040 = np.nanmean(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=0))
pSust = plt.plot(2041, \
         yPtSust2040, \
          'ok', markersize=6, markerfacecolor=snsColors[0], label='IEA\nSustainable')
yerrSust = np.zeros([2,1])
yerrSust[0,0] = np.nanmean(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=0))-np.nanmin(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=1))
yerrSust[1,0] = np.nanmax(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=1))-np.nanmean(np.nanmean(np.nansum(outageMeanSust[:,1:3,:], axis=2), axis=0))
plt.errorbar(2041, \
             yPtSust2040, \
             yerr = yerrSust, \
             ecolor = snsColors[0], elinewidth = 1, capsize = 3, fmt = 'none')




plt.fill_between(decadesToShow[0:2], np.nanmean(np.nansum(outageScenarios['const10'][:,0:2,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['const90'][:,0:2,:], axis=2), axis=0), \
                                           facecolor='gray', alpha=.5, interpolate=True)
plt.fill_between(decadesToShow[2:], np.nanmean(np.nansum(outageScenarios['const10'][:,2:,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['const90'][:,2:,:], axis=2), axis=0), \
                                           facecolor='gray', alpha=.5, interpolate=True)
outageMeanConst = (outageScenarios['const10']+outageScenarios['const90'])/2.0
plt.plot(decadesToShow[0:2], np.nanmean(np.nansum(outageMeanConst[:,0:2,:], axis=2), axis=0), '-k', color='gray', lw=2)
plt.plot(decadesToShow[2:], np.nanmean(np.nansum(outageMeanConst[:,2:,:], axis=2), axis=0), '-k', color='gray', lw=2)
plt.plot([2025, 2085], [np.nanmean(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=0)), \
                        np.nanmean(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=0))], \
                        '--k', color='gray', lw=1)
yPtConst2040 = np.nanmean(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=0))
pConst = plt.plot(2039, \
         yPtConst2040, \
          'ok', markersize=6, markerfacecolor='gray', label='Constant')
yerrConst = np.zeros([2,1])
yerrConst[0,0] = np.nanmean(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=0))-np.nanmin(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=1))
yerrConst[1,0] = np.nanmax(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=1))-np.nanmean(np.nanmean(np.nansum(outageMeanConst[:,1:3,:], axis=2), axis=0))
plt.errorbar(2039, \
             yPtConst2040, \
             yerr = yerrConst, \
             ecolor = 'gray', elinewidth = 1, capsize = 3, fmt = 'none')



plt.fill_between(decadesToShow[0:2], np.nanmean(np.nansum(outageScenarios['np10'][:,0:2,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['np90'][:,0:2,:], axis=2), axis=0), \
                                           facecolor=snsColors[1], alpha=.5, interpolate=True)
plt.fill_between(decadesToShow[2:], np.nanmean(np.nansum(outageScenarios['np10'][:,2:,:], axis=2), axis=0), \
                                np.nanmean(np.nansum(outageScenarios['np90'][:,2:,:], axis=2), axis=0), \
                                           facecolor=snsColors[1], alpha=.5, interpolate=True)
outageMeanNP = (outageScenarios['np10']+outageScenarios['np90'])/2.0
plt.plot(decadesToShow[0:2], np.nanmean(np.nansum(outageMeanNP[:,0:2,:], axis=2), axis=0), '-k', color=snsColors[1], lw=2)
plt.plot(decadesToShow[2:], np.nanmean(np.nansum(outageMeanNP[:,2:,:], axis=2), axis=0), '-k', color=snsColors[1], lw=2)
plt.plot([2025, 2085], [np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0)), \
                        np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0))], \
                        '--k', color=snsColors[1], lw=1)
yPtNP2040 = np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0))
pNP = plt.plot(2037, \
         yPtNP2040, \
          'ok', markersize=6, markerfacecolor=snsColors[1], label='IEA New\nPolicies')
yerrNP = np.zeros([2,1])
yerrNP[0,0] = np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0))-np.nanmin(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=1))
yerrNP[1,0] = np.nanmax(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=1))-np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0))
plt.errorbar(2037, \
             yPtNP2040, \
             yerr = yerrNP, \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot([2035, 2035], [-190, 0], '-k', lw=2)
plt.plot([2045, 2045], [-190, 0], '-k', lw=2)

plt.ylabel('Global curtailment (GW)', fontname = 'Helvetica', fontsize=16)
#plt.xlabel('GMT change', fontname = 'Helvetica', fontsize=16)

plt.xticks([2018, 2025, 2035, 2045, 2055, 2065, 2075, 2085])
plt.yticks(yaxis1Ticks)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(12)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(13)


leg = plt.legend(prop = {'size':9, 'family':'Helvetica'}, \
                 loc='lower left', bbox_to_anchor=(-.0145, 0.125))
leg.get_frame().set_linewidth(0.0)

ax2 = plt.twinx()
plt.ylim([-190, 0])
plt.ylabel('# Average power plants', fontname = 'Helvetica', fontsize=16)
plt.yticks(yaxis1Ticks)
plt.gca().set_yticklabels(yaxis2Ticks)

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

if plotFigs:
    plt.savefig('global-curtailment.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)


plt.show()
sys.exit()





# using mean GMT warming
outagesFut10 = []
outagesFut50 = []
outagesFut90 = []
for w in range(1, 4+1):
    
    with open('E:/data/ecoffel/data/projects/electricity/script-data/pc-change-fut-%s-%s-%s-gmt%d.dat'%(plantData, runoffData, qstr, w), 'rb') as f:
        pcChgFut = pickle.load(f)
        pCapTxxFutMeanWarming10 = pcChgFut['pCapTxxFutMeanWarming10']
        pCapTxxFutMeanWarming50 = pcChgFut['pCapTxxFutMeanWarming50']
        pCapTxxFutMeanWarming90 = pcChgFut['pCapTxxFutMeanWarming90']
    
    outagesFutGMT10 = []
    outagesFutGMT50 = []
    outagesFutGMT90 = []
    for m in range(0, pCapTxxFutMeanWarming50.shape[0]):
        outagesFutModel10 = []
        outagesFutModel50 = []
        outagesFutModel90 = []
        for p in livingPlantsInds40[2018]:#range(len(pCapTxxFutMeanWarming50[w,m])):
            
            if p >= len(pCapTxxFutMeanWarming10[m]):
                continue
            
            plantCap = globalPlants['caps'][p]
            outagesFutModel10.append(plantCap*np.nanmean(pCapTxxFutMeanWarming10[m][p])/100.0)
            outagesFutModel50.append(plantCap*np.nanmean(pCapTxxFutMeanWarming50[m][p])/100.0)
            outagesFutModel90.append(plantCap*np.nanmean(pCapTxxFutMeanWarming90[m][p])/100.0)
        outagesFutGMT10.append(outagesFutModel10)
        outagesFutGMT50.append(outagesFutModel50)
        outagesFutGMT90.append(outagesFutModel90)
    outagesFut10.append(outagesFutGMT10)
    outagesFut50.append(outagesFutGMT50)
    outagesFut90.append(outagesFutGMT90)
    
outagesFut10 = np.array(outagesFut10) 
outagesFut50 = np.array(outagesFut50) 
outagesFut90 = np.array(outagesFut90) 





sys.exit()
snsColors = sns.color_palette(["#3498db", "#e74c3c"])

ytickRange = np.arange(-100000,1,20000)
ytickLabels = np.arange(-100,1,20)
plt.figure(figsize=(3,4))
plt.xlim([-.5, 4.5])
plt.ylim([-100000,0])
plt.grid(True, color=[.9,.9,.9])

plt.plot(-.15, \
         np.nansum(outagesHist90), \
          'o', markersize=5, color=cmx.tab20(0))
plt.plot(0, \
         np.nansum(outagesHist50), \
          'o', markersize=5, color='k')
plt.plot(.15, \
         np.nansum(outagesHist10), \
          'o', markersize=5, color=cmx.tab20(6))


xpos = np.array([1,2,3,4])
plt.plot(xpos-.15, \
         np.nanmean(np.nansum(outagesFut90,axis=2),axis=1), \
          'o', markersize=5, color=cmx.tab20(0), label='10th Percentile')
plt.errorbar(xpos-.15, \
             np.nanmean(np.nansum(outagesFut90,axis=2),axis=1), \
             yerr = np.nanstd(np.nansum(outagesFut90,axis=2),axis=1), \
             ecolor = cmx.tab20(0), elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos, \
         np.nanmean(np.nansum(outagesFut50,axis=2),axis=1), \
          'o', markersize=5, color='k', label='50th Percentile')

plt.errorbar(xpos, \
             np.nanmean(np.nansum(outagesFut50,axis=2),axis=1), \
             yerr = np.nanstd(np.nansum(outagesFut50,axis=2),axis=1), \
             ecolor = 'k', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot(xpos+.15, \
         np.nanmean(np.nansum(outagesFut10,axis=2),axis=1), \
          'o', markersize=5, color=cmx.tab20(6), label='90th Percentile')
plt.errorbar(xpos+.15, \
             np.nanmean(np.nansum(outagesFut10,axis=2),axis=1), \
             yerr = np.nanstd(np.nansum(outagesFut50,axis=2),axis=1), \
             ecolor = cmx.tab20(6), elinewidth = 1, capsize = 3, fmt = 'none')

plt.ylabel('Global curtailment (GW)', fontname = 'Helvetica', fontsize=16)
plt.xlabel('GMT change', fontname = 'Helvetica', fontsize=16)
plt.xticks([0,1,2,3,4])
plt.gca().set_xticklabels(['Hist', '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])
plt.yticks(ytickRange)
plt.gca().set_yticklabels(ytickLabels)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(prop = {'size':10, 'family':'Helvetica'}, \
                 loc='lower left')
leg.get_frame().set_linewidth(0.0)


ax2 = plt.twinx()
plt.ylim([-100000,0])
ytickLabels = [int(x/(np.nanmean(globalPlants['caps'][livingPlantsInds40[2018]])/1e3)) for x in ytickLabels]
plt.ylabel('# Average power plants', fontname = 'Helvetica', fontsize=16)
plt.yticks(ytickRange)
plt.gca().set_yticklabels(ytickLabels)

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

if plotFigs:
    plt.savefig('global-curtailment.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

sys.exit()
#
#pcDiff10 = np.nanmean(pCapTxxFutMeanWarming10, axis=2) - np.nanmean(pcTxx10)
#pcDiff50 = np.nanmean(pCapTxxFutMeanWarming50, axis=2) - np.nanmean(pcTxx50)
#pcDiff90 = np.nanmean(pCapTxxFutMeanWarming90, axis=2) - np.nanmean(pcTxx90)
#
#demDiff = np.nanmax(demProj, axis=2) - np.nanmax(demHist)
#demDiffPct = 100*(np.nanmax(demProj, axis=2) - np.nanmax(demHist))/np.nanmax(demHist)
#
#additionalGenGrowth10 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff10/100)) - np.nanmax(demHist))/demDiff)-100
#additionalGenGrowth50 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff50/100)) - np.nanmax(demHist))/demDiff)-100
#additionalGenGrowth90 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff90/100)) - np.nanmax(demHist))/demDiff)-100
#
#additionalGen10 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff10/100)) - np.nanmax(demHist))/np.nanmax(demHist))
#additionalGen50 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff50/100)) - np.nanmax(demHist))/np.nanmax(demHist))
#additionalGen90 = 100*(((np.nanmax(demProj, axis=2) - np.nanmax(demProj, axis=2)*(pcDiff90/100)) - np.nanmax(demHist))/np.nanmax(demHist))
#
#additionalGenPctPt10 = additionalGen10-demDiffPct
#additionalGenPctPt50 = additionalGen50-demDiffPct
#additionalGenPctPt90 = additionalGen90-demDiffPct
#
#additionalGenGrowth10[additionalGenGrowth10<0] = np.nan
#
#xpos = np.arange(1,5)
#
#plt.figure(figsize=(3,4))
#plt.xlim([.25, 5.25])
#plt.ylim([0, 24])
#plt.grid(True, color=[.9,.9,.9])
#for i in range(demDiffPct.shape[0]):
#    pp = np.nanmean(demDiffPct[i,:])
#    
#    if i == 0:
#        labelLine = 'Warming'
#    else:
#        labelLine = None
#    
#    plt.plot([0, xpos[i]+.4], [pp, pp], '--', color = 'black', label=labelLine)
#
#ydata90 = np.nanmean(additionalGen90,axis=1)
#ydata50 = np.nanmean(additionalGen50,axis=1)
#ydata10 = np.nanmean(additionalGen10,axis=1)
#for x in range(len(xpos)):
#    
#    if x == 0:
#        label10 = '10th Percentile'
#        label50 = '50th Percentile'
#        label90 = '90th Percentile'
#    else:
#        label10 = None
#        label50 = None
#        label90 = None
#    
#    l1 = plt.plot(xpos[x]-.25, ydata90[x], marker='o', markersize=8, color = snsColors[0], label=label10)
#    l2 = plt.plot(xpos[x], ydata50[x], marker='o', markersize=8, color = 'black', label=label50)
#    l3 = plt.plot(xpos[x]+.25, ydata10[x], marker='o', markersize=8, color = snsColors[1], label=label90)
#
#yax = np.arange(0, 25, 3)
#
#plt.xticks(range(1,5))
#plt.yticks(yax)
#plt.ylabel('Warming-driven growth (%)', fontname = 'Helvetica', fontsize=16)
#plt.xlabel('GMT Change', fontname = 'Helvetica', fontsize=16)
#plt.gca().set_xticklabels(['1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])
#
#for tick in plt.gca().xaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')
#    tick.label.set_fontsize(14)
#for tick in plt.gca().yaxis.get_major_ticks():
#    tick.label.set_fontname('Helvetica')    
#    tick.label.set_fontsize(14)
#
#
#leg = plt.legend(prop = {'size':9, 'family':'Helvetica'}, \
#                 loc='lower right')
#leg.get_frame().set_linewidth(0.0)
#
#ax2 = plt.twinx()
#plt.ylim([0, 24])
#plt.ylabel('Warming-driven growth (GW)', fontname = 'Helvetica', fontsize=16)
#plt.yticks(yax)
#plt.gca().set_yticklabels([int(x) for x in np.round(yax/100 * np.nansum(globalPlants['caps']) / 1e3)])
#
#for tick in plt.gca().yaxis.get_major_ticks():
#    tick.label2.set_fontname('Helvetica')    
#    tick.label2.set_fontsize(14)
#
#if plotFigs:
#    plt.savefig('gen-growth-warming-curtailment.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
#
#
#ieaCurtailment = np.nansum(np.array([iea2017*np.nanmean(additionalGen50[0,:]/100), \
#                                     iea2025*np.nanmean(additionalGen50[1,:]/100), \
#                                     iea2030*np.nanmean(additionalGen50[1,:]/100), \
#                                     iea2035*np.nanmean(additionalGen50[1,:]/100), \
#                                     iea2040*np.nanmean(additionalGen50[2,:]/100)]), axis=1)

ieaCoal = np.array([iea2017[0], iea2025[0], iea2030[0], iea2035[0], iea2040[0]])
ieaGas = np.array([iea2017[1], iea2025[1], iea2030[1], iea2035[1], iea2040[1]]) 
ieaOil = np.array([iea2017[2], iea2025[2], iea2030[2], iea2035[2], iea2040[2]])
ieaNuke = np.array([iea2017[3], iea2025[3], iea2030[3], iea2035[3], iea2040[3]])
ieaBio = np.array([iea2017[4], iea2025[4], iea2030[4], iea2035[4], iea2040[4]])

ieaSustCoal = np.array([ieaSust2017[0], ieaSust2025[0], ieaSust2030[0], ieaSust2035[0], ieaSust2040[0]])
ieaSustGas = np.array([ieaSust2017[1], ieaSust2025[1], ieaSust2030[1], ieaSust2035[1], ieaSust2040[1]]) 
ieaSustOil = np.array([ieaSust2017[2], ieaSust2025[2], ieaSust2030[2], ieaSust2035[2], ieaSust2040[2]])
ieaSustNuke = np.array([ieaSust2017[3], ieaSust2025[3], ieaSust2030[3], ieaSust2035[3], ieaSust2040[3]])
ieaSustBio = np.array([ieaSust2017[4], ieaSust2025[4], ieaSust2030[4], ieaSust2035[4], ieaSust2040[4]])

ieaDates = np.array([2017, 2025, 2030, 2035, 2040])
ieaLegend = ['Coal', 'Gas', 'Oil', 'Nuke', 'Bio', 'Warming+\nCurtailment']

barW = 3

plt.figure(figsize=(2,4))
plt.ylim([0,100])
plt.grid(True, color=[.9,.9,.9], axis='y')

plt.bar(ieaDates, ieaCoal, width=barW, color='#f03b20')
plt.bar(ieaDates, ieaGas, bottom=ieaCoal, width=barW, color='#3182bd')
plt.bar(ieaDates, ieaOil, bottom=ieaCoal+ieaGas, width=barW, color='black')
plt.bar(ieaDates, ieaNuke, bottom=ieaCoal+ieaGas+ieaOil, width=barW, color='orange')
plt.bar(ieaDates, ieaBio, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke, width=barW, color='#56a619')
#plt.bar(ieaDates, ieaCurtailment, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke+ieaBio, width=barW, color='#7c7d7a', hatch='/')

plt.xticks([2017, 2025, 2030, 2035, 2040])
#plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Energy (EJ)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#leg = plt.legend(ieaLegend, prop = {'size':11, 'family':'Helvetica'}, \
#                 loc='right', bbox_to_anchor=(1.8, .5))
#leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('iea-by-type-new-policies.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



plt.figure(figsize=(2,4))
plt.ylim([0,100])
plt.grid(True, color=[.9,.9,.9], axis='y')

plt.bar(ieaDates, ieaSustCoal, width=barW, color='#f03b20')
plt.bar(ieaDates, ieaSustGas, bottom=ieaSustCoal, width=barW, color='#3182bd')
plt.bar(ieaDates, ieaSustOil, bottom=ieaSustCoal+ieaSustGas, width=barW, color='black')
plt.bar(ieaDates, ieaSustNuke, bottom=ieaSustCoal+ieaSustGas+ieaSustOil, width=barW, color='orange')
plt.bar(ieaDates, ieaSustBio, bottom=ieaSustCoal+ieaSustGas+ieaSustOil+ieaSustNuke, width=barW, color='#56a619')
#plt.bar(ieaDates, ieaCurtailment, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke+ieaBio, width=barW, color='#7c7d7a', hatch='/')

plt.xticks([2017, 2025, 2030, 2035, 2040])
#plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Energy (EJ)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

leg = plt.legend(ieaLegend, prop = {'size':11, 'family':'Helvetica'}, \
                 loc='right', bbox_to_anchor=(1.7, .5))
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('iea-by-type-sustainable.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


plt.show()


