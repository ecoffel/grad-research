# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import scipy.stats as st
import pandas as pd
import pickle, gzip
import el_load_global_plants
import sys, os


#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

qstr = '-anom-best-dist'

rcp = 'rcp85'

decades = np.array([[2080,2089]])

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('%s/script-data/pPolyData-%s-pow2.dat'%(dataDirDiscovery, runoffData), 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]
    plantIds = pPolyData['plantIds']
    plantYears = pPolyData['plantYears']

baseTx = 27
baseQs = 0

dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), 'QS2T2':[(baseTx**2)*(baseQs**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})

basePred10 = np.nanmean(pcModel10.predict(dfpred))
basePred50 = np.nanmean(pcModel50.predict(dfpred))
basePred90 = np.nanmean(pcModel90.predict(dfpred))

if plantData == 'useu':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=False)
elif plantData == 'world':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=True)

with open('%s/script-data/active-pp-inds-40-%s.dat'%(dataDirDiscovery, plantData), 'rb') as f:
    livingPlantsInds40 = pickle.load(f)
    
with open('%s/script-data/world-plant-caps-iea-scenarios.dat'%dataDirDiscovery, 'rb') as f:
    scenarios = pickle.load(f)
    globalPlantsCapsSust = scenarios['globalPlantsCapsSust']
    globalPlantsCapsNP = scenarios['globalPlantsCapsNP']

    
plantPcTxAllModels10_40yr = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels50_40yr = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels90_40yr = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)

plantPcTxAllModels10_sust = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels50_sust = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels90_sust = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)

plantPcTxAllModels10_const = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels50_const = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels90_const = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)

plantPcTxAllModels10_np = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels50_np = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)
plantPcTxAllModels90_np = np.full([len(models), len(globalPlants['caps']), 10, 12], np.nan)

