# -*- coding: utf-8 -*-
"""
Created on Tue Mar 26 15:57:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt 
import numpy as np
import statsmodels.api as sm
import pandas as pd
import math
import sys
import os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

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

yearsEntsoe = []
monthsEntsoe = []
daysEntsoe = []
countriesEntsoe = []
actualCapacityEntsoe = []
normalCapacityEntsoe = []
for year in range(2015, 2019):
    print('loading %d'%year)
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
                
#                if lineParts[8] != 'Forced':
#                    continue
                
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

countryList = []
with open('country-tx-cpc-2015-2018.csv', 'r') as f:
    i = 0
    for line in f:
        if i > 3:
            parts = line.split(',')
            countryList.append(parts[0])
        i += 1
countryTxData = np.genfromtxt('country-tx-cpc-2015-2018.csv', delimiter=',', skip_header=1)
countryYearData = countryTxData[0,1:]
countryMonthData = countryTxData[1,1:]
countryDayData = countryTxData[2,1:]
countryTxData = countryTxData[3:,1:]

if not 'finalTx' in locals():
    finalTx = []
    finalOutages = []
    finalOutagesBool = []
    finalOutagesCount = []
    finalOutageInds = []
    
    for c in range(len(countryList)):
        get_inds = lambda x, xs: [i for (y, i) in zip(xs, range(len(xs))) if x == y]
        indCountryEntsoe = get_inds(countryList[c], countriesEntsoe)
    
        finalTx.append([])
        finalOutages.append([])
        finalOutageInds.append([])
        finalOutagesBool.append([])
        finalOutagesCount.append([])
        for i in range(len(countryTxData[c])):
            curYear = countryYearData[i]
            curMonth = countryMonthData[i]
            curDay = countryDayData[i]
            
            curDayIndEntsoe = np.where((yearsEntsoe == curYear) & (monthsEntsoe == curMonth) & \
                                 (daysEntsoe == curDay))[0]
            
            curDayIndEntsoe = np.intersect1d(curDayIndEntsoe, indCountryEntsoe)
            
            if len(curDayIndEntsoe) > 0:
                finalOutages[c].append(np.nansum(normalCapacityEntsoe[curDayIndEntsoe] - \
                                                 actualCapacityEntsoe[curDayIndEntsoe]))
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
                
    for c in range(finalOutages.shape[0]):
        finalOutages[c,:] = normalize(finalOutages[c,:]-pd.rolling_mean(finalOutages[c,:], 15))


txAll = []
outageAll = []
outageBoolAll = []
outageCountAll = []

for c in range(finalOutages.shape[0]):
    summerInds = np.where((countryMonthData > 6) & (countryMonthData < 9))[0]
#    inds = np.intersect1d(summerInds, finalOutageInds[c])
    
    inds = summerInds
    if len(inds) > 25:
        curTx = finalTx[c,inds]
        curOutage = finalOutages[c,inds]
        curOutageBool = finalOutagesBool[c,inds]
        curOutageCount = finalOutagesCount[c,inds]


#        if c == 13:
#            notOutliers = np.where((curOutage < .1))[0]
#        else:
#            notOutliers = np.where((curOutage < (np.nanmean(curOutage)+2*np.nanstd(curOutage))))[0]
#        
#        curTx = curTx[notOutliers]
#        curOutage = curOutage[notOutliers]
        
#        z = np.polyfit(curTx, curOutage, 1)
        X = sm.add_constant(curTx)
        model = sm.OLS(curOutageBool, X).fit() 
        
        txAll.extend(curTx)
        outageAll.extend(curOutage)
        outageBoolAll.extend(curOutageBool)
        outageCountAll.extend(normalize(np.array(curOutageCount)))
        print('c = %d, country = %s, slope = %0.2f, p = %.02f' % (c, countryList[c], model.params[1]*1000, model.pvalues[1]))
#        plt.figure()
#        plt.scatter(curTx,curOutage)
#        plt.title('c = %s'%countryList[c])
#        plt.draw()
            
X = sm.add_constant(txAll)
model = sm.OLS(outageCountAll, X).fit() 

txAll = np.array(txAll)
outageBoolAll = np.array(outageBoolAll)
outageCountAll = np.array(outageCountAll)

plt.figure()
i = np.where(txAll>20)[0]
plt.scatter(txAll[i], outageBoolAll[i])
z = np.polyfit(txAll[i], outageBoolAll[i], 4)
p = np.poly1d(z)
plt.plot(range(20,45), p(range(20,45)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])

plt.figure()
plt.scatter(txAll[i], outageCountAll[i])
z = np.polyfit(txAll[i], outageCountAll[i], 4)
p = np.poly1d(z)
plt.plot(range(20,45), p(range(20,45)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])

            