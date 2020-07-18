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

import warnings
warnings.filterwarnings('ignore')

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

plotFigs = True

outputToFile = False

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'world'

qstr = '-anom-best-dist'

rcp = 'rcp85'

modelPower = 'pow2-noInteraction'

pcVal = -1

rebuild = False

decades = np.array([[2080,2089]])

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

monthLens = np.array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])

pcModel10 = []
pcModel50 = []
pcModel90 = []
plantIds = []
plantYears = []
with gzip.open('%s/script-data/pPolyData-%s-%s.dat'%(dataDirDiscovery, runoffData, modelPower), 'rb') as f:
    pPolyData = pickle.load(f)
    # these are mislabeled in dict for now (90 is 10, 10 is 90)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]
    plantIds = pPolyData['plantIds']
    plantYears = pPolyData['plantYears']
    plantCooling = pPolyData['plantCooling']
    plantFuel = pPolyData['plantFuel']
    plantAge = pPolyData['plantAge']

baseTx = 27
baseQs = 0

dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), 'QS2T2':[(baseTx**2)*(baseQs**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears, 'PlantCooling':plantCooling, 'PlantFuel':plantFuel, 'PlantAge':plantAge})

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

    
plantPcTxAllModels10_40yr = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels50_40yr = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels90_40yr = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)

plantPcTxAllModels10_sust = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels50_sust = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels90_sust = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)

plantPcTxAllModels10_const = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels50_const = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels90_const = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)

plantPcTxAllModels10_np = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels50_np = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)
plantPcTxAllModels90_np = np.full([len(models), len(globalPlants['caps']), 10, 12, 3], np.nan)

