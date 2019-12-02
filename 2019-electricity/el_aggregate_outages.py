# -*- coding: utf-8 -*-
"""
Created on Mon May 20 14:57:18 2019

@author: Ethan
"""


import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
import matplotlib.cm as cmx
import seaborn as sns
import pandas as pd
import statsmodels.api as sm
import el_load_global_plants
import pickle, gzip
import sys, os

import warnings
warnings.filterwarnings('ignore')


#matplotlib.rcParams['font.family'] = 'Helvetica'
#matplotlib.rcParams['font.weight'] = 'normal'


#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data/'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

plotFigs = True

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

# models = [sys.argv[1]]


#grdc or gldas
runoffData = 'grdc'

# world, useu, or entsoe-nuke
plantData = 'useu'

modelPower = 'pow2'

if plantData == 'useu':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=False)
elif plantData == 'world':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=True)

with open('%s/script-data/active-pp-inds-40-%s.dat'%(dataDirDiscovery, plantData), 'rb') as f:
    livingPlantsInds40 = pickle.load(f)

pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('%s/script-data/pPolyData-%s-%s.dat'%(dataDirDiscovery, runoffData, modelPower), 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]
    plantIds = pPolyData['plantIds']
    plantYears = pPolyData['plantYears']

yearRange = [1981, 2018]

monthLen = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


baseTx = 27
baseQs = 0

dfpred = pd.DataFrame({'T1':[baseTx]*len(plantIds), 'T2':[baseTx**2]*len(plantIds), \
                         'QS1':[baseQs]*len(plantIds), 'QS2':[baseQs**2]*len(plantIds), \
                         'QST':[baseTx*baseQs]*len(plantIds), 'QS2T2':[(baseTx**2)*(baseQs**2)]*len(plantIds), \
                         'PlantIds':plantIds, 'PlantYears':plantYears})

basePred10 = np.nanmean(pcModel10.predict(dfpred))
basePred50 = np.nanmean(pcModel50.predict(dfpred))
basePred90 = np.nanmean(pcModel90.predict(dfpred))

