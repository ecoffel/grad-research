# -*- coding: utf-8 -*-
"""
Created on Sun Mar 31 18:49:31 2019

@author: Ethan
"""

import numpy as np

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

def loadEntsoeWithLatLon(dataDir):
    
    print('loading entsoe plant locations...')
    ppCommissionYear = []
    ppName = []
    ppLat = []
    ppLon = []
    ppProjId = []
    
    # first load database with entsoe power plant locations
    with open('%s/ecoffel/data/projects/electricity/entsoe/entsoe-power-plant-locations.csv' % (dataDir), 'r', encoding='latin-1') as f:
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
            with open('%s/ecoffel/data/projects/electricity/entsoe/OutagesPU/%d_%d_OutagesPU.csv' % (dataDir, year, month), 'r', encoding='utf-16') as f:
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
                    
                    if lineParts[8] != 'Forced':
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


def loadEntsoe(dataDir):
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
            with open('%s/ecoffel/data/projects/electricity/entsoe/OutagesPU/%d_%d_OutagesPU.csv' % (dataDir, year, month), 'r', encoding='utf-16') as f:
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
                    
                    if lineParts[8] != 'Forced':
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





def matchEntsoeWxPlantSpecific(entsoeData, wxdata):
    fileName = ''
    fileNameCDD = ''
    
    fileNameQs = 'entsoe-qs-gldas.csv'
    
    #for averaging cdd, tx
    smoothingLen = 4
    
    if wxdata == 'cpc':
        fileName = 'entsoe-tx-cpc.csv'
        fileNameCDD = 'entsoe-cdd-cpc.csv'
    elif wxdata == 'era':
        fileName = 'entsoe-tx-era.csv'
        fileNameCDD = 'entsoe-cdd-era.csv'
    elif wxdata == 'ncep':
        fileName = 'entsoe-tx-ncep.csv'
        fileNameCDD = 'entsoe-cdd-ncep.csv'
    elif wxdata == 'all':
        fileName = ['entsoe-tx-cpc.csv', 'entsoe-tx-era.csv', 'entsoe-tx-ncep.csv']
        fileNameCDD = ['entsoe-cdd-cpc.csv', 'entsoe-cdd-era.csv', 'entsoe-cdd-ncep.csv']
    
    
    tx = []
    cdd = []
    qs = []
    txYears = []
    txMonths = []
    txDays = []
    
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
        
        
        cdd1 = np.genfromtxt(fileNameCDD[0], delimiter=',')    
        cdd2 = np.genfromtxt(fileNameCDD[1], delimiter=',')    
        cdd3 = np.genfromtxt(fileNameCDD[2], delimiter=',')    
        
        cdd = np.zeros([cdd1.shape[0]-3, cdd1.shape[1]])
        for i in range(3,cdd1.shape[0]):
            for j in range(cdd1.shape[1]):
                cdd[i-3,j] = np.nanmean([cdd1[i,j], cdd2[i,j], cdd3[i,j]])
        
    else:
        tx = np.genfromtxt(fileName, delimiter=',')
        cdd = np.genfromtxt(fileNameCDD, delimiter=',')
        
        txYears = tx[0,:]
        txMonths = tx[1,:]
        txDays = tx[2,:]
        tx = tx[3:,:]
        cdd = cdd[3:,:]
    
    qsRaw = np.genfromtxt(fileNameQs, delimiter=',')    
    qs = np.zeros([qsRaw.shape[0]-3, qsRaw.shape[1]])
    for i in range(3,qsRaw.shape[0]):
        for j in range(qsRaw.shape[1]):
            qs[i-3,j] = np.nanmean([qsRaw[i,j], qsRaw[i,j], qsRaw[i,j]])
    
    finalTx = []
    finalTxAvg = []
    finalCDDAcc = []
    finalTxSummer = []
    finalQs = []
    finalQsAnom = []
    finalQsSummer = []
    finalQsAnomSummer = []
    finalTxAvgSummer = []
    finalCDDAccSummer = []
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
    
        finalTx.append([])
        finalTxAvg.append([])
        finalQs.append([])
        finalQsSummer.append([])
        finalTxSummer.append([])
        finalTxAvgSummer.append([])
        finalCDDAcc.append([])
        finalCDDAccSummer.append([])
        finalCapacity.append([])
        finalCapacitySummer.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
        finalOutagesBoolSummer.append([])
        finalOutagesCount.append([])
        
        plantInds = np.where((entsoeData['lats'] == entsoeLat[c]) & \
                             (entsoeData['lons'] == entsoeLon[c]))[0]
        
        
        curTxAvg = []
        for d in range(tx.shape[1]):
            if d > smoothingLen-1:
                curTxAvg.append(np.nanmean(tx[c,d-(smoothingLen-1):d+1]))
            else:
                curTxAvg.append(np.nan)
                
        curCDDAcc = []
        for d in range(cdd.shape[1]):
            if d < smoothingLen-1:
                curCDDAcc.append(np.nan)
            else:
                curCDDAcc.append(np.nansum(cdd[c,d-(smoothingLen-1):d+1]))
                
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
            finalTxAvg[c].append(curTxAvg[i])
            finalCDDAcc[c].append(curCDDAcc[i])
            finalQs[c].append(qs[c,i])
            
            # record temps for only summer days
            if curMonth == 7 or curMonth == 8:
                finalTxSummer[c].append(tx[c,i])
                finalTxAvgSummer[c].append(curTxAvg[i])
                finalCDDAccSummer[c].append(curCDDAcc[i])    
                finalQsSummer[c].append(qs[c,i])
        
        outageInd = np.where(np.array(finalCapacity[c]) < 1)[0]
        finalOutageInds[c].extend(outageInd)
        
        curQs = np.array(finalQsSummer[c])
        finalQsAnomSummer.append((curQs - np.nanmean(curQs)) / np.nanstd(curQs))
        
        curQs = np.array(finalQs[c])
        finalQsAnom.append((curQs - np.nanmean(curQs)) / np.nanstd(curQs))
        
    
    finalQs = np.array(finalQs)
    finalQsAnom = np.array(finalQsAnom)
    finalQsSummer = np.array(finalQsSummer)
    finalQsAnomSummer = np.array(finalQsAnomSummer)
    
    finalTx = np.array(finalTx)
    finalTxAvg = np.array(finalTxAvg)
    finalCDDAcc = np.array(finalCDDAcc)
    finalTxSummer = np.array(finalTxSummer)
    finalTxAvgSummer = np.array(finalTxAvgSummer)
    finalCDDAccSummer = np.array(finalCDDAccSummer)
    finalCapacity = np.array(finalCapacity)
    finalCapacitySummer = np.array(finalCapacitySummer)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesBoolSummer = np.array(finalOutagesBoolSummer)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
    
    entsoeLat = np.array(entsoeLat)
    entsoeLon = np.array(entsoeLon)
    
    d = {'tx':finalTx, 'txSummer':finalTxSummer, \
         'txAvg':finalTxAvg, 'txAvgSummer':finalTxAvgSummer, \
         'cdd':finalCDDAcc, 'cddSummer':finalCDDAccSummer, \
         'qs':finalQs, 'qsAnom':finalQsAnom, \
         'qsSummer':finalQsSummer, 'qsAnomSummer':finalQsAnomSummer, \
         'years':txYears, 'months':txMonths, 'days':txDays, \
         'countries':entsoeData['countries'][plantInds[0]], 'capacity':finalCapacity, 'capacitySummer':finalCapacitySummer, \
         'outagesBool':finalOutagesBool, 'outagesBoolSummer':finalOutagesBoolSummer, 'outagesCount':finalOutagesCount, \
         'lats':entsoeLat, 'lons':entsoeLon}
    return d


