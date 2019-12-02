# -*- coding: utf-8 -*-
"""
Created on Sun Mar 31 18:49:31 2019

@author: Ethan
"""

import numpy as np
import scipy.stats as st
import os, pickle
import el_find_best_runoff_dist

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

def running_mean(x, N):
    cumsum = np.cumsum(np.insert(x, 0, 0)) 
    return (cumsum[N:] - cumsum[:-N]) / float(N)

def normalize(v):
    nn = np.where(~np.isnan(v))[0]
    norm = np.linalg.norm(v[nn])
    newv = v.copy()
    if norm == 0: 
       return newv
   
    return newv / float(norm)
    

monthsList = ['January', 'February', 'March', 'April', 'May', 'June', \
              'July', 'August', 'September', 'October', 'November', 'December']

def getMonth(m):
    return monthsList.index(m)+1

def getEUCountryCode(s):
    euCodes = ['AL', 'AD', 'AM', 'AT', 'BY', 'BE', 'BA', 'BG', 'CH', 'CY', 'CZ', 'DE', \
               'DK', 'EE', 'ES', 'FO', 'FI', 'FR', 'GB', 'GE', 'GI', 'GR', 'HU', 'HR', \
               'IE', 'IS', 'IT', 'LT', 'LU', 'LV', 'MC', 'MK', 'MT', 'NO', 'NL', 'PO', \
               'PT', 'RO', 'SE', 'SI', 'SK', 'SM', 'VA']
    for c in euCodes:
        if c in s:
            return c