if not os.path.isfile('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-10.dat'%(dataDirDiscovery, runoffData, plantData, modelPower)):

    extra=''
    if not 'globalPCHist50' in locals():
        
        with open('%s/pc-future-%s/%s-pc-hist-hourly-%s-10%s.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, extra), 'rb') as f:
            globalPCHist = pickle.load(f)
            globalPCHist10 = globalPCHist['globalPCHist10']
        
        with open('%s/pc-future-%s/%s-pc-hist-hourly-%s-50%s.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, extra), 'rb') as f:
            globalPCHist = pickle.load(f)
            globalPCHist50 = globalPCHist['globalPCHist50']
            
        with open('%s/pc-future-%s/%s-pc-hist-hourly-%s-90%s.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, extra), 'rb') as f:
            globalPCHist = pickle.load(f)
            globalPCHist90 = globalPCHist['globalPCHist90']
        
    yearlyOutagesHist10 = np.full([len(livingPlantsInds40[2018]), 12], np.nan)
    yearlyOutagesHist50 = np.full([len(livingPlantsInds40[2018]), 12], np.nan)
    yearlyOutagesHist90 = np.full([len(livingPlantsInds40[2018]), 12], np.nan)
    
    print('calculating total capacity outage for historical')
    
    numPlants10 = 0
    numPlants50 = 0
    numPlants90 = 0
    
    # over all plants that are active in 2018
    for pInd, p in enumerate(livingPlantsInds40[2018]):#range(globalPCHist50.shape[0]):
        
        if pInd % 500 == 0:
            print('plant %d...'%pInd)
        
        numYears = 0
        
        yearlyOutagesHistCurPlant10 = np.full([globalPCHist50.shape[1], 12], np.nan)
        yearlyOutagesHistCurPlant50 = np.full([globalPCHist50.shape[1], 12], np.nan)
        yearlyOutagesHistCurPlant90 = np.full([globalPCHist50.shape[1], 12], np.nan)
        
        plantHasData10 = False
        plantHasData50 = False
        plantHasData90 = False
        
        # calculate the total outage (MW) on each day of each year
        for year in range(globalPCHist50.shape[1]):
            yearlyOutagesHistCurYear10 = np.full([12], np.nan)
            yearlyOutagesHistCurYear50 = np.full([12], np.nan)
            yearlyOutagesHistCurYear90 = np.full([12], np.nan)
            
            numDays10 = 0
            numDays50 = 0
            numDays90 = 0

            for month in range(12):
                curMonthPc = np.reshape(globalPCHist10[p,year,month,:,:], [globalPCHist10[p,year,month,:,:].size])
                monthlyOutages10 = (basePred10-curMonthPc) / 100.0
                monthlyOutages10[monthlyOutages10 < 0] = 0
                monthlyOutages10[monthlyOutages10 > 1] = np.nan
                numHours10 = len(np.where(~np.isnan(monthlyOutages10))[0])
                # this is in MWh
                monthlyTotal10 = np.nansum(globalPlants['caps'][p] * monthlyOutages10)
                
                # divide by actual # of days with non-nan data in this month, then multiply by full month length
                # this accounts for model/years where there are nans
                if numHours10 > 0:
                    monthlyTotal10 /= numHours10
                    # now this too is MWh
                    monthlyTotal10 *= monthLen[month] * 24
                    yearlyOutagesHistCurYear10[month] = monthlyTotal10
                    
                
                curMonthPc = np.reshape(globalPCHist50[p,year,month,:,:], [globalPCHist50[p,year,month,:,:].size])
                monthlyOutages50 = (basePred50-curMonthPc) / 100.0
                monthlyOutages50[monthlyOutages50 < 0] = 0
                monthlyOutages50[monthlyOutages50 > 1] = np.nan
                numHours50 = len(np.where(~np.isnan(monthlyOutages50))[0])
                # this is in MWh
                monthlyTotal50 = np.nansum(globalPlants['caps'][p] * monthlyOutages50)
                
                # divide by actual # of days with non-nan data in this month, then multiply by full month length
                # this accounts for model/years where there are nans
                if numHours50 > 0:
                    monthlyTotal50 /= numHours50
                    # now this too is MWh
                    monthlyTotal50 *= monthLen[month] * 24
                    yearlyOutagesHistCurYear50[month] = monthlyTotal50
                    
                    
                    
                curMonthPc = np.reshape(globalPCHist90[p,year,month,:,:], [globalPCHist90[p,year,month,:,:].size])
                monthlyOutages90 = (basePred90-curMonthPc) / 100.0
                monthlyOutages90[monthlyOutages90 < 0] = 0
                monthlyOutages90[monthlyOutages90 > 1] = np.nan
                numHours90 = len(np.where(~np.isnan(monthlyOutages90))[0])
                # this is in MWh
                monthlyTotal90 = np.nansum(globalPlants['caps'][p] * monthlyOutages90)
                
                # divide by actual # of days with non-nan data in this month, then multiply by full month length
                # this accounts for model/years where there are nans
                if numHours90 > 0:
                    monthlyTotal90 /= numHours90
                    # now this too is MWh
                    monthlyTotal90 *= monthLen[month] * 24
                    yearlyOutagesHistCurYear90[month] = monthlyTotal90
            
            
            if len(np.where(~np.isnan(yearlyOutagesHistCurYear10))[0]) == 12:
                yearlyOutagesHistCurPlant10[year, :] = yearlyOutagesHistCurYear10
                plantHasData10 = True
                
            if len(np.where(~np.isnan(yearlyOutagesHistCurYear50))[0]) == 12:
                yearlyOutagesHistCurPlant50[year, :] = yearlyOutagesHistCurYear50
                plantHasData50 = True
            
            if len(np.where(~np.isnan(yearlyOutagesHistCurYear90))[0]) == 12:
                yearlyOutagesHistCurPlant90[year, :] = yearlyOutagesHistCurYear90
                plantHasData90 = True
        
        # divide by # of years to get total outage per month/year, if there is data
#         if len(yearlyOutagesHistCurPlant10) > 0:
        yearlyOutagesHistCurPlant10 = np.nanmean(yearlyOutagesHistCurPlant10, axis=0)
        if plantHasData10: numPlants10 += 1
        yearlyOutagesHist10[pInd, :] = yearlyOutagesHistCurPlant10
        
        yearlyOutagesHistCurPlant50 = np.nanmean(yearlyOutagesHistCurPlant50, axis=0)
        if plantHasData50: numPlants50 += 1
        yearlyOutagesHist50[pInd, :] = yearlyOutagesHistCurPlant50
        
        yearlyOutagesHistCurPlant90 = np.nanmean(yearlyOutagesHistCurPlant90, axis=0)
        if plantHasData90: numPlants90 += 1
        yearlyOutagesHist90[pInd, :] = yearlyOutagesHistCurPlant90
            
            
#         if len(yearlyOutagesHistCurPlant50) > 0:
#             yearlyOutagesHistCurPlant50 = np.array(yearlyOutagesHistCurPlant50)
#             yearlyOutagesHistCurPlant50 = np.nanmean(yearlyOutagesHistCurPlant50, axis=0)
        
#             if plantHasData50: numPlants50 += 1
        
#             yearlyOutagesHist50.append(yearlyOutagesHistCurPlant50)
            
            
#         if len(yearlyOutagesHistCurPlant90) > 0:
#             yearlyOutagesHistCurPlant90 = np.array(yearlyOutagesHistCurPlant90)
#             yearlyOutagesHistCurPlant90 = np.nanmean(yearlyOutagesHistCurPlant90, axis=0)
        
#             if plantHasData90: numPlants90 += 1
        
#             yearlyOutagesHist90.append(yearlyOutagesHistCurPlant90)
            
    
    # sum over all plants, divide by # plants with data, multiply by total number of plants regardless
    # of whether they have data
    yearlyOutagesHist10 = (np.nansum(yearlyOutagesHist10, axis=0)/numPlants10)*yearlyOutagesHist10.shape[0]
    yearlyOutagesHist50 = (np.nansum(yearlyOutagesHist50, axis=0)/numPlants50)*yearlyOutagesHist50.shape[0]
    yearlyOutagesHist90 = (np.nansum(yearlyOutagesHist90, axis=0)/numPlants90)*yearlyOutagesHist90.shape[0]
    
    with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-10.dat'%(dataDirDiscovery, runoffData, plantData, modelPower), 'wb') as f:
        pickle.dump(yearlyOutagesHist10, f)
        
    with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-50.dat'%(dataDirDiscovery, runoffData, plantData, modelPower), 'wb') as f:
        pickle.dump(yearlyOutagesHist50, f)
        
    with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-90.dat'%(dataDirDiscovery, runoffData, plantData, modelPower), 'wb') as f:
        pickle.dump(yearlyOutagesHist90, f)


for model in range(len(models)):
    
    yearlyOutagesCurModel10 = np.full([4, 12], np.nan)
    yearlyOutagesCurModel50 = np.full([4, 12], np.nan)
    yearlyOutagesCurModel90 = np.full([4, 12], np.nan)

    if os.path.isfile('%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-10.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model])):
        print('skipping %s...'%models[model])
        continue

    for w in range(1,4+1):
        
        fileName10 = '%s/pc-future-%s/%s-pc-future-anom-best-dist-10-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffData, plantData, w, modelPower, models[model])
        fileName50 = '%s/pc-future-%s/%s-pc-future-anom-best-dist-50-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffData, plantData, w, modelPower, models[model])
        fileName90 = '%s/pc-future-%s/%s-pc-future-anom-best-dist-90-%ddeg-%s-%s.dat'%(dataDirDiscovery, runoffData, plantData, w, modelPower, models[model])
        
        if os.path.isfile(fileName10):
            with open(fileName10, 'rb') as f:
                globalPC = pickle.load(f)
                globalPCFut10 = globalPC['globalPCFut10']
            with open(fileName50, 'rb') as f:
                globalPC = pickle.load(f)
                globalPCFut50 = globalPC['globalPCFut50']
            with open(fileName90, 'rb') as f:
                globalPC = pickle.load(f)
                globalPCFut90 = globalPC['globalPCFut90']
        else:
            print('%s not found!'%fileName10)
            continue
        
        yearlyOutagesGMT10 = np.full([len(livingPlantsInds40[2018]), 12], np.nan)
        yearlyOutagesGMT50 = np.full([len(livingPlantsInds40[2018]), 12], np.nan)
        yearlyOutagesGMT90 = np.full([len(livingPlantsInds40[2018]), 12], np.nan)
    
        print('calculating total capacity outage for %s/+%dC'%(models[model],w))
        
        # num plants for current model with data
        numPlants10 = 0
        numPlants50 = 0
        numPlants90 = 0
        
        # over all plants living in 2018
        for pInd, p in enumerate(livingPlantsInds40[2018]):#range(globalPCFut10.shape[0]):                
            yearlyOutagesCurPlant10 = np.full([globalPCFut10.shape[1], 12], np.nan)
            yearlyOutagesCurPlant50 = np.full([globalPCFut10.shape[1], 12], np.nan)
            yearlyOutagesCurPlant90 = np.full([globalPCFut10.shape[1], 12], np.nan)
            
            if pInd%500 == 0:
                print('plant %d...'%pInd)
            
            plantHasData10 = False
            plantHasData50 = False
            plantHasData90 = False
            
            # calculate the total outage (MW) on each day of each year
            for year in range(globalPCFut10.shape[1]):
                yearlyOutagesCurYear10 = np.full([12], np.nan)
                yearlyOutagesCurYear50 = np.full([12], np.nan)
                yearlyOutagesCurYear90 = np.full([12], np.nan)
                
                for month in range(12):

                    curMonthPc = np.reshape(globalPCFut10[p,year,month,:,:], [globalPCFut10[p,year,month,:,:].size])
                    monthlyOutages10 = (basePred10-curMonthPc) / 100.0
                    monthlyOutages10[monthlyOutages10<0] = 0
                    monthlyOutages10[monthlyOutages10>1] = np.nan
                    
                    curMonthPc = np.reshape(globalPCFut50[p,year,month,:,:], [globalPCFut50[p,year,month,:,:].size])
                    monthlyOutages50 = (basePred50-curMonthPc) / 100.0
                    monthlyOutages50[monthlyOutages50<0] = 0
                    monthlyOutages50[monthlyOutages50>1] = np.nan
                    
                    curMonthPc = np.reshape(globalPCFut90[p,year,month,:,:], [globalPCFut90[p,year,month,:,:].size])
                    monthlyOutages90 = (basePred90-curMonthPc) / 100.0
                    monthlyOutages90[monthlyOutages90<0] = 0
                    monthlyOutages90[monthlyOutages90>1] = np.nan
#                    
#                    indBadData10 = np.where((monthlyOutages10 < 0) | (monthlyOutages10 > 1))[0]
#                    monthlyOutages10[indBadData10] = np.nan
#                    
#                    indBadData50 = np.where((monthlyOutages50 < 0) | (monthlyOutages50 > 1))[0]
#                    monthlyOutages50[indBadData50] = np.nan
#                    
#                    indBadData90 = np.where((monthlyOutages90 < 0) | (monthlyOutages90 > 1))[0]
#                    monthlyOutages90[indBadData90] = np.nan
    
                    numHours10 = len(np.where(~np.isnan(monthlyOutages10))[0])
                    monthlyTotal10 = np.nansum(globalPlants['caps'][p] * monthlyOutages10)
                    
                    # divide by actual # of days in this month, then multiply by full summer (62 days)
                    # this accounts for model/years where there are nans
                    if numHours10 > 0:
                        monthlyTotal10 /= numHours10
                        monthlyTotal10 *= monthLen[month] * 24
                        yearlyOutagesCurYear10[month] = monthlyTotal10
                    
                    numHours50 = len(np.where(~np.isnan(monthlyOutages50))[0])
                    monthlyTotal50 = np.nansum(globalPlants['caps'][p] * monthlyOutages50)
                    
                    if numHours50 > 0:
                        monthlyTotal50 /= numHours50
                        monthlyTotal50 *= monthLen[month] * 24                           
                        yearlyOutagesCurYear50[month] = monthlyTotal50
                    
                    numHours90 = len(np.where(~np.isnan(monthlyOutages90))[0])
                    monthlyTotal90 = np.nansum(globalPlants['caps'][p] * monthlyOutages90)
                    
                    if numHours90 > 0:
                        monthlyTotal90 /= numHours90
                        monthlyTotal90 *= monthLen[month] * 24
                        yearlyOutagesCurYear90[month] = monthlyTotal90
                    
                
                if len(np.where(~np.isnan(yearlyOutagesCurYear10))[0]) == 12:
                    yearlyOutagesCurPlant10[year, :] = yearlyOutagesCurYear10
                    plantHasData10 = True
                
                if len(np.where(~np.isnan(yearlyOutagesCurYear50))[0]) == 12:
                    yearlyOutagesCurPlant50[year, :] = yearlyOutagesCurYear50
                    plantHasData50 = True
                
                if len(np.where(~np.isnan(yearlyOutagesCurYear90))[0]) == 12:
                    yearlyOutagesCurPlant90[year, :] = yearlyOutagesCurYear90
                    plantHasData90 = True
                    
            
            yearlyOutagesCurPlant10 = np.nanmean(yearlyOutagesCurPlant10, axis=0)
            if plantHasData10: numPlants10 += 1
            yearlyOutagesGMT10[pInd, :] = yearlyOutagesCurPlant10

            yearlyOutagesCurPlant50 = np.nanmean(yearlyOutagesCurPlant50, axis=0)
            if plantHasData50: numPlants50 += 1
            yearlyOutagesGMT50[pInd, :] = yearlyOutagesCurPlant50

            yearlyOutagesCurPlant90 = np.nanmean(yearlyOutagesCurPlant90, axis=0)
            if plantHasData90: numPlants90 += 1
            yearlyOutagesGMT90[pInd, :] = yearlyOutagesCurPlant90
            
#             # divide by # of years to get total outage per year, if there is data
#             if len(yearlyOutagesCurPlant10) > 0:
#                 yearlyOutagesCurPlant10 = np.array(yearlyOutagesCurPlant10)
#                 yearlyOutagesCurPlant10 = np.nanmean(yearlyOutagesCurPlant10, axis=0)
#                 yearlyOutagesCurGMT10.append(yearlyOutagesCurPlant10)                    
#                 if plantHasData10: numPlants10 += 1
            
            
#             if len(yearlyOutagesCurPlant50) > 0:
#                 yearlyOutagesCurPlant50 = np.array(yearlyOutagesCurPlant50)
#                 yearlyOutagesCurPlant50 = np.nanmean(yearlyOutagesCurPlant50, axis=0)
#                 yearlyOutagesCurGMT50.append(yearlyOutagesCurPlant50)                    
#                 if plantHasData50: numPlants50 += 1
                
#             if len(yearlyOutagesCurPlant90) > 0:
#                 yearlyOutagesCurPlant90 = np.array(yearlyOutagesCurPlant90)
#                 yearlyOutagesCurPlant90 = np.nanmean(yearlyOutagesCurPlant90, axis=0)
#                 yearlyOutagesCurGMT90.append(yearlyOutagesCurPlant90)
#                 if plantHasData90: numPlants90 += 1
                
        # divide by number of plants
        yearlyOutagesGMT10 = (np.nansum(yearlyOutagesGMT10, axis=0)/numPlants10)*yearlyOutagesGMT10.shape[0]
        yearlyOutagesCurModel10[w-1, :] = yearlyOutagesGMT10
        
        yearlyOutagesGMT50 = (np.nansum(yearlyOutagesGMT50, axis=0)/numPlants50)*yearlyOutagesGMT50.shape[0]
        yearlyOutagesCurModel50[w-1, :] = yearlyOutagesGMT50
        
        yearlyOutagesGMT90 = (np.nansum(yearlyOutagesGMT90, axis=0)/numPlants90)*yearlyOutagesGMT90.shape[0]
        yearlyOutagesCurModel90[w-1, :] = yearlyOutagesGMT90
        
    
    with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-10.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model]), 'wb') as f:
        pickle.dump(yearlyOutagesCurModel10, f)
    
    with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-50.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model]), 'wb') as f:
        pickle.dump(yearlyOutagesCurModel50, f)
        
    with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-90.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model]), 'wb') as f:
        pickle.dump(yearlyOutagesCurModel90, f)
    

