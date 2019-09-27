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
import statsmodels.api as sm
import el_load_global_plants
import pickle, gzip
import sys, os


matplotlib.rcParams['font.family'] = 'Helvetica'
matplotlib.rcParams['font.weight'] = 'normal'


#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = False

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']


#grdc or gldas
runoffData = 'grdc'

# world, useu, or entsoe-nuke
plantData = 'useu'

# '-distfit' or ''
qsfit = '-qdistfit-gamma'

modelPower = 'pow2'

if plantData == 'useu':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=False)
elif plantData == 'world':
    globalPlants = el_load_global_plants.loadGlobalPlants(world=True)

with open('E:/data/ecoffel/data/projects/electricity/script-data/active-pp-inds-40-%s.dat'%plantData, 'rb') as f:
    livingPlantsInds40 = pickle.load(f)

pcModel10 = []
pcModel50 = []
pcModel90 = []
with gzip.open('E:/data/ecoffel/data/projects/electricity/script-data/pPolyData-%s-%s.dat'%(runoffData, modelPower), 'rb') as f:
    pPolyData = pickle.load(f)
    pcModel10 = pPolyData['pcModel10'][0]
    pcModel50 = pPolyData['pcModel50'][0]
    pcModel90 = pPolyData['pcModel90'][0]

yearRange = [1981, 2018]

monthLen = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


txBase = 27
qsBase = 0
basePred10 = pcModel10.predict([1, txBase, txBase**2, \
                              qsBase, qsBase**2, \
                              txBase*qsBase, (txBase**2)*(qsBase**2), \
                              0])[0]
basePred50 = pcModel50.predict([1, txBase, txBase**2, \
                              qsBase, qsBase**2, \
                              txBase*qsBase, (txBase**2)*(qsBase**2), \
                              0])[0]
basePred90 = pcModel90.predict([1, txBase, txBase**2, \
                              qsBase, qsBase**2, \
                              txBase*qsBase, (txBase**2)*(qsBase**2), \
                              0])[0]

