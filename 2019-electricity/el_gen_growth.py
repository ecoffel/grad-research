# -*- coding: utf-8 -*-
"""
Created on Wed Jun 26 15:19:34 2019

@author: Ethan
"""

import matplotlib.pyplot as plt 
import matplotlib.cm as cmx
import seaborn as sns
import statsmodels.api as sm
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

plotFigs = False

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

rcp = 'rcp85'

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
iea2018 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7])
iea2025 = np.array([9896.2, 6828.9, 763.2, 3088.7, 890.4])
iea2030 = np.array([10015.9, 7517.4, 675.7, 3252.7, 1056.9])
iea2035 = np.array([10172.0, 8265.5, 597.3, 3520.0, 1238.2])
iea2040 = np.array([10335.1, 9070.6, 527.2, 3725.8, 1427.3])

ieaSust2018 = np.array([9858.1, 5855.4, 939.6, 2636.8, 622.7])
ieaSust2025 = np.array([7193.0, 6810.0, 604.0, 3302.0, 1039.0])
ieaSust2030 = np.array([4847.0, 6829.0, 413.0, 3887.0, 1324.0])
ieaSust2035 = np.array([3050.0, 6254.0, 274.0, 4534.0, 1646.0])
ieaSust2040 = np.array([1981.0, 5358.0, 197.0, 4960.0, 1967.0])



# convert to EJ
iea2018EJ = iea2018 * 3600 * 1e12 / 1e18
iea2025EJ = iea2025 * 3600 * 1e12 / 1e18
iea2030EJ = iea2030 * 3600 * 1e12 / 1e18
iea2035EJ = iea2035 * 3600 * 1e12 / 1e18
iea2040EJ = iea2040 * 3600 * 1e12 / 1e18

ieaSust2018EJ = iea2018 * 3600 * 1e12 / 1e18
ieaSust2025EJ = iea2025 * 3600 * 1e12 / 1e18
ieaSust2030EJ = iea2030 * 3600 * 1e12 / 1e18
ieaSust2035EJ = iea2035 * 3600 * 1e12 / 1e18
ieaSust2040EJ = iea2040 * 3600 * 1e12 / 1e18


#  convert to MW
iea2018MW = iea2018 * 1e6 / 365 / 24
iea2025MW = iea2025 * 1e6 / 365 / 24
iea2030MW = iea2030 * 1e6 / 365 / 24
iea2035MW = iea2035 * 1e6 / 365 / 24
iea2040MW = iea2040 * 1e6 / 365 / 24

ieaNPSlope = (sum(iea2040MW)-sum(iea2018MW))/(2040-2018)

ieaSust2018MW = ieaSust2018 * 1e6 / 365 / 24
ieaSust2025MW = ieaSust2025 * 1e6 / 365 / 24 
ieaSust2030MW = ieaSust2030 * 1e6 / 365 / 24 
ieaSust2035MW = ieaSust2035 * 1e6 / 365 / 24 
ieaSust2040MW = ieaSust2040 * 1e6 / 365 / 24 

ieaSustSlope = (sum(ieaSust2040MW)-sum(ieaSust2018MW))/(2040-2018)

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

with open('%s/script-data/world-plant-caps-iea-scenarios.dat'%dataDirDiscovery, 'wb') as f:
    scenarios = {'globalPlantsCapsSust':globalPlantsCapsSust, \
                 'globalPlantsCapsNP':globalPlantsCapsNP}
    pickle.dump(scenarios, f)

with open('%s/script-data/pc-at-txx-hist-%s-%s-1981-2018.dat'%(dataDirDiscovery, plantData, runoffData), 'rb') as f:
    pcChgHist = pickle.load(f)

    pcTxx10 = pcChgHist['pCapTxx10']
    pcTxx50 = pcChgHist['pCapTxx50']
    pcTxx90 = pcChgHist['pCapTxx90']
    
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

outagesHistTrend10 = np.zeros([pcTxx50.shape[1],1])
outagesHistTrend50 = np.zeros([pcTxx50.shape[1],1])
outagesHistTrend90 = np.zeros([pcTxx50.shape[1],1])
for y in range(pcTxx50.shape[1]):
    outagesHistTrend10[y] = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]] * (pcTxx10[livingPlantsInds40[2018], y]/100.0))/1e3
    outagesHistTrend50[y] = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]] * (pcTxx50[livingPlantsInds40[2018], y]/100.0))/1e3
    outagesHistTrend90[y] = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]] * (pcTxx90[livingPlantsInds40[2018], y]/100.0))/1e3