with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-10.dat'%(dataDirDiscovery, runoffData, plantData, modelPower), 'rb') as f:
    yearlyOutagesHist10 = pickle.load(f)
    
with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-50.dat'%(dataDirDiscovery, runoffData, plantData, modelPower), 'rb') as f:
    yearlyOutagesHist50 = pickle.load(f)
    
with gzip.open('%s/agg-outages-%s/aggregated-%s-outages-hist-hourly-%s-90.dat'%(dataDirDiscovery, runoffData, plantData, modelPower), 'rb') as f:
    yearlyOutagesHist90 = pickle.load(f)

yearlyOutagesFut10 = []
yearlyOutagesFut50 = []
yearlyOutagesFut90 = []

for model in range(len(models[0])):
    yearlyOutagesCurModel10 = []
    yearlyOutagesCurModel50 = []
    yearlyOutagesCurModel90 = []


    fileName10 = '%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-10.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model])
    fileName50 = '%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-50.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model])
    fileName90 = '%s/agg-outages-%s/aggregated-%s-outages-fut-hourly-%s-%s-90.dat'%(dataDirDiscovery, runoffData, plantData, modelPower, models[model])
    
    if os.path.isfile(fileName10):
        
        with gzip.open(fileName10) as f:
            yearlyOutagesCurModel10 = pickle.load(f)
        with gzip.open(fileName50) as f:
            yearlyOutagesCurModel50 = pickle.load(f)
        with gzip.open(fileName90) as f:
            yearlyOutagesCurModel90 = pickle.load(f)
            
        yearlyOutagesFut10.append(yearlyOutagesCurModel10)
        yearlyOutagesFut50.append(yearlyOutagesCurModel50)
        yearlyOutagesFut90.append(yearlyOutagesCurModel90)

