# -*- coding: utf-8 -*-
"""
Created on Mon Apr  1 09:47:36 2019

@author: Ethan
"""

import json
import numpy as np
import pandas as pd
import scipy.stats as st
import el_find_best_runoff_dist

import sys, os, pickle

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
#dataDir = 'e:/data/'
dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

plotFigs = False

def running_mean(x, N):
    cumsum = np.cumsum(np.insert(x, 0, 0)) 
    return (cumsum[N:] - cumsum[:-N]) / float(N)

def loadNukeData(dataDir):
    print('loading nuke eba...')
    
    usPlants = pd.read_csv('%s/cooling-data/us-plant-data.csv'%dataDir, delimiter=',', header=4)
    usPlants = usPlants[usPlants['Fuel Types']=='NUC']
    
    usPlantsCoolingData = pd.read_csv('%s/cooling-data/cooling_detail_2014.csv'%dataDir, delimiter=',', header=2, squeeze=True)
    coolingTypes = {'O':0, 'R':1, 'D':2}

    eba = []
    for line in open('%s/NUC_STATUS.txt' % dataDir, 'r'):
        if (len(eba)+1) % 100 == 0:
            print('loading line ', (len(eba)+1))
            
        curLine = json.loads(line)

        if 'data' in curLine.keys():
            
            curLine['data'].reverse()
            curLineNew = curLine.copy()
            
            del curLineNew['data']
            curLineNew['year'] = []
            curLineNew['month'] = []
            curLineNew['day'] = []
            curLineNew['cooling'] = np.nan
            curLineNew['age'] = np.nan
            curLineNew['data'] = []
            
            for datapt in curLine['data']:
                # restrict to before 2019
                if int(datapt[0][0:4]) > 2018:
                    continue
                
                curLineNew['year'].append(int(datapt[0][0:4]))
                curLineNew['month'].append(int(datapt[0][4:6]))
                curLineNew['day'].append(int(datapt[0][6:8]))
                if not datapt[1] == None:
                    curLineNew['data'].append(float(datapt[1]))
                else:
                    curLineNew['data'].append(np.nan)
            
            for p in range(usPlants.shape[0]):
                if np.array(list(usPlants['Plant Name']))[p] in curLine['name'] and \
                    'generator' not in curLine['name'] and 'percent' not in curLine['name'] and 'outage' in curLine['name']:

                    curPlant = usPlantsCoolingData[usPlantsCoolingData['Plant Code']==np.array(list(usPlants['Plant Code']))[p]]
                    curCool = np.array(list(curPlant['923 Cooling Type']))
                    nn = np.where((curCool != 'nan'))[0]
                    curLineNew['cooling'] = coolingTypes[curCool[nn][0][0]]
                    
                    curAge = np.nanmean(np.array(list(curPlant['Generator Inservice Year'])))
                    if np.isnan(curAge):
                        curAge = -1
                    elif curAge < 1979:
                        curAge = 1970
                    elif curAge < 1989:
                        curAge = 1980
                    elif curAge >= 1990:
                        curAge = 1990
                    
                    curLineNew['age'] = curAge
                    
            if np.isnan(curLineNew['cooling']):
                curLineNew['cooling'] = -1
                    
            curLineNew['year'] = np.array(curLineNew['year'])
            curLineNew['month'] = np.array(curLineNew['month'])
            curLineNew['day'] = np.array(curLineNew['day'])
            curLineNew['cooling'] = np.array(curLineNew['cooling'])
            curLineNew['age'] = np.array(curLineNew['age'])
            curLineNew['data'] = np.array(curLineNew['data'])
            
            eba.append(curLineNew)
    return eba