if not os.path.isfile('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-10.dat'%(runoffData, plantData, qsfit, modelPower)):

    extra=''
    if not 'globalPCHist50' in locals():
        try:
            with gzip.open('E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-10%s.dat'%(runoffData, plantData, qsfit, modelPower, extra), 'rb') as f:
                globalPCHist = pickle.load(f)
                globalPCHist10 = globalPCHist['globalPCHist10']
        except:
            with open('E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-10%s.dat'%(runoffData, plantData, qsfit, modelPower, extra), 'rb') as f:
                globalPCHist = pickle.load(f)
                globalPCHist10 = globalPCHist['globalPCHist10']
        
        try:
            with gzip.open('E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-50%s.dat'%(runoffData, plantData, qsfit, modelPower, extra), 'rb') as f:
                globalPCHist = pickle.load(f)
                globalPCHist50 = globalPCHist['globalPCHist50']
        except:
            with open('E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-50%s.dat'%(runoffData, plantData, qsfit, modelPower, extra), 'rb') as f:
                globalPCHist = pickle.load(f)
                globalPCHist50 = globalPCHist['globalPCHist50']
            
        try:
            with gzip.open('E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-90%s.dat'%(runoffData, plantData, qsfit, modelPower, extra), 'rb') as f:
                globalPCHist = pickle.load(f)
                globalPCHist90 = globalPCHist['globalPCHist90']
        except:
            with open('E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-hist%s-%s-90%s.dat'%(runoffData, plantData, qsfit, modelPower, extra), 'rb') as f:
                globalPCHist = pickle.load(f)
                globalPCHist90 = globalPCHist['globalPCHist90']
            
    yearlyOutagesHist10 = []
    yearlyOutagesHist50 = []
    yearlyOutagesHist90 = []
    
    print('calculating total capacity outage for historical')
    
    numPlants10 = 0
    numPlants50 = 0
    numPlants90 = 0
    
    # over all plants that are active in 2018
    for p in livingPlantsInds40[2018]:#range(globalPCHist50.shape[0]):
        
        if p % 500 == 0:
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
                
                monthlyOutages10 = (basePred10-np.array(globalPCHist10[p,year,month][:])) / 100.0
                monthlyOutages10[monthlyOutages10 < 0] = 0
                monthlyOutages10[monthlyOutages10 > 1] = np.nan
                numDays10 = len(np.where(~np.isnan(monthlyOutages10))[0])
                monthlyTotal10 = np.nansum(globalPlants['caps'][p] * monthlyOutages10 * 1e6)
                
                # divide by actual # of days with non-nan data in this month, then multiply by full month length
                # this accounts for model/years where there are nans
                if numDays10 > 0:
                    monthlyTotal10 /= numDays10
                    monthlyTotal10 *= monthLen[month] * 24 * 3600
                    
                    yearlyOutagesHistCurYear10.append(monthlyTotal10)
                    
                
                monthlyOutages50 = (basePred50-np.array(globalPCHist50[p,year,month][:])) / 100.0
                monthlyOutages50[monthlyOutages50 < 0] = 0
                monthlyOutages50[monthlyOutages50 > 1] = np.nan
                numDays50 = len(np.where(~np.isnan(monthlyOutages50))[0])
                monthlyTotal50 = np.nansum(globalPlants['caps'][p] * monthlyOutages50 * 1e6)
                
                if numDays50 > 0:
                    monthlyTotal50 /= numDays50
                    monthlyTotal50 *= monthLen[month] * 24 * 3600
                    
                    yearlyOutagesHistCurYear50.append(monthlyTotal50)
                    
                    
                    
                monthlyOutages90 = (basePred90-np.array(globalPCHist90[p,year,month][:])) / 100.0
                monthlyOutages90[monthlyOutages90 < 0] = 0
                monthlyOutages90[monthlyOutages90 > 1] = np.nan
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
            
    
    # sum over all plants, divide by # plants with data, multiply by total number of plants regardless
    # of whether they have data
    yearlyOutagesHist10 = np.array(yearlyOutagesHist10)
    yearlyOutagesHist10 = (np.nansum(yearlyOutagesHist10, axis=0)/numPlants10)*yearlyOutagesHist10.shape[0]
    
    yearlyOutagesHist50 = np.array(yearlyOutagesHist50)
    yearlyOutagesHist50 = (np.nansum(yearlyOutagesHist50, axis=0)/numPlants50)*yearlyOutagesHist50.shape[0]
    
    yearlyOutagesHist90 = np.array(yearlyOutagesHist90)
    yearlyOutagesHist90 = (np.nansum(yearlyOutagesHist90, axis=0)/numPlants90)*yearlyOutagesHist90.shape[0]
    
    with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-10.dat'%(runoffData, plantData, qsfit, modelPower), 'wb') as f:
        pickle.dump(yearlyOutagesHist10, f)
        
    with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-50.dat'%(runoffData, plantData, qsfit, modelPower), 'wb') as f:
        pickle.dump(yearlyOutagesHist50, f)
        
    with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-90.dat'%(runoffData, plantData, qsfit, modelPower), 'wb') as f:
        pickle.dump(yearlyOutagesHist90, f)





