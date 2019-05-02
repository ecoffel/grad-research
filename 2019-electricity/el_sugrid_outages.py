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


useEra = True
plotFigs = False

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
#outagesForcedPJM[0,:] = outagesForcedPJM[0,:]-pd.rolling_mean(outagesForcedPJM[0,:], smoothingLen)
#outagesForcedPJM[1,:] = outagesForcedPJM[1,:]-pd.rolling_mean(outagesForcedPJM[1,:], smoothingLen)
#outagesForcedPJM[2,:] = outagesForcedPJM[2,:]-pd.rolling_mean(outagesForcedPJM[2,:], smoothingLen)

stateList = []

fileName = 'subgrid-tx-cpc-2004-2018.csv'
if useEra:
    fileName = 'subgrid-tx-era-2004-2018.csv'
    
with open(fileName, 'r') as f:
    i = 0
    for line in f:
        if i > 2:
            parts = line.split(',')
            stateList.append(parts[0])
        i += 1
stateTxData = np.genfromtxt(fileName, delimiter=',', skip_header=1)
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

outagesPJMTotal = []
outagesPJMTotal.extend(outagesForcedPJM[0,:])
outagesPJMTotal.extend(outagesForcedPJM[1,:])
outagesPJMTotal.extend(outagesForcedPJM[2,:])
outagesPJMTotal = np.array(outagesPJMTotal)

txPJMTotal = []
txPJMTotal.extend(txPJM)
txPJMTotal.extend(txPJM)
txPJMTotal.extend(txPJM)
txPJMTotal = np.array(txPJMTotal)
txPJM = txPJMTotal

outagesISNE = normalize(outagesISNE)
outagesPJM = normalize(outagesPJMTotal)
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



binstep = 4
bin_y1 = 20
bin_y2 = 40

bincounts = []
for t in range(bin_y1, bin_y2, binstep):
    bincounts.append(len(x[(x >= t) & (x <= t+binstep)]))


plt.figure(figsize=(6,1))
plt.xlim([bin_y1, bin_y2])
#plt.ylim([0, 1])

plt.bar(range(bin_y1, bin_y2, binstep), bincounts, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], width = binstep, align = 'edge', \
        zorder=0)

plt.gca().set_xticks([])
plt.gca().set_xticklabels([])
plt.gca().set_yticks([0, 30, 60])
plt.gca().set_yticklabels(['0', '30', '60'])

