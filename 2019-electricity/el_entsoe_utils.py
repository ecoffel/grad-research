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

def loadEntsoe(dataDir):
    
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


def matchEntsoeWxPlantSpecific(entsoeData, useEra):
    fileName = 'entsoe-tx-cpc.csv'
    if useEra:
        fileName = 'entsoe-tx-era.csv'
        
    tx = np.genfromtxt(fileName, delimiter=',')
    
    txYears = tx[0,:]
    txMonths = tx[1,:]
    txDays = tx[2,:]
    tx = tx[3:,:]
    
    finalTx = []
    finalCapacity = []
    finalOutagesBool = []
    finalOutagesCount = []
    finalOutageInds = []
    
    print('matching entsoe outages with wx...')
    
    uniquePlants = list(set(entsoeData['names']))
    
    # loop over each power plant
    for c in range(len(uniquePlants)):
    
        finalTx.append([])
        finalCapacity.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
        finalOutagesCount.append([])
        
        plantInds = [k for k in range(len(entsoeData['names'])) if entsoeData['names'][k] == uniquePlants[c]]
        
        # and each day
        for i in range(tx.shape[1]):
            curYear = txYears[i]
            curMonth = txMonths[i]
            curDay = txDays[i]
            
            curDayIndEntsoe = np.where((entsoeData['years'] == curYear) & (entsoeData['months'] == curMonth) & \
                                 (entsoeData['days'] == curDay))[0]
            
            curDayIndEntsoe = np.intersect1d(curDayIndEntsoe, plantInds)
            
            if len(curDayIndEntsoe) > 0:
                perc = []
                for p in curDayIndEntsoe:    
                    perc.append(entsoeData['actualCapacity'][p] / entsoeData['normalCapacity'][p])
                
                finalCapacity[c].append(np.nanmean(perc))
                finalOutagesBool[c].append(1)
            else:
                # 1 here because plant at 100% capacity
                finalCapacity[c].append(1)
                
                # 0 here because no outage
                finalOutagesBool[c].append(0)
            
            finalOutagesCount[c].append(len(curDayIndEntsoe))
            finalTx[c].append(tx[c,i])

        
        outageInd = np.where(np.array(finalCapacity[c]) < 1)[0]
        finalOutageInds[c].extend(outageInd)
    
    finalTx = np.array(finalTx)
    finalCapacity = np.array(finalCapacity)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
    
    d = {'tx':finalTx, 'years':txYears, 'months':txMonths, 'days':txDays, \
         'countries':entsoeData['countries'][plantInds[0]], 'capacity':finalCapacity, 'outagesBool':finalOutagesBool, \
         'outagesCount':finalOutagesCount}
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
    finalCapacity = []
    finalOutagesBool = []
    finalOutagesCount = []
    finalOutageInds = []
    
    print('matching entsoe outages with wx...')
    
    for c in range(len(countryList)):
        get_inds = lambda x, xs: [i for (y, i) in zip(xs, range(len(xs))) if x == y]
        indCountryEntsoe = get_inds(countryList[c], entsoeData['countries'])
    
        finalTx.append([])
        finalCapacity.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
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
            else:
                # 1 here because plant at 100% capacity
                finalCapacity[c].append(1)
                
                # 0 here because no outage
                finalOutagesBool[c].append(0)
            
            finalOutagesCount[c].append(len(curDayIndEntsoe))
            finalTx[c].append(countryTxData[c,i])

        
        outageInd = np.where(np.array(finalCapacity[c]) < 1)[0]
        finalOutageInds[c].extend(outageInd)
    
    finalTx = np.array(finalTx)
    finalCapacity = np.array(finalCapacity)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
    
    d = {'tx':finalTx, 'years':countryYearData, 'months':countryMonthData, 'days':countryDayData, \
         'countries':countryList, 'capacity':finalCapacity, 'outagesBool':finalOutagesBool, \
         'outagesCount':finalOutagesCount}
    return d





def aggregateEntsoeDataPlantSpecific(entsoeMatchDataPlant):
    # aggregate country entsoe outdata data into single 1d array
    txAll = []
    capacityAll = []
    outageBoolAll = []
    outageCountAll = []
    
    for c in range(entsoeMatchData['capacity'].shape[0]):
        inds = np.where((entsoeMatchData['months'] > 6) & (entsoeMatchData['months'] < 9))[0]
    
        curTx = entsoeMatchData['tx'][c,inds]
        curCapacity = entsoeMatchData['capacity'][c,inds]
        curOutageBool = entsoeMatchData['outagesBool'][c,inds]
        curOutageCount = entsoeMatchData['outagesCount'][c,inds]
    
        # outages reported for this country
        if np.nansum(curOutageCount) > 0:
            txAll.extend(curTx)
            capacityAll.extend(curCapacity)
            outageBoolAll.extend(curOutageBool)
            outageCountAll.extend(normalize(np.array(curOutageCount)))
    
    txAll = np.array(txAll)
    capacityAll = np.array(capacityAll)
    outageBoolAll = np.array(outageBoolAll)
    outageCountAll = np.array(outageCountAll)
    
    d = {'tx':txAll, 'capacity':capacityAll, 'outagesBool':outageBoolAll, \
         'outagesCount':outageCountAll}
    return d


def aggregateEntsoeData(entsoeMatchData):
    # aggregate country entsoe outdata data into single 1d array
    txAll = []
    capacityAll = []
    outageBoolAll = []
    outageCountAll = []
    
    for c in range(entsoeMatchData['capacity'].shape[0]):
        inds = np.where((entsoeMatchData['months'] > 6) & (entsoeMatchData['months'] < 9))[0]
    
        curTx = entsoeMatchData['tx'][c,inds]
        curCapacity = entsoeMatchData['capacity'][c,inds]
        curOutageBool = entsoeMatchData['outagesBool'][c,inds]
        curOutageCount = entsoeMatchData['outagesCount'][c,inds]
    
        # outages reported for this country
        if np.nansum(curOutageCount) > 0:
            txAll.extend(curTx)
            capacityAll.extend(curCapacity)
            outageBoolAll.extend(curOutageBool)
            outageCountAll.extend(normalize(np.array(curOutageCount)))
    
    txAll = np.array(txAll)
    capacityAll = np.array(capacityAll)
    outageBoolAll = np.array(outageBoolAll)
    outageCountAll = np.array(outageCountAll)
    
    d = {'tx':txAll, 'capacity':capacityAll, 'outagesBool':outageBoolAll, \
         'outagesCount':outageCountAll}
    return d


def exportLatLon(entsoeData):
    import csv
    i = 0
    with open('entsoe-lat-lon.csv', 'w') as f:
        csvWriter = csv.writer(f)    
        for i in range(len(entsoeData['lats'])):
            csvWriter.writerow([i, entsoeData['lats'][i], entsoeData['lons'][i]])
    
    