for model in range(len(models)):
    yearlyOutagesCurModel10 = []
    yearlyOutagesCurModel50 = []
    yearlyOutagesCurModel90 = []

    if os.path.isfile('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-10.dat'%(runoffData, plantData, qsfit, modelPower, models[model])) or \
       os.path.isfile('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-10.dat'%(runoffData, plantData, qsfit)):
        print('skipping %s...'%models[model])
        continue

    for w in range(1,4+1):
        
        yearlyOutagesCurGMT10 = []
        yearlyOutagesCurGMT50 = []
        yearlyOutagesCurGMT90 = []
        
        fileName = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-%ddeg-%s-%s.dat'%(runoffData, plantData, qsfit, w, modelPower, models[model])
        fileName10 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-10-%ddeg-%s-%s.dat'%(runoffData, plantData, qsfit, w, modelPower, models[model])
        fileName50 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-50-%ddeg-%s-%s.dat'%(runoffData, plantData, qsfit, w, modelPower, models[model])
        fileName90 = 'E:\data\ecoffel\data\projects\electricity\pc-future-%s\%s-pc-future%s-90-%ddeg-%s-%s.dat'%(runoffData, plantData, qsfit, w, modelPower, models[model])
        
        if os.path.isfile(fileName):
            try:
                with gzip.open(fileName, 'rb') as f:
                    globalPC = pickle.load(f)
                    
                    globalPCFut10 = globalPC['globalPCFut10']
                    globalPCFut50 = globalPC['globalPCFut50']
                    globalPCFut90 = globalPC['globalPCFut90']
            except:
                with open(fileName, 'rb') as f:
                    globalPC = pickle.load(f)
                    
                    globalPCFut10 = globalPC['globalPCFut10']
                    globalPCFut50 = globalPC['globalPCFut50']
                    globalPCFut90 = globalPC['globalPCFut90']
        elif os.path.isfile(fileName10):
            try:
                with gzip.open(fileName10, 'rb') as f:
                    globalPC = pickle.load(f)
                    globalPCFut10 = globalPC['globalPCFut10']
            except:
                with open(fileName10, 'rb') as f:
                    globalPC = pickle.load(f)
                    globalPCFut10 = globalPC['globalPCFut10']
            
            try:
                with gzip.open(fileName50, 'rb') as f:
                    globalPC = pickle.load(f)
                    globalPCFut50 = globalPC['globalPCFut50']
            except:
                with open(fileName50, 'rb') as f:
                    globalPC = pickle.load(f)
                    globalPCFut50 = globalPC['globalPCFut50']
            
            try:
                with gzip.open(fileName90, 'rb') as f:
                    globalPC = pickle.load(f)
                    globalPCFut90 = globalPC['globalPCFut90']
            except:
                with open(fileName90, 'rb') as f:
                    globalPC = pickle.load(f)
                    globalPCFut90 = globalPC['globalPCFut90']
                
        print('calculating total capacity outage for %s/+%dC'%(models[model],w))
        
        # num plants for current model with data
        numPlants10 = 0
        numPlants50 = 0
        numPlants90 = 0
        
        # over all plants living in 2018
        for p in livingPlantsInds40[2018]:#range(globalPCFut10.shape[0]):                
            yearlyOutagesCurPlant10 = []
            yearlyOutagesCurPlant50 = []
            yearlyOutagesCurPlant90 = []
            
            if p%1000 == 0:
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
            
                    monthlyOutages10 = (basePred10-np.array(globalPCFut10[p,year,month][:])) / 100.0
                    monthlyOutages10[monthlyOutages10<0] = 0
                    monthlyOutages10[monthlyOutages10>1] = np.nan
                    
                    monthlyOutages50 = (basePred50-np.array(globalPCFut50[p,year,month][:])) / 100.0
                    monthlyOutages50[monthlyOutages50<0] = 0
                    monthlyOutages50[monthlyOutages50>1] = np.nan
                    
                    monthlyOutages90 = (basePred90-np.array(globalPCFut90[p,year,month][:])) / 100.0
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
                yearlyOutagesCurGMT10.append(yearlyOutagesCurPlant10)                    
                if plantHasData10: numPlants10 += 1
            
            
            if len(yearlyOutagesCurPlant50) > 0:
                yearlyOutagesCurPlant50 = np.array(yearlyOutagesCurPlant50)
                yearlyOutagesCurPlant50 = np.nanmean(yearlyOutagesCurPlant50, axis=0)
                yearlyOutagesCurGMT50.append(yearlyOutagesCurPlant50)                    
                if plantHasData50: numPlants50 += 1
                
            if len(yearlyOutagesCurPlant90) > 0:
                yearlyOutagesCurPlant90 = np.array(yearlyOutagesCurPlant90)
                yearlyOutagesCurPlant90 = np.nanmean(yearlyOutagesCurPlant90, axis=0)
                yearlyOutagesCurGMT90.append(yearlyOutagesCurPlant90)
                if plantHasData90: numPlants90 += 1
                
        # divide by number of plants
        yearlyOutagesCurGMT10 = np.array(yearlyOutagesCurGMT10)
        yearlyOutagesCurGMT10 = (np.nansum(yearlyOutagesCurGMT10, axis=0)/numPlants10)*yearlyOutagesCurGMT10.shape[0]
        yearlyOutagesCurModel10.append(yearlyOutagesCurGMT10)
        
        yearlyOutagesCurGMT50 = np.array(yearlyOutagesCurGMT50)
        yearlyOutagesCurGMT50 = (np.nansum(yearlyOutagesCurGMT50, axis=0)/numPlants50)*yearlyOutagesCurGMT50.shape[0]
        yearlyOutagesCurModel50.append(yearlyOutagesCurGMT50)
        
        yearlyOutagesCurGMT90 = np.array(yearlyOutagesCurGMT90)
        yearlyOutagesCurGMT90 = (np.nansum(yearlyOutagesCurGMT90, axis=0)/numPlants90)*yearlyOutagesCurGMT90.shape[0]
        yearlyOutagesCurModel90.append(yearlyOutagesCurGMT90)
        
    
    yearlyOutagesCurModel10 = np.array(yearlyOutagesCurModel10)
    yearlyOutagesCurModel50 = np.array(yearlyOutagesCurModel50)
    yearlyOutagesCurModel90 = np.array(yearlyOutagesCurModel90)
    
    with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-10.dat'%(runoffData, plantData, qsfit, modelPower, models[model]), 'wb') as f:
        pickle.dump(yearlyOutagesCurModel10, f)
    
    with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-50.dat'%(runoffData, plantData, qsfit, modelPower, models[model]), 'wb') as f:
        pickle.dump(yearlyOutagesCurModel50, f)
        
    with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-90.dat'%(runoffData, plantData, qsfit, modelPower, models[model]), 'wb') as f:
        pickle.dump(yearlyOutagesCurModel90, f)
    
    
    