for m in range(len(models)):
    
    if not rebuild:
        
        print('loading model %s'%models[m])
        with open('%s/script-data/pc-change-fut-hourly-%s-%s%s-%s-%s-%s-pcVal-0-%d-%d.dat'% \
                  (dataDirDiscovery, plantData, runoffData, qstr, rcp, modelPower, models[m], decades[0,0], decades[0,1]), 'rb') as f:
            pcChg = pickle.load(f)
            
            plantPcTxAllModels10_40yr[m, :, :, :, 0] = pcChg['plantPcAggTx10_40yr']
            plantPcTxAllModels50_40yr[m, :, :, :, 0] = pcChg['plantPcAggTx50_40yr']
            plantPcTxAllModels90_40yr[m, :, :, :, 0] = pcChg['plantPcAggTx90_40yr']
            
            plantPcTxAllModels10_sust[m, :, :, :, 0] = pcChg['plantPcAggTx10_sust']
            plantPcTxAllModels50_sust[m, :, :, :, 0] = pcChg['plantPcAggTx50_sust']
            plantPcTxAllModels90_sust[m, :, :, :, 0] = pcChg['plantPcAggTx90_sust']
            
            plantPcTxAllModels10_const[m, :, :, :, 0] = pcChg['plantPcAggTx10_const']
            plantPcTxAllModels50_const[m, :, :, :, 0] = pcChg['plantPcAggTx50_const']
            plantPcTxAllModels90_const[m, :, :, :, 0] = pcChg['plantPcAggTx90_const']
            
            plantPcTxAllModels10_np[m, :, :, :, 0] = pcChg['plantPcAggTx10_np']
            plantPcTxAllModels50_np[m, :, :, :, 0] = pcChg['plantPcAggTx50_np']
            plantPcTxAllModels90_np[m, :, :, :, 0] = pcChg['plantPcAggTx90_np']
        
        
        with open('%s/script-data/pc-change-fut-hourly-%s-%s%s-%s-%s-%s-pcVal-1-%d-%d.dat'% \
                  (dataDirDiscovery, plantData, runoffData, qstr, rcp, modelPower, models[m], decades[0,0], decades[0,1]), 'rb') as f:
            pcChg = pickle.load(f)
            
            plantPcTxAllModels10_40yr[m, :, :, :, 1] = pcChg['plantPcAggTx10_40yr']
            plantPcTxAllModels50_40yr[m, :, :, :, 1] = pcChg['plantPcAggTx50_40yr']
            plantPcTxAllModels90_40yr[m, :, :, :, 1] = pcChg['plantPcAggTx90_40yr']
            
            plantPcTxAllModels10_sust[m, :, :, :, 1] = pcChg['plantPcAggTx10_sust']
            plantPcTxAllModels50_sust[m, :, :, :, 1] = pcChg['plantPcAggTx50_sust']
            plantPcTxAllModels90_sust[m, :, :, :, 1] = pcChg['plantPcAggTx90_sust']
            
            plantPcTxAllModels10_const[m, :, :, :, 1] = pcChg['plantPcAggTx10_const']
            plantPcTxAllModels50_const[m, :, :, :, 1] = pcChg['plantPcAggTx50_const']
            plantPcTxAllModels90_const[m, :, :, :, 1] = pcChg['plantPcAggTx90_const']
            
            plantPcTxAllModels10_np[m, :, :, :, 1] = pcChg['plantPcAggTx10_np']
            plantPcTxAllModels50_np[m, :, :, :, 1] = pcChg['plantPcAggTx50_np']
            plantPcTxAllModels90_np[m, :, :, :, 1] = pcChg['plantPcAggTx90_np']
        
        
        with open('%s/script-data/pc-change-fut-hourly-%s-%s%s-%s-%s-%s-%d-%d.dat'% \
                  (dataDirDiscovery, plantData, runoffData, qstr, rcp, modelPower, models[m], decades[0,0], decades[0,1]), 'rb') as f:
            pcChg = pickle.load(f)
            
            plantPcTxAllModels10_40yr[m, :, :, :, 2] = pcChg['plantPcAggTx10_40yr']
            plantPcTxAllModels50_40yr[m, :, :, :, 2] = pcChg['plantPcAggTx50_40yr']
            plantPcTxAllModels90_40yr[m, :, :, :, 2] = pcChg['plantPcAggTx90_40yr']
            
            plantPcTxAllModels10_sust[m, :, :, :, 2] = pcChg['plantPcAggTx10_sust']
            plantPcTxAllModels50_sust[m, :, :, :, 2] = pcChg['plantPcAggTx50_sust']
            plantPcTxAllModels90_sust[m, :, :, :, 2] = pcChg['plantPcAggTx90_sust']
            
            plantPcTxAllModels10_const[m, :, :, :, 2] = pcChg['plantPcAggTx10_const']
            plantPcTxAllModels50_const[m, :, :, :, 2] = pcChg['plantPcAggTx50_const']
            plantPcTxAllModels90_const[m, :, :, :, 2] = pcChg['plantPcAggTx90_const']
            
            plantPcTxAllModels10_np[m, :, :, :, 2] = pcChg['plantPcAggTx10_np']
            plantPcTxAllModels50_np[m, :, :, :, 2] = pcChg['plantPcAggTx50_np']
            plantPcTxAllModels90_np[m, :, :, :, 2] = pcChg['plantPcAggTx90_np']
        
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

        if outputToFile:
            print('processing %s/%d...'%(models[m], decades[0,0]), file=open("el_aggregate_pc_model_warming.txt", "a"))
        else:
            print('processing %s/%d...'%(models[m], decades[0,0]))

        if outputToFile:
            print('loading future tx data', file=open("el_aggregate_pc_model_warming.txt", "a"))
        else:
            print('loading future tx data')
        fileNameTemp = '%s/future-temps/%s-pp-%s-tx-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, models[m], decades[0,0], decades[0,1])
        plantTxData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        plantTxData = plantTxData[3:,:]
        
        if outputToFile:
            print('loading future tn data', file=open("el_aggregate_pc_model_warming.txt", "a"))
        else:
            print('loading future tn data')
        fileNameTemp = '%s/future-temps/%s-pp-%s-tn-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, models[m], decades[0,0], decades[0,1])    
        plantTnData = np.genfromtxt(fileNameTemp, delimiter=',', skip_header=0)
        plantTnData = plantTnData[3:,:]
        
        fileNameRunoffDistFit = '%s/future-temps/%s-pp-%s-runoff-anom-cmip5-%s-%d-%d.csv'% \
                                 (dataDirDiscovery, plantData, rcp, models[m], decades[0,0], decades[0,1]) 
        
        if outputToFile:
            print('loading future runoff anomalies', file=open("el_aggregate_pc_model_warming.txt", "a"))
        else:
            print('loading future runoff anomalies')
        plantQsData = np.genfromtxt(fileNameRunoffDistFit, delimiter=',', skip_header=0)
        plantQsYears = plantQsData[0,:]
        plantQsMonths = plantQsData[1,:]
        plantQsDays = plantQsData[2,:]
        plantQsData = plantQsData[3:,:]

        if outputToFile:
            print('calculating pc', file=open("el_aggregate_pc_model_warming.txt", "a"))
        else:
            print('calculating pc')
        # compute pc for every plant
        for p in range(plantTxData.shape[0]):

            if p % 1000 == 0:
                if outputToFile:
                    print('plant %d of %d'%(p, plantTxData.shape[0]), file=open("el_aggregate_pc_model_warming.txt", "a"))
                else:
                    print('plant %d of %d'%(p, plantTxData.shape[0]))

            # all tx and qs data for this plant for the decade
            tx = plantTxData[p,:]
            tn = plantTnData[p,:]
            qs = plantQsData[p,:]

            qs[qs < -5] = np.nan
            qs[qs > 5] = np.nan
            
            txHourly = np.full([tx.shape[0], 24], np.nan)
            qsHourly = np.full([qs.shape[0], 24], np.nan)
            
            for d in range(1, tx.shape[0]):
                qsHourly[d, :] = [qs[d]]*24
                # set daily min
                txHourly[d, 0] = tn[d]
                
                # set daily max
                txHourly[d, 12] = tx[d]
                
                # interpolate 1st half of day
                txHourly[d, 1:12] = np.linspace(txHourly[d, 0], txHourly[d, 12], 11)
                
                if d < txHourly.shape[0]-1:
                    # interpolate down to next day's min
                    txHourly[d, 13:24] = np.linspace(txHourly[d, 12], tn[d+1], 11)
                else:
                    # if today is the final day, go back down to today's min
                    txHourly[d, 13:24] = np.linspace(txHourly[d, 12], tn[d], 11)
            
            txHourly = np.reshape(txHourly, [txHourly.size])
            qsHourly = np.reshape(qsHourly, [qsHourly.size])

            # heat related outages for every day in decade for current plant
            plantPcTx10CurDecade = np.full([len(txHourly)], np.nan)
            plantPcTx50CurDecade = np.full([len(txHourly)], np.nan)
            plantPcTx90CurDecade = np.full([len(txHourly)], np.nan)

            indCompute = np.where((~np.isnan(txHourly)) & (~np.isnan(qsHourly)) & (txHourly > baseTx))[0]
            indPlantIdsCompute = np.random.choice(len(plantIds), len(indCompute))

            curPlantAge = globalPlants['yearCom'][p]
            if np.isnan(curPlantAge):
                curPlantAges = plantAge[indPlantIdsCompute]
            else:
                if curPlantAge <= 1979: 
                    curPlantAge = 1970
                elif curPlantAge < 1990: 
                    curPlantAge = 1980
                elif curPlantAge >= 1990: 
                    curPlantAge = 1990
                curPlantAges = np.array([curPlantAge]*len(indPlantIdsCompute))
            
            if pcVal >= 0:
                dfpred = pd.DataFrame({'T1':txHourly[indCompute], 'T2':txHourly[indCompute]**2, \
                                     'QS1':qsHourly[indCompute], 'QS2':qsHourly[indCompute]**2, \
                                     'QST':txHourly[indCompute]*qsHourly[indCompute], 'QS2T2':(txHourly[indCompute]**2)*(qsHourly[indCompute]**2), \
                                     'PlantIds':plantIds[indPlantIdsCompute], 'PlantYears':plantYears[indPlantIdsCompute], \
                                     'PlantCooling':[pcVal]*len(indPlantIdsCompute), 'PlantFuel':plantFuel[indPlantIdsCompute], \
                                     'PlantAge':curPlantAges})
            else:
                dfpred = pd.DataFrame({'T1':txHourly[indCompute], 'T2':txHourly[indCompute]**2, \
                                     'QS1':qsHourly[indCompute], 'QS2':qsHourly[indCompute]**2, \
                                     'QST':txHourly[indCompute]*qsHourly[indCompute], 'QS2T2':(txHourly[indCompute]**2)*(qsHourly[indCompute]**2), \
                                     'PlantIds':plantIds[indPlantIdsCompute], 'PlantYears':plantYears[indPlantIdsCompute], \
                                     'PlantCooling':plantCooling[indPlantIdsCompute], 'PlantFuel':plantFuel[indPlantIdsCompute], \
                                     'PlantAge':curPlantAges})

            plantPcTx10CurDecade[indCompute] = pcModel10.predict(dfpred) - basePred10
            plantPcTx50CurDecade[indCompute] = pcModel50.predict(dfpred) - basePred50
            plantPcTx90CurDecade[indCompute] = pcModel90.predict(dfpred) - basePred90

            plantPcTx10CurDecade[plantPcTx10CurDecade > 0] = 0
            plantPcTx50CurDecade[plantPcTx50CurDecade > 0] = 0
            plantPcTx90CurDecade[plantPcTx90CurDecade > 0] = 0

            plantPcTx10CurDecade[plantPcTx10CurDecade < -100] = -100
            plantPcTx50CurDecade[plantPcTx50CurDecade < -100] = -100
            plantPcTx90CurDecade[plantPcTx90CurDecade < -100] = -100
            
            plantPcTx10CurDecade = np.reshape(plantPcTx10CurDecade, [tx.shape[0], 24])
            plantPcTx50CurDecade = np.reshape(plantPcTx50CurDecade, [tx.shape[0], 24])
            plantPcTx90CurDecade = np.reshape(plantPcTx90CurDecade, [tx.shape[0], 24])
            
            # now disaggregate by year/month
            for yInd, year in enumerate(range(decades[0,0], decades[0, 1]+1)):
                for mInd, month in enumerate(range(1, 12+1)):
                    ind = np.where((plantQsYears == year) & (plantQsMonths == month))[0]

                    if p in livingPlantsInds40[lifespan40Scenario]:
                        plantPcTx10_40yr[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx10CurDecade[ind, :]/100.0 * globalPlants['caps'][p]))/1e3
                        plantPcTx50_40yr[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx50CurDecade[ind, :]/100.0 * globalPlants['caps'][p]))/1e3
                        plantPcTx90_40yr[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx90CurDecade[ind, :]/100.0 * globalPlants['caps'][p]))/1e3

                    if p in livingPlantsInds40[constantScenario]:
                        plantPcTx10_const[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx10CurDecade[ind, :]/100.0 * globalPlants['caps'][p]))/1e3
                        plantPcTx50_const[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx50CurDecade[ind, :]/100.0 * globalPlants['caps'][p]))/1e3
                        plantPcTx90_const[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx90CurDecade[ind, :]/100.0 * globalPlants['caps'][p]))/1e3

                    if p in livingPlantsInds40[constantScenario]:
                        plantCap = np.nanmean(globalPlantsCapsSust[p,-10:])
                        plantPcTx10_sust[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx10CurDecade[ind, :]/100.0 * plantCap))/1e3
                        plantPcTx50_sust[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx50CurDecade[ind, :]/100.0 * plantCap))/1e3
                        plantPcTx90_sust[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx90CurDecade[ind, :]/100.0 * plantCap))/1e3

                    if p in livingPlantsInds40[constantScenario]:
                        plantCap = np.nanmean(globalPlantsCapsNP[p,-10:])
                        plantPcTx10_np[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx10CurDecade[ind, :]/100.0 * plantCap))/1e3
                        plantPcTx50_np[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx50CurDecade[ind, :]/100.0 * plantCap))/1e3
                        plantPcTx90_np[p, yInd, mInd] = np.nansum(np.nansum(plantPcTx90CurDecade[ind, :]/100.0 * plantCap))/1e3

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
        with open('%s/script-data/pc-change-fut-hourly-%s-%s%s-%s-%s-%s-pcVal-%d-%d-%d.dat'% \
                  (dataDirDiscovery, plantData, runoffData, qstr, rcp, modelPower, models[m], pcVal, decades[0,0], decades[0,1]), 'wb') as f:
            pickle.dump(pcChg, f)


            