def matchEntsoeWxCountry(entsoeData, useEra):
    fileName = 'country-tx-cpc-2015-2018.csv'
    if useEra:
        fileName = 'country-tx-era-2015-2018.csv'
    
    countryList = []
    with open(fileName, 'r') as f:
        i = 0
        for line in f:
            if i > 3:
                parts = line.split(',')
                countryList.append(parts[0])
            i += 1
    countryTxData = np.genfromtxt(fileName, delimiter=',', skip_header=1)
    countryYearData = countryTxData[0,1:]
    countryMonthData = countryTxData[1,1:]
    countryDayData = countryTxData[2,1:]
    countryTxData = countryTxData[3:,1:]
    
    finalTx = []
    finalTxSummer = []
    finalCapacity = []
    finalCapacitySummer = []
    finalOutagesBool = []
    finalOutagesBoolSummer = []
    finalOutagesCount = []
    finalOutageInds = []
    
    print('matching entsoe outages with wx...')
    
    for c in range(len(countryList)):
        get_inds = lambda x, xs: [i for (y, i) in zip(xs, range(len(xs))) if x == y]
        indCountryEntsoe = get_inds(countryList[c], entsoeData['countries'])
    
        finalTx.append([])
        finalTxSummer.append([])
        finalCapacity.append([])
        finalCapacitySummer.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
        finalOutagesBoolSummer.append([])
        finalOutagesCount.append([])
        for i in range(len(countryTxData[c])):
            curYear = countryYearData[i]
            curMonth = countryMonthData[i]
            curDay = countryDayData[i]
            
            curDayIndEntsoe = np.where((entsoeData['years'] == curYear) & (entsoeData['months'] == curMonth) & \
                                 (entsoeData['days'] == curDay))[0]
            
            curDayIndEntsoe = np.intersect1d(curDayIndEntsoe, indCountryEntsoe)
            
            if len(curDayIndEntsoe) > 0:
                perc = []
                for p in curDayIndEntsoe:    
                    perc.append(entsoeData['actualCapacity'][p] / entsoeData['normalCapacity'][p])
                
                finalCapacity[c].append(np.nanmean(perc))
                finalOutagesBool[c].append(1)
                
                if curMonth == 7 or curMonth == 8:
                    finalOutagesBoolSummer[c].append(1)
                    finalCapacitySummer[c].append(np.nanmean(perc))    
            else:
                # 1 here because plant at 100% capacity
                finalCapacity[c].append(1)
                
                # 0 here because no outage
                finalOutagesBool[c].append(0)
                
                if curMonth == 7 or curMonth == 8:
                    finalOutagesBoolSummer[c].append(0)
                    finalCapacitySummer[c].append(1)    
            
            finalOutagesCount[c].append(len(curDayIndEntsoe))
            finalTx[c].append(countryTxData[c,i])
            
            if curMonth == 7 or curMonth == 8:
                finalTxSummer[c].append(countryTxData[c,i])    

        outageInd = np.where(np.array(finalCapacity[c]) < 1)[0]
        finalOutageInds[c].extend(outageInd)
    
    finalTx = np.array(finalTx)
    finalTxSummer = np.array(finalTxSummer)
    finalCapacity = np.array(finalCapacity)
    finalCapacitySummer = np.array(finalCapacitySummer)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesBoolSummer = np.array(finalOutagesBoolSummer)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
    
    d = {'tx':finalTx, 'txSummer':finalTxSummer, \
         'years':countryYearData, 'months':countryMonthData, 'days':countryDayData, \
         'countries':countryList, 'capacity':finalCapacity, 'capacitySummer':finalCapacitySummer, \
         'outagesBool':finalOutagesBool, 'outagesBoolSummer':finalOutagesBoolSummer, 'outagesCount':finalOutagesCount}
    return d



