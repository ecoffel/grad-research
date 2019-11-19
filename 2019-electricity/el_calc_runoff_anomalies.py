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
plantData = 'world'

# 'gmt-cmip5, decade-cmip5'
anomType = 'gmt-cmip5'

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

# models = ['bcc-csm1-1-m', 'canesm2', \
#               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
#               'gfdl-esm2g', 'gfdl-esm2m', \
#               'inmcm4', 'miroc5', 'miroc-esm', \
#               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']



if anomType == 'decade-cmip5':
    models = [sys.argv[1]]

    for m in range(len(models)):

        print('processing %s'%(models[m]))

        fileNameRunoffRaw = '%s/future-temps/world-pp-rcp85-runoff-raw-cmip5-%s-2080-2089.csv'%(dataDirDiscovery, models[m])
        fileNameRunoffAnom = '%s/future-temps/world-pp-rcp85-runoff-anom-cmip5-%s-2080-2089.csv'%(dataDirDiscovery, models[m])

        if not os.path.isfile(fileNameRunoffRaw):
            continue

        plantQsDataRaw = np.genfromtxt(fileNameRunoffRaw, delimiter=',', skip_header=0)

        plantQsAnomData = np.full(plantQsDataRaw.shape, np.nan)
        plantQsAnomData[0, :] = plantQsDataRaw[0, :]
        plantQsAnomData[1, :] = plantQsDataRaw[1, :]
        plantQsAnomData[2, :] = plantQsDataRaw[2, :]

#         for p in range(3, plantQsDataRaw.shape[0]):
        for p in range(3, plantQsDataRaw.shape[0]-3):

            if p%100 == 0:
                print('plant %d of %d'%(p, plantQsDataRaw.shape[0]))

#           with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3), 'rb') as f:
            with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p), 'rb') as f:
                distParams = pickle.load(f)
                curQsStd = distParams['std']

    #             plantQsAnomData[p, :] = (plantQsDataRaw[p, :] - np.nanmean(plantQsDataRaw[p, :]))/curQsStd
                plantQsAnomData[p+3, :] = (plantQsDataRaw[p+3, :] - np.nanmean(plantQsDataRaw[p+3, :]))/curQsStd
        print('saving data to %s'%fileNameRunoffAnom)
        np.savetxt(fileNameRunoffAnom, plantQsAnomData, delimiter=',')
    
    
elif anomType == 'gmt-cmip5':
    models = [sys.argv[1]]

    for w in range(1, 4+1):

        for m in range(len(models)):

            print('processing %s/%d'%(models[m], w))

            fileNameRunoffRaw = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-raw-cmip5-%s.csv'%(dataDirDiscovery, plantData, w, models[m])
            fileNameRunoffAnom = '%s/gmt-anomaly-temps/%s-pp-%ddeg-runoff-anom-best-dist-cmip5-%s.csv'%(dataDirDiscovery, plantData, w, models[m])
            fileNameRunoffHist = '%s/future-temps/%s-pp-hist-runoff-raw-cmip5-%s-1981-2005.csv'%(dataDirDiscovery, plantData, models[m])

            if not os.path.isfile(fileNameRunoffRaw) or not os.path.isfile(fileNameRunoffHist):
                continue

            plantQsDataRaw = np.genfromtxt(fileNameRunoffRaw, delimiter=',', skip_header=0)
            plantQsDataHist = np.genfromtxt(fileNameRunoffHist, delimiter=',', skip_header=0)

            plantQsAnomData = np.full(plantQsDataRaw.shape, np.nan)
            plantQsAnomData[0, :] = plantQsDataRaw[0, :]
            plantQsAnomData[1, :] = plantQsDataRaw[1, :]
            plantQsAnomData[2, :] = plantQsDataRaw[2, :]

            for p in range(3, plantQsDataRaw.shape[0]):

                if (p-3)%100 == 0:
                    print('plant %d of %d'%(p-3, plantQsDataRaw.shape[0]-3))

#                 if not os.path.isfile('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3)):
                nn = np.where(~np.isnan(plantQsDataHist[p-3,:]))[0]
                best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(plantQsDataHist[p-3,nn])
                with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsPercentile = dist.cdf(plantQsDataHist[p-3,nn], *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsStd}
                    pickle.dump(distParams, f)
                    print('cmip5 hist %d/%s: dist = %s, std = %.4f'%(p-3, models[m], str(dist), curQsStd))
#                 else:
#                     with open('%s/dist-fits/best-fit-%s-hist-cmip5-%s-plant-%d.dat'%(dataDirDiscovery, plantData, models[m], p-3), 'rb') as f:
#                         distParams = pickle.load(f)
#                         curQsStd = distParams['std']


                plantQsAnomData[p, :] = (plantQsDataRaw[p, :] - np.nanmean(plantQsDataRaw[p, :]))/curQsStd
            print('saving data to %s'%fileNameRunoffAnom)
            np.savetxt(fileNameRunoffAnom, plantQsAnomData, delimiter=',')
            
            