# -*- coding: utf-8 -*-
"""
Created on Sun Mar 31 16:58:58 2019

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 11:25:12 2019

@author: Ethan
"""


import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import statsmodels.api as sm
from sklearn.linear_model import LogisticRegression
import seaborn as sns
import el_entsoe_utils
import el_nuke_utils
import sys

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = True
plotFigs = True

outageDaysOnly = True


def bootstrap_resample(X, n=None):
    """ Bootstrap resample an array_like
    Parameters
    ----------
    X : array_like
      data to resample
    n : int, optional
      length of resampled array, equal to len(X) if n==None
    Results
    -------
    returns X_resamples
    """
    if n == None:
        n = len(X)
        
    resample_i = np.floor(np.random.rand(n)*len(X)).astype(int)
    return resample_i

entsoeData = el_entsoe_utils.loadEntsoe(dataDir)
entsoePlantData = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, useEra=useEra)
#entsoeMatchData = el_entsoe_utils.matchEntsoeWx(entsoeData, useEra=useEra)
entsoeAgData = el_entsoe_utils.aggregateEntsoeData(entsoePlantData)

nukeData = el_nuke_utils.loadNukeData(dataDir)
nukeTx, nukeTxIds = el_nuke_utils.loadWxData(nukeData, useEra=useEra)
nukeAgData = el_nuke_utils.accumulateNukeWxData(nukeData, nukeTx, nukeTxIds)


xtotal = []
xtotal.extend(nukeAgData['txSummer'])
xtotal.extend(entsoeAgData['tx'])
xtotal = np.array(xtotal)

ytotal = []
ytotal.extend(nukeAgData['capacitySummer'])
ytotal.extend(100*entsoeAgData['capacity'])
ytotal = np.array(ytotal)



xtotalBool = []
xtotalBool.extend(nukeAgData['txSummer'])
xtotalBool.extend(entsoeAgData['tx'])
xtotalBool = np.array(xtotalBool)

ytotalBool = []
ytotalBool.extend(nukeAgData['outagesBool'])
ytotalBool.extend(entsoeAgData['outagesBool'])
ytotalBool = np.array(ytotalBool)




# determine breakpoint in data
#for i in range(20,35):
#    ind1 = np.where(xtotal<i)[0]
#    ind2 = np.where(xtotal>i)[0]
#    
#    if len(ind1) < 10 or len(ind2) < 10: continue
#    
#    mdlX1 = sm.add_constant(xtotal[ind1])
#    mdl1 = sm.OLS(ytotal[ind1], mdlX1).fit()
#    
#    mdlX2 = sm.add_constant(xtotal[ind2])
#    mdl2 = sm.OLS(ytotal[ind2], mdlX2).fit()
#    print('t = %d, slope1 = %.6f, p1 = %.2f, slope1 = %.6f, p1 = %.2f'%(i,mdl1.params[1], mdl1.pvalues[1], \
#                                                                        mdl2.params[1], mdl2.pvalues[1]))



indOutages = np.where(ytotal<100)

if outageDaysOnly:
    df = pd.DataFrame({'x':xtotal[indOutages], 'y':ytotal[indOutages]})
else:
    df = pd.DataFrame({'x':xtotal, 'y':ytotal})


plt.figure(figsize=(4,4))
plt.xlim([20,44])
plt.ylim([-25, 105])
sns.regplot(x='x', y='y', data=df, order=3, \
            scatter_kws={"color": [.5, .5, .5], "facecolor":[.75, .75, .75], "s":10, 'alpha':.25}, \
            line_kws={"color": [234/255., 49/255., 49/255.]})

sns.regplot(x='x', y='y', data=df, order=1, scatter=False, \
            line_kws={"color": [244/255., 153/255., 34/255.]})

if outageDaysOnly:
    plt.xlim([20, 44])
    sns.regplot(x='x', y='y', data=df, lowess=True, scatter=False, \
                line_kws={"color": [34/255., 171/255., 244/255.]})


plt.xlim([19,45])
plt.ylim([-25, 105])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica') 
    tick.label.set_fontsize(14)

plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks(range(20,45,4))
plt.gca().set_yticks(range(0,101,20))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

#plt.title('July - August', fontname = 'Helvetica', fontsize=16)
if plotFigs:
    if outageDaysOnly:
        plt.savefig('nuke-eu-cap-reduction-outage-days.png', format='png', dpi=300, bbox_inches = 'tight', pad_inches = 0)
    else:
        plt.savefig('nuke-eu-cap-reduction-all-days.png', format='png', dpi=300, bbox_inches = 'tight', pad_inches = 0)



binstep = 4
bin_x1 = 20
bin_x2 = 44


bincounts = []
for t in range(bin_x1, bin_x2, binstep):
    if outageDaysOnly:
        bincounts.append(len(xtotal[(ytotal < 100) & (xtotal >= t) & (xtotal < t+binstep)]))
    else:
        bincounts.append(len(xtotal[(xtotal >= t) & (xtotal < t+binstep)]))