totalTwh_40yr = 0
totalTwh_const = monthLens * np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])/1e6*24
totalTwh_sust = monthLens * np.nansum(np.nanmean(globalPlantsCapsSust[livingPlantsInds40[2018], -10:], axis=1))/1e6*24
totalTwh_np = monthLens * np.nansum(np.nanmean(globalPlantsCapsNP[livingPlantsInds40[2018], -10:], axis=1))/1e6*24

# these are in TWh
projCurtailment_40yr_pcVal0 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_40yr[:,:,:,:,0], axis=3), axis=2), axis=1)/1e3
projCurtailment_const_pcVal0 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_const[:,:,:,:,0], axis=3), axis=2), axis=1)/1e3
projCurtailment_sust_pcVal0 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_sust[:,:,:,:,0], axis=3), axis=2), axis=1)/1e3
projCurtailment_np_pcVal0 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_np[:,:,:,:,0], axis=3), axis=2), axis=1)/1e3

projCurtailment_40yr_pcVal1 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_40yr[:,:,:,:,1], axis=3), axis=2), axis=1)/1e3
projCurtailment_const_pcVal1 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_const[:,:,:,:,1], axis=3), axis=2), axis=1)/1e3
projCurtailment_sust_pcVal1 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_sust[:,:,:,:,1], axis=3), axis=2), axis=1)/1e3
projCurtailment_np_pcVal1 = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_np[:,:,:,:,1], axis=3), axis=2), axis=1)/1e3