for m in range(len(models)):
    
    if os.path.isfile('%s/script-data/pc-change-fut-%s-%s%s-%s-%s-%d-%d.dat-aids'% \
                      (dataDirDiscovery, plantData, runoffData, qstr, rcp, models[m], decades[0,0], decades[0,1])):
        
        print('loading model %s'%models[m])
        with open('%s/script-data/pc-change-fut-%s-%s%s-%s-%s-%d-%d.dat'% \
                  (dataDirDiscovery, plantData, runoffData, qstr, rcp, models[m], decades[0,0], decades[0,1]), 'rb') as f:
            pcChg = pickle.load(f)
            
            plantPcTxAllModels10_40yr[m, :, :, :] = pcChg['plantPcAggTx10_40yr']
            plantPcTxAllModels50_40yr[m, :, :, :] = pcChg['plantPcAggTx50_40yr']
            plantPcTxAllModels90_40yr[m, :, :, :] = pcChg['plantPcAggTx90_40yr']
            
            plantPcTxAllModels10_sust[m, :, :, :] = pcChg['plantPcAggTx10_sust']
            plantPcTxAllModels50_sust[m, :, :, :] = pcChg['plantPcAggTx50_sust']
            plantPcTxAllModels90_sust[m, :, :, :] = pcChg['plantPcAggTx90_sust']
            
            plantPcTxAllModels10_const[m, :, :, :] = pcChg['plantPcAggTx10_const']
            plantPcTxAllModels50_const[m, :, :, :] = pcChg['plantPcAggTx50_const']
            plantPcTxAllModels90_const[m, :, :, :] = pcChg['plantPcAggTx90_const']
            
            plantPcTxAllModels10_np[m, :, :, :] = pcChg['plantPcAggTx10_np']
            plantPcTxAllModels50_np[m, :, :, :] = pcChg['plantPcAggTx50_np']
            plantPcTxAllModels90_np[m, :, :, :] = pcChg['plantPcAggTx90_np']
            
    else:
        
        # ref years for constant and 40yr scenarios
        lifespan40Scenario = 2085
        constantScenario = 2018

        # monthly aggregated outages relative to base period
        plantPcTx10_40yr = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx50_40yr = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx90_40yr = np.full([len(globalPlants['caps']), 10, 12], np.nan)

        plantPcTx10_sust = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx50_sust = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx90_sust = np.full([len(globalPlants['caps']), 10, 12], np.nan)

        plantPcTx10_const = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx50_const = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx90_const = np.full([len(globalPlants['caps']), 10, 12], np.nan)

        plantPcTx10_np = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx50_np = np.full([len(globalPlants['caps']), 10, 12], np.nan)
        plantPcTx90_np = np.full([len(globalPlants['caps']), 10, 12], np.nan)

        print('processing %s/%d...'%(models[m], decades[0,0]))

        print('loading future tx data')
        fileNameTemp = '%s/future-temps/%s-pp-%s-tx-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, models[m], decades[0,0], decades[0,1])    
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        plantTxData = plantTxData[3:,:]
        
        print('loading future tn data')
        fileNameTemp = '%s/future-temps/%s-pp-%s-tn-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, models[m], decades[0,0], decades[0,1])    
        plantTnData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        plantTnData = plantTnData[3:,:]

        plantTempHourlyData = np.full([plantTxData.shape[0], plantTxData.shape[1],  24], np.nan)
        
        print('interpolating hourly temps')
        for p in range(plantTxData.shape[0]):
            if p%10==0:
                print('plant %d of %d'%(p, plantTxData.shape[0]))
            # copy over plant id
            plantTempHourlyData[p, 0, :] = [plantTxData[p, 0]]*24
            
            for d in range(1, plantTxData.shape[1]):
                # set daily min
                plantTempHourlyData[p, d, 0] = plantTnData[p, d]
                
                # set daily max
                plantTempHourlyData[p, d, 12] = plantTxData[p, d]
                
                # interpolate 1st half of day
                plantTempHourlyData[p, d, 1:12] = np.linspace(plantTempHourlyData[p, d, 0], plantTempHourlyData[p, d, 12], 11)
                
                if d < plantTxData.shape[1]-1:
                    # interpolate down to next day's min
                    plantTempHourlyData[p, d, 13:24] = np.linspace(plantTempHourlyData[p, d, 12], plantTnData[p,d+1], 11)
                else:
                    # if today is the final day, go back down to today's min
                    plantTempHourlyData[p, d, 13:24] = np.linspace(plantTempHourlyData[p, d, 12], plantTnData[p,d], 11)
            
        sys.exit()
        fileNameRunoffDistFit = '%s/future-temps/%s-pp-%s-runoff-anom-cmip5-%s-%d-%d.csv'% \
                                 (dataDirDiscovery, plantData, rcp, models[m], decades[0,0], decades[0,1]) 
        print('loading future runoff anomalies')
        plantQsData = np.genfromtxt(fileNameRunoffDistFit, delimiter=',', skip_header=0)
        plantQsYears = plantQsData[0,:]
        plantQsMonths = plantQsData[1,:]
        plantQsDays = plantQsData[2,:]
        plantQsData = plantQsData[3:,:]

        print('calculating pc')
        # compute pc for every plant
        for p in range(plantTxData.shape[0]):

            if p % 1000 == 0:
                print('plant %d of %d'%(p, plantTxData.shape[0]))

            # all tx and qs data for this plant for the decade
            tx = plantTxData[p,:]
            qs = plantQsData[p,:]

            qs[qs < -5] = np.nan
            qs[qs > 5] = np.nan

            # heat related outages for every day in decade for current plant
            plantPcTx10CurDecade = np.full([len(tx)], np.nan)
            plantPcTx50CurDecade = np.full([len(tx)], np.nan)
            plantPcTx90CurDecade = np.full([len(tx)], np.nan)

            indCompute = np.where((~np.isnan(tx)) & (~np.isnan(qs)) & (tx > baseTx))[0]
            indPlantIdsCompute = np.random.choice(len(plantIds), len(indCompute))

            dfpred = pd.DataFrame({'T1':tx[indCompute], 'T2':tx[indCompute]**2, \
                                     'QS1':qs[indCompute], 'QS2':qs[indCompute]**2, \
                                     'QST':tx[indCompute]*qs[indCompute], 'QS2T2':(tx[indCompute]**2)*(qs[indCompute]**2), \
                                     'PlantIds':plantIds[indPlantIdsCompute], 'PlantYears':plantYears[indPlantIdsCompute]})

            plantPcTx10CurDecade[indCompute] = pcModel10.predict(dfpred) - basePred10
            plantPcTx50CurDecade[indCompute] = pcModel50.predict(dfpred) - basePred50
            plantPcTx90CurDecade[indCompute] = pcModel90.predict(dfpred) - basePred90

            plantPcTx10CurDecade[plantPcTx10CurDecade > 0] = 0
            plantPcTx50CurDecade[plantPcTx50CurDecade > 0] = 0
            plantPcTx90CurDecade[plantPcTx90CurDecade > 0] = 0

            plantPcTx10CurDecade[plantPcTx10CurDecade < -100] = -100
            plantPcTx50CurDecade[plantPcTx50CurDecade < -100] = -100
            plantPcTx90CurDecade[plantPcTx90CurDecade < -100] = -100
            
            # now disaggregate by year/month
            for yInd, year in enumerate(range(decades[0,0], decades[0, 1]+1)):
                for mInd, month in enumerate(range(1, 12+1)):
                    ind = np.where((plantQsYears == year) & (plantQsMonths == month))[0]

                    if p in livingPlantsInds40[lifespan40Scenario]:
                        plantPcTx10_40yr[p, yInd, mInd] = np.nansum(plantPcTx10CurDecade[ind]/100.0 * globalPlants['caps'][p])/1e3
                        plantPcTx50_40yr[p, yInd, mInd] = np.nansum(plantPcTx50CurDecade[ind]/100.0 * globalPlants['caps'][p])/1e3
                        plantPcTx90_40yr[p, yInd, mInd] = np.nansum(plantPcTx90CurDecade[ind]/100.0 * globalPlants['caps'][p])/1e3

                    if p in livingPlantsInds40[constantScenario]:
                        plantPcTx10_const[p, yInd, mInd] = np.nansum(plantPcTx10CurDecade[ind]/100.0 * globalPlants['caps'][p])/1e3
                        plantPcTx50_const[p, yInd, mInd] = np.nansum(plantPcTx50CurDecade[ind]/100.0 * globalPlants['caps'][p])/1e3
                        plantPcTx90_const[p, yInd, mInd] = np.nansum(plantPcTx90CurDecade[ind]/100.0 * globalPlants['caps'][p])/1e3

                    if p in livingPlantsInds40[constantScenario]:
                        plantCap = np.nanmean(globalPlantsCapsSust[p,-10:])
                        plantPcTx10_sust[p, yInd, mInd] = np.nansum(plantPcTx10CurDecade[ind]/100.0 * plantCap)/1e3
                        plantPcTx50_sust[p, yInd, mInd] = np.nansum(plantPcTx50CurDecade[ind]/100.0 * plantCap)/1e3
                        plantPcTx90_sust[p, yInd, mInd] = np.nansum(plantPcTx90CurDecade[ind]/100.0 * plantCap)/1e3

                    if p in livingPlantsInds40[constantScenario]:
                        plantCap = np.nanmean(globalPlantsCapsNP[p,-10:])
                        plantPcTx10_np[p, yInd, mInd] = np.nansum(plantPcTx10CurDecade[ind]/100.0 * plantCap)/1e3
                        plantPcTx50_np[p, yInd, mInd] = np.nansum(plantPcTx50CurDecade[ind]/100.0 * plantCap)/1e3
                        plantPcTx90_np[p, yInd, mInd] = np.nansum(plantPcTx90CurDecade[ind]/100.0 * plantCap)/1e3

        plantPcTxAllModels10_40yr[m, :, :, :] = plantPcTx10_40yr
        plantPcTxAllModels50_40yr[m, :, :, :] = plantPcTx50_40yr
        plantPcTxAllModels90_40yr[m, :, :, :] = plantPcTx90_40yr

        plantPcTxAllModels10_const[m, :, :, :] = plantPcTx10_const
        plantPcTxAllModels50_const[m, :, :, :] = plantPcTx50_const
        plantPcTxAllModels90_const[m, :, :, :] = plantPcTx90_const

        plantPcTxAllModels10_sust[m, :, :, :] = plantPcTx10_sust
        plantPcTxAllModels50_sust[m, :, :, :] = plantPcTx50_sust
        plantPcTxAllModels90_sust[m, :, :, :] = plantPcTx90_sust

        plantPcTxAllModels10_np[m, :, :, :] = plantPcTx10_np
        plantPcTxAllModels50_np[m, :, :, :] = plantPcTx50_np
        plantPcTxAllModels90_np[m, :, :, :] = plantPcTx90_np

        pcChg = {'plantPcAggTx10_40yr':plantPcTx10_40yr, \
                 'plantPcAggTx50_40yr':plantPcTx50_40yr, \
                 'plantPcAggTx90_40yr':plantPcTx90_40yr, \
                 'plantPcAggTx10_const':plantPcTx10_const, \
                 'plantPcAggTx50_const':plantPcTx50_const, \
                 'plantPcAggTx90_const':plantPcTx90_const, \
                 'plantPcAggTx10_sust':plantPcTx10_sust, \
                 'plantPcAggTx50_sust':plantPcTx50_sust, \
                 'plantPcAggTx90_sust':plantPcTx90_sust, \
                 'plantPcAggTx10_np':plantPcTx10_np, \
                 'plantPcAggTx50_np':plantPcTx50_np, \
                 'plantPcAggTx90_np':plantPcTx90_np}
        with open('%s/script-data/pc-change-fut-%s-%s%s-%s-%s-%d-%d.dat'% \
                  (dataDirDiscovery, plantData, runoffData, qstr, rcp, models[m], decades[0,0], decades[0,1]), 'wb') as f:
            pickle.dump(pcChg, f)











