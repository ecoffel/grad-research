# -*- coding: utf-8 -*-
"""
Created on Mon Apr  1 09:47:36 2019

@author: Ethan
"""

import json
import numpy as np
import scipy.stats as st

import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = True
plotFigs = False

def running_mean(x, N):
    cumsum = np.cumsum(np.insert(x, 0, 0)) 
    return (cumsum[N:] - cumsum[:-N]) / float(N)

def loadNukeData(dataDir):
    print('loading nuke eba...')
    eba = []
    for line in open('%s/ecoffel/data/projects/electricity/NUC_STATUS.txt' % dataDir, 'r'):
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
    fileNameCDD = ''
    
    if wxdata == 'cpc':
        fileName = 'nuke-tx-cpc.csv'
        fileNameCDD = 'nuke-cdd-cpc.csv'
    elif wxdata == 'era':
        fileName = 'nuke-tx-era.csv'
        fileNameCDD = 'nuke-cdd-era.csv'
    elif wxdata == 'ncep':
        fileName = 'nuke-tx-ncep.csv'
        fileNameCDD = 'nuke-cdd-ncep.csv'
    elif wxdata == 'all':
        fileName = ['nuke-tx-cpc.csv', 'nuke-tx-era.csv', 'nuke-tx-ncep.csv']
        fileNameCDD = ['nuke-cdd-cpc.csv', 'nuke-cdd-era.csv', 'nuke-cdd-ncep.csv']
        
        
    tx = []
    cdd = []
    
    if wxdata == 'all':
        tx1 = np.genfromtxt(fileName[0], delimiter=',')
        tx2 = np.genfromtxt(fileName[1], delimiter=',')    
        tx3 = np.genfromtxt(fileName[2], delimiter=',')    
        
        tx = tx1.copy()
        for i in range(0,tx1.shape[0]):
            for j in range(1,tx1.shape[1]):
                tx[i,j] = np.nanmean([tx1[i,j], tx2[i,j], tx3[i,j]])
        
        
        cdd1 = np.genfromtxt(fileNameCDD[0], delimiter=',')    
        cdd2 = np.genfromtxt(fileNameCDD[1], delimiter=',')    
        cdd3 = np.genfromtxt(fileNameCDD[2], delimiter=',')    
        
        cdd = cdd1.copy()
        for i in range(0,cdd1.shape[0]):
            for j in range(1,cdd1.shape[1]):
                cdd[i,j] = np.nanmean([cdd1[i,j], cdd2[i,j], cdd3[i,j]])
        
    else:
        tx = np.genfromtxt(fileName, delimiter=',')
        cdd = np.genfromtxt(fileNameCDD, delimiter=',')
    
    
    fileNameGldas = 'nuke-qs-gldas-all.csv'
    qs = np.genfromtxt(fileNameGldas, delimiter=',')
    
    fileNameGrdc = 'nuke-qs-grdc.csv'
    qsGrdcRaw = np.genfromtxt(fileNameGrdc, delimiter=',')
    
    qsGrdc = []
    for p in range(qsGrdcRaw.shape[0]):
        curq = [np.nan]*30
        curq.extend(running_mean(qsGrdcRaw[p,1:], 30))
        qsGrdc.append(curq)
    qsGrdc = np.array(qsGrdc)
    
    
    # these ids store the line numbers for plant level outage and capacity data in the EBA file
    ids = []
    matchedQs = []
    for i in range(tx.shape[0]):
        # current facility outage name
        outageId = int(tx[i,0])
        name = eba[outageId]['name']
        
        matchedQs.append([])
        
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
        qsInd = 1
        lastM = 1
        for m in range(len(eba[ids[i][0]]['month'])):
            curM = eba[ids[i][0]]['month'][m]
            if curM != lastM:
                qsInd += 1
                lastM = eba[ids[i][0]]['month'][m]
            matchedQs[i].append(qs[i,qsInd])
    matchedQs = np.array(matchedQs)
    
    return {'tx':np.array(tx), 'cdd':np.array(cdd), 'qs':matchedQs, 'qsGrdc':qsGrdc[:,1:], 'ids':np.array(ids)}