# convert all to twh
yearlyOutagesHist10 /= 1e6
yearlyOutagesHist50 /= 1e6
yearlyOutagesHist90 /= 1e6
yearlyOutagesFut10 = np.array(yearlyOutagesFut10)/1e6
yearlyOutagesFut50 = np.array(yearlyOutagesFut50)/1e6
yearlyOutagesFut90 = np.array(yearlyOutagesFut90)/1e6

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

#xd = np.array(list(range(1981, 2018+1)))-1981+1

#z = np.polyfit(xd, mean10[0,:], 1)
#histPolyTx10 = np.poly1d(z)
#z = np.polyfit(xd, mean50[0,:], 1)
#histPolyTx50 = np.poly1d(z)
#z = np.polyfit(xd, mean90[0,:], 1)
#histPolyTx90 = np.poly1d(z)

# in PJ
# yearlyOutagesHist10 = yearlyOutagesHist10/1e18*1e3
# yearlyOutagesHist50 = yearlyOutagesHist50/1e18*1e3
# yearlyOutagesHist90 = yearlyOutagesHist90/1e18*1e3

# yearlyOutagesFut10 = yearlyOutagesFut10/1e18*1e3
# yearlyOutagesFut50 = yearlyOutagesFut50/1e18*1e3
# yearlyOutagesFut90 = yearlyOutagesFut90/1e18*1e3
                               