def get3LetterEUCountryCodes():
    codes = ['AUT', 'BEL', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', 'EST', 'FIN', 'FRA', 'DEU', 'GRC', \
             'HUN', 'IRL', 'ITA', 'LVA', 'LTU', 'LUX', 'MLT', 'NLD', 'POL', 'PRT', 'ROU', 'SVK',\
             'SVN', 'ESP', 'SWE', 'GBR']
    return codes

def getFuelType(s):
    types = ['coal', 'oil', 'gas', 'nuclear', 'cogeneration', 'biomass']
    for t in types:
        if t in s.lower() or s.lower() in t:
            return t

def loadEntsoeWithLatLon(dataDir, forced):
    
    print('loading entsoe plant locations...')
    print('datadir = %s'%dataDir)
    ppCommissionYear = []
    ppName = []
    ppLat = []
    ppLon = []
    ppProjId = []
    
    # first load database with entsoe power plant locations
    with open('%s/entsoe/entsoe-power-plant-locations.csv'%dataDir, 'r', encoding='latin-1') as f:
        i = 0
        for line in f:
            if i == 0:
                i += 1
                continue
            
            parts = line.split(',')
            
            if len(parts[1].strip()) > 0:
                ppName.append(parts[1].strip())
            else:
                ppName.append('')
                
            if len(parts[8].strip()) > 0:
                ppCommissionYear.append(float(parts[8].strip()))
            else:
                ppCommissionYear.append(np.nan)
                
            if len(parts[10].strip()) > 0: 
                ppLat.append(float(parts[10].strip()))
            else:
                ppLat.append(np.nan)
                
            if len(parts[11].strip()) > 0:
                ppLon.append(float(parts[11].strip()))
            else:
                ppLon.append(np.nan)
                
            if len(parts[13].strip()) > 0:
                ppProjId.append(parts[13].strip())
            else:
                ppProjId.append('')
                
    yearsEntsoe = []
    monthsEntsoe = []
    daysEntsoe = []
    latsEntsoe = []
    lonsEntsoe = []
    namesEntsoe = []
    fuelTypesEntsoe = []
    eicEntsoe = []
    countriesEntsoe = []
    actualCapacityEntsoe = []
    normalCapacityEntsoe = []
    for year in range(2015, 2019):
        print('loading entsoe year %d...'%year)
        for month in range(1, 13):
            with open('%s/entsoe/OutagesPU/%d_%d_OutagesPU.csv' % (dataDir, year, month), 'r', encoding='utf-16') as f:
                n = 0
                
                countryInd = -1
                capActInd = -1
                capNormInd = -1
                eicInd = -1
                nameInd = -1
                
                for line in f:
                    lineParts = line.split('\t')
                    
                    if n == 0:
                        for p in range(len(lineParts)):
                            if lineParts[p].strip() == 'MapCode':
                                countryInd = p
                            elif lineParts[p].strip() == 'InstalledCapacity':
                                capNormInd = p
                            elif lineParts[p].strip() == 'UnavailabilityValue':
                                capActInd = p
                            elif lineParts[p].strip() == 'PowerRecourceEIC':
                                eicInd = p
                            elif lineParts[p].strip() == 'UnitName':
                                nameInd = p
                        n += 1
                        continue
                    
                    if countryInd == -1 or capActInd == -1 or capNormInd == -1:
                        print('no data for %d/%d'%(month,year))
                        break
                    
                    if len(lineParts) < 20:
                        continue
                    
                    if forced and lineParts[8] != 'Forced':
                        continue
                    
                    if 'Hydro' in lineParts[15] or \
                        'hydro' in lineParts[15] or \
                        'Wind' in lineParts[15] or \
                        'wind' in lineParts[15]:
                        continue
                    
                    curEIC = lineParts[eicInd].strip()
                    curName = lineParts[nameInd].strip()
                    
                    # now search for lat/lon using the eic in location database
                    eicLatInds = [k for k in range(len(ppName)) if curName in ppName[k] or curEIC in ppProjId[k]]
                    
                    if len(eicLatInds) >= 1:
                        yearsEntsoe.append(int(lineParts[0]))
                        monthsEntsoe.append(int(lineParts[1]))
                        daysEntsoe.append(int(lineParts[2]))
                        latsEntsoe.append(ppLat[eicLatInds[0]])
                        lonsEntsoe.append(ppLon[eicLatInds[0]])
                        eicEntsoe.append(curEIC)
                        countriesEntsoe.append(getEUCountryCode(lineParts[countryInd]))
                        namesEntsoe.append(curName)
                        fuelTypesEntsoe.append(getFuelType(lineParts[15].strip()))
                        actualCapacityEntsoe.append(float(lineParts[capActInd]))
                        normalCapacityEntsoe.append(float(lineParts[capNormInd]))
                    
    yearsEntsoe = np.array(yearsEntsoe)
    monthsEntsoe = np.array(monthsEntsoe)
    daysEntsoe = np.array(daysEntsoe)
    latsEntsoe = np.array(latsEntsoe)
    lonsEntsoe = np.array(lonsEntsoe)
    countriesEntsoe = np.array(countriesEntsoe)
    actualCapacityEntsoe = np.array(actualCapacityEntsoe)
    normalCapacityEntsoe = np.array(normalCapacityEntsoe)
    
    d = {'years':yearsEntsoe, 'months':monthsEntsoe, 'days':daysEntsoe, \
         'lats':latsEntsoe, 'lons':lonsEntsoe, \
         'countries':countriesEntsoe, 'names': namesEntsoe, \
         'fuelTypes':fuelTypesEntsoe, \
         'actualCapacity':actualCapacityEntsoe, \
         'normalCapacity':normalCapacityEntsoe}
    
    return d


def loadEntsoe(dataDir, forced):
    yearsEntsoe = []
    monthsEntsoe = []
    daysEntsoe = []
    namesEntsoe = []
    fuelTypesEntsoe = []
    eicEntsoe = []
    countriesEntsoe = []
    actualCapacityEntsoe = []
    normalCapacityEntsoe = []
    for year in range(2015, 2019):
        print('loading entsoe year %d...'%year)
        for month in range(1, 13):
            with open('%s/entsoe/OutagesPU/%d_%d_OutagesPU.csv' % (dataDir, year, month), 'r', encoding='utf-16') as f:
                n = 0
                
                countryInd = -1
                capActInd = -1
                capNormInd = -1
                eicInd = -1
                nameInd = -1
                
                for line in f:
                    lineParts = line.split('\t')
                    
                    if n == 0:
                        for p in range(len(lineParts)):
                            if lineParts[p].strip() == 'MapCode':
                                countryInd = p
                            elif lineParts[p].strip() == 'InstalledCapacity':
                                capNormInd = p
                            elif lineParts[p].strip() == 'UnavailabilityValue':
                                capActInd = p
                            elif lineParts[p].strip() == 'PowerRecourceEIC':
                                eicInd = p
                            elif lineParts[p].strip() == 'UnitName':
                                nameInd = p
                        n += 1
                        continue
                    
                    if countryInd == -1 or capActInd == -1 or capNormInd == -1:
                        print('no data for %d/%d'%(month,year))
                        break
                    
                    if len(lineParts) < 20:
                        continue
                    
                    if forced and lineParts[8] != 'Forced':
                        continue
                    
                    if 'Hydro' in lineParts[15] or \
                        'hydro' in lineParts[15] or \
                        'Wind' in lineParts[15] or \
                        'wind' in lineParts[15]:
                        continue
                    
                    curEIC = lineParts[eicInd].strip()
                    curName = lineParts[nameInd].strip()
                    
                    yearsEntsoe.append(int(lineParts[0]))
                    monthsEntsoe.append(int(lineParts[1]))
                    daysEntsoe.append(int(lineParts[2]))
                    eicEntsoe.append(curEIC)
                    countriesEntsoe.append(getEUCountryCode(lineParts[countryInd]))
                    namesEntsoe.append(curName)
                    fuelTypesEntsoe.append(getFuelType(lineParts[15].strip()))
                    actualCapacityEntsoe.append(float(lineParts[capActInd]))
                    normalCapacityEntsoe.append(float(lineParts[capNormInd]))
                    
    yearsEntsoe = np.array(yearsEntsoe)
    monthsEntsoe = np.array(monthsEntsoe)
    daysEntsoe = np.array(daysEntsoe)
    countriesEntsoe = np.array(countriesEntsoe)
    actualCapacityEntsoe = np.array(actualCapacityEntsoe)
    normalCapacityEntsoe = np.array(normalCapacityEntsoe)
    
    d = {'years':yearsEntsoe, 'months':monthsEntsoe, 'days':daysEntsoe, \
         'countries':countriesEntsoe, 'names': namesEntsoe, \
         'fuelTypes':fuelTypesEntsoe, \
         'actualCapacity':actualCapacityEntsoe, \
         'normalCapacity':normalCapacityEntsoe}
    
    return d





def matchEntsoeWxPlantSpecific(datadir, entsoeData, wxdata, forced):
    fileName = ''
    fileNameCDD = ''
    
    if forced:
        fileNameQs = '%s/script-data/entsoe-qs-gldas-all.csv'%dataDir
    else:
        fileNameQs = '%s/script-data/entsoe-qs-gldas-all-nonforced.csv'%dataDir
    
    fileNameQsGrdc = '%s/script-data/entsoe-qs-grdc-nonforced.csv'%dataDir
    fileNameQsGldasBasinWide = '%s/script-data/entsoe-qs-gldas-basin-avg-nonforced.csv'%dataDir
    
    if wxdata == 'cpc':
        fileName = '%s/script-data/entsoe-tx-cpc.csv'%dataDir
    elif wxdata == 'era':
        fileName = '%s/script-data/entsoe-tx-era.csv'%dataDir
    elif wxdata == 'ncep':
        fileName = '%s/script-data/entsoe-tx-ncep.csv'%dataDir
    elif wxdata == 'all':
        if forced:
            fileName = ['%s/script-data/entsoe-tx-cpc.csv'%dataDir, \
                        '%s/script-data/entsoe-tx-era.csv'%dataDir, \
                        '%s/script-data/entsoe-tx-ncep.csv'%dataDir]
        else:
            fileName = ['%s/script-data/entsoe-tx-cpc-nonforced.csv'%dataDir, \
                        '%s/script-data/entsoe-tx-era-nonforced.csv'%dataDir, \
                        '%s/script-data/entsoe-tx-ncep-nonforced.csv'%dataDir]
            
    tx = []
    qs = []
    qsGldasBasin = []
    qsGrdc = []
    txYears = []
    txMonths = []
    txDays = []
    plantIds = []
    
    # the number to start the IDs at to differentiate from the nuke data
    baseId = 100
    
    if wxdata == 'all':
        tx1 = np.genfromtxt(fileName[0], delimiter=',')    
        tx2 = np.genfromtxt(fileName[1], delimiter=',')    
        tx3 = np.genfromtxt(fileName[2], delimiter=',')    
        
        txYears = tx1[0,:]
        txMonths = tx1[1,:]
        txDays = tx1[2,:]
        
        tx = np.zeros([tx1.shape[0]-3, tx1.shape[1]])
        for i in range(3,tx1.shape[0]):
            for j in range(tx1.shape[1]):
                tx[i-3,j] = np.nanmean([tx1[i,j], tx2[i,j], tx3[i,j]])
        
    else:
        tx = np.genfromtxt(fileName, delimiter=',')
        
        txYears = tx[0,:]
        txMonths = tx[1,:]
        txDays = tx[2,:]
        tx = tx[3:,:]
    
    
    smoothingLen = 30
    
    qsRaw = np.genfromtxt(fileNameQs, delimiter=',')
    qsRaw = qsRaw[3:,:]
    
    qs = qsRaw
    
    qsGldasBasin = np.genfromtxt(fileNameQsGldasBasinWide, delimiter=',')
    qsGldasBasin = qsGldasBasin[3:,:]
    qsGldasBasinSmooth = np.full(qsGldasBasin.shape, np.nan)
    for p in range(qsGldasBasin.shape[0]):
        curq = running_mean(qsGldasBasin[p,:], smoothingLen)
        buf = qsGldasBasin.shape[1]-len(curq)
        qsGldasBasinSmooth[p, buf:] = curq
    qsGldasBasin = qsGldasBasinSmooth
    
    qsGrdcRaw = np.genfromtxt(fileNameQsGrdc, delimiter=',')  
    qsGrdcRaw = qsGrdcRaw[3:,:]
    
    # calc the running mean of the daily qrdc data
    qsGrdc = np.full(qsGrdcRaw.shape, np.nan)
    for p in range(qsGrdcRaw.shape[0]):
        curq = running_mean(qsGrdcRaw[p,:], smoothingLen)
        buf = qsGrdc.shape[1]-len(curq)
        qsGrdc[p, buf:] = curq
    
    finalTx = []
    finalTxSummer = []
    
    finalQs = []
    finalQsAnom = []
    finalQsPercentile = []
    finalQsSummer = []
    finalQsAnomSummer = []
    finalQsPercentileSummer = []
    
    finalQsGldasBasin = []
    finalQsGldasBasinAnom = []
    finalQsGldasBasinPercentile = []
    finalQsGldasBasinSummer = []
    finalQsGldasBasinAnomSummer = []
    finalQsGldasBasinPercentileSummer = []
    
    finalQsGrdc = []
    finalQsGrdcAnom = []
    finalQsGrdcPercentile = []
    finalQsGrdcSummer = []
    finalQsGrdcAnomSummer = []
    finalQsGrdcPercentileSummer = []
    
    finalCapacity = []
    finalCapacitySummer = []
    finalOutagesBool = []
    finalOutagesBoolSummer = []
    finalOutagesCount = []
    finalOutageInds = []
    
    print('matching entsoe outages with wx...')
    
    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
    
    # loop over each power plant
    for c in range(len(entsoeLat)):
        
        plantIds.append(c + baseId)
        
        finalTx.append([])
        finalQs.append([])
        finalQsSummer.append([])
        
        finalQsGldasBasin.append([])
        finalQsGldasBasinSummer.append([])
        
        finalQsGrdc.append([])
        finalQsGrdcSummer.append([])
        
        finalTxSummer.append([])
        finalCapacity.append([])
        finalCapacitySummer.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
        finalOutagesBoolSummer.append([])
        finalOutagesCount.append([])
        
        plantInds = np.where((entsoeData['lats'] == entsoeLat[c]) & \
                             (entsoeData['lons'] == entsoeLon[c]))[0]
        
        # and each day
        for i in range(tx.shape[1]):
            curYear = txYears[i]
            curMonth = txMonths[i]
            curDay = txDays[i]
            
            # the indices in the raw entsoe data for the current day
            curDayIndEntsoe = np.where((entsoeData['years'] == curYear) & (entsoeData['months'] == curMonth) & \
                                 (entsoeData['days'] == curDay))[0]
            
            # intersect the indices for the current plant on the current day
            curDayIndEntsoe = np.intersect1d(curDayIndEntsoe, plantInds)
            
            # there is some outage recorded for current plant on current day
            if len(curDayIndEntsoe) > 0:
                perc = []
                # loop over all entries for current plant on current day (maybe there are > 1)
                for p in curDayIndEntsoe:    
                    perc.append(entsoeData['actualCapacity'][p] / entsoeData['normalCapacity'][p])
                
                # record the average capacity for current plant on current day
                finalCapacity[c].append(np.nanmean(perc))
                
                # 1 here because there is an outage
                finalOutagesBool[c].append(1)
                
                # record outages for only summer
                if curMonth == 7 or curMonth == 8:
                    finalCapacitySummer[c].append(np.nanmean(perc))
                    finalOutagesBoolSummer[c].append(1)
            # no outage reported
            else:
                # 1 here because plant at 100% capacity
                finalCapacity[c].append(1)
            
                # 0 here because no outage
                finalOutagesBool[c].append(0)
            
                if curMonth == 7 or curMonth == 8:
                    finalCapacitySummer[c].append(1)
                    finalOutagesBoolSummer[c].append(0)
                
            finalOutagesCount[c].append(len(curDayIndEntsoe))
            finalTx[c].append(tx[c,i])
            finalQs[c].append(qs[c,i])
            finalQsGldasBasin[c].append(qsGldasBasin[c,i])
            finalQsGrdc[c].append(qsGrdc[c,i])
            
            # record temps for only summer days
            if curMonth == 7 or curMonth == 8:
                finalTxSummer[c].append(tx[c,i])
                finalQsSummer[c].append(qs[c,i])
                finalQsGldasBasinSummer[c].append(qsGldasBasin[c,i])
                finalQsGrdcSummer[c].append(qsGrdc[c,i])
        
        outageInd = np.where(np.array(finalCapacity[c]) < 1)[0]
        finalOutageInds[c].extend(outageInd)

        
        # calculate dist anomalies for SUMMER
        curQs = np.array(finalQsSummer[c])
        nn = np.where(~np.isnan(curQs))[0]          
        if os.path.isfile('%s/dist-fits/best-fit-entsoe-%d-gldas-summer.dat'%(datadir, c)): 
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas-summer.dat'%(datadir, c), 'rb') as f:
                distParams = pickle.load(f)
                curQsStd = distParams['std']
                dist = getattr(st, distParams['name'])
                tmpQsPercentileSummer = dist.cdf(curQs, *distParams['params'])
        else:
            best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas-summer.dat'%(datadir, c), 'wb') as f:
                dist = getattr(st, best_fit_name)
                tmpQsPercentileSummer = dist.cdf(curQs, *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsStd,
                              'cdf':tmpQsPercentileSummer}
                pickle.dump(distParams, f)
                print('gldas summer plant %d: dist = %s, std = %.4f'%(c, str(dist), curQsStd))
        finalQsAnomSummer.append((curQs - np.nanmean(curQs)) / curQsStd)
        finalQsPercentileSummer.append(tmpQsPercentileSummer)
        
        
        
        curQsGldasBasin = np.array(finalQsGldasBasinSummer[c])
        nn = np.where(~np.isnan(curQsGldasBasin))[0]          
        if os.path.isfile('%s/dist-fits/best-fit-entsoe-%d-gldas-basin-avg-summer.dat'%(datadir, c)): 
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas-basin-avg-summer.dat'%(datadir, c), 'rb') as f:
                distParams = pickle.load(f)
                curQsGldasBasinStd = distParams['std']
                dist = getattr(st, distParams['name'])
                tmpQsGldasBasinPercentileSummer = dist.cdf(curQsGldasBasin, *distParams['params'])
        else:
            best_fit_name, best_fit_params, curQsGldasBasinStd = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas-basin-avg-summer.dat'%(datadir, c), 'wb') as f:
                dist = getattr(st, best_fit_name)
                tmpQsGldasBasinPercentileSummer = dist.cdf(curQsGldasBasin, *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsGldasBasinStd,
                              'cdf':tmpQsGldasBasinPercentileSummer}
                pickle.dump(distParams, f)
                print('gldas basin summer plant %d: dist = %s, std = %.4f'%(c, str(dist), curQsGldasBasinStd))
        finalQsGldasBasinAnomSummer.append((curQsGldasBasin - np.nanmean(curQsGldasBasin)) / curQsGldasBasinStd)
        finalQsGldasBasinPercentileSummer.append(tmpQsGldasBasinPercentileSummer)
        
        curQsGrdc = np.array(finalQsGrdcSummer[c])
        nn = np.where(~np.isnan(curQsGrdc))[0]          
        if os.path.isfile('%s/dist-fits/best-fit-entsoe-%d-grdc-summer.dat'%(datadir, c)): 
            with open('%s/dist-fits/best-fit-entsoe-%d-grdc-summer.dat'%(datadir, c), 'rb') as f:
                distParams = pickle.load(f)
                curQsGrdcStd = distParams['std']
                dist = getattr(st, distParams['name'])
                tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *distParams['params'])
        else:
            best_fit_name, best_fit_params, curQsGrdcStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
            with open('%s/dist-fits/best-fit-entsoe-%d-grdc-summer.dat'%(datadir, c), 'wb') as f:
                dist = getattr(st, best_fit_name)
                tmpQsGrdcPercentileSummer = dist.cdf(curQsGrdc, *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsGrdcStd,
                              'cdf':tmpQsGrdcPercentileSummer}
                pickle.dump(distParams, f)
                print('grdc summer plant %d: dist = %s, std = %.4f'%(c, str(dist), curQsGrdcStd))
        finalQsGrdcAnomSummer.append((curQsGrdc - np.nanmean(curQsGrdc)) / curQsGrdcStd)
        finalQsGrdcPercentileSummer.append(tmpQsGrdcPercentileSummer)
        
        
        
        # calculate dist anomalies for ALL YEAR
        curQs = np.array(finalQs[c])
        nn = np.where(~np.isnan(curQs))[0]          
        if os.path.isfile('%s/dist-fits/best-fit-entsoe-%d-gldas.dat'%(datadir, c)): 
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas.dat'%(datadir, c), 'rb') as f:
                distParams = pickle.load(f)
                curQsStd = distParams['std']
                dist = getattr(st, distParams['name'])
                tmpQsPercentile = dist.cdf(curQs, *distParams['params'])
        else:
            best_fit_name, best_fit_params, curQsStd = el_find_best_runoff_dist.best_fit_distribution(curQs[nn])
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas.dat'%(datadir, c), 'wb') as f:
                dist = getattr(st, best_fit_name)
                tmpQsPercentile = dist.cdf(curQs, *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsStd,
                              'cdf':tmpQsPercentile}
                pickle.dump(distParams, f)
                print('gldas all year plant %d: dist = %s, std = %.4f'%(c, str(dist), curQsStd))
        finalQsAnom.append((curQs - np.nanmean(curQs)) / curQsStd)
        finalQsPercentile.append(tmpQsPercentile)
        
        
        curQsGldasBasin = np.array(finalQsGldasBasin[c])
        nn = np.where(~np.isnan(curQsGldasBasin))[0]          
        if os.path.isfile('%s/dist-fits/best-fit-entsoe-%d-gldas-basin-avg.dat'%(datadir, c)): 
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas-basin-avg.dat'%(datadir, c), 'rb') as f:
                distParams = pickle.load(f)
                curQsGldasBasinStd = distParams['std']
                dist = getattr(st, distParams['name'])
                tmpQsGldasBasinPercentile = dist.cdf(curQsGldasBasin, *distParams['params'])
        else:
            best_fit_name, best_fit_params, curQsGldasBasinStd = el_find_best_runoff_dist.best_fit_distribution(curQsGldasBasin[nn])
            with open('%s/dist-fits/best-fit-entsoe-%d-gldas-basin-avg.dat'%(datadir, c), 'wb') as f:
                dist = getattr(st, best_fit_name)
                tmpQsGldasBasinPercentile = dist.cdf(curQsGldasBasin, *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsGldasBasinStd,
                              'cdf':tmpQsGldasBasinPercentile}
                pickle.dump(distParams, f)
                print('gldas basin all year plant %d: dist = %s, std = %.4f'%(c, str(dist), curQsGldasBasinStd))
        finalQsGldasBasinAnom.append((curQsGldasBasin - np.nanmean(curQsGldasBasin)) / curQsGldasBasinStd)
        finalQsGldasBasinPercentile.append(tmpQsGldasBasinPercentile)
        
        
        curQsGrdc = np.array(finalQsGrdc[c])
        nn = np.where(~np.isnan(curQsGrdc))[0]          
        if os.path.isfile('%s/dist-fits/best-fit-entsoe-%d-grdc.dat'%(datadir, c)): 
            with open('%s/dist-fits/best-fit-entsoe-%d-grdc.dat'%(datadir, c), 'rb') as f:
                distParams = pickle.load(f)
                curQsGrdcStd = distParams['std']
                dist = getattr(st, distParams['name'])
                tmpQsGrdcPercentile = dist.cdf(curQsGrdc, *distParams['params'])
        else:
            best_fit_name, best_fit_params, curQsGrdcStd = el_find_best_runoff_dist.best_fit_distribution(curQsGrdc[nn])
            with open('%s/dist-fits/best-fit-entsoe-%d-grdc.dat'%(datadir, c), 'wb') as f:
                dist = getattr(st, best_fit_name)
                tmpQsGrdcPercentile = dist.cdf(curQsGrdc, *best_fit_params)
                distParams = {'name':best_fit_name,
                              'params':best_fit_params, 
                              'std':curQsGrdcStd,
                              'cdf':tmpQsGrdcPercentile}
                pickle.dump(distParams, f)
                print('grdc all year plant %d: dist = %s, std = %.4f'%(c, str(dist), curQsGrdcStd))
        finalQsGrdcAnom.append((curQsGrdc - np.nanmean(curQsGrdc)) / curQsGrdcStd)
        finalQsGrdcPercentile.append(tmpQsGrdcPercentile)
        
    
    finalQs = np.array(finalQs)
    finalQsAnom = np.array(finalQsAnom)
    finalQsPercentile = np.array(finalQsPercentile)
    finalQsSummer = np.array(finalQsSummer)
    finalQsAnomSummer = np.array(finalQsAnomSummer)
    finalQsPercentileSummer = np.array(finalQsPercentileSummer)
    
    finalQsGldasBasin = np.array(finalQsGldasBasin)
    finalQsGldasBasinAnom = np.array(finalQsGldasBasinAnom)
    finalQsGldasBasinPercentile = np.array(finalQsGldasBasinPercentile)
    finalQsGldasBasinSummer = np.array(finalQsGldasBasinSummer)
    finalQsGldasBasinAnomSummer = np.array(finalQsGldasBasinAnomSummer)
    finalQsGldasBasinPercentileSummer = np.array(finalQsGldasBasinPercentileSummer)
    
    finalQsGrdc = np.array(finalQsGrdc)
    finalQsGrdcAnom = np.array(finalQsGrdcAnom)
    finalQsGrdcPercentile = np.array(finalQsGrdcPercentile)
    finalQsGrdcSummer = np.array(finalQsGrdcSummer)
    finalQsGrdcAnomSummer = np.array(finalQsGrdcAnomSummer)
    finalQsGrdcPercentileSummer = np.array(finalQsGrdcPercentileSummer)
    
    finalTx = np.array(finalTx)
    finalTxSummer = np.array(finalTxSummer)
    finalCapacity = np.array(finalCapacity)
    finalCapacitySummer = np.array(finalCapacitySummer)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesBoolSummer = np.array(finalOutagesBoolSummer)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
    
    entsoeLat = np.array(entsoeLat)
    entsoeLon = np.array(entsoeLon)
    
    d = {'tx':finalTx, 'txSummer':finalTxSummer, \
         'qs':finalQs, 'qsAnom':finalQsAnom, 'qsPercentile':finalQsPercentile, \
         'qsGldasBasin':finalQsGldasBasin, 'qsGldasBasinAnom':finalQsGldasBasinAnom, 'qsGldasBasinPercentile':finalQsGldasBasinPercentile, \
         'qsSummer':finalQsSummer, 'qsAnomSummer':finalQsAnomSummer, 'qsPercentileSummer':finalQsPercentileSummer, \
         'qsGldasBasinSummer':finalQsGldasBasinSummer, 'qsGldasBasinAnomSummer':finalQsGldasBasinAnomSummer, 'qsGldasBasinPercentileSummer':finalQsGldasBasinPercentileSummer, \
         'qsGrdc':finalQsGrdc, 'qsGrdcAnom':finalQsGrdcAnom, 'qsGrdcPercentile':finalQsGrdcPercentile, \
         'qsGrdcSummer':finalQsGrdcSummer, 'qsGrdcAnomSummer':finalQsGrdcAnomSummer, 'qsGrdcPercentileSummer':finalQsGrdcPercentileSummer, \
         'years':txYears, 'months':txMonths, 'days':txDays, \
         'plantIds':plantIds, \
         'countries':entsoeData['countries'][plantInds[0]], 'capacity':finalCapacity, 'capacitySummer':finalCapacitySummer, \
         'outagesBool':finalOutagesBool, 'outagesBoolSummer':finalOutagesBoolSummer, 'outagesCount':finalOutagesCount, \
         'lats':entsoeLat, 'lons':entsoeLon}
    return d