def aggregateEntsoeData(entsoeMatchData):
    # aggregate country entsoe outdata data into single 1d array
    txAll = []
    txAvgAll = []
    qsAll = []
    qsAnomAll = []
    cddAll = []
    capacityAll = []
    outageBoolAll = []
    outageCountAll = []
    
    plantMonths = []
    plantDays = []
    plantIds = []
    plantMeanTemps = []
    # the number to start the IDs at to differentiate from the nuke data
    baseId = 100
    
    for c in range(entsoeMatchData['capacity'].shape[0]):
        inds = np.where((entsoeMatchData['months'] > 6) & (entsoeMatchData['months'] < 9))[0]
    
        curQsAnom = entsoeMatchData['qsAnom'][c,inds]
        curQs = entsoeMatchData['qs'][c,inds]
        curTx = entsoeMatchData['tx'][c,inds]
        curTxAvg = entsoeMatchData['txAvg'][c,inds]
        curCdd = entsoeMatchData['cdd'][c,inds]
        curCapacity = entsoeMatchData['capacity'][c,inds]
        curOutageBool = entsoeMatchData['outagesBool'][c,inds]
        curOutageCount = entsoeMatchData['outagesCount'][c,inds]
    
        # at least one outage reported for this country/plant
        if np.nansum(curOutageCount) > 0:
            txAll.extend(curTx)
            txAvgAll.extend(curTxAvg)
            
            qsAll.extend(curQs)
            qsAnomAll.extend(curQsAnom)
            
            cddAll.extend(curCdd)
            plantMeanTemps.extend([np.nanmean(curTx)]*len(curTx))
            capacityAll.extend(curCapacity)
            outageBoolAll.extend(curOutageBool)
            outageCountAll.extend(normalize(np.array(curOutageCount)))
            plantIds.extend([c+baseId] * len(curTx))
            plantMonths.extend(entsoeMatchData['months'][inds])
            plantDays.extend(entsoeMatchData['days'][inds])
    
    txAll = np.array(txAll)
    txAvgAll = np.array(txAvgAll)
    qsAll = np.array(qsAll)
    qsAnomAll = np.array(qsAnomAll)
    cddAll = np.array(cddAll)
    capacityAll = np.array(capacityAll)
    outageBoolAll = np.array(outageBoolAll)
    outageCountAll = np.array(outageCountAll)
    plantIds = np.array(plantIds)
    plantMonths = np.array(plantMonths)
    plantDays = np.array(plantDays)
    
    d = {'txSummer':txAll, 'txAvgSummer':txAvgAll, 'cddSummer':cddAll, \
         'qsSummer':qsAll, 'qsAnomSummer':qsAnomAll, \
         'capacitySummer':capacityAll, 'outagesBoolSummer':outageBoolAll, \
         'outagesCount':outageCountAll, 'plantMonths':plantMonths, \
         'plantDays':plantDays, 'plantIds':plantIds, 'plantMeanTemps':plantMeanTemps}
    return d


def exportLatLon(entsoeData):
    
    import csv
    uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
    entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
    entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
    
    i = 0
    with open('entsoe-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(entsoeLat)):
            csvWriter.writerow([i, entsoeLat[i], entsoeLon[i]])
    
    