yearlyOutagesFut10 = np.moveaxis(yearlyOutagesFut10, 1, 0)
yearlyOutagesFut50 = np.moveaxis(yearlyOutagesFut50, 1, 0)
yearlyOutagesFut90 = np.moveaxis(yearlyOutagesFut90, 1, 0)


if plantData == 'world':
    yLimSet = 850
    yTickStep = 200
    yticks = np.arange(0,yLimSet,yTickStep)
else:
    yLimSet = 49
    yTickStep = 10
    yTicks = [0, 10, 20, 30, 40]
    yticks = np.arange(0,49,yTickStep)

                            
# Twh
totalMonthlyEnergy = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])*30*24/1e6
totalAnnualEnergy = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])*24*365/1e6
xpos = [1,2,3,4,5,6,7,8,9,10,11,12]

pctEnergyGrid = np.round(yticks/totalAnnualEnergy*100,decimals=1)

outageSumHist = []
outageSum1 = []
outageSum2 = []
outageSum3 = []
outageSum4 = []

for m in range(0,12):
    outageSumHist.append(np.nansum(yearlyOutagesHist50[0:m+1]))
    outageSum1.append(np.nansum(yearlyOutagesFut50[0,:,0:m+1], axis=1))
    outageSum2.append(np.nansum(yearlyOutagesFut50[1,:,0:m+1], axis=1))
    outageSum3.append(np.nansum(yearlyOutagesFut50[2,:,0:m+1], axis=1))
    outageSum4.append(np.nansum(yearlyOutagesFut50[3,:,0:m+1], axis=1))