X = sm.add_constant(len(outagesHistTrend50))
mdl = sm.OLS(outagesHistTrend50, X).fit()

sys.exit()

with open('%s/script-data/pc-at-txx-change-fut-%s-%s-%s.dat'%(dataDirDiscovery, plantData, runoffData, rcp), 'rb') as f:
    pcChgFut = pickle.load(f)
    
    # at the moment the key is Rcp85 for both scenarios - just stored in different files
    pCapTxxFutCurRcp_10 = pcChgFut['pCapTxxFutRcp8510']
    pCapTxxFutCurRcp_50 = pcChgFut['pCapTxxFutRcp8550']
    pCapTxxFutCurRcp_90 = pcChgFut['pCapTxxFutRcp8590']


if os.path.isfile('%s/script-data/pc-change-scenarios-%s-%s-%s.dat'%(dataDirDiscovery, rcp, plantData, runoffData)):
    with open('%s/script-data/pc-change-scenarios-%s-%s-%s.dat'%(dataDirDiscovery, rcp, plantData, runoffData), 'rb') as f:
        outageScenarios = pickle.load(f)
else:
    outagesFutCurRcp_const_10 = []
    outagesFutCurRcp_const_50 = []
    outagesFutCurRcp_const_90 = []
    
    outagesFutCurRcp_40yr_10 = []
    outagesFutCurRcp_40yr_50 = []
    outagesFutCurRcp_40yr_90 = []
    
    outagesFutCurRcp_sust_10 = []
    outagesFutCurRcp_sust_50 = []
    outagesFutCurRcp_sust_90 = []
    
    outagesFutCurRcp_np_10 = []
    outagesFutCurRcp_np_50 = []
    outagesFutCurRcp_np_90 = []
    
    for m in range(0, pCapTxxFutCurRcp_50.shape[0]):
        
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
        
        for d in range(pCapTxxFutCurRcp_50.shape[1]):
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
        
            for p in range(pCapTxxFutCurRcp_10.shape[2]):#range(len(pCapTxxFutMeanWarming50[w,m])):
                
                lifespan40Scenario = 2020+((d*10)+5)
                constantScenario = 2018
                
                # constant scenario
                if p not in livingPlantsInds40[constantScenario]:
                    outagesFutDecade_const_10.append(np.nan)
                    outagesFutDecade_const_50.append(np.nan)
                    outagesFutDecade_const_90.append(np.nan)
                else:
                    plantCap = globalPlants['caps'][p]
                    outagesFutDecade_const_10.append(plantCap*np.nanmean(pCapTxxFutCurRcp_10[m,d,p,:])/100.0)
                    outagesFutDecade_const_50.append(plantCap*np.nanmean(pCapTxxFutCurRcp_50[m,d,p,:])/100.0)
                    outagesFutDecade_const_90.append(plantCap*np.nanmean(pCapTxxFutCurRcp_90[m,d,p,:])/100.0)
                
                # 40yr scenario
                if p not in livingPlantsInds40[lifespan40Scenario]:
                    outagesFutDecade_40yr_10.append(np.nan)
                    outagesFutDecade_40yr_50.append(np.nan)
                    outagesFutDecade_40yr_90.append(np.nan)
                else:
                    plantCap = globalPlants['caps'][p]
                    outagesFutDecade_40yr_10.append(plantCap*np.nanmean(pCapTxxFutCurRcp_10[m,d,p,:])/100.0)
                    outagesFutDecade_40yr_50.append(plantCap*np.nanmean(pCapTxxFutCurRcp_50[m,d,p,:])/100.0)
                    outagesFutDecade_40yr_90.append(plantCap*np.nanmean(pCapTxxFutCurRcp_90[m,d,p,:])/100.0)
                
                # sust scenario
                if p not in livingPlantsInds40[constantScenario]:
                    outagesFutDecade_sust_10.append(np.nan)
                    outagesFutDecade_sust_50.append(np.nan)
                    outagesFutDecade_sust_90.append(np.nan)
                else:
                    plantCap = np.nanmean(globalPlantsCapsSust[p,2+(d*10):2+(d*10)+9])
                    outagesFutDecade_sust_10.append(plantCap*np.nanmean(pCapTxxFutCurRcp_10[m,d,p,:])/100.0)
                    outagesFutDecade_sust_50.append(plantCap*np.nanmean(pCapTxxFutCurRcp_50[m,d,p,:])/100.0)
                    outagesFutDecade_sust_90.append(plantCap*np.nanmean(pCapTxxFutCurRcp_90[m,d,p,:])/100.0)
                
                # np scenario
                if p not in livingPlantsInds40[constantScenario]:
                    outagesFutDecade_np_10.append(np.nan)
                    outagesFutDecade_np_50.append(np.nan)
                    outagesFutDecade_np_90.append(np.nan)
                else:
                    plantCap = np.nanmean(globalPlantsCapsNP[p,2+(d*10):2+(d*10)+9])
                    outagesFutDecade_np_10.append(plantCap*np.nanmean(pCapTxxFutCurRcp_10[m,d,p,:])/100.0)
                    outagesFutDecade_np_50.append(plantCap*np.nanmean(pCapTxxFutCurRcp_50[m,d,p,:])/100.0)
                    outagesFutDecade_np_90.append(plantCap*np.nanmean(pCapTxxFutCurRcp_90[m,d,p,:])/100.0)
                
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
            
        outagesFutCurRcp_const_10.append(outagesFutModel_const_10)
        outagesFutCurRcp_const_50.append(outagesFutModel_const_50)
        outagesFutCurRcp_const_90.append(outagesFutModel_const_90)
        
        outagesFutCurRcp_40yr_10.append(outagesFutModel_40yr_10)
        outagesFutCurRcp_40yr_50.append(outagesFutModel_40yr_50)
        outagesFutCurRcp_40yr_90.append(outagesFutModel_40yr_90)
        
        outagesFutCurRcp_sust_10.append(outagesFutModel_sust_10)
        outagesFutCurRcp_sust_50.append(outagesFutModel_sust_50)
        outagesFutCurRcp_sust_90.append(outagesFutModel_sust_90)
        
        outagesFutCurRcp_np_10.append(outagesFutModel_np_10)
        outagesFutCurRcp_np_50.append(outagesFutModel_np_50)
        outagesFutCurRcp_np_90.append(outagesFutModel_np_90)
    
    outagesFutCurRcp_const_10 = np.array(outagesFutCurRcp_const_10)
    outagesFutCurRcp_const_50 = np.array(outagesFutCurRcp_const_50)
    outagesFutCurRcp_const_90 = np.array(outagesFutCurRcp_const_90)
    
    outagesFutCurRcp_40yr_10 = np.array(outagesFutCurRcp_40yr_10)
    outagesFutCurRcp_40yr_50 = np.array(outagesFutCurRcp_40yr_50)
    outagesFutCurRcp_40yr_90 = np.array(outagesFutCurRcp_40yr_90)
    
    outagesFutCurRcp_sust_10 = np.array(outagesFutCurRcp_sust_10)
    outagesFutCurRcp_sust_50 = np.array(outagesFutCurRcp_sust_50)
    outagesFutCurRcp_sust_90 = np.array(outagesFutCurRcp_sust_90)
    
    outagesFutCurRcp_np_10 = np.array(outagesFutCurRcp_np_10)
    outagesFutCurRcp_np_50 = np.array(outagesFutCurRcp_np_50)
    outagesFutCurRcp_np_90 = np.array(outagesFutCurRcp_np_90)
    
    outageScenarios = {'const10':outagesFutCurRcp_const_10/1e3,\
                       'const50':outagesFutCurRcp_const_50/1e3,\
                       'const90':outagesFutCurRcp_const_90/1e3,\
                       '40yr10':outagesFutCurRcp_40yr_10/1e3,\
                       '40yr50':outagesFutCurRcp_40yr_50/1e3,\
                       '40yr90':outagesFutCurRcp_40yr_90/1e3,\
                       'sust10':outagesFutCurRcp_sust_10/1e3,\
                       'sust50':outagesFutCurRcp_sust_50/1e3,\
                       'sust90':outagesFutCurRcp_sust_90/1e3,\
                       'np10':outagesFutCurRcp_np_10/1e3,\
                       'np50':outagesFutCurRcp_np_50/1e3,\
                       'np90':outagesFutCurRcp_np_90/1e3}
    
    with open('%s/script-data/pc-change-scenarios-%s-%s-%s.dat'%(dataDirDiscovery, rcp, plantData, runoffData), 'wb') as f:
        pickle.dump(outageScenarios, f)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])


