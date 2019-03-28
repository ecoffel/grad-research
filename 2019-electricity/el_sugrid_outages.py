# -*- coding: utf-8 -*-
"""
Created on Mon Mar 25 12:10:41 2019

@author: Ethan
"""

import json
import el_readUSCRN
import el_wet_bulb
import el_cooling_tower_model
import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import glob
import statsmodels.api as sm
import math
import sys
import os

from el_subgrids import subgrids

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

def normalize(v):
    nn = np.where(~np.isnan(v))[0]
    norm = np.linalg.norm(v[nn])
    newv = v.copy()
    if norm == 0: 
       return newv
   
    newv[nn] = newv[nn] / norm
    return newv

monthsList = ['January', 'February', 'March', 'April', 'May', 'June', \
              'July', 'August', 'September', 'October', 'November', 'December']

def getMonth(m):
    return monthsList.index(m)+1


smoothingLen = 15
monthRange = [7,8]

yearsSWPP = []
monthsSWPP = []
daysSWPP = []
outagesSWPP = []
txSWPP = []

print('loading SWPP data...')
for year in range(2016, 2018+1):
    for month in range(1, 13):
        for day in range(1, 32):
            if not os.path.isfile('%s/ecoffel/data/projects/electricity/swpp/swpp_%d_%d_%d.csv' % (dataDir, year, month, day)):
                continue
            
            with open('%s/ecoffel/data/projects/electricity/swpp/swpp_%d_%d_%d.csv' % (dataDir, year, month, day), 'r') as f:
                n = 0
                
                yearsSWPP.append(year)
                monthsSWPP.append(month)
                daysSWPP.append(day)
                
                dailyMeanOutage = []
                for line in f:
                    if n == 0:
                        n += 1
                        continue
                    
                    # on a data row
                    parts = line.split(',')
                    
                    dateStr = parts[0]
                    dateStrParts = dateStr.split()[0].split('/')
                    
                    if int(dateStrParts[0]) == month and int(dateStrParts[1]) == day and int(dateStrParts[2]) == year:
                        dailyMeanOutage.append(float(parts[1].strip()))
                    else:
                        break

                outagesSWPP.append(np.nanmean(np.array(dailyMeanOutage)))

yearsSWPP = np.array(yearsSWPP)
monthsSWPP = np.array(monthsSWPP)
daysSWPP = np.array(daysSWPP)
outagesSWPP = np.array(outagesSWPP)
outagesSWPP = outagesSWPP - pd.rolling_mean(outagesSWPP, smoothingLen)


yearsISNE = []
monthsISNE = []
daysISNE = []
peakLoadISNE = []
capacityISNE = []
outagesISNE = []
txISNE = []

print('loading ISNE data...')
for year in range(2004, 2018+1):
    with open('%s/ecoffel/data/projects/electricity/isne/isne_%d.csv' % (dataDir, year), 'r') as f:
        n = 0
        for line in f:
            
            # on a data row
            parts = line.split(',')
            if parts[1] in monthsList:
                yearsISNE.append(year)
                monthsISNE.append(getMonth(parts[1]))
                daysISNE.append(int(parts[2]))
                
                peakLoadInd = 4
                capacityInd = 5
                outageInd = 8
                if year >= 2014:
                    outageInd = 7
                
                try:
                    peakLoadISNE.append(int(parts[peakLoadInd]))
                except:
                    peakLoadISNE.append(np.nan)
                
                try:
                    capacityISNE.append(int(parts[capacityInd]))
                except:
                    capacityISNE.append(np.nan)
#                    
                try:
                    outagesISNE.append(int(parts[outageInd]))
                except:
                    outagesISNE.append(np.nan)
            
            n += 1

yearsISNE = np.array(yearsISNE)
monthsISNE = np.array(monthsISNE)
daysISNE = np.array(daysISNE)
peakLoadISNE = np.array(peakLoadISNE)-pd.rolling_mean(np.array(peakLoadISNE), smoothingLen)
capacityISNE = np.array(capacityISNE)-pd.rolling_mean(np.array(capacityISNE), smoothingLen)
outagesISNE = np.array(outagesISNE)-pd.rolling_mean(np.array(outagesISNE), smoothingLen)


yearsPJM = []
monthsPJM = []
daysPJM = []
outagesTotalPJM = [[],[],[]]
outagesForcedPJM = [[],[],[]]
txPJM = []

