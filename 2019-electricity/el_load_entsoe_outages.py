# -*- coding: utf-8 -*-
"""
Created on Tue Mar 26 15:57:40 2019

@author: Ethan
"""

import matplotlib.pyplot as plt 
import numpy as np
import statsmodels.api as sm
import el_entsoe_utils

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = True
plotFigs = False


entsoeData = el_entsoe_utils.loadEntsoe(dataDir)
entsoeMatchData = el_entsoe_utils.matchEntsoeWx(entsoeData, useEra=True)
entsoeAgData = el_entsoe_utils.aggregateEntsoeData(entsoeMatchData)

# determine breakpoint in data
for i in range(25,36):
    ind1 = np.where(entsoeAgData['tx']<i)[0]
    ind2 = np.where(entsoeAgData['tx']>i)[0]
    
    if len(ind1) < 10 or len(ind2) < 10: continue
    
    mdlX1 = sm.add_constant(entsoeAgData['tx'][ind1])
    mdl1 = sm.OLS(entsoeAgData['outagesBool'][ind1], mdlX1).fit()
    
    mdlX2 = sm.add_constant(entsoeAgData['tx'][ind2])
    mdl2 = sm.OLS(entsoeAgData['outagesBool'][ind2], mdlX2).fit()
    print('t = %d, slope1 = %.6f, p1 = %.2f, slope1 = %.6f, p1 = %.2f'%(i,mdl1.params[1], mdl1.pvalues[1], \
                                                                        mdl2.params[1], mdl2.pvalues[1]))


x = entsoeAgData['tx']
y = 100-(entsoeAgData['outages']*100)

thresh = 27

if useEra:
    thresh = 27

ind1 = np.where(x<thresh)[0]
ind2 = np.where(x>thresh)[0]

z1 = np.polyfit(x[ind1], y[ind1], 1)
p1 = np.poly1d(z1)

z2 = np.polyfit(x[ind2], y[ind2], 1)
p2 = np.poly1d(z2)

plt.figure(figsize=(3,3))
plt.scatter(x, y, s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(10, thresh+1), p1(range(10, thresh+1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot(range(thresh, 39), p2(range(thresh, 39)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([thresh, thresh], [-10, 100], '--k')
plt.xlim([10, 40])
plt.xticks(range(10, 40+1, 4))
plt.ylim([0, 105])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
if plotFigs:
    if useEra:
        plt.savefig('entsoe-outages-era.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
    else:
        plt.savefig('entsoe-outages-cpc.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)




binnedOutageData = []
binnedOutageMeans = []
binnedTx = []

binstep = 2
bin_x1 = 12
bin_x2 = 36
for c in range(len(entsoeMatchData['countries'])):
    binnedOutageData.append([])
    for t in range(bin_x1, bin_x2, binstep):
        tempInds = np.where((entsoeMatchData['tx'][c] >= t) & (entsoeMatchData['tx'][c] < t+binstep))[0]
        binnedOutageData[c].append(np.nanmean(entsoeMatchData['outagesBool'][c, tempInds]))
binnedOutageData = np.array(binnedOutageData)

for t in range(bin_x1, bin_x2, binstep):
    tempInds = np.where((entsoeAgData['tx'] >= t) & (entsoeAgData['tx'] < t+binstep))[0]
    if len(tempInds) > 0:
        binnedOutageMeans.append(np.nanmean(entsoeAgData['outagesBool'][tempInds])*100)
        binnedTx.append(t)
    else:
        binnedOutageMeans.append(np.nan)
        


z = np.polyfit(binnedTx, binnedOutageMeans, 5)
p = np.poly1d(z)

plt.figure(figsize=(3,3))
plt.bar(range(bin_x1, bin_x2, binstep), binnedOutageMeans, yerr = np.nanstd(binnedOutageData, axis=0)*100/2, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], width = 2, align = 'edge', \
        error_kw=dict(lw=2, capsize=3, capthick=2), ecolor = [.25, .25, .25])
plt.plot(range(13, 37), p(range(12, 36)), "--", linewidth = 2, color = [234/255., 49/255., 49/255.])
plt.xlim([11, 37])
plt.ylim([0, 35])

plt.gca().set_xticks(range(12,40,4))
plt.gca().set_yticks(range(0,34,5))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plants with outages (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
if plotFigs:
    if useEra:
        plt.savefig('entsoe-perc-plants-with-outages-era.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
    else:
        plt.savefig('entsoe-perc-plants-with-outages-cpc.epc', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