outageSum1 = np.sort(np.array(outageSum1), axis=1)
outageSum2 = np.sort(np.array(outageSum2), axis=1)
outageSum3 = np.sort(np.array(outageSum3), axis=1)
outageSum4 = np.sort(np.array(outageSum4), axis=1)

#plt.rc('font', family='helvetica', weight='normal')
#plt.rc('axes', labelweight='normal')

plt.figure(figsize=(5,2))
#plt.ylim([0, 320])
plt.ylim([0,yLimSet])
plt.xlim([0,13])
plt.grid(True, alpha = 0.25)
plt.gca().set_axisbelow(True)

plt.plot(xpos, outageSumHist, '-', lw=2, color='black', label='Historical')
plt.plot(xpos, np.nanmean(outageSum2, axis=1), '-', lw=2, color='#ffb835', label='+ 2$\degree$C')
plt.plot(xpos, outageSum2[:,-1], '--', lw=2, color='#ffb835')
plt.plot(xpos, np.nanmean(outageSum4, axis=1), '-', lw=2, color=snsColors[1], label='+ 4$\degree$C')
plt.plot(xpos, outageSum4[:,-1], '--', lw=2, color=snsColors[1])

plt.fill_between(xpos, outageSumHist, [0]*12, facecolor='black', alpha=.5, interpolate=True)
plt.fill_between(xpos, np.nanmean(outageSum2, axis=1), outageSumHist, facecolor='#ffb835', alpha=.5, interpolate=True)
plt.fill_between(xpos, np.nanmean(outageSum4, axis=1), np.nanmean(outageSum2, axis=1), facecolor=snsColors[1], alpha=.5, interpolate=True)