projCurtailment_40yr = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_40yr[:,:,:,:,2], axis=3), axis=2), axis=1)/1e3
projCurtailment_const = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_const[:,:,:,:,2], axis=3), axis=2), axis=1)/1e3
projCurtailment_sust = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_sust[:,:,:,:,2], axis=3), axis=2), axis=1)/1e3
projCurtailment_np = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_np[:,:,:,:,2], axis=3), axis=2), axis=1)/1e3

msize = 10

plt.rc('xtick', labelsize=14)    # fontsize of the tick labels
plt.rc('ytick', labelsize=14)    # fontsize of the tick labels
plt.rcParams["font.family"] = "Helvetica"
    
plt.figure(figsize=(1.5,4.5))
if rcp == 'rcp85':
    plt.ylim([-380,20])
elif rcp == 'rcp45':
    plt.ylim([-250,20])
plt.xlim([.5, 4.5])
plt.grid(True, color=[.9,.9,.9])


yPt_40yr_pcVal0 = np.nanmean(projCurtailment_40yr_pcVal0)
p40Yr_pcVal0 = plt.plot(1, yPt_40yr_pcVal0, 'xk', markersize=msize, markerfacecolor='#56a619')

yPt_40yr_pcVal1 = np.nanmean(projCurtailment_40yr_pcVal1)
p40Yr_pcVal1 = plt.plot(1, yPt_40yr_pcVal1, 'ok', markersize=msize, markerfacecolor='#56a619')