sys.exit()

#pcChg = {'pCapTx10':pCapTx10, 'pCapTx50':pCapTx50, 'pCapTx90':pCapTx90, \
#         'pCapTxx10':pCapTxx10, 'pCapTxx50':pCapTxx50, 'pCapTxx90':pCapTxx90}
#with open('plantPcChange.dat', 'wb') as f:
#    pickle.dump(pcChg, f)


pcTx10 = np.squeeze(np.nanmean(pCapTx10[0,:,:], axis=0))
pcTx50 = np.squeeze(np.nanmean(pCapTx50[0,:,:], axis=0))
pcTx90 = np.squeeze(np.nanmean(pCapTx90[0,:,:], axis=0))

pcTxx10 = np.squeeze(np.nanmean(pCapTxx10[0,:,:], axis=0))
pcTxx50 = np.squeeze(np.nanmean(pCapTxx50[0,:,:], axis=0))
pcTxx90 = np.squeeze(np.nanmean(pCapTxx90[0,:,:], axis=0))

xd = np.array(list(range(1981, 2018+1)))-1981+1

z = np.polyfit(xd, pcTx10, 1)
histPolyTx10 = np.poly1d(z)
z = np.polyfit(xd, pcTx50, 1)
histPolyTx50 = np.poly1d(z)
z = np.polyfit(xd, pcTx90, 1)
histPolyTx90 = np.poly1d(z)