plt.xticks(range(1,13))
plt.gca().set_xticklabels(range(1,13))
plt.yticks(yticks)
plt.xlabel('Month', fontname = 'Helvetica', fontsize=16)
#plt.ylabel('Cumulative US-EU outage (EJ)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

#plt.tick_params(
#    axis='x',          # changes apply to the x-axis
#    which='both',      # both major and minor ticks are affected
#    bottom=False,      # ticks along the bottom edge are off
#    top=False,         # ticks along the top edge are off
#    labelbottom=False) # labels along the bottom edge are off

ax2 = plt.gca().twinx()
plt.xlim([0,13])
plt.ylim([0,yLimSet])
plt.yticks(yticks)
plt.gca().set_yticklabels(pctEnergyGrid)

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

if plotFigs:
    plt.savefig('accumulated-annual-outage-cdf-%s-%s.png'%(plantData,runoffData), format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0, transparent=True)

    
    
    
    
if plantData == 'world':
    yLimSet = 160
    yTickStep = 50
else:
    yLimSet = 14
    yTickStep = 2

yticks = np.arange(0,yLimSet,yTickStep)
pctEnergyGrid = np.round(yticks/totalMonthlyEnergy*100,decimals=1)

yearlyOutagesFut50GMT2Sorted = np.sort(yearlyOutagesFut50[1,:,:],axis=0)
yearlyOutagesFut50GMT4Sorted = np.sort(yearlyOutagesFut50[3,:,:],axis=0)