with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-10.dat'%(runoffData, plantData, qsfit, modelPower), 'rb') as f:
    yearlyOutagesHist10 = pickle.load(f)
    
with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-50.dat'%(runoffData, plantData, qsfit, modelPower), 'rb') as f:
    yearlyOutagesHist50 = pickle.load(f)
    
with gzip.open('E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-hist%s-%s-90.dat'%(runoffData, plantData, qsfit, modelPower), 'rb') as f:
    yearlyOutagesHist90 = pickle.load(f)

yearlyOutagesFut10 = []
yearlyOutagesFut50 = []
yearlyOutagesFut90 = []

for model in range(len(models)):
    yearlyOutagesCurModel10 = []
    yearlyOutagesCurModel50 = []
    yearlyOutagesCurModel90 = []


    fileName10 = 'E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-10.dat'%(runoffData, plantData, qsfit, modelPower, models[model])
    fileName50 = 'E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-50.dat'%(runoffData, plantData, qsfit, modelPower, models[model])
    fileName90 = 'E:/data/ecoffel/data/projects/electricity/agg-outages-%s/aggregated-%s-outages-fut%s-%s-%s-90.dat'%(runoffData, plantData, qsfit, modelPower, models[model])
    
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

yearlyOutagesFut10 = np.array(yearlyOutagesFut10)
yearlyOutagesFut50 = np.array(yearlyOutagesFut50)
yearlyOutagesFut90 = np.array(yearlyOutagesFut90)

sys.exit()
    

snsColors = sns.color_palette(["#3498db", "#e74c3c"])