def loadWxData(eba, wxdata):
    # read tw time series
    fileName = ''
    
    if wxdata == 'cpc':
        fileName = '%s/script-data/nuke-tx-cpc.csv'%dataDir
    elif wxdata == 'era':
        fileName = '%s/script-data/nuke-tx-era.csv'%dataDir
    elif wxdata == 'ncep':
        fileName = '%s/script-data/nuke-tx-ncep.csv'%dataDir
    elif wxdata == 'all':
        fileName = ['%s/script-data/nuke-tx-cpc.csv'%dataDir, '%s/script-data/nuke-tx-era.csv'%dataDir, '%s/script-data/nuke-tx-ncep.csv'%dataDir]
        
    tx = []
    
    if wxdata == 'all':
        tx1 = np.genfromtxt(fileName[0], delimiter=',')
        tx2 = np.genfromtxt(fileName[1], delimiter=',')    
        tx3 = np.genfromtxt(fileName[2], delimiter=',')    
        
        # this takes average of all temp datasets but leaves 1st col with the plant id's there
        tx = tx1.copy()
        for i in range(0, tx1.shape[0]):
            for j in range(1, tx1.shape[1]):
                tx[i,j] = np.nanmean([tx1[i,j], tx2[i,j], tx3[i,j]])
    else:
        tx = np.genfromtxt(fileName, delimiter=',')
    
    smoothingLen = 30
    
    fileNameGldas = '%s/script-data/nuke-qs-gldas-all.csv'%dataDir
    qsGldas = np.genfromtxt(fileNameGldas, delimiter=',')
    qs = qsGldas[:,1:]
    
    fileNameGldasBasinWide = '%s/script-data/nuke-qs-gldas-basin-avg.csv'%dataDir
    qsGldasBasin = np.genfromtxt(fileNameGldasBasinWide, delimiter=',')
    qsGldasBasin = qsGldasBasin[:, 1:]
    
    fileNameNldas = '%s/script-data/nuke-qs-nldas-all.csv'%dataDir
    qsNldasRaw = np.genfromtxt(fileNameNldas, delimiter=',')
    qsNldasRaw = qsNldasRaw[:,1:]
    
    fileNameGrun = '%s/script-data/nuke-qs-grun.csv'%dataDir
    qsGrun = np.genfromtxt(fileNameGrun, delimiter=',')
    qsGrun = qsGrun[:, 1:]
    
    fileNameGrdc = '%s/script-data/nuke-qs-grdc.csv'%dataDir
    qsGrdcRaw = np.genfromtxt(fileNameGrdc, delimiter=',')
    qsGrdcRaw = qsGrdcRaw[:, 1:]
    
    # calc the running mean of the daily qrdc data
    smoothingLen = 30
    qsGrdc = np.full(qsGrdcRaw.shape, np.nan)
    for p in range(qsGrdcRaw.shape[0]):
        curq = running_mean(qsGrdcRaw[p,:], smoothingLen)
        buf = qsGrdc.shape[1]-len(curq)
        qsGrdc[p, buf:] = curq
    
    qsNldas = np.full(qsNldasRaw.shape, np.nan)
    for p in range(qsNldasRaw.shape[0]):
        curq = running_mean(qsNldasRaw[p,:], smoothingLen)
        buf = qsNldas.shape[1]-len(curq)
        qsNldas[p, buf:] = curq
    
    # these ids store the line numbers for plant level outage and capacity data in the EBA file
    ids = []
    matchedQs = np.full([tx.shape[0], tx.shape[1]-1], np.nan)
    matchedQsGldasBasin = np.full([tx.shape[0], tx.shape[1]-1], np.nan)
    matchedQsGrun = np.full([tx.shape[0], tx.shape[1]-1], np.nan)
    for i in range(tx.shape[0]):
        # current facility outage name
        outageId = int(tx[i,0])
        name = eba[outageId]['name']
        
        if 'for generator' in name: 
            continue
        
        nameParts = name.split(' at ')
        for n in range(len(eba)):
            if 'Nuclear generating capacity' in eba[n]['name'] and \
               not 'outage' in eba[n]['name'] and \
               not 'for generator' in eba[n]['name'] and \
               nameParts[1] in eba[n]['name']:
                   capacityId = n
                   ids.append([outageId, capacityId])
        
        # match monthly qs values to daily tx data
        qsInd = 0
        lastM = -1
        for m in range(len(eba[ids[i][0]]['month'])):
            curM = eba[ids[i][0]]['month'][m]
            if lastM == -1:
                lastM = curM
            elif curM != lastM:
                qsInd += 1
                lastM = curM
            matchedQs[i,m] = qs[i,qsInd]
            matchedQsGrun[i,m] = qsGrun[i,qsInd]
            matchedQsGldasBasin[i,m] = qsGldasBasin[i,qsInd]
    
    # smooth gldas data w/ running mean
    qsGldasSmooth = matchedQs
#     qsGldasSmooth = np.full(matchedQs.shape, np.nan)
#     for p in range(matchedQs.shape[0]):
#         curq = running_mean(matchedQs[p,:], smoothingLen)
#         buf = matchedQs.shape[1]-len(curq)
#         qsGldasSmooth[p, buf:] = curq
    
    qsGldasBasinSmooth = matchedQsGldasBasin
#     qsGldasBasinSmooth = np.full(matchedQsGldasBasin.shape, np.nan)
#     for p in range(matchedQsGldasBasin.shape[0]):
#         curq = running_mean(matchedQsGldasBasin[p,:], smoothingLen)
#         buf = matchedQsGldasBasin.shape[1]-len(curq)
#         qsGldasBasinSmooth[p, buf:] = curq
    
    return {'tx':np.array(tx), \
            'qs':qsGldasSmooth, 'qsNldas':qsNldas, 'qsGrdc':qsGrdc, 'qsGldasBasin':qsGldasBasinSmooth, 'qsGrun':matchedQsGrun, \
            'ids':np.array(ids)}

