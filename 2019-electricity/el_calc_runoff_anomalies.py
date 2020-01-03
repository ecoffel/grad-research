# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 17:49:10 2019

@author: Ethan
"""


import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import scipy.stats as st
import statsmodels.api as sm
import pickle, gzip
import sys,os

import el_build_temp_demand_model
import el_find_best_runoff_dist

import warnings
warnings.filterwarnings('ignore')

# world, useu, entsoe-nuke
plantData = 'useu'

# 'gmt-cmip5, decade-cmip5', 'hist', 'at-txx'
anomType = 'gmt-cmip5'

runoffData = 'gldas'

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

# models = ['bcc-csm1-1-m', 'canesm2', \
#               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
#               'gfdl-esm2g', 'gfdl-esm2m', \
#               'inmcm4', 'miroc5', 'miroc-esm', \
#               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

if anomType == 'at-txx':

    model = sys.argv[1]
    rcp = sys.argv[2]
    
    decades = np.array([[2020,2029],\
                   [2030, 2039],\
                   [2040,2049],\
                   [2050,2059],\
                   [2060,2069],\
                   [2070,2079],\
                   [2080,2089]])
    
    for d in range(decades.shape[0]):
        fileNameRunoffRaw = '%s/future-temps/%s-pp-%s-runoff-at-txx-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, model, decades[d,0], decades[d,1])
        fileNameRunoffAnom = '%s/future-temps/%s-pp-%s-runoff-anom-at-txx-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, model, decades[d,0], decades[d,1])
        fileNameRunoffPercentile = '%s/future-temps/%s-pp-%s-runoff-percentile-at-txx-cmip5-%s-%d-%d.csv'%(dataDirDiscovery, plantData, rcp, model, decades[d,0], decades[d,1])

        plantQsDataRaw = np.genfromtxt(fileNameRunoffRaw, delimiter=',', skip_header=0)
        plantQsAnomData = np.full(plantQsDataRaw.shape, np.nan)
        plantQsPercentileData = np.full(plantQsDataRaw.shape, np.nan)

        for p in range(0, plantQsAnomData.shape[0]):

            with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, model, p), 'rb') as f:
                if p%100 == 0:
                    print('plant %d of %d'%(p, plantQsDataRaw.shape[0]))

                distParams = pickle.load(f)
                dist = getattr(st, distParams['name'])
                curQsPercentile = dist.cdf(plantQsDataRaw[p, :], *distParams['params'])
                curQsStd = distParams['std']

                plantQsAnomData[p, :] = (plantQsDataRaw[p, :] - np.nanmean(plantQsDataRaw[p, :]))/curQsStd
                plantQsPercentileData[p, :] = curQsPercentile
        print('saving data to %s'%fileNameRunoffAnom)
        np.savetxt(fileNameRunoffAnom, plantQsAnomData, delimiter=',')
        np.savetxt(plantQsPercentileData, plantQsPercentileData, delimiter=',')

elif anomType == 'hist':
    # this is gldas data for historical plants
    print('processing %s hist runoff'%plantData)

#     startP = int(sys.argv[1])
#     endP = int(sys.argv[2])
    
    fileNameRunoffRaw = '%s/script-data/%s-pp-runoff-raw-%s-1981-2018.csv'%(dataDirDiscovery, plantData, runoffData)
    fileNameRunoffAnom = '%s/script-data/%s-pp-runoff-anom-%s-1981-2018.csv'%(dataDirDiscovery, plantData, runoffData)#, startP, endP)

    plantQsDataRaw = np.genfromtxt(fileNameRunoffRaw, delimiter=',', skip_header=0)

    # find inds of each unique month - data is monthly and we don't need to fit over daily copies!
    plantQsDataRawMonthly = []
    uniqueMonthInds = []
    curMonth = -1
    for d in range(plantQsDataRaw.shape[1]):
        if curMonth == -1 or plantQsDataRaw[1,d] != curMonth:
            uniqueMonthInds.append(d)
            curMonth = plantQsDataRaw[1,d]
    uniqueMonthInds = np.array(uniqueMonthInds)
    
    plantQsAnomData = np.full(plantQsDataRaw.shape, np.nan)
    plantQsAnomData[0, :] = plantQsDataRaw[0, :]
    plantQsAnomData[1, :] = plantQsDataRaw[1, :]
    plantQsAnomData[2, :] = plantQsDataRaw[2, :]
    
    for p in range(3, plantQsAnomData.shape[0]):
        
        if not os.path.isfile('%s/dist-fits/best-fit-%s-hist-%s-plant-%d.dat'%(dataDirDiscovery, plantData, runoffData, p-3)):
            curq = plantQsDataRaw[p-3, uniqueMonthInds]
            nn = np.where(~np.isnan(curq))[0]
            best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(curq[nn])
            with open('%s/dist-fits/best-fit-%s-hist-%s-plant-%d.dat'%(dataDirDiscovery, plantData, runoffData, p-3), 'wb') as f:
                dist = getattr(st, best_fit_name)
    #                 tmpQsPercentile = dist.cdf(plantQsDataHist[p-3,nn], *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsStd}
                pickle.dump(distParams, f)
                print('%s hist %d: dist = %s, std = %.4f'%(runoffData, p-3, str(dist), curQsStd))

        with open('%s/dist-fits/best-fit-%s-hist-%s-plant-%d.dat'%(dataDirDiscovery, plantData, runoffData, p-3), 'rb') as f:
            if p%100 == 0:
                print('plant %d of %d'%(p, plantQsDataRaw.shape[0]))
            distParams = pickle.load(f)
            curQsStd = distParams['std']

            plantQsAnomData[p, :] = (plantQsDataRaw[p, :] - np.nanmean(plantQsDataRaw[p, :]))/curQsStd
    print('saving data to %s'%fileNameRunoffAnom)
    np.savetxt(fileNameRunoffAnom, plantQsAnomData, delimiter=',')

elif anomType == 'decade-cmip5':
    models = [sys.argv[1]]
    rcp = sys.argv[2]

    for m in range(len(models)):

        print('processing %s'%(models[m]))

        fileNameRunoffRaw = '%s/future-temps/world-pp-%s-runoff-cmip5-%s-2080-2089.csv'%(dataDirDiscovery, rcp, models[m])
        fileNameRunoffAnom = '%s/future-temps/world-pp-%s-runoff-anom-cmip5-%s-2080-2089.csv'%(dataDirDiscovery, rcp, models[m])
        fileNameRunoffPercentile = '%s/future-temps/world-pp-%s-runoff-percentile-cmip5-%s-2080-2089.csv'%(dataDirDiscovery, rcp, models[m])

        if not os.path.isfile(fileNameRunoffRaw):
            continue

        plantQsDataRaw = np.genfromtxt(fileNameRunoffRaw, delimiter=',', skip_header=0)

        plantQsAnomData = np.full(plantQsDataRaw.shape, np.nan)
        plantQsAnomData[0, :] = plantQsDataRaw[0, :]
        plantQsAnomData[1, :] = plantQsDataRaw[1, :]
        plantQsAnomData[2, :] = plantQsDataRaw[2, :]
        
        plantQsPercentileData = np.full(plantQsDataRaw.shape, np.nan)
        plantQsPercentileData[0, :] = plantQsDataRaw[0, :]
        plantQsPercentileData[1, :] = plantQsDataRaw[1, :]
        plantQsPercentileData[2, :] = plantQsDataRaw[2, :]

        for p in range(3, plantQsDataRaw.shape[0]):
            if p%100 == 0:
                print('plant %d of %d'%(p, plantQsDataRaw.shape[0]))

            with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3), 'rb') as f:
                distParams = pickle.load(f)
                dist = getattr(st, distParams['name'])
                curQsPercentile = dist.cdf(plantQsDataRaw[p, :], *distParams['params'])
                curQsStd = distParams['std']
                
                plantQsPercentileData[p, :] = curQsPercentile
                plantQsAnomData[p, :] = (plantQsDataRaw[p, :] - np.nanmean(plantQsDataRaw[p, :]))/curQsStd
        
        print('saving data to %s'%fileNameRunoffAnom)
        np.savetxt(fileNameRunoffAnom, plantQsAnomData, delimiter=',')
        np.savetxt(fileNameRunoffPercentile, plantQsPercentileData, delimiter=',')
    
elif anomType == 'gmt-cmip5':
    models = [sys.argv[1]]

    for w in range(1, 4+1):

        for m in range(len(models)):

            print('processing %s/%d'%(models[m], w))

            fileNameRunoffRaw = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-raw-cmip5-%s-preIndRef.csv'%(dataDirDiscovery, plantData, w, models[m])
            fileNameRunoffAnom = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-anom-best-dist-cmip5-%s-preIndRef.csv'%(dataDirDiscovery, plantData, w, models[m])
            fileNameRunoffPercentile = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-percentile-best-dist-cmip5-%s-preIndRef.csv'%(dataDirDiscovery, plantData, w, models[m])
            fileNameRunoffHist = '%s/future-temps/%s-pp-hist-runoff-raw-cmip5-%s-1981-2005.csv'%(dataDirDiscovery, plantData, models[m])

            if not os.path.isfile(fileNameRunoffRaw) or not os.path.isfile(fileNameRunoffHist):
                continue

            plantQsDataRaw = np.genfromtxt(fileNameRunoffRaw, delimiter=',', skip_header=0)
            plantQsDataHist = np.genfromtxt(fileNameRunoffHist, delimiter=',', skip_header=0)

            plantQsAnomData = np.full(plantQsDataRaw.shape, np.nan)
            plantQsAnomData[0, :] = plantQsDataRaw[0, :]
            plantQsAnomData[1, :] = plantQsDataRaw[1, :]
            plantQsAnomData[2, :] = plantQsDataRaw[2, :]
            
            plantQsPercentileData = np.full(plantQsDataRaw.shape, np.nan)
            plantQsPercentileData[0, :] = plantQsDataRaw[0, :]
            plantQsPercentileData[1, :] = plantQsDataRaw[1, :]
            plantQsPercentileData[2, :] = plantQsDataRaw[2, :]

            for p in range(3, plantQsDataRaw.shape[0]):

                if (p-3)%100 == 0:
                    print('plant %d of %d'%(p-3, plantQsDataRaw.shape[0]-3))

                if not os.path.isfile('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3)):
                    nn = np.where(~np.isnan(plantQsDataHist[p-3,:]))[0]
                    best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(plantQsDataHist[p-3,nn])
                    with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3), 'wb') as f:
                        dist = getattr(st, best_fit_name)
                        tmpQsPercentile = dist.cdf(plantQsDataHist[p-3,:], *best_fit_params)
                        distParams = {'name':best_fit_name,
                                      'params':best_fit_params, 
                                      'std':curQsStd}
                        pickle.dump(distParams, f)
                        print('cmip5 hist %d/%s: dist = %s, std = %.4f'%(p-3, models[m], str(dist), curQsStd))
                else:
                    with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3), 'rb') as f:
                        distParams = pickle.load(f)
                        curQsStd = distParams['std']
                        dist = getattr(st, distParams['name'])
                        tmpQsPercentile = dist.cdf(plantQsDataRaw[p-3, :], *distParams['params'])


                plantQsPercentileData[p, :] = tmpQsPercentile
                plantQsAnomData[p, :] = (plantQsDataRaw[p, :] - np.nanmean(plantQsDataRaw[p, :]))/curQsStd
            print('saving data to %s'%fileNameRunoffAnom)
            np.savetxt(fileNameRunoffAnom, plantQsAnomData, delimiter=',')
            np.savetxt(fileNameRunoffPercentile, plantQsPercentileData, delimiter=',')
            
            