decadesToShow = [d[0]+5 for d in decades]
yaxis1Ticks = np.arange(-300,1,50)
yaxis2Ticks = [int(-x) for x in yaxis1Ticks/avgPlantSize]

plt.figure(figsize=(6,4))
plt.ylim([-325, 0])
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
          'ok', markersize=6, markerfacecolor=snsColors[1], label='IEA Stated\nPolicies')
yerrNP = np.zeros([2,1])
yerrNP[0,0] = np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0))-np.nanmin(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=1))
yerrNP[1,0] = np.nanmax(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=1))-np.nanmean(np.nanmean(np.nansum(outageMeanNP[:,1:3,:], axis=2), axis=0))
plt.errorbar(2037, \
             yPtNP2040, \
             yerr = yerrNP, \
             ecolor = snsColors[1], elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot([2035, 2035], [-325, 0], '-k', lw=2)
plt.plot([2045, 2045], [-325, 0], '-k', lw=2)

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
                 loc='lower left', bbox_to_anchor=(-.0145, 0.12))
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
    plt.savefig('global-curtailment-%s.png'%rcp, format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)


plt.show()
sys.exit()


ieaCoal = np.array([iea2018[0], iea2025[0], iea2030[0], iea2035[0], iea2040[0]])
ieaGas = np.array([iea2018[1], iea2025[1], iea2030[1], iea2035[1], iea2040[1]]) 
ieaOil = np.array([iea2018[2], iea2025[2], iea2030[2], iea2035[2], iea2040[2]])
ieaNuke = np.array([iea2018[3], iea2025[3], iea2030[3], iea2035[3], iea2040[3]])
ieaBio = np.array([iea2018[4], iea2025[4], iea2030[4], iea2035[4], iea2040[4]])