z = np.polyfit(xd, pcTxx10, 1)
histPolyTxx10 = np.poly1d(z)
z = np.polyfit(xd, pcTxx50, 1)
histPolyTxx50 = np.poly1d(z)
z = np.polyfit(xd, pcTxx90, 1)
histPolyTxx90 = np.poly1d(z)


plt.figure(figsize=(4,4))
plt.xlim([0, 105])
plt.ylim([93,96])
plt.grid(True)

plt.plot(xd, histPolyTxx10(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8)
p2 = plt.plot(xd, histPolyTxx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8, label='TXx')
plt.plot(xd, histPolyTxx90(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8)

plt.plot([55, 70, 85, 100], \
         [np.nanmean(np.nanmean(pCapTxx10[1,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx10[2,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx10[3,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx10[4,:,:], axis=1), axis=0)], \
          'o', markersize=7, color=cmx.tab20(6))

plt.plot([55, 70, 85, 100], \
         [np.nanmean(np.nanmean(pCapTxx50[1,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx50[2,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx50[3,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx50[4,:,:], axis=1), axis=0)], \
          'o', markersize=7, color='black')

plt.plot([55, 70, 85, 100], \
         [np.nanmean(np.nanmean(pCapTxx90[1,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx90[2,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx90[3,:,:], axis=1), axis=0), \
          np.nanmean(np.nanmean(pCapTxx90[4,:,:], axis=1), axis=0)], \
          'o', markersize=7, color=cmx.tab20(0))

plt.plot([38,38], [90,100], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, 55, 70, 85, 100])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)


plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

sys.exit()











if plotFigs:
    plt.savefig('hist-pp-chg-over-time.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.figure(figsize=(1,4))
plt.grid(True)

ychg = [np.nanmean(np.squeeze(pCapTxx50[0,:,32:]-pCapTxx50[0,:,0:5]), axis=1)]

medianprops = dict(linestyle='-', linewidth=2, color='black')
meanpointprops = dict(marker='D', markeredgecolor='black',
                      markerfacecolor='red', markersize=5)
bplot = plt.boxplot(ychg, showmeans=True, sym='.', patch_artist=True, \
                    medianprops=medianprops, meanprops=meanpointprops, zorder=0)

colors = ['lightgray']
for patch in bplot['boxes']:
    patch.set_facecolor([.75, .75, .75])

plt.plot([0,2], [0,0], '--', color='black')

plt.gca().set_xticks([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.ylabel('Plant capacity change (% pts)', fontname = 'Helvetica', fontsize=16)



if plotFigs:
    plt.savefig('hist-pp-chg-boxplot.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)