def accumulateNukeWxDataPlantLevel(eba, nukeMatchData):
    
    summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]
    
    tx = nukeMatchData['tx']
    cdd = nukeMatchData['cdd']
    qs = nukeMatchData['qs']
    qsGrdc = nukeMatchData['qsGrdc']
    ids = nukeMatchData['ids']
    
    nukeLat = []
    nukeLon = []
    
    plantCapacity = []
    plantPercCapacity = []
    plantTx = []
    plantTxSummer = []
    plantCDD = []
    
    plantQsSummer = []
    plantQsAnomSummer = []
    plantQsPercentileSummer = []
    
    plantQsTmp = []
    plantQs = []
    plantQsAnom = []
    plantQsPercentile = []
    
    plantQsGrdcSummer = []
    plantQsGrdcAnomSummer = []
    plantQsGrdcPercentileSummer = []
    
    plantQsGrdcTmp = []
    plantQsGrdc = []
    plantQsGrdcAnom = []
    plantQsGrdcPercentile = []
    
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
            
            plantQsTmp.append(qs[i])
            plantQsGrdcTmp.append(qsGrdc[i])
            
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
    plantQsTmp = np.array(plantQsTmp)
    plantQsGrdcTmp = np.array(plantQsGrdcTmp)
    nukeLat = np.array(nukeLat)
    nukeLon = np.array(nukeLon)
    
    finalPlantPercCapacity = []
    finalPlantPercCapacitySummer = []
    
    for i in range(plantPercCapacity.shape[0]):
        
        curPC = plantPercCapacity[i]
        curTx = tx[i,1:]
        curCDD = cdd[i,1:]
        
        curQs = plantQsTmp[i]
        curQsGrdc = plantQsGrdcTmp[i]
        
        if len(curPC)==len(curTx):
            
            # append without restricting to summer
            finalPlantPercCapacity.append(curPC)
            plantTx.append(curTx)
            
            tmpQsPercentile = np.zeros(curQs.size)
            tmpQsPercentile[tmpQsPercentile == 0] = np.nan
            tmpQsGrdcPercentile = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentile[tmpQsGrdcPercentile == 0] = np.nan
            
            # find std of qs distribution
            dist = st.gamma
            nn = np.where(~np.isnan(curQs))[0]
            if len(nn) > 10:
                args = dist.fit(curQs[nn])
                curQsStd = dist.std(*args)
                tmpQsPercentile = dist.cdf(curQs, *args)
            else:
                curQsStd = np.nan
            
            dist = st.gamma
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if len(nn) > 10:
                args = dist.fit(curQsGrdc[nn])
                curQsGrdcStd = dist.std(*args)
                tmpQsGrdcPercentile = dist.cdf(curQsGrdc, *args)
            else:
                curQsGrdcStd = np.nan
            
            
            plantQs.append(curQs)