print('loading PJM data...')
for year in range(2015, 2018+1):
    yearsPJMCur = []
    monthsPJMCur = []
    daysPJMCur = []
    outagesTotalPJMCur = [[],[],[]]
    outagesForcedPJMCur = [[],[],[]]
    
    with open('%s/ecoffel/data/projects/electricity/pjm/pjm_%d.csv' % (dataDir, year), 'r') as f:
        n = 0
        regionCnt = 0
        for line in f:
            if n == 0:
                n += 1
                continue
            
            # on a data row
            parts = line.split(',')
            if len(parts[0]) == 0:
                continue
            
            dateParts = parts[0].split()[0].split('/')
            
            monthExt = int(dateParts[0])
            dayExt = int(dateParts[1])
            yearExt = int(dateParts[2])
            
            dateParts = parts[1].split()[0].split('/')
            
            monthFct = int(dateParts[0])
            dayFct = int(dateParts[1])
            yearFct = int(dateParts[2])
            
            if dayExt != dayFct:
                regionCnt = 0
                continue
            
            if regionCnt == 2:
                yearsPJMCur.append(yearExt)
                monthsPJMCur.append(monthExt)
                daysPJMCur.append(dayExt)
            
            outagesTotalPJMCur[regionCnt].append(float(parts[3]))
            outagesForcedPJMCur[regionCnt].append(float(parts[6]))
            regionCnt += 1
            
            n += 1
        
        yearsPJMCur.reverse()
        monthsPJMCur.reverse()
        daysPJMCur.reverse()
        
        outagesTotalPJMCur[0].reverse()
        outagesTotalPJMCur[1].reverse()
        outagesTotalPJMCur[2].reverse()
        
        outagesForcedPJMCur[0].reverse()
        outagesForcedPJMCur[1].reverse()
        outagesForcedPJMCur[2].reverse()
        
        yearsPJM.extend(yearsPJMCur)
        monthsPJM.extend(monthsPJMCur)
        daysPJM.extend(daysPJMCur)
        outagesTotalPJM[0].extend(outagesTotalPJMCur[0])
        outagesTotalPJM[1].extend(outagesTotalPJMCur[1])
        outagesTotalPJM[2].extend(outagesTotalPJMCur[2])
        outagesForcedPJM[0].extend(outagesForcedPJMCur[0])
        outagesForcedPJM[1].extend(outagesForcedPJMCur[1])
        outagesForcedPJM[2].extend(outagesForcedPJMCur[2])
        
yearsPJM = np.array(yearsPJM)
monthsPJM = np.array(monthsPJM)
daysPJM = np.array(daysPJM)

outagesTotalPJM = np.array(outagesTotalPJM)

outagesTotalPJM[0,:] = np.squeeze(np.squeeze(outagesTotalPJM[0,:])-pd.rolling_mean(np.squeeze(outagesTotalPJM[0,:]), smoothingLen))
outagesTotalPJM[1,:] = np.squeeze(np.squeeze(outagesTotalPJM[1,:])-pd.rolling_mean(np.squeeze(outagesTotalPJM[1,:]), smoothingLen))
outagesTotalPJM[2,:] = np.squeeze(np.squeeze(outagesTotalPJM[2,:])-pd.rolling_mean(np.squeeze(outagesTotalPJM[2,:]), smoothingLen))

outagesForcedPJM = np.array(outagesForcedPJM)
outagesForcedPJM[0,:] = outagesForcedPJM[0,:]-pd.rolling_mean(outagesForcedPJM[0,:], smoothingLen)
outagesForcedPJM[1,:] = outagesForcedPJM[1,:]-pd.rolling_mean(outagesForcedPJM[1,:], smoothingLen)
outagesForcedPJM[2,:] = outagesForcedPJM[2,:]-pd.rolling_mean(outagesForcedPJM[2,:], smoothingLen)

stateList = []
with open('subgrid-tx-cpc-2004-2018.csv', 'r') as f:
    i = 0
    for line in f:
        if i > 2:
            parts = line.split(',')
            stateList.append(parts[0])
        i += 1
stateTxData = np.genfromtxt('subgrid-tx-cpc-2004-2018.csv', delimiter=',', skip_header=1)
stateYearData = stateTxData[0,1:]
stateMonthData = stateTxData[1,1:]
stateDayData = stateTxData[2,1:]
stateTxData = stateTxData[3:,1:]