yPt_40yr = np.nanmean(projCurtailment_40yr)
# p40Yr = plt.plot(1, yPt_40yr, 'ok', markersize=msize, markerfacecolor='#56a619')
# plt.plot([1, 4.5], [yPt_40yr, yPt_40yr], '--', color='#56a619')
p40Yr_pcValMean = (yPt_40yr_pcVal1+yPt_40yr_pcVal0)/2
plt.plot([1, 4.5], [p40Yr_pcValMean, p40Yr_pcValMean], '--', color='#56a619')
yerr40yr = np.zeros([2,1])
yerr40yr[0,0] = np.nanmean(projCurtailment_40yr_pcVal1)-np.nanmin(projCurtailment_40yr_pcVal1)
yerr40yr[1,0] = np.nanmax(projCurtailment_40yr_pcVal0)-np.nanmean(projCurtailment_40yr_pcVal1)
plt.errorbar(1, yPt_40yr, yerr = yerr40yr, ecolor = '#56a619', elinewidth = 1, capsize = 3, fmt = 'none')



yPt_sust_pcVal0 = np.nanmean(projCurtailment_sust_pcVal0)
pSust_pcVal0 = plt.plot(2, yPt_sust_pcVal0, 'xk', markersize=msize, markerfacecolor='#3498db')