plt.gca().set_yticks([])
plt.gca().set_yticklabels([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

if plotFigs:
    plt.savefig('outage-hist-swpp-era.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)




xtotal.extend(x)
ytotal.extend(y)
#hotInds = np.where((x>25))[0]
#x = x[hotInds]
#y = y[hotInds]


#print(np.polyfit(x,y,1))

X = sm.add_constant(x)
model = sm.OLS(y, X).fit() 

thresh = 33
p_xlim1 = 24
p_xlim2 = 39
if useEra:
    thresh = 32

ind1 = np.where(x<thresh)[0]
ind2 = np.where(x>thresh)[0]

z1 = np.polyfit(x[ind1], y[ind1], 1)
p1 = np.poly1d(z1)

z2 = np.polyfit(x[ind2], y[ind2], 1)
p2 = np.poly1d(z2)

x1 = 20
x2 = 40

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(p_xlim1, thresh+1), p1(range(p_xlim1, thresh+1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot(range(thresh, p_xlim2), p2(range(thresh, p_xlim2)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([thresh, thresh], [-1, 1], '--k')
plt.plot([20,40], [0, 0], '--k')
plt.xlim([x1, x2])
plt.xticks(range(x1,x2+1,4))
plt.yticks(np.arange(-.06,.1,.03))
plt.ylim([-.12, .1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized outages', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
if plotFigs:
    plt.savefig('us-outages-swpp.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)

print('SWPP ----------------------------')

xtotal = np.array(xtotal)
ytotal = np.array(ytotal)
for i in range(30,37):
    ind1 = np.where(xtotal<i)[0]
    ind2 = np.where(xtotal>i)[0]
    
    if len(ind1) < 10 or len(ind2) < 10: continue
    
    mdlX1 = sm.add_constant(xtotal[ind1])
    mdl1 = sm.OLS(ytotal[ind1], mdlX1).fit()
    
    mdlX2 = sm.add_constant(xtotal[ind2])
    mdl2 = sm.OLS(ytotal[ind2], mdlX2).fit()
    print('t = %d, slope1 = %.6f, p1 = %.2f, slope1 = %.6f, p1 = %.2f'%(i,mdl1.params[1], mdl1.pvalues[1], \
                                                                        mdl2.params[1], mdl2.pvalues[1]))





summerInds = np.where((monthsPJM >= monthRange[0]) & (monthsPJM <= monthRange[1]))[0]

y = outagesPJM
x = txPJM

x = x[summerInds]
y = y[summerInds]
nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
x = x[nn]
y = y[nn]



binstep = 4
bin_y1 = 20
bin_y2 = 40

bincounts = []
for t in range(bin_y1, bin_y2, binstep):
    bincounts.append(len(x[(x >= t) & (x <= t+binstep)]))


plt.figure(figsize=(6,1))
plt.xlim([bin_y1, bin_y2])
#plt.ylim([0, 1])

plt.bar(range(bin_y1, bin_y2, binstep), bincounts, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], width = binstep, align = 'edge', \
        zorder=0)

plt.gca().set_xticks([])
plt.gca().set_xticklabels([])
plt.gca().set_yticks([0, 30, 60])
plt.gca().set_yticklabels(['0', '30', '60'])

plt.gca().set_yticks([])
plt.gca().set_yticklabels([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

if plotFigs:
    plt.savefig('outage-hist-pjm-era.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)




thresh = 31
p_xlim1 = 24
p_xlim2 = 35
if useEra:
    thresh = 29
    p_xlim1 = 23
    p_xlim2 = 33

ind1 = np.where(x<thresh)[0]
ind2 = np.where(x>thresh)[0]

z1 = np.polyfit(x[ind1], y[ind1], 1)
p1 = np.poly1d(z1)

z2 = np.polyfit(x[ind2], y[ind2], 1)
p2 = np.poly1d(z2)


x1 = 20
x2 = 40

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(p_xlim1, thresh+1), p1(range(p_xlim1, thresh+1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot(range(thresh, p_xlim2), p2(range(thresh, p_xlim2)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([thresh, thresh], [-1, 1], '--k')
plt.plot([20,40], [0, 0], '--k')
plt.xlim([x1, x2])
plt.xticks(range(x1,x2+1,4))
plt.yticks(np.arange(-.06,.1,.03))
plt.ylim([-.12, .1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized outages', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
if plotFigs:
    plt.savefig('us-outages-pjm.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)


print('PJM ----------------------------')
xtotal = np.array(x)
ytotal = np.array(y)
for i in range(26,34):
    ind1 = np.where(xtotal<i)[0]
    ind2 = np.where(xtotal>i)[0]

    if len(ind1) < 10 or len(ind2) < 10: continue

    mdlX1 = sm.add_constant(xtotal[ind1])
    mdl1 = sm.OLS(ytotal[ind1], mdlX1).fit()
    
    mdlX2 = sm.add_constant(xtotal[ind2])
    mdl2 = sm.OLS(ytotal[ind2], mdlX2).fit()
    print('t = %d, slope1 = %.6f, p1 = %.2f, slope1 = %.6f, p1 = %.2f'%(i,mdl1.params[1], mdl1.pvalues[1], \
                                                                        mdl2.params[1], mdl2.pvalues[1]))
















summerInds = np.where((monthsISNE >= monthRange[0]) & (monthsISNE <= monthRange[0]))[0]

y = outagesISNE
x = txISNE

x = x[summerInds]
y = y[summerInds]
nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
x = x[nn]
y = y[nn]




binstep = 4
bin_y1 = 20
bin_y2 = 40

bincounts = []
for t in range(bin_y1, bin_y2, binstep):
    bincounts.append(len(x[(x >= t) & (x <= t+binstep)]))


plt.figure(figsize=(6,1))
plt.xlim([bin_y1, bin_y2])
#plt.ylim([0, 1])

plt.bar(range(bin_y1, bin_y2, binstep), bincounts, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], width = binstep, align = 'edge', \
        zorder=0)

plt.gca().set_xticks([])
plt.gca().set_xticklabels([])
plt.gca().set_yticks([0, 30, 60])
plt.gca().set_yticklabels(['0', '30', '60'])

plt.gca().set_yticks([])
plt.gca().set_yticklabels([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

if plotFigs:
    plt.savefig('outage-hist-isne-era.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)




#print(np.polyfit(x,y,1))

X = sm.add_constant(x)
model = sm.OLS(y, X).fit() 

thresh = 30
p_xlim1 = 20
p_xlim2 = 35
if useEra:
    thresh = 28
    p_xlim1 = 20
    p_xlim2 = 32

ind1 = np.where(x<thresh)[0]
ind2 = np.where(x>thresh)[0]


z1 = np.polyfit(x[ind1], y[ind1], 1)
p1 = np.poly1d(z1)

z2 = np.polyfit(x[ind2], y[ind2], 1)
p2 = np.poly1d(z2)

x1 = 20
x2 = 40

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(p_xlim1, thresh+1), p1(range(p_xlim1, thresh+1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot(range(thresh, p_xlim2), p2(range(thresh, p_xlim2)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([thresh, thresh], [-1, 1], '--k')
plt.plot([10,50], [0, 0], '--k')
plt.xlim([x1, x2])
plt.xticks(range(x1,x2+1,4))
plt.yticks(np.arange(-.06,.1,.03))
plt.ylim([-.12, .1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized outages', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
if plotFigs:
    plt.savefig('us-outages-isne.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)


print('ISNE ----------------------------')
xtotal = np.array(x)
ytotal = np.array(y)
for i in range(12,34):
    ind1 = np.where(xtotal<i)[0]
    ind2 = np.where(xtotal>i)[0]
    
    if len(ind1) < 10 or len(ind2) < 10: continue
    
    mdlX1 = sm.add_constant(xtotal[ind1])
    mdl1 = sm.OLS(ytotal[ind1], mdlX1).fit()
    
    mdlX2 = sm.add_constant(xtotal[ind2])
    mdl2 = sm.OLS(ytotal[ind2], mdlX2).fit()
    print('t = %d, slope1 = %.6f, p1 = %.2f, slope1 = %.6f, p1 = %.2f'%(i,mdl1.params[1], mdl1.pvalues[1], \
                                                                        mdl2.params[1], mdl2.pvalues[1]))










