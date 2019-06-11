# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 17:49:10 2019

@author: Ethan
"""


import matplotlib.pyplot as plt 
import seaborn as sns
import numpy as np
import statsmodels.api as sm
import pickle
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

plotFigs = True


if not 'eData' in locals():
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)

nukePlants = eData['nukePlantDataAll']
nukeData = eData['nukeAgDataAll']

normalCap = nukePlants['normalCapacity']
cap = nukeData['percCapacity']
mon = nukeData['plantMonthsAll']


meanOutage = []

for m in range(1, 13):
    ind = np.where(mon[0,:] == m)[0]
    meanOutage.append(100-np.array(np.nanmean(cap[:,ind], axis=1)))
meanOutage = np.array(meanOutage)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])

plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([0, 28])
plt.grid(True, alpha=.5)

b = plt.bar(range(1, 13), np.nanmean(meanOutage, axis=1), \
            yerr = np.nanstd(meanOutage, axis=1)/2, error_kw = dict(lw=1.5, capsize=3, capthick=1.5, ecolor=[.25, .25, .25]))
for i in range(len(b)):
    if i == 6 or i == 7:
        b[i].set_color(snsColors[1])
        b[i].set_edgecolor('black')
    else:
        b[i].set_color(snsColors[0])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Mean outage (%)', fontname = 'Helvetica', fontsize=12)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)





mon = nukeData['plantMonthsAll']
tx = nukePlants['tx']
histTempsByMonth = []

for m in range(1, 13):
    ind = np.where(mon[0,:] == m)[0]
    histTempsByMonth.append(np.array(np.nanmean(np.nanmean(tx[:, ind], axis=1))))
histTempsByMonth = np.array(histTempsByMonth)


fig = plt.figure(figsize=(4,2))
plt.xlim([0, 13])
plt.ylim([4, 35])
plt.grid(True, alpha=.5)

plt.plot(list(range(1,13)), histTempsByMonth, '-k', lw=3)
plt.plot(list(range(1,13)), histTempsByMonth+3, '--', lw=1, color=snsColors[1])
plt.plot(list(range(1,13)), histTempsByMonth+4, '-', lw=3, color=snsColors[1])
plt.plot(list(range(1,13)), histTempsByMonth+5, '--', lw=1, color=snsColors[1])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

plt.gca().spines['bottom'].set_visible(False)
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off



#plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Mean temperature ($\degree$C)', fontname = 'Helvetica', fontsize=12)

#x0,x1 = plt.gca().get_xlim()
#y0,y1 = plt.gca().get_ylim()
#plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('temps-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


genData = {}
with open('genData.dat', 'rb') as f:
    genData = pickle.load(f)

tx = genData['txScatter']
gen = genData['genTxScatter']
mon = genData['monthScatter']    

txAll = []
genAll = []
monAll = []

for s in range(tx.shape[0]):
    txAll.extend(tx[s])
    genAll.extend(gen[s])
    monAll.extend(mon[s])

txAll = np.array(txAll)
genAll = np.array(genAll) * 100
monAll = np.array(monAll)
    

genByMonth = []
for m in range(1, 13):    
    ind = np.where(monAll == m)[0]
    genByMonth.append(np.array(np.nanmean(genAll[ind])))
genByMonth = np.array(genByMonth)
genByMonth = 1 + ((genByMonth - np.nanmean(genByMonth)) / (np.nanmax(genByMonth) - np.nanmin(genByMonth)))


plt.figure(figsize=(4,1))
plt.xlim([0, 13])
plt.ylim([.5, 1.7])
plt.grid(True, alpha=.5)

plt.plot(list(range(1,13)), genByMonth, '-k', lw=3)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(10)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(10)

plt.gca().spines['bottom'].set_visible(False)
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off


#plt.xlabel('Month', fontname = 'Helvetica', fontsize=12)
#plt.ylabel('Generation', fontname = 'Helvetica', fontsize=12)

if plotFigs:
    plt.savefig('gen-by-month-wide.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)


sys.exit()


lats = np.array([float(x) for x in nukePlants['plantLats']])
temps = np.nanmean(nukePlants['txSummer'], axis=1)
plantCaps = 100-nukePlants['capacitySummer']

X = sm.add_constant(temps)
mdl = sm.OLS(np.nanmean(plantCaps,axis=1),X).fit()

z = np.polyfit(temps, np.nanmean(plantCaps,axis=1), 1)
p = np.poly1d(z)

xd = np.arange(24, 37)

plt.figure(figsize=(4,4))
plt.xlim([21, 40])
plt.ylim([-.2, 20])
plt.grid(True, alpha=.5)

plt.scatter(temps,np.nanmean(plantCaps,axis=1), s=50, c='gray', edgecolors='black')
plt.plot(xd, p(xd), '--', color=snsColors[1], linewidth=3)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Mean summer Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean summer outage (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_yticks(range(0,21,4))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-mean-temp.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



plantYears = nukePlants['plantYears']
plantMonths = nukePlants['plantMonths']

meanOutageYear = []

for y in np.unique(plantYears[0]):
    indYr = np.where((plantYears[0] == y) & ((plantMonths[0] == 7) | (plantMonths[0] == 8)))[0]
    meanOutageYear.append(100-np.array(np.nanmean(cap[:,indYr], axis=1)))
meanOutageYear = np.array(meanOutageYear)



plt.figure(figsize=(4,4))
plt.xlim([0, 13])
plt.ylim([0, 12.25])
plt.grid(True, alpha=.5)

plt.plot(range(1,12+1), np.nanmean(meanOutageYear, axis=1), '-', color='gray', linewidth=5)
plt.errorbar(range(1,12+1), np.nanmean(meanOutageYear, axis=1), yerr=np.nanstd(meanOutageYear, axis=1)/2, lw=0, elinewidth=1.5, capsize=3, capthick=1.5, ecolor=[.25, .25, .25])
for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Year', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean summer outage (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks(range(1,13))
xl = ['2007', '', '', '', \
      '2011', '', '', '2014', \
      '', '', '', '2018']
plt.gca().set_xticklabels(xl)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-year.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



X = sm.add_constant(normalCap)
mdl = sm.OLS(np.nanmean(plantCaps,axis=1),X).fit()

z = np.polyfit(normalCap, np.nanmean(plantCaps,axis=1), 1)
p = np.poly1d(z)

xd = np.arange(500, 3900)

plt.figure(figsize=(4,4))
plt.xlim([0, 4500])
plt.ylim([-.2, 20])
plt.grid(True, alpha=.5)

plt.scatter(normalCap, np.nanmean(plantCaps,axis=1), s=50, c='gray', edgecolors='black')
plt.plot(xd, p(xd), '--', color=snsColors[1], linewidth=3)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Plant design capacity (MW)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean summer outage (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_yticks(range(0,21,4))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('outages-by-plant-design-capacity.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)



plt.show()