yPt_sust_pcVal1 = np.nanmean(projCurtailment_sust_pcVal1)
pSust_pcVal1 = plt.plot(2, yPt_sust_pcVal1, 'ok', markersize=msize, markerfacecolor='#3498db')

yPt_sust = np.nanmean(projCurtailment_sust)
# pSust = plt.plot(2, yPt_sust, 'ok', markersize=msize, markerfacecolor='#3498db', label='IEA Sustainability')
# plt.plot([2, 4.5], [yPt_sust, yPt_sust], '--', color='#3498db')
p_sust_pcValMean = (yPt_sust_pcVal1+yPt_sust_pcVal0)/2
plt.plot([2, 4.5], [p_sust_pcValMean, p_sust_pcValMean], '--', color='#3498db')
yerrSust = np.zeros([2,1])
yerrSust[0,0] = np.nanmean(projCurtailment_sust_pcVal1)-np.nanmin(projCurtailment_sust_pcVal1)
yerrSust[1,0] = np.nanmax(projCurtailment_sust_pcVal0)-np.nanmean(projCurtailment_sust_pcVal1)
plt.errorbar(2, yPt_sust, yerr = yerrSust, ecolor = '#3498db', elinewidth = 1, capsize = 3, fmt = 'none')


yPt_const_pcVal0 = np.nanmean(projCurtailment_const_pcVal0)
pConst_pcVal0 = plt.plot(3, yPt_const_pcVal0, 'xk', markersize=msize, markerfacecolor='gray')

yPt_const_pcVal1 = np.nanmean(projCurtailment_const_pcVal1)
pConst_pcVal1 = plt.plot(3, yPt_const_pcVal1, 'ok', markersize=msize, markerfacecolor='gray')

yPt_const = np.nanmean(projCurtailment_const)
# pConst = plt.plot(3, yPt_const, 'ok', markersize=msize, markerfacecolor='gray')
# plt.plot([3, 4.5], [yPt_const, yPt_const], '--', color='gray')
p_const_pcValMean = (yPt_const_pcVal1+yPt_const_pcVal0)/2
plt.plot([3, 4.5], [p_const_pcValMean, p_const_pcValMean], '--', color='gray')
yerrConst = np.zeros([2,1])
yerrConst[0,0] = np.nanmean(projCurtailment_const_pcVal1)-np.nanmin(projCurtailment_const_pcVal1)
yerrConst[1,0] = np.nanmax(projCurtailment_const_pcVal0)-np.nanmean(projCurtailment_const_pcVal1)
plt.errorbar(3, yPt_const, yerr = yerrConst, ecolor = 'gray', elinewidth = 1, capsize = 3, fmt = 'none')



yPt_np_pcVal0 = np.nanmean(projCurtailment_np_pcVal0)
pNp_pcVal0 = plt.plot(4, yPt_np_pcVal0, 'xk', markersize=msize, markerfacecolor='#e74c3c', label='Once-\nthrough')

yPt_np_pcVal1 = np.nanmean(projCurtailment_np_pcVal1)
plt.plot(4, yPt_np_pcVal1, 'ok', markersize=msize, markerfacecolor='white', label='Recir-\nculating')
pNp_pcVal1 = plt.plot(4, yPt_np_pcVal1, 'ok', markersize=msize, markerfacecolor='#e74c3c')


