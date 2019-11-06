# -*- coding: utf-8 -*-
"""
Created on Mon Apr  1 09:47:36 2019

@author: Ethan
"""

import json
import numpy as np
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
                    
            curLineNew['year'] = np.array(curLineNew['year'])
            curLineNew['month'] = np.array(curLineNew['month'])
            curLineNew['day'] = np.array(curLineNew['day'])
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
    qsGldasBasinAvg = np.genfromtxt(fileNameGldasBasinWide, delimiter=',')
    qsGldasBasinAvg = qsGldasBasinAvg[:, 1:]
    
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
    
    # these ids store the line numbers for plant level outage and capacity data in the EBA file
    ids = []
    matchedQs = np.full([tx.shape[0], tx.shape[1]-1], np.nan)
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
    
    # smooth gldas data w/ running mean
    qsGldasSmooth = np.full(matchedQs.shape, np.nan)
    for p in range(matchedQs.shape[0]):
        curq = running_mean(matchedQs[p,:], smoothingLen)
        buf = matchedQs.shape[1]-len(curq)
        qsGldasSmooth[p, buf:] = curq
    
    return {'tx':np.array(tx), \
            'qs':qsGldasSmooth, 'qsGrdc':qsGrdc, 'qsGldasBasin':qsGldasBasinAvg, \
            'ids':np.array(ids)}