plt.figure(figsize=(5,2))
#plt.xlim([0, 7])
plt.xlim([0,13])
plt.ylim([0, yLimSet])
plt.grid(True, alpha = 0.25)
plt.gca().set_axisbelow(True)

plt.plot(xpos, yearlyOutagesHist50, '-', lw=2, color='black', label='Historical')
plt.plot(xpos, np.nanmean(yearlyOutagesFut50[1],axis=0), '-', lw=2, color='#ffb835', label='+ 2$\degree$C')
plt.plot(xpos, yearlyOutagesFut50GMT2Sorted[-2,:], '--', lw=2, color='#ffb835')
plt.plot(xpos, np.nanmean(yearlyOutagesFut50[3],axis=0), '-', lw=2, color=snsColors[1], label='+ 4$\degree$C')
plt.plot(xpos, yearlyOutagesFut50GMT4Sorted[-3,:], '--', lw=2, color=snsColors[1])


plt.fill_between(xpos, yearlyOutagesHist50, [0]*12, facecolor='black', alpha=.5, interpolate=True)
plt.fill_between(xpos, yearlyOutagesHist50, np.nanmean(yearlyOutagesFut50[1],axis=0), facecolor='#ffb835', alpha=.5, interpolate=True)
plt.fill_between(xpos, np.nanmean(yearlyOutagesFut50[1],axis=0), np.nanmean(yearlyOutagesFut50[3],axis=0), facecolor=snsColors[1], alpha=.5, interpolate=True)

plt.xticks(xpos)
plt.yticks(yticks)
#plt.xlabel('Month', fontname = 'Helvetica', fontsize=16)
#plt.ylabel('Monthly US-EU outage (EJ)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off


leg = plt.legend(prop = {'size':12, 'family':'Helvetica', 'weight':'normal'}, loc = 'upper left')
leg.get_frame().set_linewidth(0.0)            

#leg = plt.legend(prop = {'size':11, 'family':'Helvetica'})
#leg.get_frame().set_linewidth(0.0)
    
ax2 = plt.gca().twinx()
plt.xlim([0,13])
plt.ylim([0, yLimSet])
plt.yticks(yticks)
plt.gca().set_yticklabels(pctEnergyGrid)
#plt.ylabel('% of US-EU electricity capacity', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('accumulated-monthly-outage-%s-%s.png'%(plantData, runoffData), format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0, transparent=True)

plt.show()
sys.exit()