#            plantQsAnom.append((curQs-np.nanmean(curQs))/np.nanstd(curQs))
            plantQsAnom.append((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentile.append(tmpQsPercentile)
            plantQsGrdc.append(curQsGrdc)
#            plantQsGrdcAnom.append((curQsGrdc-np.nanmean(curQsGrdc))/np.nanstd(curQsGrdc))
            plantQsGrdcAnom.append((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentile.append(tmpQsGrdcPercentile)
            
            # restrict to summer only
            curPC = curPC[summerInds]
            curTx = curTx[summerInds]
            curCDD = curCDD[summerInds]
            curQs = curQs[summerInds]
            curQsGrdc = curQsGrdc[summerInds]
            nn = np.where((~np.isnan(curPC)) & (~np.isnan(curTx)) & (~np.isnan(curCDD)) & (~np.isnan(curQs)))[0]
            curPC = curPC[nn]
            curTx = curTx[nn]
            curCDD = curCDD[nn]
            curQs = curQs[nn]
            curQsGrdc = curQsGrdc[nn]
            
            
            tmpQsPercentileSummer = np.zeros(curQs.size)
            tmpQsPercentileSummer[tmpQsPercentileSummer == 0] = np.nan
            tmpQsGrdcPercentileSummer = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentileSummer[tmpQsGrdcPercentileSummer == 0] = np.nan
            
            # find std of qs distribution
            dist = st.gamma
            nn = np.where(~np.isnan(curQs))[0]
            if len(nn) > 10:
                args = dist.fit(curQs)
                curQsStd = dist.std(*args)
                tmpQsPercentileSummer = dist.cdf(curQs, *args)
            else:
                curQsStd = np.nan
            
            dist = st.gamma
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if len(nn) > 10:
                args = dist.fit(curQsGrdc)
                curQsGrdcStd = dist.std(*args)
                tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *args)
            else:
                curQsGrdcStd = np.nan
            
            
            # now aggregate summer-restricted variables for this plant
            finalPlantPercCapacitySummer.append(curPC)
            plantTxSummer.append(curTx)
            plantCDD.append(curCDD)
            plantQsSummer.append(curQs)
#            plantQsAnomSummer.append((curQs-np.nanmean(curQs))/np.nanstd(curQs))
            plantQsAnomSummer.append((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentileSummer.append(tmpQsPercentileSummer)
            
            plantQsGrdcSummer.append(curQsGrdc)
#            plantQsGrdcAnomSummer.append((curQsGrdc-np.nanmean(curQsGrdc))/np.nanstd(curQsGrdc))
            plantQsGrdcAnomSummer.append((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentileSummer.append(tmpQsGrdcPercentileSummer)
            
            
    plantTx = np.array(plantTx)
    plantTxSummer = np.array(plantTxSummer)
    plantCDD = np.array(plantCDD)
    
    plantQs = np.array(plantQs)
    plantQsAnom = np.array(plantQsAnom)
    plantQsPercentile = np.array(plantQsPercentile)
    plantQsSummer = np.array(plantQsSummer)
    plantQsAnomSummer = np.array(plantQsAnomSummer)
    plantQsPercentileSummer = np.array(plantQsPercentileSummer)
    
    plantQsGrdc = np.array(plantQsGrdc)
    plantQsGrdcAnom = np.array(plantQsGrdcAnom)
    plantQsGrdcPercentile = np.array(plantQsGrdcPercentile)
    plantQsGrdcSummer = np.array(plantQsGrdcSummer)
    plantQsGrdcAnomSummer = np.array(plantQsGrdcAnomSummer)
    plantQsGrdcPercentileSummer = np.array(plantQsGrdcPercentileSummer)
    
    plantIds = np.array(plantIds)
    
    finalPlantPercCapacity = np.array(finalPlantPercCapacity)
    finalPlantPercCapacitySummer = np.array(finalPlantPercCapacitySummer)
    
    d = {'txSummer': plantTxSummer, 'tx':plantTx, 'cddSummer':plantCDD, \
         'qsSummer':plantQsSummer, 'qsAnomSummer':plantQsAnomSummer, 'qsPercentileSummer':plantQsPercentileSummer, \
         'qs':plantQs, 'qsAnom':plantQsAnom, 'qsPercentile':plantQsPercentile, \
         'qsGrdcSummer':plantQsGrdcSummer, 'qsGrdcAnomSummer':plantQsGrdcAnomSummer, 'qsGrdcPercentileSummer':plantQsGrdcPercentileSummer, \
         'qsGrdc':plantQsGrdc, 'qsGrdcAnom':plantQsGrdcAnom, 'qsGrdcPercentile':plantQsGrdcPercentile, \
         'capacitySummer':finalPlantPercCapacitySummer, 'capacity':finalPlantPercCapacity, \
         'normalCapacity':plantCapacity, \
         'plantIds':plantIds, 'summerInds':summerInds, \
         'plantLats':nukeLat, 'plantLons':nukeLon, \
         'plantYearsAll':plantYears, 'plantMonthsAll':plantMonths, 'plantDaysAll':plantDays}
    return d






def accumulateNukeWxData(eba, nukeMatchData):
    
    tx = nukeMatchData['tx']
    cdd = nukeMatchData['cdd']
    ids = nukeMatchData['ids']
    qs = nukeMatchData['qs']
    qsGrdc = nukeMatchData['qsGrdc']
    
    # for averaging cdd and tx
    smoothingLen = 4
    
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
    plantQsGrdc = np.array(plantQsGrdc)
    
    outageBool = []
    
    plantQsTotal = []
    plantQsAnomTotal = []
    plantQsPercentileTotal = []
    plantQsGrdcTotal = []
    plantQsGrdcAnomTotal = []
    plantQsGrdcPercentileTotal = []
    plantTxTotal = []
    plantTxAvgTotal = []
    plantCDDAccTotal = []
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
        plantCDD = cdd[i,1:]
        curQs = plantQs[i]
        curQsGrdc = plantQsGrdc[i]
        
        # accumulate weekly cdd
        
        plantCDDSmooth = []
        for d in range(len(plantCDD)):
            if d < (smoothingLen-1):
                plantCDDSmooth.append(np.nan)
            else:
                plantCDDSmooth.append(np.nansum(plantCDD[d-(smoothingLen-1):d+1]))
            
        plantCDDSmooth = np.array(plantCDDSmooth)
        
        
        plantTxAvg = []
        for d in range(tx.shape[1]):
            if d > smoothingLen-1:
                plantTxAvg.append(np.nanmean(tx[i,d-(smoothingLen-1):d+1]))
            else:
                plantTxAvg.append(np.nan)
        
        plantTxAvg = np.array(plantTxAvg)
        
        if len(plantTx)==len(plantCap):
            plantCap = plantCap[summerInds]
            plantTx = plantTx[summerInds]
            plantTxAvg = plantTxAvg[summerInds]
            plantCDD = plantCDD[summerInds]
            plantCDDSmooth = plantCDDSmooth[summerInds]
            curQs = curQs[summerInds]
            curQsGrdc = curQsGrdc[summerInds]
            
            nn = np.where((~np.isnan(plantCap)) & (~np.isnan(plantTx)) & (~np.isnan(plantTxAvg)) \
                          & (~np.isnan(plantCDD)) & (~np.isnan(plantCDDSmooth)) & (~np.isnan(curQs)))[0]
            
            curQs = curQs[nn]
            curQsGrdc = curQsGrdc[nn]
            plantCap = plantCap[nn]
            plantTx = plantTx[nn]
            plantTxAvg = plantTxAvg[nn]
            plantCDD = plantCDD[nn]
            plantCDDSmooth = plantCDDSmooth[nn]
            
            tmpQsPercentile = np.zeros(curQs.size)
            tmpQsPercentile[tmpQsPercentile == 0] = np.nan
            tmpQsGrdcPercentile = np.zeros(curQsGrdc.size)
            tmpQsGrdcPercentile[tmpQsGrdcPercentile == 0] = np.nan
            
            # find std of qs distribution
            dist = st.gamma
            nn = np.where(~np.isnan(curQs))[0]
            if len(nn) > 10:
                args = dist.fit(curQs[nn])
                curQsStd = dist.std(*args)
                tmpQsPercentile = dist.cdf(curQs, *args)
#                curQsStd = np.nanstd(curQs)
            else:
                curQsStd = np.nan
            
            dist = st.gamma
            nn = np.where(~np.isnan(curQsGrdc))[0]
            if len(nn) > 10:
                args = dist.fit(curQsGrdc[nn])
                curQsGrdcStd = dist.std(*args)
                tmpQsGrdcPercentile = dist.cdf(curQsGrdc, *args)
#                curQsGrdcStd = np.nanstd(curQsGrdc)
            else:
                curQsGrdcStd = np.nan
            
            plantQsTotal.extend(curQs)
            plantQsAnomTotal.extend((curQs-np.nanmean(curQs))/curQsStd)
            plantQsPercentileTotal.extend(tmpQsPercentile)
            plantQsGrdcTotal.extend(curQsGrdc)
            plantQsGrdcAnomTotal.extend((curQsGrdc-np.nanmean(curQsGrdc))/curQsGrdcStd)
            plantQsGrdcPercentileTotal.extend(tmpQsGrdcPercentile)
            
            plantCapTotal.extend(plantCap)
            plantTxTotal.extend(plantTx)
            plantTxAvgTotal.extend(plantTxAvg)
            plantCDDAccTotal.extend(plantCDDSmooth)
            
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
    plantQsGrdcTotal = np.array(plantQsGrdcTotal)
    plantQsGrdcAnomTotal = np.array(plantQsGrdcAnomTotal)
    
    plantTxTotal = np.array(plantTxTotal)
    plantTxAvgTotal = np.array(plantTxAvgTotal)
    plantCDDAccTotal = np.array(plantCDDAccTotal)
    plantCapTotal = np.array(plantCapTotal)
    plantIdsAcc = np.array(plantIdsAcc)
    yearsAcc = np.array(yearsAcc)
    monthsAcc = np.array(monthsAcc)
    daysAcc = np.array(daysAcc)
    
    d = {'txSummer':plantTxTotal, 'txAvgSummer':plantTxAvgTotal, 'cddSummer':plantCDDAccTotal, \
         'qsSummer':plantQsTotal, 'qsAnomSummer':plantQsAnomTotal, 'qsPercentileSummer':plantQsPercentileTotal, \
         'qsGrdcSummer':plantQsGrdcTotal, 'qsGrdcAnomSummer':plantQsGrdcAnomTotal, 'qsGrdcPercentileSummer':plantQsGrdcPercentileTotal, \
         'capacitySummer':plantCapTotal, 'percCapacity':percCapacity, \
         'summerInds':summerInds, 'outagesBoolSummer':outageBool, 'plantIds':plantIdsAcc, \
         'plantMeanTemps':plantMeanTempsAcc, 'plantYearsAll':plantYears, 'plantMonthsAll':plantMonths, \
         'plantYearsSummer':yearsAcc, 'plantMonthsSummer':monthsAcc, 'plantDaysSummer':daysAcc}
    return d