def aggregateEntsoeData(entsoeMatchData):
    # aggregate country entsoe outdata data into single 1d array
    txAll = []
    qsAll = []
    qsAnomAll = []
    qsPercentileAll = []
    qsGldasBasinAll = []
    qsGldasBasinAnomAll = []
    qsGldasBasinPercentileAll = []
    qsGrdcAll = []
    qsGrdcAnomAll = []
    qsGrdcPercentileAll = []
    capacityAll = []
    outageBoolAll = []
    outageCountAll = []
    
    plantYears = []
    plantMonths = []
    plantDays = []
    plantIds = []
    plantMeanTemps = []
    
    for c in range(entsoeMatchData['capacity'].shape[0]):
        inds = np.where((entsoeMatchData['months'] >= 7) & (entsoeMatchData['months'] <= 8))[0]
    
        curQsAnom = entsoeMatchData['qsAnom'][c,inds]
        curQsPercentile = entsoeMatchData['qsPercentile'][c,inds]
        curQs = entsoeMatchData['qs'][c,inds]
        
        curQsGldasBasinAnom = entsoeMatchData['qsGldasBasinAnom'][c,inds]
        curQsGldasBasinPercentile = entsoeMatchData['qsGldasBasinPercentile'][c,inds]
        curQsGldasBasin = entsoeMatchData['qsGldasBasin'][c,inds]
        
        curQsGrdcAnom = entsoeMatchData['qsGrdcAnom'][c,inds]
        curQsGrdcPercentile = entsoeMatchData['qsGrdcPercentile'][c,inds]
        curQsGrdc = entsoeMatchData['qsGrdc'][c,inds]
        curTx = entsoeMatchData['tx'][c,inds]
        curCapacity = entsoeMatchData['capacity'][c,inds]
        curOutageBool = entsoeMatchData['outagesBool'][c,inds]
        curOutageCount = entsoeMatchData['outagesCount'][c,inds]
    
        # at least one outage reported for this plant
        if np.nansum(curOutageCount) > 0:
            txAll.extend(curTx)
            
            qsAll.extend(curQs)
            qsAnomAll.extend(curQsAnom)
            qsPercentileAll.extend(curQsPercentile)
            
            qsGldasBasinAll.extend(curQsGldasBasin)
            qsGldasBasinAnomAll.extend(curQsGldasBasinAnom)
            qsGldasBasinPercentileAll.extend(curQsGldasBasinPercentile)
            
            qsGrdcAll.extend(curQsGrdc)
            qsGrdcAnomAll.extend(curQsGrdcAnom)
            qsGrdcPercentileAll.extend(curQsGrdcPercentile)
            
            plantMeanTemps.extend([np.nanmean(curTx)]*len(curTx))
            capacityAll.extend(curCapacity)
            outageBoolAll.extend(curOutageBool)
            outageCountAll.extend(normalize(np.array(curOutageCount)))
            plantIds.extend([entsoeMatchData['plantIds'][c]] * len(curTx))
            plantYears.extend(entsoeMatchData['years'][inds])
            plantMonths.extend(entsoeMatchData['months'][inds])
            plantDays.extend(entsoeMatchData['days'][inds])
    
    txAll = np.array(txAll)
    qsAll = np.array(qsAll)
    qsAnomAll = np.array(qsAnomAll)
    qsPercentileAll = np.array(qsPercentileAll)
    
    qsGldasBasinAll = np.array(qsGldasBasinAll)
    qsGldasBasinAnomAll = np.array(qsGldasBasinAnomAll)
    qsGldasBasinPercentileAll = np.array(qsGldasBasinPercentileAll)
    
    qsGrdcAll = np.array(qsGrdcAll)
    qsGrdcAnomAll = np.array(qsGrdcAnomAll)
    qsGrdcPercentileAll = np.array(qsGrdcPercentileAll)
    
    capacityAll = np.array(capacityAll)
    outageBoolAll = np.array(outageBoolAll)
    outageCountAll = np.array(outageCountAll)
    plantIds = np.array(plantIds)
    plantYears = np.array(plantYears)
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    
    d = {'txSummer':txAll, 'qsSummer':qsAll, 'qsAnomSummer':qsAnomAll, 'qsPercentileSummer':qsPercentileAll, \
         'qsGldasBasinSummer':qsGldasBasinAll, 'qsGldasBasinAnomSummer':qsGldasBasinAnomAll, 'qsGldasBasinPercentileSummer':qsGldasBasinPercentileAll, \
         'qsGrdcSummer':qsGrdcAll, 'qsGrdcAnomSummer':qsGrdcAnomAll, 'qsGrdcPercentileSummer':qsGrdcPercentileAll, \
         'capacitySummer':capacityAll, 'outagesBoolSummer':outageBoolAll, \
         'outagesCount':outageCountAll, 'plantYears':plantYears, 'plantMonths':plantMonths, \
         'plantDays':plantDays, 'plantIds':plantIds, 'plantMeanTemps':plantMeanTemps}
    return d


def exportLatLon(entsoeData):
    
    import csv
    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
    
    i = 0
    with open('%s/script-data/entsoe-lat-lon-nonforced.csv'%dataDir, 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(entsoeLat)):
            csvWriter.writerow([i, entsoeLat[i], entsoeLon[i]])
    
    