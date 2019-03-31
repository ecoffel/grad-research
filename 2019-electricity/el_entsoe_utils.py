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


def loadEntsoe(dataDir):
    yearsEntsoe = []
    monthsEntsoe = []
    daysEntsoe = []
    countriesEntsoe = []
    actualCapacityEntsoe = []
    normalCapacityEntsoe = []
    for year in range(2015, 2019):
        print('loading entsoe year %d...'%year)
        for month in range(1, 13):
            with open('%s/ecoffel/data/projects/electricity/entsoe/OutagesPU/%d_%d_OutagesPU.csv' % (dataDir, year, month), 'r', encoding='utf-16') as f:
                n = 0
                for line in f:
                    if n == 0:
                        n += 1
                        continue
                    
                    lineParts = line.split('\t')
                    
                    if len(lineParts) < 20:
                        continue
                    
                    if lineParts[8] != 'Forced':
                        continue
                    
                    if 'Hydro' in lineParts[15] or \
                        'hydro' in lineParts[15] or \
                        'Wind' in lineParts[15] or \
                        'wind' in lineParts[15]:
                        continue
                    
                    yearsEntsoe.append(int(lineParts[0]))
                    monthsEntsoe.append(int(lineParts[1]))
                    daysEntsoe.append(int(lineParts[2]))
                    countriesEntsoe.append(getEUCountryCode(lineParts[12]))
                    actualCapacityEntsoe.append(float(lineParts[19]))
                    normalCapacityEntsoe.append(float(lineParts[18]))
                    
    yearsEntsoe = np.array(yearsEntsoe)
    monthsEntsoe = np.array(monthsEntsoe)
    daysEntsoe = np.array(daysEntsoe)
    countriesEntsoe = np.array(countriesEntsoe)
    actualCapacityEntsoe = np.array(actualCapacityEntsoe)
    normalCapacityEntsoe = np.array(normalCapacityEntsoe)
    
    d = {'years':yearsEntsoe, 'months':monthsEntsoe, 'days':daysEntsoe, \
         'countries':countriesEntsoe, 'actualCapacity':actualCapacityEntsoe, \
         'normalCapacity':normalCapacityEntsoe}
    
    return d


def matchEntsoeWx(entsoeData, useEra):
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
    finalOutages = []
    finalOutagesBool = []
    finalOutagesCount = []
    finalOutageInds = []
    
    print('matching entsoe outages with wx...')
    
    for c in range(len(countryList)):
        get_inds = lambda x, xs: [i for (y, i) in zip(xs, range(len(xs))) if x == y]
        indCountryEntsoe = get_inds(countryList[c], entsoeData['countries'])
    
        finalTx.append([])
        finalOutages.append([])
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
                
                finalOutages[c].append(np.nanmean(perc))
                finalOutagesBool[c].append(1)
            else:
                finalOutages[c].append(0)
                finalOutagesBool[c].append(0)
            
            finalOutagesCount[c].append(len(curDayIndEntsoe))
            finalTx[c].append(countryTxData[c,i])

        
        outageInd = np.where(np.array(finalOutages[c]) > 0)[0]
        finalOutageInds[c].extend(outageInd)
    
    finalTx = np.array(finalTx)
    finalOutages = np.array(finalOutages)
    finalOutagesBool = np.array(finalOutagesBool)
    finalOutagesCount = np.array(finalOutagesCount)
    finalOutageInds = np.array(finalOutageInds)
    
    d = {'tx':finalTx, 'years':countryYearData, 'months':countryMonthData, 'days':countryDayData, \
         'countries':countryList, 'outages':finalOutages, 'outagesBool':finalOutagesBool, \
         'outagesCount':finalOutagesCount}
    return d


def aggregateEntsoeData(entsoeMatchData):
    # aggregate country entsoe outdata data into single 1d array
    txAll = []
    outageAll = []
    outageBoolAll = []
    outageCountAll = []
    
    for c in range(entsoeMatchData['outages'].shape[0]):
        inds = np.where((entsoeMatchData['months'] > 6) & (entsoeMatchData['months'] < 9))[0]
    
        curTx = entsoeMatchData['tx'][c,inds]
        curOutage = entsoeMatchData['outages'][c,inds]
        curOutageBool = entsoeMatchData['outagesBool'][c,inds]
        curOutageCount = entsoeMatchData['outagesCount'][c,inds]
    
        # outages reported for this country
        if np.nansum(curOutageCount) > 0:
            txAll.extend(curTx)
            outageAll.extend(curOutage)
            outageBoolAll.extend(curOutageBool)
            outageCountAll.extend(normalize(np.array(curOutageCount)))
    
    txAll = np.array(txAll)
    outageAll = np.array(outageAll)
    outageBoolAll = np.array(outageBoolAll)
    outageCountAll = np.array(outageCountAll)
    
    d = {'tx':txAll, 'outages':outageAll, 'outagesBool':outageBoolAll, \
         'outagesCount':outageCountAll}
    return d