yPt_np = np.nanmean(projCurtailment_np)
# pNp = plt.plot(4, yPt_np, 'ok', markersize=msize, markerfacecolor='#e74c3c')
# plt.plot([4, 4.5], [yPt_np, yPt_np], '--', color='#e74c3c')
p_np_pcValMean = (yPt_np_pcVal1+yPt_np_pcVal0)/2
plt.plot([4, 4.5], [p_np_pcValMean, p_np_pcValMean], '--', color='#e74c3c')
yerrNp = np.zeros([2,1])
yerrNp[0,0] = np.nanmean(projCurtailment_np_pcVal1)-np.nanmin(projCurtailment_np_pcVal1)
yerrNp[1,0] = np.nanmax(projCurtailment_np_pcVal0)-np.nanmean(projCurtailment_np_pcVal1)
plt.errorbar(4, yPt_np, yerr = yerrNp, ecolor = '#e74c3c', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot([.5,4.5], [0,0], '--', color='black')

plt.ylabel('Global annually \naccumulated curtailment\n(TWh)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':10, 'family':'Helvetica'}, framealpha=0, bbox_to_anchor=(.89,0.26))
leg.get_frame().set_linewidth(0.0)

plt.gca().yaxis.tick_right()
plt.gca().yaxis.set_label_position("right")

# for tick in plt.gca().yaxis.get_major_ticks():
#     tick.label.set_fontname('Helvetica')    
#     tick.label.set_fontsize(14)

plt.gca().get_xaxis().set_visible(False)

if plotFigs:
    plt.savefig('annual-total-curtailment-2080s-%s-%s-pcVal-both.eps'%(rcp, modelPower), format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

            
print('np: %.2f to %.2f $B'%((yPt_np-yerrNp[0])*1e9*.2/1e9, (yPt_np+yerrNp[1])*1e9*.1/1e9))
print('const: %.2f to %.2f $B'%((yPt_const-yerrConst[0])*1e9*.2/1e9, (yPt_const+yerrConst[1])*1e9*.1/1e9))
print('sust: %.2f to %.2f $B'%((yPt_sust-yerrSust[0])*1e9*.2/1e9, (yPt_sust+yerrSust[1])*1e9*.1/1e9))

# print('pcVal = 1')
# print('np: %.2f to %.2f $B'%((yPt_np_pcVal1-yerrNp_pcVal1[0])*1e9*.2/1e9, (yPt_np_pcVal1+yerrNp_pcVal1[1])*1e9*.1/1e9))
# print('const: %.2f to %.2f $B'%((yPt_const_pcVal1-yerrConst_pcVal1[0])*1e9*.2/1e9, (yPt_const_pcVal1+yerrConst_pcVal1[1])*1e9*.1/1e9))
# print('sust: %.2f to %.2f $B'%((yPt_sust_pcVal1-yerrSust_pcVal1[0])*1e9*.2/1e9, (yPt_sust_pcVal1+yerrSust_pcVal1[1])*1e9*.1/1e9))

plt.show()
sys.exit()

            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
totalTwh_40yr = 0
totalTwh_const = monthLens * np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])/1e6*24
totalTwh_sust = monthLens * np.nansum(np.nanmean(globalPlantsCapsSust[livingPlantsInds40[2018], -10:], axis=1))/1e6*24
totalTwh_np = monthLens * np.nansum(np.nanmean(globalPlantsCapsNP[livingPlantsInds40[2018], -10:], axis=1))/1e6*24

# these are in TWh
projCurtailment_40yr = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_40yr[:,:,:,:], axis=3), axis=2), axis=1)/1e3
projCurtailment_const = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_const[:,:,:,:], axis=3), axis=2), axis=1)/1e3
projCurtailment_sust = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_sust[:,:,:,:], axis=3), axis=2), axis=1)/1e3
projCurtailment_np = np.nansum(np.nanmean(np.nansum(plantPcTxAllModels50_np[:,:,:,:], axis=3), axis=2), axis=1)/1e3

msize = 10