def accumulateNukeWxDataPlantLevel(datadir, eba, nukeMatchData):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    tx = nukeMatchData['tx']
    qs = nukeMatchData['qs']
    qsGldasBasin = nukeMatchData['qsGldasBasin']
    qsGrdc = nukeMatchData['qsGrdc']
    ids = nukeMatchData['ids']
    
    nukeLat = []
    nukeLon = []
    
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
    
    # data for stations with complete wx/pc data
    plantQsCompletePlants = []
    plantQsGldasBasinCompletePlants = []
    plantQsGrdcCompletePlants = []
    
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
            plantQsGrdcCompletePlants.append(qsGrdc[i])
            plantQsGldasBasinCompletePlants.append(qsGldasBasin[i])
            
            nukeLat.append(eba[ids[i,0]]['lat'])
            nukeLon.append(eba[ids[i,0]]['lon'])
            
            plantIds.append(i)
            
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
    plantQsGldasBasinCompletePlants = np.array(plantQsGldasBasinCompletePlants)
    plantQsGrdcCompletePlants = np.array(plantQsGrdcCompletePlants)
    
    nukeLat = np.array(nukeLat)
    nukeLon = np.array(nukeLon)
    
    finalPlantPercCapacity = []
    finalPlantPercCapacitySummer = []
    
    for i in range(plantPercCapacity.shape[0]):
        
        curPC = plantPercCapacity[i]
        curTx = tx[i,1:]
        
        curQs = plantQsCompletePlants[i]
        curQsGrdc = plantQsGrdcCompletePlants[i]
        curQsGldasBasin = plantQsGldasBasinCompletePlants[i]
        
        # make sure that there is tx and pc data for every day
        if len(curPC) == len(curTx):
            
            # append without restricting to summer
            finalPlantPercCapacity.append(curPC)
            plantTx.append(curTx)
            
            tmpQsPercentile = np.zeros(curQs.size)
            tmpQsPercentile[tmpQsPercentile == 0] = np.nan
            
            tmpQsGldasBasinPercentile = np.zeros(curQs.size)
            tmpQsGldasBasinPercentile[tmpQsGldasBasinPercentile == 0] = np.nan
            
            tmpQsGrdcPercentile = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentile[tmpQsGrdcPercentile == 0] = np.nan
            
            
            # use best dist fit to calc anomalies and percentiles for gldas runoff data (all year)
            nn = np.where(~np.isnan(curQs))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-plant-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-plant-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for gldas plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-plant-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQs[nn])
                curQsStd = dist.std(*args)
                tmpQsPercentile = dist.cdf(curQs, *args)
            else:
                curQsStd = np.nan
            
            # use best dist fit to calc anomalies and percentiles for gldas basin avg runoff data (all year)
            nn = np.where(~np.isnan(curQsGldasBasin))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-basin-plant-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-plant-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for gldas basin plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-plant-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQsGldasBasin[nn])
                curQsGldasBasinStd = dist.std(*args)
                tmpQsGldasBasinPercentile = dist.cdf(curQsGldasBasin, *args)
            else:
                curQsGldasBasinStd = np.nan
                          
                          
            # use best dist fit to calc anomalies and percentiles for grdc runoff data (all year)
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grdc-plant-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-plant-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for grdc plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-plant-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQsGrdc[nn])
                curQsGrdcStd = dist.std(*args)
                tmpQsGrdcPercentile = dist.cdf(curQsGrdc, *args)
            else:
                curQsGrdcStd = np.nan
            
            
            plantQs.append(curQs)
            plantQsAnom.append((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentile.append(tmpQsPercentile)
            
            plantQsGldasBasin.append(curQsGldasBasin)
            plantQsGldasBasinAnom.append((curQs-np.nanmean(curQsGldasBasin))/curQsGldasBasinStd)
            plantQsGldasBasinPercentile.append(tmpQsGldasBasinPercentile)
            
            plantQsGrdc.append(curQsGrdc)
            plantQsGrdcAnom.append((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentile.append(tmpQsGrdcPercentile)
            
            # restrict to summer only
            curPC = curPC[summerInds]
            curTx = curTx[summerInds]
            curQs = curQs[summerInds]
            curQsGrdc = curQsGrdc[summerInds]
            curQsGldasBasin = curQsGldasBasin[summerInds]
            
            nn = np.where((~np.isnan(curPC)) & (~np.isnan(curTx)))[0]
            
            # restrict to summer days with both pc and tx data
            curPC = curPC[nn]
            curTx = curTx[nn]
            curQs = curQs[nn]
            curQsGrdc = curQsGrdc[nn]
            curQsGldasBasin = curQsGldasBasin[nn]
            
            tmpQsPercentileSummer = np.zeros(curQs.size)
            tmpQsPercentileSummer[tmpQsPercentileSummer == 0] = np.nan
            
            tmpQsGldasBasinPercentileSummer = np.zeros(curQsGldasBasin.size)
            tmpQsGldasBasinPercentileSummer[tmpQsGldasBasinPercentileSummer == 0] = np.nan
            
            tmpQsGrdcPercentileSummer = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentileSummer[tmpQsGrdcPercentileSummer == 0] = np.nan
            
            # use best dist fit to calc anomalies and percentiles for gldas summer runoff data
            nn = np.where(~np.isnan(curQs))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-summer-plant-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer-plant-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for gldas plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer-plant-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQs[nn])
                curQsStd = dist.std(*args)
                tmpQsPercentileSummer = dist.cdf(curQs, *args)
            else:
                curQsStd = np.nan
            
            # use best dist fit to calc anomalies and percentiles for gldas basin avg summer runoff data
            nn = np.where(~np.isnan(curQsGldasBasin))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer-plant-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer-plant-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for gldas basin plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer-plant-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQsGldasBasin[nn])
                curQsGldasBasinStd = dist.std(*args)
                tmpQsGldasBasinPercentileSummer = dist.cdf(curQsGldasBasin, *args)
            else:
                curQsGldasBasinStd = np.nan
                          
                          
            # use best dist fit to calc anomalies and percentiles for grdc summer runoff data
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grdc-summer-plant-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer-plant-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for grdc plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer-plant-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQsGrdc[nn])
                curQsGrdcStd = dist.std(*args)
                tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *args)
            else:
                curQsGrdcStd = np.nan
            
            
            # now aggregate summer-restricted variables for this plant
            finalPlantPercCapacitySummer.append(curPC)
            plantTxSummer.append(curTx)
            plantQsSummer.append(curQs)
            plantQsAnomSummer.append((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentileSummer.append(tmpQsPercentileSummer)
            
            plantQsGldasBasinSummer.append(curQsGldasBasin)
            plantQsGldasBasinAnomSummer.append((curQsGldasBasin-np.nanmean(curQsGldasBasin))/curQsGldasBasinStd)
            plantQsGldasBasinPercentileSummer.append(tmpQsGldasBasinPercentileSummer)
            
            plantQsGrdcSummer.append(curQsGrdc)
            plantQsGrdcAnomSummer.append((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentileSummer.append(tmpQsGrdcPercentileSummer)
            
            
    plantTx = np.array(plantTx)
    plantTxSummer = np.array(plantTxSummer)
    
    plantQs = np.array(plantQs)
    plantQsAnom = np.array(plantQsAnom)
    plantQsPercentile = np.array(plantQsPercentile)
    plantQsSummer = np.array(plantQsSummer)
    plantQsAnomSummer = np.array(plantQsAnomSummer)
    plantQsPercentileSummer = np.array(plantQsPercentileSummer)
    
    plantQsGldasBasinSummer = np.array(plantQsGldasBasinSummer)
    plantQsGldasBasinAnomSummer = np.array(plantQsGldasBasinAnomSummer)
    plantQsGldasBasinPercentileSummer = np.array(plantQsGldasBasinPercentileSummer)
    
    plantQsGrdc = np.array(plantQsGrdc)
    plantQsGrdcAnom = np.array(plantQsGrdcAnom)
    plantQsGrdcPercentile = np.array(plantQsGrdcPercentile)
    
    plantQsGrdcSummer = np.array(plantQsGrdcSummer)
    plantQsGrdcAnomSummer = np.array(plantQsGrdcAnomSummer)
    plantQsGrdcPercentileSummer = np.array(plantQsGrdcPercentileSummer)
    
    plantQsAnom[plantQsAnom < -5] = np.nan
    plantQsAnom[plantQsAnom > 5] = np.nan
    plantQsAnomSummer[plantQsAnomSummer < -5] = np.nan
    plantQsAnomSummer[plantQsAnomSummer > 5] = np.nan
    plantQsGrdcAnom[plantQsGrdcAnom < -5] = np.nan
    plantQsGrdcAnom[plantQsGrdcAnom > 5] = np.nan
    plantQsGrdcAnomSummer[plantQsGrdcAnomSummer < -5] = np.nan
    plantQsGrdcAnomSummer[plantQsGrdcAnomSummer > 5] = np.nan
    
    plantIds = np.array(plantIds)
    
    finalPlantPercCapacity = np.array(finalPlantPercCapacity)
    finalPlantPercCapacitySummer = np.array(finalPlantPercCapacitySummer)
    
    d = {'txSummer': plantTxSummer, 'tx':plantTx, \
         'qsSummer':plantQsSummer, 'qsAnomSummer':plantQsAnomSummer, 'qsPercentileSummer':plantQsPercentileSummer, \
         'qsGldasBasinSummer':plantQsGldasBasinSummer, 'qsGldasBasinAnomSummer':plantQsGldasBasinAnomSummer, 'qsGldasBasinPercentileSummer':plantQsGldasBasinPercentileSummer, \
         'qs':plantQs, 'qsAnom':plantQsAnom, 'qsPercentile':plantQsPercentile, \
         'qsGrdcSummer':plantQsGrdcSummer, 'qsGrdcAnomSummer':plantQsGrdcAnomSummer, 'qsGrdcPercentileSummer':plantQsGrdcPercentileSummer, \
         'qsGrdc':plantQsGrdc, 'qsGrdcAnom':plantQsGrdcAnom, 'qsGrdcPercentile':plantQsGrdcPercentile, \
         'capacitySummer':finalPlantPercCapacitySummer, 'capacity':finalPlantPercCapacity, \
         'normalCapacity':plantCapacity, \
         'plantIds':plantIds, 'summerInds':summerInds, \
         'plantLats':nukeLat, 'plantLons':nukeLon, \
         'plantYearsAll':plantYears, 'plantMonthsAll':plantMonths, 'plantDaysAll':plantDays}
    return d






def accumulateNukeWxData(datadir, eba, nukeMatchData):
    
    tx = nukeMatchData['tx']
    ids = nukeMatchData['ids']
    qs = nukeMatchData['qs']
    qsGldasBasin = nukeMatchData['qsGldasBasin']
    qsGrdc = nukeMatchData['qsGrdc']
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    percCapacity = []
    totalOut = []
    totalCap = []
    
    # unique identifiers for plants
    plantIds = []
    plantYears = []
    plantMonths = []
    plantDays = []
    plantQs = []
    plantQsGldasBasin = []
    plantQsGrdc = []
    
    for i in range(ids.shape[0]):
        out = np.array(eba[ids[i,0]]['data'])
        cap = np.array(eba[ids[i,1]]['data'])     
        
        if len(out) == 4383 and len(cap) == 4383:
            
            # calc the plant operating capacity (% of total normal capacity)
            percCapacity.append(100*(1-(out/cap)))
            
            plantIds.append([i]*len(out))
            plantYears.append(eba[ids[i,0]]['year'])
            plantMonths.append(eba[ids[i,0]]['month'])
            plantDays.append(eba[ids[i,0]]['day'])
            
            plantQs.append(qs[i])
            plantQsGldasBasin.append(qsGldasBasin[i])
            plantQsGrdc.append(qsGrdc[i])
            
            if len(totalOut) == 0:
                totalOut = out
                totalCap = cap
            else:
                totalOut += out
                totalCap += cap
    
    percCapacity = np.array(percCapacity)  
    plantIds = np.array(plantIds)
    plantYears = np.array(plantYears)
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    plantQs = np.array(plantQs)
    plantQsGldasBasin = np.array(plantQsGldasBasin)
    plantQsGrdc = np.array(plantQsGrdc)
    
    outageBool = []
    
    plantQsTotal = []
    plantQsAnomTotal = []
    plantQsPercentileTotal = []
                          
    plantQsGldasBasinTotal = []
    plantQsGldasBasinAnomTotal = []
    plantQsGldasBasinPercentileTotal = []
                          
    plantQsGrdcTotal = []
    plantQsGrdcAnomTotal = []
    plantQsGrdcPercentileTotal = []
   
    plantTxTotal = []
    plantCapTotal = []
    plantIdsAcc = []
    plantMeanTempsAcc = []
    yearsAcc = []
    monthsAcc = []
    daysAcc = []
    
    # loop over all plants
    for i in range(percCapacity.shape[0]):
        
        plantCap = percCapacity[i]
        plantTx = tx[i,1:]
        curQs = plantQs[i]
        curQsGldasBasin = plantQsGldasBasin[i]
        curQsGrdc = plantQsGrdc[i]
        
        if len(plantTx)==len(plantCap):
            plantCap = plantCap[summerInds]
            plantTx = plantTx[summerInds]
            curQs = curQs[summerInds]
            curQsGldasBasin = curQsGldasBasin[summerInds]
            curQsGrdc = curQsGrdc[summerInds]
            
            nn = np.where((~np.isnan(plantCap)) & (~np.isnan(plantTx)))[0]
            
            curQs = curQs[nn]
            curQsGldasBasin = curQsGldasBasin[nn]
            curQsGrdc = curQsGrdc[nn]
            plantCap = plantCap[nn]
            plantTx = plantTx[nn]
            
            tmpQsPercentile = np.zeros(curQs.size)
            tmpQsPercentile[tmpQsPercentile == 0] = np.nan
            
            tmpQsGldasBasinPercentile = np.zeros(curQsGldasBasin.size)
            tmpQsGldasBasinPercentile[tmpQsGldasBasinPercentile == 0] = np.nan
            
            tmpQsGrdcPercentile = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentile[tmpQsGrdcPercentile == 0] = np.nan
                
            nn = np.where(~np.isnan(curQs))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-summer-agg-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer-agg-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for gldas plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-summer-agg-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQs[nn])
                curQsStd = dist.std(*args)
                tmpQsPercentile = dist.cdf(curQs, *args)
            else:
                curQsStd = np.nan
            
            
            nn = np.where(~np.isnan(curQsGldasBasin))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer-agg-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer-agg-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for gldas basin average plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-gldas-basin-summer-agg-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQsGldasBasin[nn])
                curQsGldasBasinStd = dist.std(*args)
                tmpQsGldasBasinPercentile = dist.cdf(curQsGldasBasin, *args)
            else:
                curQsGldasBasinStd = np.nan
                
            
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if os.path.isfile('%s/dist-fits/best-fit-nuke-%d-grdc-summer-agg-level.dat'%(datadir, i)): 
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer-agg-level.dat'%(datadir, i), 'rb') as f:
                    distParams = pickle.load(f)
                    dist = getattr(st, distParams['name'])
            else:
                print('finding best distribution for grdc plant %d'%i)
                best_fit_name, best_fit_params = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
                with open('%s/dist-fits/best-fit-nuke-%d-grdc-summer-agg-level.dat'%(datadir, i), 'wb') as f:
                    distParams = {'name':best_fit_name,
                                  'params':best_fit_params}
                    dist = getattr(st, distParams['name'])
                    pickle.dump(distParams, f)
            
            if len(nn) > 10:
                args = dist.fit(curQsGrdc[nn])
                curQsGrdcStd = dist.std(*args)
                tmpQsGrdcPercentile = dist.cdf(curQsGrdc, *args)
            else:
                curQsGrdcStd = np.nan
            
            plantQsTotal.extend(curQs)
            plantQsAnomTotal.extend((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentileTotal.extend(tmpQsPercentile)
            
            plantQsGldasBasinTotal.extend(curQsGldasBasin)
            plantQsGldasBasinAnomTotal.extend((curQs-np.nanmean(curQsGldasBasin))/curQsGldasBasinStd)
            plantQsGldasBasinPercentileTotal.extend(tmpQsGldasBasinPercentile)
            
            plantQsGrdcTotal.extend(curQsGrdc)
            plantQsGrdcAnomTotal.extend((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentileTotal.extend(tmpQsGrdcPercentile)
            
            plantCapTotal.extend(plantCap)
            plantTxTotal.extend(plantTx)
            
            plantIdsAcc.extend(plantIds[i,summerInds])
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
    
    plantQsGldasBasinTotal = np.array(plantQsGldasBasinTotal)
    plantQsGldasBasinAnomTotal = np.array(plantQsGldasBasinAnomTotal)
    
    plantQsGrdcTotal = np.array(plantQsGrdcTotal)
    plantQsGrdcAnomTotal = np.array(plantQsGrdcAnomTotal)
    
    plantQsAnomTotal[plantQsAnomTotal < -5] = np.nan
    plantQsAnomTotal[plantQsAnomTotal > 5] = np.nan
    plantQsGldasBasinAnomTotal[plantQsGldasBasinAnomTotal < -5] = np.nan
    plantQsGldasBasinAnomTotal[plantQsGldasBasinAnomTotal > 5] = np.nan
    plantQsGrdcAnomTotal[plantQsGrdcAnomTotal < -5] = np.nan
    plantQsGrdcAnomTotal[plantQsGrdcAnomTotal > 5] = np.nan
    
    plantTxTotal = np.array(plantTxTotal)
    plantCapTotal = np.array(plantCapTotal)
    plantIdsAcc = np.array(plantIdsAcc)
    yearsAcc = np.array(yearsAcc)
    monthsAcc = np.array(monthsAcc)
    daysAcc = np.array(daysAcc)
    
    d = {'txSummer':plantTxTotal, \
         'qsSummer':plantQsTotal, 'qsAnomSummer':plantQsAnomTotal, 'qsPercentileSummer':plantQsPercentileTotal, \
         'qsGldasBasinSummer':plantQsGldasBasinTotal, 'qsGldasBasinAnomSummer':plantQsGldasBasinAnomTotal, 'qsGldasBasinPercentileSummer':plantQsGldasBasinPercentileTotal, \
         'qsGrdcSummer':plantQsGrdcTotal, 'qsGrdcAnomSummer':plantQsGrdcAnomTotal, 'qsGrdcPercentileSummer':plantQsGrdcPercentileTotal, \
         'capacitySummer':plantCapTotal, 'percCapacity':percCapacity, \
         'summerInds':summerInds, 'outagesBoolSummer':outageBool, 'plantIds':plantIdsAcc, \
         'plantMeanTemps':plantMeanTempsAcc, 'plantYearsAll':plantYears, 'plantMonthsAll':plantMonths, \
         'plantYearsSummer':yearsAcc, 'plantMonthsSummer':monthsAcc, 'plantDaysSummer':daysAcc}
    return d