# plot hist of days in each temp bin
plt.figure(figsize=(6,1))
plt.xlim([19, 45])
#plt.ylim([0, 1])

plt.bar(range(bin_x1, bin_x2, binstep), bincounts, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], width = binstep, align = 'edge', \
        zorder=0)

plt.gca().set_xticks([])
plt.gca().set_xticklabels([])
if outageDaysOnly:
    plt.gca().set_yticks([0, 1500, 3000])
    plt.gca().set_yticklabels(['0', '1.5K', '3K'])
else:
    plt.gca().set_yticks([0, 10000, 20000])
    plt.gca().set_yticklabels(['0', '10K', '20K'])

plt.gca().set_yticks([])
plt.gca().set_yticklabels([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

if plotFigs:
    if outageDaysOnly:
        plt.savefig('temp-day-hist-only-outages-era.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
    else:
        plt.savefig('temp-day-hist-all-days-era.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)




dfLogistic = pd.DataFrame({'x':xtotalBool, 'y':ytotalBool})

binnedOutageData = []
binnedTx = []

binstep = 4
bin_x1 = 20
bin_x2 = 44
for i in range(entsoePlantData['tx'].shape[0]):
    binnedOutageData.append([])
    for t in range(bin_x1, bin_x2, binstep):
        tempInds = np.where((entsoePlantData['tx'][i] >= t) & (entsoePlantData['tx'][i] < t+binstep))[0]
        if len(tempInds) > 0:
            binnedOutageData[i].append(np.nanmean(entsoePlantData['outagesBool'][i, tempInds]))
        else:
            binnedOutageData[i].append(np.nan)


for i in range(nukeAgData['percCapacity'].shape[0]):
    binnedOutageData.append([])
    
    y = nukeAgData['percCapacity'][i]
    x = nukeTx[i,1:]

    if len(y) == len(x):
        y = y[nukeAgData['summerInds']]
        x = x[nukeAgData['summerInds']]
        nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
        
        # convert to boolean: 0 = no outage, > 0 = outage
        y = 100-y[nn]
        x = x[nn]
        y[y>0] = 100
        
        for t in range(bin_x1, bin_x2, binstep):
            tempInds = np.where((x >= t) & (x < t+binstep))[0]
            if len(tempInds) > 0:
                binnedOutageData[-1].append(np.nanmean(y[tempInds]))
            else:
                binnedOutageData[-1].append(np.nan)

binnedOutageData = np.array(binnedOutageData)
binnedOutageData = binnedOutageData / 100


boxy = []
boxyMeans = []
for c in range(binnedOutageData.shape[1]):
    boxy.append([])
    for i in range(binnedOutageData.shape[0]):
        if not np.isnan(binnedOutageData[i, c]):
            boxy[-1].append(binnedOutageData[i, c])
    boxyMeans.append(np.mean(boxy[-1]))


z = np.polyfit(range(bin_x1, bin_x2, binstep), np.nanmean(binnedOutageData, axis=0), 3)
p = np.poly1d(z)

plt.figure(figsize=(4,4))
#plt.bar(range(bin_x1, bin_x2, binstep), np.nanmean(binnedOutageData, axis=0),\
#        yerr = np.nanstd(binnedOutageData, axis=0)/2, \
#        facecolor = [.75, .75, .75], \
#        edgecolor = [0, 0, 0], width = 2, align = 'edge', \
#        error_kw=dict(lw=2, capsize=3, capthick=2), ecolor = [.25, .25, .25], zorder=0)


medianprops = dict(linestyle='-', linewidth=2, color='black')
meanpointprops = dict(marker='D', markeredgecolor='black',
                      markerfacecolor='red')
bplot = plt.boxplot(boxy, positions = range(22, 44, 4), showmeans=True, widths=4, sym='.', patch_artist=True, \
                    medianprops=medianprops, meanprops=meanpointprops, zorder=0)

colors = ['lightgray']
for patch in bplot['boxes']:
    patch.set_facecolor([.75, .75, .75])

    

plt.xlim([20, 44])
sns.regplot(x='x', y='y', data=dfLogistic, logistic=True, scatter=False, \
            line_kws={"color": [234/255., 49/255., 49/255.]})

#plt.plot(range(21, 44), p(range(20, 43)), "--", linewidth = 2, color = [234/255., 49/255., 49/255.])
plt.xlim([19, 45])
plt.ylim([0, .55])

plt.gca().set_xticks(range(20,45,4))
plt.gca().set_xticklabels(range(20,45,4))
plt.gca().set_yticks(np.arange(0,1.1,.20))
plt.gca().set_yticklabels(range(0,110,20))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily max temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plants with outages (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))
if plotFigs:
    if useEra:
        plt.savefig('nuke-eu-perc-plants-with-outages-era.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
    else:
        plt.savefig('nuke-eu-perc-plants-with-outages-cpc.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