ieaSustCoal = np.array([ieaSust2018[0], ieaSust2025[0], ieaSust2030[0], ieaSust2035[0], ieaSust2040[0]])
ieaSustGas = np.array([ieaSust2018[1], ieaSust2025[1], ieaSust2030[1], ieaSust2035[1], ieaSust2040[1]]) 
ieaSustOil = np.array([ieaSust2018[2], ieaSust2025[2], ieaSust2030[2], ieaSust2035[2], ieaSust2040[2]])
ieaSustNuke = np.array([ieaSust2018[3], ieaSust2025[3], ieaSust2030[3], ieaSust2035[3], ieaSust2040[3]])
ieaSustBio = np.array([ieaSust2018[4], ieaSust2025[4], ieaSust2030[4], ieaSust2035[4], ieaSust2040[4]])

ieaDates = np.array([2018, 2025, 2030, 2035, 2040])
ieaLegend = ['Coal', 'Gas', 'Oil', 'Nuke', 'Bio', 'Warming+\nCurtailment']

barW = 3

plt.figure(figsize=(4,4))
plt.ylim([0,27000])
plt.grid(True, color=[.9,.9,.9], axis='y')

plt.bar(ieaDates, ieaCoal, width=barW, color='#f03b20')
plt.bar(ieaDates, ieaGas, bottom=ieaCoal, width=barW, color='#3182bd')
plt.bar(ieaDates, ieaOil, bottom=ieaCoal+ieaGas, width=barW, color='black')
plt.bar(ieaDates, ieaNuke, bottom=ieaCoal+ieaGas+ieaOil, width=barW, color='orange')
plt.bar(ieaDates, ieaBio, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke, width=barW, color='#56a619')
#plt.bar(ieaDates, ieaCurtailment, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke+ieaBio, width=barW, color='#7c7d7a', hatch='/')

plt.xticks([2018, 2025, 2030, 2035, 2040])
#plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Electricity generation (TWh)', fontname = 'Helvetica', fontsize=16)

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
    plt.savefig('iea-by-type-stated-policies-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



plt.figure(figsize=(4,4))
plt.ylim([0,27000])
plt.grid(True, color=[.9,.9,.9], axis='y')

plt.bar(ieaDates, ieaSustCoal, width=barW, color='#f03b20')
plt.bar(ieaDates, ieaSustGas, bottom=ieaSustCoal, width=barW, color='#3182bd')
plt.bar(ieaDates, ieaSustOil, bottom=ieaSustCoal+ieaSustGas, width=barW, color='black')
plt.bar(ieaDates, ieaSustNuke, bottom=ieaSustCoal+ieaSustGas+ieaSustOil, width=barW, color='orange')
plt.bar(ieaDates, ieaSustBio, bottom=ieaSustCoal+ieaSustGas+ieaSustOil+ieaSustNuke, width=barW, color='#56a619')
#plt.bar(ieaDates, ieaCurtailment, bottom=ieaCoal+ieaGas+ieaOil+ieaNuke+ieaBio, width=barW, color='#7c7d7a', hatch='/')

plt.xticks([2018, 2025, 2030, 2035, 2040])
#plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Electricity generation (TWh)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

# leg = plt.legend(ieaLegend, prop = {'size':11, 'family':'Helvetica'}, \
#                  loc='right', bbox_to_anchor=(1.7, .5))
# leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('iea-by-type-sustainable-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


plt.show()