y = []
# add list for current day
for i in range(stateTxData.shape[1]):
    meanTx = 0
    for state in subgrids['ISNE']['states']:
        meanTx += stateTxData[stateList.index(state)-1, i]                                
    if len(np.where((stateYearData[i] == np.array(yearsISNE)) & (stateMonthData[i] == np.array(monthsISNE)) & (stateDayData[i] == np.array(daysISNE)))[0]) > 0:
        txISNE.append(meanTx / len(subgrids['ISNE']['states']))

# add list for current day
for i in range(stateTxData.shape[1]):
    meanTx = 0
    for state in subgrids['PJM']['states']:
        meanTx += stateTxData[stateList.index(state)-1, i]         
    if len(np.where((stateYearData[i] == (np.array(yearsPJM))) & (stateMonthData[i] == np.array(monthsPJM)) & (stateDayData[i] == np.array(daysPJM)))[0]) > 0:                       
        txPJM.append(meanTx / len(subgrids['PJM']['states']))   

for i in range(stateTxData.shape[1]):
    meanTx = 0
    for state in subgrids['SWPP']['states']:
        meanTx += stateTxData[stateList.index(state)-1, i]         
    if len(np.where((stateYearData[i] == np.array(yearsSWPP)) & (stateMonthData[i] == np.array(monthsSWPP)) & (stateDayData[i] == np.array(daysSWPP)))[0]) > 0:                       
        txSWPP.append(meanTx / len(subgrids['SWPP']['states']))   


txISNE = np.array(txISNE)
txPJM = np.array(txPJM)
txSWPP = np.array(txSWPP)
sys.exit()
outagesISNE = normalize(outagesISNE)
outagesPJM = normalize(np.nanmean(outagesTotalPJM,axis=0))
outagesSWPP = normalize(outagesSWPP)


xtotal = []
ytotal = []

summerInds = np.where((monthsSWPP >= monthRange[0]) & (monthsSWPP <= monthRange[1]))[0]

y = outagesSWPP
x = txSWPP

x = x[summerInds]
y = y[summerInds]
nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
x = x[nn]
y = y[nn]

xtotal.extend(x)
ytotal.extend(y)
#hotInds = np.where((x>25))[0]
#x = x[hotInds]
#y = y[hotInds]


#print(np.polyfit(x,y,1))

X = sm.add_constant(x)
model = sm.OLS(y, X).fit() 

z = np.polyfit(x, y, 4)
p = np.poly1d(z)

x1 = 20
x2 = 39

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(x1+1, x2-1), p(range(x1+1, x2-1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([20,40], [0, 0], '--k')
plt.xlim([x1, x2])
plt.xticks(range(x1,x2+1,2))
plt.yticks(np.arange(-.06,.1,.03))
plt.ylim([-.07, .1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized outages', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
#plt.savefig('us-outages-swpp.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)









summerInds = np.where((monthsPJM >= monthRange[0]) | (monthsPJM <= monthRange[1]))[0]

y = outagesPJM
x = txPJM

x = x[summerInds]
y = y[summerInds]
nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
x = x[nn]
y = y[nn]

xtotal.extend(x)
ytotal.extend(y)
#print(np.polyfit(x,y,1))

X = sm.add_constant(x)
model = sm.OLS(y, X).fit() 

z = np.polyfit(x, y, 4)
p = np.poly1d(z)

x1 = 20
x2 = 39

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(x1+1, x2-1), p(range(x1+1, x2-1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([20,40], [0, 0], '--k')
plt.xlim([x1, x2])
plt.xticks(range(x1,x2+1,2))
plt.yticks(np.arange(-.06,.1,.03))
plt.ylim([-.07, .1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized outages', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
#plt.savefig('us-outages-pjm.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)



















summerInds = np.where((monthsISNE >= monthRange[0]) | (monthsISNE <= monthRange[0]))[0]

y = outagesISNE
x = txISNE

x = x[summerInds]
y = y[summerInds]
nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
x = x[nn]
y = y[nn]

xtotal.extend(x)
ytotal.extend(y)
#hotInds = np.where((x>25))[0]
#x = x[hotInds]
#y = y[hotInds]


#print(np.polyfit(x,y,1))

X = sm.add_constant(x)
model = sm.OLS(y, X).fit() 

z = np.polyfit(x, y, 4)
p = np.poly1d(z)

x1 = 20
x2 = 39

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(x1+1, x2-1), p(range(x1+1, x2-1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([10,50], [0, 0], '--k')
plt.xlim([x1, x2])
plt.xticks(range(x1,x2+1,2))
plt.yticks(np.arange(-.06,.1,.03))
plt.ylim([-.07, .1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized outages', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
#plt.savefig('us-outages-isne.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)