plt.rc('xtick', labelsize=14)    # fontsize of the tick labels
plt.rc('ytick', labelsize=14)    # fontsize of the tick labels
plt.rcParams["font.family"] = "Helvetica"
    
plt.figure(figsize=(1.5,4.5))
if rcp == 'rcp85':
    plt.ylim([-375,10])
elif rcp == 'rcp45':
    plt.ylim([-250,10])
plt.xlim([.5, 4.5])
plt.grid(True, color=[.9,.9,.9])


yPt_40yr = np.nanmean(projCurtailment_40yr)
p40Yr = plt.plot(1, yPt_40yr, 'ok', markersize=msize, markerfacecolor='#56a619', label='40 Year\nLifespan')
plt.plot([1, 4.5], [yPt_40yr, yPt_40yr], '--', color='#56a619')
yerr40yr = np.zeros([2,1])
yerr40yr[0,0] = np.nanmean(projCurtailment_40yr)-np.nanmin(projCurtailment_40yr)
yerr40yr[1,0] = np.nanmax(projCurtailment_40yr)-np.nanmean(projCurtailment_40yr)
plt.errorbar(1, yPt_40yr, yerr = yerr40yr, ecolor = '#56a619', elinewidth = 1, capsize = 3, fmt = 'none')

yPt_sust = np.nanmean(projCurtailment_sust)
pSust = plt.plot(2, yPt_sust, 'ok', markersize=msize, markerfacecolor='#3498db', label='IEA Sustainability')
plt.plot([2, 4.5], [yPt_sust, yPt_sust], '--', color='#3498db')
yerrSust = np.zeros([2,1])
yerrSust[0,0] = np.nanmean(projCurtailment_sust)-np.nanmin(projCurtailment_sust)
yerrSust[1,0] = np.nanmax(projCurtailment_sust)-np.nanmean(projCurtailment_sust)
plt.errorbar(2, yPt_sust, yerr = yerrSust, ecolor = '#3498db', elinewidth = 1, capsize = 3, fmt = 'none')

yPt_const = np.nanmean(projCurtailment_const)
pConst = plt.plot(3, yPt_const, 'ok', markersize=msize, markerfacecolor='gray', label='Constant')
plt.plot([3, 4.5], [yPt_const, yPt_const], '--', color='gray')
yerrConst = np.zeros([2,1])
yerrConst[0,0] = np.nanmean(projCurtailment_const)-np.nanmin(projCurtailment_const)
yerrConst[1,0] = np.nanmax(projCurtailment_const)-np.nanmean(projCurtailment_const)
plt.errorbar(3, yPt_const, yerr = yerrConst, ecolor = 'gray', elinewidth = 1, capsize = 3, fmt = 'none')

yPt_np = np.nanmean(projCurtailment_np)
pNp = plt.plot(4, yPt_np, 'ok', markersize=msize, markerfacecolor='#e74c3c', label='IEA New Policies')
plt.plot([4, 4.5], [yPt_np, yPt_np], '--', color='#e74c3c')
yerrNp = np.zeros([2,1])
yerrNp[0,0] = np.nanmean(projCurtailment_np)-np.nanmin(projCurtailment_np)
yerrNp[1,0] = np.nanmax(projCurtailment_np)-np.nanmean(projCurtailment_np)
plt.errorbar(4, yPt_np, yerr = yerrNp, ecolor = '#e74c3c', elinewidth = 1, capsize = 3, fmt = 'none')

plt.plot([.5,4.5], [0,0], '--', color='black')

plt.ylabel('Global annually \naccumulated curtailment\n(TWh)', fontname = 'Helvetica', fontsize=16)

plt.gca().yaxis.tick_right()
plt.gca().yaxis.set_label_position("right")

# for tick in plt.gca().yaxis.get_major_ticks():
#     tick.label.set_fontname('Helvetica')    
#     tick.label.set_fontsize(14)

plt.gca().get_xaxis().set_visible(False)

if plotFigs:
    plt.savefig('annual-total-curtailment-2080s-%s-%s-pcVal-%d.eps'%(rcp, modelPower, pcVal), format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

    
    