#xd = np.array(list(range(1981, 2018+1)))-1981+1

#z = np.polyfit(xd, mean10[0,:], 1)
#histPolyTx10 = np.poly1d(z)
#z = np.polyfit(xd, mean50[0,:], 1)
#histPolyTx50 = np.poly1d(z)
#z = np.polyfit(xd, mean90[0,:], 1)
#histPolyTx90 = np.poly1d(z)

# in PJ
yearlyOutagesHist10 = yearlyOutagesHist10/1e18*1e3
yearlyOutagesHist50 = yearlyOutagesHist50/1e18*1e3
yearlyOutagesHist90 = yearlyOutagesHist90/1e18*1e3

yearlyOutagesFut10 = yearlyOutagesFut10/1e18*1e3
yearlyOutagesFut50 = yearlyOutagesFut50/1e18*1e3
yearlyOutagesFut90 = yearlyOutagesFut90/1e18*1e3
                               
yearlyOutagesFut10 = np.moveaxis(yearlyOutagesFut10, 1, 0)
yearlyOutagesFut50 = np.moveaxis(yearlyOutagesFut50, 1, 0)
yearlyOutagesFut90 = np.moveaxis(yearlyOutagesFut90, 1, 0)


                            
# PJ
totalMonthlyEnergy = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])*30*24*3600*1e6/1e18*1e3
totalAnnualEnergy = np.nansum(globalPlants['caps'][livingPlantsInds40[2018]])*30*24*3600*1e6/1e18*1e3*12
xpos = [1,2,3,4,5,6,7,8,9,10,11,12]
yticks = np.arange(0,270,50)
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
plt.ylim([0,290])
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
plt.ylim([0,290])
plt.yticks(yticks)
plt.gca().set_yticklabels(pctEnergyGrid)

for tick in plt.gca().yaxis.get_major_ticks():
    tick.label2.set_fontname('Helvetica')    
    tick.label2.set_fontsize(14)

if plotFigs:
    plt.savefig('accumulated-annual-outage-cdf-%s-%s.png'%(plantData,runoffData), format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

    
    
    
    
    
    
    
    
    
    
    
    

yticks = np.arange(0,81,20)
pctEnergyGrid = np.round(yticks/totalMonthlyEnergy*100,decimals=1)

yearlyOutagesFut50GMT2Sorted = np.sort(yearlyOutagesFut50[1,:,:],axis=0)
yearlyOutagesFut50GMT4Sorted = np.sort(yearlyOutagesFut50[3,:,:],axis=0)

plt.figure(figsize=(5,2))
#plt.xlim([0, 7])
plt.xlim([0,13])
plt.ylim([0, 90])
plt.grid(True, alpha = 0.25)
plt.gca().set_axisbelow(True)

plt.plot(xpos, yearlyOutagesHist50, '-', lw=2, color='black', label='Historical')
plt.plot(xpos, np.nanmean(yearlyOutagesFut50[1],axis=0), '-', lw=2, color='#ffb835', label='+ 2$\degree$C')
plt.plot(xpos, yearlyOutagesFut50GMT2Sorted[-1,:], '--', lw=2, color='#ffb835')
plt.plot(xpos, np.nanmean(yearlyOutagesFut50[3],axis=0), '-', lw=2, color=snsColors[1], label='+ 4$\degree$C')
plt.plot(xpos, yearlyOutagesFut50GMT4Sorted[-1,:], '--', lw=2, color=snsColors[1])


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
plt.ylim([0, 90])
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
    plt.savefig('accumulated-monthly-outage-%s.png'%runoffData, format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()
sys.exit()

xpos = np.array([1, 3, 4, 5, 6])

plt.figure(figsize=(5,4))
plt.xlim([0, 7])
#plt.ylim([.55, 1.175])
plt.ylim([0, 1.2])
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
    plt.savefig('accumulated-annual-outage-%s.eps'%runoffData, format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)