def accumulateNukeWxDataPlantLevel(datadir, eba, nukeMatchData):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    tx = nukeMatchData['tx']
    qs = nukeMatchData['qs']
    qsNldas = nukeMatchData['qsNldas']
    qsGldasBasin = nukeMatchData['qsGldasBasin']
    qsGrdc = nukeMatchData['qsGrdc']
    qsGrun = nukeMatchData['qsGrun']
    ids = nukeMatchData['ids']
    
    nukeLat = []
    nukeLon = []
    
    nukeCooling = []
    nukeAge = []
    
    plantCapacity = []
    plantPercCapacity = []
    plantTx = []
    plantTxSummer = []
    
    plantQsSummer = []
    plantQsGldasBasinSummer = []
    plantQsAnomSummer = []
    plantQsPercentileSummer = []
    
    plantQs = []
    plantQsAnom = []
    plantQsPercentile = []
    
    plantQsNldasSummer = []
    plantQsNldasAnomSummer = []
    plantQsNldasPercentileSummer = []
    
    plantQsNldas = []
    plantQsNldasAnom = []
    plantQsNldasPercentile = []
    
    plantQsGldasBasin = []
    plantQsGldasBasinAnom = []
    plantQsGldasBasinPercentile = []
    
    plantQsGldasBasinSummer = []
    plantQsGldasBasinAnomSummer = []
    plantQsGldasBasinPercentileSummer = []
    
    plantQsGrdcSummer = []
    plantQsGrdcAnomSummer = []
    plantQsGrdcPercentileSummer = []
    
    plantQsGrdc = []
    plantQsGrdcAnom = []
    plantQsGrdcPercentile = []
    
    plantQsGrunSummer = []
    plantQsGrunAnomSummer = []
    plantQsGrunPercentileSummer = []
    
    plantQsGrun = []
    plantQsGrunAnom = []
    plantQsGrunPercentile = []
    
    # data for stations with complete wx/pc data
    plantQsCompletePlants = []
    plantQsNldasCompletePlants = []
    plantQsGldasBasinCompletePlants = []
    plantQsGrdcCompletePlants = []
    plantQsGrunCompletePlants = []
    
    plantYears = []
    plantMonths = []
    plantDays = []
    
    plantIds = []
    
    for i in range(ids.shape[0]):
        out = np.array(eba[ids[i,0]]['data'])
        cap = np.array(eba[ids[i,1]]['data'])     
        
        if len(out) == 4383 and len(cap) == 4383:
            # calc the plant operating capacity (% of total normal capacity)
            plantPercCapacity.append(100*(1-(out/cap)))
            
            plantYears.append(eba[ids[i,0]]['year'])
            plantMonths.append(eba[ids[i,0]]['month'])
            plantDays.append(eba[ids[i,0]]['day'])
            
            plantQsCompletePlants.append(qs[i])
            plantQsNldasCompletePlants.append(qsNldas[i])
            plantQsGrdcCompletePlants.append(qsGrdc[i])
            plantQsGrunCompletePlants.append(qsGrun[i])
            plantQsGldasBasinCompletePlants.append(qsGldasBasin[i])
            
            nukeLat.append(eba[ids[i,0]]['lat'])
            nukeLon.append(eba[ids[i,0]]['lon'])
            
            nukeCooling.append(eba[ids[i,0]]['cooling'])
            nukeAge.append(eba[ids[i,0]]['age'])
            
            plantIds.append(i+1)
            
            # find total generating capacity for this plant
            for p in range(len(eba)):
                if 'Nuclear generating capacity' in eba[p]['name'] and \
                    eba[p]['lat'] == eba[ids[i,0]]['lat'] and \
                    eba[p]['lon'] == eba[ids[i,0]]['lon'] and \
                    not 'outage' in eba[p]['name'] and \
                    not 'generator' in eba[p]['name']:
                        plantCapacity.append(np.nanmax(eba[p]['data']))
                        
    plantCapacity = np.array(plantCapacity)  
    plantPercCapacity = np.array(plantPercCapacity)  
    plantYears = np.array(plantYears)
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    
    plantQsCompletePlants = np.array(plantQsCompletePlants)
    plantQsNldasCompletePlants = np.array(plantQsNldasCompletePlants)
    plantQsGldasBasinCompletePlants = np.array(plantQsGldasBasinCompletePlants)
    plantQsGrdcCompletePlants = np.array(plantQsGrdcCompletePlants)
    plantQsGrunCompletePlants = np.array(plantQsGrunCompletePlants)
    
    nukeLat = np.array(nukeLat)
    nukeLon = np.array(nukeLon)
    
    nukeCooling = np.array(nukeCooling)
    nukeAge = np.array(nukeAge)
    
    finalPlantPercCapacity = []
    finalPlantPercCapacitySummer = []
    
    for i in range(plantPercCapacity.shape[0]):
        
        curPC = plantPercCapacity[i]
        curTx = tx[i,1:]
        
        curQs = plantQsCompletePlants[i]
        curQsNldas = plantQsNldasCompletePlants[i]
        curQsGrdc = plantQsGrdcCompletePlants[i]
        curQsGrun = plantQsGrunCompletePlants[i]
        curQsGldasBasin = plantQsGldasBasinCompletePlants[i]
        
        # make sure that there is tx and pc data for every day
        if len(curPC) == len(curTx):
            
            # append without restricting to summer
            finalPlantPercCapacity.append(curPC)
            plantTx.append(curTx)
            
            tmpQsPercentile = np.zeros(curQs.size)
            tmpQsPercentile[tmpQsPercentile == 0] = np.nan
            
            tmpQsNldasPercentile = np.zeros(curQsNldas.size)
            tmpQsNldasPercentile[tmpQsNldasPercentile == 0] = np.nan
            
            tmpQsGldasBasinPercentile = np.zeros(curQs.size)
            tmpQsGldasBasinPercentile[tmpQsGldasBasinPercentile == 0] = np.nan
            
            tmpQsGrdcPercentile = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentile[tmpQsGrdcPercentile == 0] = np.nan
            
            tmpQsGrunPercentile = np.zeros(curQsGrun.size)
            tmpQsGrunPercentile[tmpQsGrunPercentile == 0] = np.nan
            
            
            # use best dist fit to calc anomalies and percentiles for nldas runoff data (all year)
            nn = np.where(~np.isnan(curQsNldas))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-nldas.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-nldas.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsNldasStd = distParams['std']
                    tmpQsNldasPercentile = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsNldasStd = el_find_best_runoff_dist.best_fit_distribution(curQsNldas[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-nldas.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsNldasPercentile = dist.cdf(curQsNldas, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsNldasStd,
                                  'cdf':tmpQsNldasPercentile}
                    pickle.dump(distParams, f)
                    print('nldas all year plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsNldasStd))
            
            
            # use best dist fit to calc anomalies and percentiles for gldas runoff data (all year)
            nn = np.where(~np.isnan(curQs))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsStd = distParams['std']
                    tmpQsPercentile = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsPercentile = dist.cdf(curQs, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsStd,
                                  'cdf':tmpQsPercentile}
                    pickle.dump(distParams, f)
                    print('gldas all year plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsStd))
            
            
            
            # use best dist fit to calc anomalies and percentiles for gldas basin avg runoff data
            nn = np.where(~np.isnan(curQsGldasBasin))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-basin.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGldasBasinStd = distParams['std']
                    tmpQsGldasBasinPercentile = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGldasBasinStd = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGldasBasinPercentile = dist.cdf(curQsGldasBasin, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGldasBasinStd,
                                  'cdf':tmpQsGldasBasinPercentile}
                    pickle.dump(distParams, f)
                    print('gldas all year basin plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGldasBasinStd))
                
            
            # use best dist fit to calc anomalies and percentiles for grdc runoff data
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grdc.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grdc.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGrdcStd = distParams['std']
                    tmpQsGrdcPercentile = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGrdcStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grdc.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGrdcStd,
                                  'cdf':tmpQsGrdcPercentile}
                    pickle.dump(distParams, f)
                    print('grdc all year plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGrdcStd))
            
            # use best dist fit to calc anomalies and percentiles for grun runoff data
            nn = np.where(~np.isnan(curQsGrun))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grun.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grun.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGrunStd = distParams['std']
                    tmpQsGrunPercentile = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGrunStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrun[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grun.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGrunPercentileSummer = dist.cdf(curQsGrun, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGrunStd,
                                  'cdf':tmpQsGrunPercentile}
                    pickle.dump(distParams, f)
                    print('grun all year plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGrunStd))
            
            
            plantQsNldas.append(curQsNldas)
            plantQsNldasAnom.append((curQsNldas-np.nanmean(curQsNldas))/curQsNldasStd)
            plantQsNldasPercentile.append(tmpQsNldasPercentile)
            
            plantQs.append(curQs)
            plantQsAnom.append((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentile.append(tmpQsPercentile)
            
            plantQsGldasBasin.append(curQsGldasBasin)
            plantQsGldasBasinAnom.append((curQs-np.nanmean(curQsGldasBasin))/curQsGldasBasinStd)
            plantQsGldasBasinPercentile.append(tmpQsGldasBasinPercentile)
            
            plantQsGrdc.append(curQsGrdc)
            plantQsGrdcAnom.append((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentile.append(tmpQsGrdcPercentile)
            
            plantQsGrun.append(curQsGrun)
            plantQsGrunAnom.append((curQsGrun-np.nanmean(curQsGrun))/curQsGrunStd)
            plantQsGrunPercentile.append(tmpQsGrunPercentile)
            
            # restrict to summer only
            curPC = curPC[summerInds]
            curTx = curTx[summerInds]
            curQs = curQs[summerInds]
            curQsNldas = curQsNldas[summerInds]            
            curQsGrdc = curQsGrdc[summerInds]
            curQsGrun = curQsGrun[summerInds]
            curQsGldasBasin = curQsGldasBasin[summerInds]
            
            nn = np.where((~np.isnan(curPC)) & (~np.isnan(curTx)))[0]
            
            # restrict to summer days with both pc and tx data
            curPC = curPC[nn]
            curTx = curTx[nn]
            curQs = curQs[nn]
            curQsNldas = curQsNldas[nn]
            curQsGrdc = curQsGrdc[nn]
            curQsGrun = curQsGrun[nn]
            curQsGldasBasin = curQsGldasBasin[nn]
            
            tmpQsPercentileSummer = np.zeros(curQs.size)
            tmpQsPercentileSummer[tmpQsPercentileSummer == 0] = np.nan
            
            tmpQsNldasPercentileSummer = np.zeros(curQsNldas.size)
            tmpQsNldasPercentileSummer[tmpQsNldasPercentileSummer == 0] = np.nan
            
            tmpQsGldasBasinPercentileSummer = np.zeros(curQsGldasBasin.size)
            tmpQsGldasBasinPercentileSummer[tmpQsGldasBasinPercentileSummer == 0] = np.nan
            
            tmpQsGrdcPercentileSummer = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentileSummer[tmpQsGrdcPercentileSummer == 0] = np.nan
            
            tmpQsGrunPercentileSummer = np.zeros(curQsGrun.size)
            tmpQsGrunPercentileSummer[tmpQsGrunPercentileSummer == 0] = np.nan
            

            # use best dist fit to calc anomalies and percentiles for nldas summer runoff data
            nn = np.where(~np.isnan(curQsNldas))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-nldas-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-nldas-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsNldasStd = distParams['std']
                    tmpQsNldasPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsNldasStd = el_find_best_runoff_dist.best_fit_distribution(curQsNldas[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-nldas-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsNldasPercentileSummer = dist.cdf(curQsNldas, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsNldasStd,
                                  'cdf':tmpQsNldasPercentileSummer}
                    pickle.dump(distParams, f)
                    print('nldas summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsNldasStd))
            
            
            # use best dist fit to calc anomalies and percentiles for gldas summer runoff data
            nn = np.where(~np.isnan(curQs))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsStd = distParams['std']
                    tmpQsPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsPercentileSummer = dist.cdf(curQs, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsStd,
                                  'cdf':tmpQsPercentileSummer}
                    pickle.dump(distParams, f)
                    print('gldas summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsStd))
            
            
            
            # use best dist fit to calc anomalies and percentiles for gldas basin avg summer runoff data
            nn = np.where(~np.isnan(curQsGldasBasin))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGldasBasinStd = distParams['std']
                    tmpQsGldasBasinPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGldasBasinStd = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGldasBasinPercentileSummer = dist.cdf(curQsGldasBasin, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGldasBasinStd,
                                  'cdf':tmpQsGldasBasinPercentileSummer}
                    pickle.dump(distParams, f)
                    print('gldas summer basin plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGldasBasinStd))
                
            
            # use best dist fit to calc anomalies and percentiles for grdc summer runoff data
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grdc-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGrdcStd = distParams['std']
                    tmpQsGrdcPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGrdcStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGrdcStd,
                                  'cdf':tmpQsGrdcPercentileSummer}
                    pickle.dump(distParams, f)
                    print('grdc summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGrdcStd))
            
            # use best dist fit to calc anomalies and percentiles for grun summer runoff data
            nn = np.where(~np.isnan(curQsGrun))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grun-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grun-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGrunStd = distParams['std']
                    tmpQsGrunPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGrunStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrun[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grun-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGrunPercentileSummer = dist.cdf(curQsGrun, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGrunStd,
                                  'cdf':tmpQsGrunPercentileSummer}
                    pickle.dump(distParams, f)
                    print('grun summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGrunStd))
            
            
            # now aggregate summer-restricted variables for this plant
            finalPlantPercCapacitySummer.append(curPC)
            plantTxSummer.append(curTx)
            plantQsSummer.append(curQs)
            plantQsAnomSummer.append((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentileSummer.append(tmpQsPercentileSummer)
            
            plantQsNldasSummer.append(curQsNldas)
            plantQsNldasAnomSummer.append((curQsNldas-np.nanmean(curQsNldas))/curQsNldasStd)
            plantQsNldasPercentileSummer.append(tmpQsNldasPercentileSummer)
            
            plantQsGldasBasinSummer.append(curQsGldasBasin)
            plantQsGldasBasinAnomSummer.append((curQsGldasBasin-np.nanmean(curQsGldasBasin))/curQsGldasBasinStd)
            plantQsGldasBasinPercentileSummer.append(tmpQsGldasBasinPercentileSummer)
            
            plantQsGrdcSummer.append(curQsGrdc)
            plantQsGrdcAnomSummer.append((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentileSummer.append(tmpQsGrdcPercentileSummer)
            
            plantQsGrunSummer.append(curQsGrun)
            plantQsGrunAnomSummer.append((curQsGrun-np.nanmean(curQsGrun))/curQsGrunStd)
            plantQsGrunPercentileSummer.append(tmpQsGrunPercentileSummer)
            
            
    plantTx = np.array(plantTx)
    plantTxSummer = np.array(plantTxSummer)
    
    plantQs = np.array(plantQs)
    plantQsAnom = np.array(plantQsAnom)
    plantQsPercentile = np.array(plantQsPercentile)
    plantQsSummer = np.array(plantQsSummer)
    plantQsAnomSummer = np.array(plantQsAnomSummer)
    plantQsPercentileSummer = np.array(plantQsPercentileSummer)
    
    plantQsNldas = np.array(plantQsNldas)
    plantQsNldasAnom = np.array(plantQsNldasAnom)
    plantQsNldasPercentile = np.array(plantQsNldasPercentile)
    plantQsNldasSummer = np.array(plantQsNldasSummer)
    plantQsNldasAnomSummer = np.array(plantQsNldasAnomSummer)
    plantQsNldasPercentileSummer = np.array(plantQsNldasPercentileSummer)
    
    plantQsGldasBasinSummer = np.array(plantQsGldasBasinSummer)
    plantQsGldasBasinAnomSummer = np.array(plantQsGldasBasinAnomSummer)
    plantQsGldasBasinPercentileSummer = np.array(plantQsGldasBasinPercentileSummer)
    
    plantQsGrdc = np.array(plantQsGrdc)
    plantQsGrdcAnom = np.array(plantQsGrdcAnom)
    plantQsGrdcPercentile = np.array(plantQsGrdcPercentile)
    
    plantQsGrdcSummer = np.array(plantQsGrdcSummer)
    plantQsGrdcAnomSummer = np.array(plantQsGrdcAnomSummer)
    plantQsGrdcPercentileSummer = np.array(plantQsGrdcPercentileSummer)
    
    plantQsGrun = np.array(plantQsGrun)
    plantQsGrunAnom = np.array(plantQsGrunAnom)
    plantQsGrunPercentile = np.array(plantQsGrunPercentile)
    
    plantQsGrunSummer = np.array(plantQsGrunSummer)
    plantQsGrunAnomSummer = np.array(plantQsGrunAnomSummer)
    plantQsGrunPercentileSummer = np.array(plantQsGrunPercentileSummer)
    
    plantQsAnom[plantQsAnom < -5] = np.nan
    plantQsAnom[plantQsAnom > 5] = np.nan
    plantQsAnomSummer[plantQsAnomSummer < -5] = np.nan
    plantQsAnomSummer[plantQsAnomSummer > 5] = np.nan
    plantQsNldasAnom[plantQsNldasAnom < -5] = np.nan
    plantQsNldasAnom[plantQsNldasAnom > 5] = np.nan
    plantQsNldasAnomSummer[plantQsNldasAnomSummer < -5] = np.nan
    plantQsNldasAnomSummer[plantQsNldasAnomSummer > 5] = np.nan
    plantQsGrdcAnom[plantQsGrdcAnom < -5] = np.nan
    plantQsGrdcAnom[plantQsGrdcAnom > 5] = np.nan
    plantQsGrdcAnomSummer[plantQsGrdcAnomSummer < -5] = np.nan
    plantQsGrdcAnomSummer[plantQsGrdcAnomSummer > 5] = np.nan
    plantQsGrunAnom[plantQsGrunAnom < -5] = np.nan
    plantQsGrunAnom[plantQsGrunAnom > 5] = np.nan
    plantQsGrunAnomSummer[plantQsGrunAnomSummer < -5] = np.nan
    plantQsGrunAnomSummer[plantQsGrunAnomSummer > 5] = np.nan
    
    plantIds = np.array(plantIds)
    nukeCooling = np.array(nukeCooling)
    nukeAge = np.array(nukeAge)
    
    finalPlantPercCapacity = np.array(finalPlantPercCapacity)
    finalPlantPercCapacitySummer = np.array(finalPlantPercCapacitySummer)
    
    d = {'txSummer': plantTxSummer, 'tx':plantTx, \
         'qsSummer':plantQsSummer, 'qsAnomSummer':plantQsAnomSummer, 'qsPercentileSummer':plantQsPercentileSummer, \
         'qsNldasSummer':plantQsNldasSummer, 'qsNldasAnomSummer':plantQsNldasAnomSummer, 'qsNldasPercentileSummer':plantQsNldasPercentileSummer, \
         'qsGldasBasinSummer':plantQsGldasBasinSummer, 'qsGldasBasinAnomSummer':plantQsGldasBasinAnomSummer, 'qsGldasBasinPercentileSummer':plantQsGldasBasinPercentileSummer, \
         'qs':plantQs, 'qsAnom':plantQsAnom, 'qsPercentile':plantQsPercentile, \
         'qsNldas':plantQsNldas, 'qsNldasAnom':plantQsNldasAnom, 'qsNldasPercentile':plantQsNldasPercentile, \
         'qsGrdcSummer':plantQsGrdcSummer, 'qsGrdcAnomSummer':plantQsGrdcAnomSummer, 'qsGrdcPercentileSummer':plantQsGrdcPercentileSummer, \
         'qsGrdc':plantQsGrdc, 'qsGrdcAnom':plantQsGrdcAnom, 'qsGrdcPercentile':plantQsGrdcPercentile, \
         'qsGrun':plantQsGrun, 'qsGrunAnom':plantQsGrunAnom, 'qsGrunPercentile':plantQsGrunPercentile, \
         'capacitySummer':finalPlantPercCapacitySummer, 'capacity':finalPlantPercCapacity, \
         'normalCapacity':plantCapacity, \
         'plantIds':plantIds, 'summerInds':summerInds, \
         'plantLats':nukeLat, 'plantLons':nukeLon, \
         'plantCooling':nukeCooling, 'plantFuel':[0]*len(nukeCooling), 'plantAge':nukeAge, \
         'plantYearsAll':plantYears, 'plantMonthsAll':plantMonths, 'plantDaysAll':plantDays}
    return d






def accumulateNukeWxData(datadir, eba, nukeMatchData):
    
    tx = nukeMatchData['tx']
    ids = nukeMatchData['ids']
    qs = nukeMatchData['qs']
    qsNldas = nukeMatchData['qsNldas']
    qsGldasBasin = nukeMatchData['qsGldasBasin']
    qsGrdc = nukeMatchData['qsGrdc']
    qsGrun = nukeMatchData['qsGrun']
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    percCapacity = []
    totalOut = []
    totalCap = []
    
    # unique identifiers for plants
    plantIds = []
    plantCooling = []
    plantAge = []
    plantYears = []
    plantMonths = []
    plantDays = []
    plantQs = []
    plantQsNldas = []
    plantQsGldasBasin = []
    plantQsGrdc = []
    plantQsGrun = []
    
    for i in range(ids.shape[0]):
        out = np.array(eba[ids[i,0]]['data'])
        cap = np.array(eba[ids[i,1]]['data'])     
        
        if len(out) == 4383 and len(cap) == 4383:
            
            # calc the plant operating capacity (% of total normal capacity)
            percCapacity.append(100*(1-(out/cap)))
            
            plantIds.append([i+1]*len(out))
            plantCooling.append([eba[ids[i,0]]['cooling']]*len(out))
            plantAge.append([eba[ids[i,0]]['age']]*len(out))
            plantYears.append(eba[ids[i,0]]['year'])
            plantMonths.append(eba[ids[i,0]]['month'])
            plantDays.append(eba[ids[i,0]]['day'])
            
            plantQs.append(qs[i])
            plantQsNldas.append(qsNldas[i])
            plantQsGldasBasin.append(qsGldasBasin[i])
            plantQsGrdc.append(qsGrdc[i])
            plantQsGrun.append(qsGrun[i])
            
            if len(totalOut) == 0:
                totalOut = out
                totalCap = cap
            else:
                totalOut += out
                totalCap += cap
    
    percCapacity = np.array(percCapacity)  
    plantIds = np.array(plantIds)
    plantCooling = np.array(plantCooling)
    plantAge = np.array(plantAge)
    plantYears = np.array(plantYears)
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    plantQs = np.array(plantQs)
    plantQsNldas = np.array(plantQsNldas)
    plantQsGldasBasin = np.array(plantQsGldasBasin)
    plantQsGrdc = np.array(plantQsGrdc)
    plantQsGrun = np.array(plantQsGrun)
    
    outageBool = []
    
    plantQsTotal = []
    plantQsAnomTotal = []
    plantQsPercentileTotal = []
    
    plantQsNldasTotal = []
    plantQsNldasAnomTotal = []
    plantQsNldasPercentileTotal = []
                          
    plantQsGldasBasinTotal = []
    plantQsGldasBasinAnomTotal = []
    plantQsGldasBasinPercentileTotal = []
                          
    plantQsGrdcTotal = []
    plantQsGrdcAnomTotal = []
    plantQsGrdcPercentileTotal = []
    
    plantQsGrunTotal = []
    plantQsGrunAnomTotal = []
    plantQsGrunPercentileTotal = []
   
    plantTxTotal = []
    plantCapTotal = []
    plantIdsAcc = []
    plantCoolingAcc = []
    plantAgeAcc = []
    plantMeanTempsAcc = []
    yearsAcc = []
    monthsAcc = []
    daysAcc = []
    
    # loop over all plants
    for i in range(percCapacity.shape[0]):
        
        plantCap = percCapacity[i]
        plantTx = tx[i,1:]
        curQs = plantQs[i]
        curQsNldas = plantQsNldas[i]
        curQsGldasBasin = plantQsGldasBasin[i]
        curQsGrdc = plantQsGrdc[i]
        curQsGrun = plantQsGrun[i]
        
        if len(plantTx)==len(plantCap):
            plantCap = plantCap[summerInds]
            plantTx = plantTx[summerInds]
            curQs = curQs[summerInds]
            curQsNldas = curQsNldas[summerInds]
            curQsGldasBasin = curQsGldasBasin[summerInds]
            curQsGrdc = curQsGrdc[summerInds]
            curQsGrun = curQsGrun[summerInds]
            
            nn = np.where((~np.isnan(plantCap)) & (~np.isnan(plantTx)))[0]
            
            curQs = curQs[nn]
            curQsNldas = curQsNldas[nn]
            curQsGldasBasin = curQsGldasBasin[nn]
            curQsGrdc = curQsGrdc[nn]
            curQsGrun = curQsGrun[nn]
            plantCap = plantCap[nn]
            plantTx = plantTx[nn]
            
            # use best dist fit to calc anomalies and percentiles for nldas summer runoff data
            nn = np.where(~np.isnan(curQsNldas))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-nldas-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-nldas-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsNldasStd = distParams['std']
                    tmpQsNldasPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsNldasStd = el_find_best_runoff_dist.best_fit_distribution(curQsNldas[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-nldas-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsNldasPercentileSummer = dist.cdf(curQsNldas, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsNldasStd,
                                  'cdf':tmpQsNldasPercentileSummer}
                    pickle.dump(distParams, f)
                    print('nldas summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsNldasStd))
                    
            
            # use best dist fit to calc anomalies and percentiles for gldas summer runoff data
            nn = np.where(~np.isnan(curQs))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsStd = distParams['std']
                    tmpQsPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsPercentileSummer = dist.cdf(curQs, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsStd,
                                  'cdf':tmpQsPercentileSummer}
                    pickle.dump(distParams, f)
                    print('gldas summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsStd))
            
            
            
            # use best dist fit to calc anomalies and percentiles for gldas basin avg summer runoff data
            nn = np.where(~np.isnan(curQsGldasBasin))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGldasBasinStd = distParams['std']
                    tmpQsGldasBasinPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGldasBasinStd = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGldasBasinPercentileSummer = dist.cdf(curQsGldasBasin, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGldasBasinStd,
                                  'cdf':tmpQsGldasBasinPercentileSummer}
                    pickle.dump(distParams, f)
                    print('gldas summer basin plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGldasBasinStd))
                
            
            # use best dist fit to calc anomalies and percentiles for grdc summer runoff data
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grdc-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGrdcStd = distParams['std']
                    tmpQsGrdcPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGrdcStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGrdcStd,
                                  'cdf':tmpQsGrdcPercentileSummer}
                    pickle.dump(distParams, f)
                    print('grdc summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGrdcStd))
            
            # use best dist fit to calc anomalies and percentiles for grun summer runoff data
            nn = np.where(~np.isnan(curQsGrun))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grun-summer.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grun-summer.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    curQsGrunStd = distParams['std']
                    tmpQsGrunPercentileSummer = distParams['cdf']
            else:
                best_fit_name, best_fit_params, curQsGrunStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrun[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grun-summer.dat'%(datadir, i), 'wb') as f:
                    dist = getattr(st, best_fit_name)
                    tmpQsGrunPercentileSummer = dist.cdf(curQsGrun, *best_fit_params)
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params, 
                                  'std':curQsGrunStd,
                                  'cdf':tmpQsGrunPercentileSummer}
                    pickle.dump(distParams, f)
                    print('grun summer plant %d: dist = %s, std = %.4f'%(i, str(dist), curQsGrunStd))
            
            plantQsNldasTotal.extend(curQsNldas)
            plantQsNldasAnomTotal.extend((curQsNldas-np.nanmean(curQsNldas))/curQsNldasStd)
            plantQsNldasPercentileTotal.extend(tmpQsNldasPercentileSummer)
            
            plantQsTotal.extend(curQs)
            plantQsAnomTotal.extend((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentileTotal.extend(tmpQsPercentileSummer)
            
            plantQsGldasBasinTotal.extend(curQsGldasBasin)
            plantQsGldasBasinAnomTotal.extend((curQs-np.nanmean(curQsGldasBasin))/curQsGldasBasinStd)
            plantQsGldasBasinPercentileTotal.extend(tmpQsGldasBasinPercentileSummer)
            
            plantQsGrdcTotal.extend(curQsGrdc)
            plantQsGrdcAnomTotal.extend((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentileTotal.extend(tmpQsGrdcPercentileSummer)
            
            plantQsGrunTotal.extend(curQsGrun)
            plantQsGrunAnomTotal.extend((curQsGrun-np.nanmean(curQsGrun))/curQsGrunStd)
            plantQsGrunPercentileTotal.extend(tmpQsGrunPercentileSummer)
            
            plantCapTotal.extend(plantCap)
            plantTxTotal.extend(plantTx)
            
            plantIdsAcc.extend(plantIds[i,summerInds])
            plantCoolingAcc.extend(plantCooling[i,summerInds])
            plantAgeAcc.extend(plantAge[i,summerInds])
            plantMeanTempsAcc.extend([np.nanmean(plantTx)]*len(plantTx))
            yearsAcc.extend(plantYears[i,summerInds])
            monthsAcc.extend(plantMonths[i,summerInds])
            daysAcc.extend(plantDays[i,summerInds])            
            
            for k in range(len(plantCap)):
                if plantCap[k] < 100:
                    outageBool.append(1)
                else:
                    outageBool.append(0)
    
    plantQsTotal = np.array(plantQsTotal)
    plantQsAnomTotal = np.array(plantQsAnomTotal)
    
    plantQsNldasTotal = np.array(plantQsNldasTotal)
    plantQsNldasAnomTotal = np.array(plantQsNldasAnomTotal)
    
    plantQsGldasBasinTotal = np.array(plantQsGldasBasinTotal)
    plantQsGldasBasinAnomTotal = np.array(plantQsGldasBasinAnomTotal)
    
    plantQsGrdcTotal = np.array(plantQsGrdcTotal)
    plantQsGrdcAnomTotal = np.array(plantQsGrdcAnomTotal)
    
    plantQsGrunTotal = np.array(plantQsGrunTotal)
    plantQsGrunAnomTotal = np.array(plantQsGrunAnomTotal)
    
    plantQsAnomTotal[plantQsAnomTotal < -5] = np.nan
    plantQsAnomTotal[plantQsAnomTotal > 5] = np.nan
    plantQsNldasAnomTotal[plantQsNldasAnomTotal < -5] = np.nan
    plantQsNldasAnomTotal[plantQsNldasAnomTotal > 5] = np.nan
    plantQsGldasBasinAnomTotal[plantQsGldasBasinAnomTotal < -5] = np.nan
    plantQsGldasBasinAnomTotal[plantQsGldasBasinAnomTotal > 5] = np.nan
    plantQsGrdcAnomTotal[plantQsGrdcAnomTotal < -5] = np.nan
    plantQsGrdcAnomTotal[plantQsGrdcAnomTotal > 5] = np.nan
    plantQsGrunAnomTotal[plantQsGrunAnomTotal < -5] = np.nan
    plantQsGrunAnomTotal[plantQsGrunAnomTotal > 5] = np.nan
    
    plantTxTotal = np.array(plantTxTotal)
    plantCapTotal = np.array(plantCapTotal)
    plantIdsAcc = np.array(plantIdsAcc)
    plantCoolingAcc = np.array(plantCoolingAcc)
    plantAgeAcc = np.array(plantAgeAcc)
    yearsAcc = np.array(yearsAcc)
    monthsAcc = np.array(monthsAcc)
    daysAcc = np.array(daysAcc)
    
    d = {'txSummer':plantTxTotal, \
         'qsSummer':plantQsTotal, 'qsAnomSummer':plantQsAnomTotal, 'qsPercentileSummer':plantQsPercentileTotal, \
         'qsNldasSummer':plantQsNldasTotal, 'qsNldasAnomSummer':plantQsNldasAnomTotal, 'qsNldasPercentileSummer':plantQsNldasPercentileTotal, \
         'qsGldasBasinSummer':plantQsGldasBasinTotal, 'qsGldasBasinAnomSummer':plantQsGldasBasinAnomTotal, 'qsGldasBasinPercentileSummer':plantQsGldasBasinPercentileTotal, \
         'qsGrdcSummer':plantQsGrdcTotal, 'qsGrdcAnomSummer':plantQsGrdcAnomTotal, 'qsGrdcPercentileSummer':plantQsGrdcPercentileTotal, \
         'qsGrunSummer':plantQsGrunTotal, 'qsGrunAnomSummer':plantQsGrunAnomTotal, 'qsGrunPercentileSummer':plantQsGrunPercentileTotal, \
         'capacitySummer':plantCapTotal, 'percCapacity':percCapacity, \
         'summerInds':summerInds, 'outagesBoolSummer':outageBool, 'plantIds':plantIdsAcc, \
         'plantCooling':plantCoolingAcc, 'plantFuel':[0]*len(plantCoolingAcc), 'plantAge':plantAgeAcc, \
         'plantMeanTemps':plantMeanTempsAcc, 'plantYearsAll':plantYears, 'plantMonthsAll':plantMonths, \
         'plantYearsSummer':yearsAcc, 'plantMonthsSummer':monthsAcc, 'plantDaysSummer':daysAcc}
    return d


