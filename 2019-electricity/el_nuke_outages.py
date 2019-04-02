# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 11:25:12 2019

@author: Ethan
"""

import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import statsmodels.api as sm
import el_nuke_utils

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = False
plotFigs = False

months = range(1,13)

eba = el_nuke_utils.loadNukeData(dataDir)
tx, ids = el_nuke_utils.loadWxData(eba, useEra=useEra)
ebaAcc = el_nuke_utils.accumulateNukeWxData(eba, tx, ids)


for i in range(10,43):
    ind1 = np.where(ebaAcc['txSummer']<i)[0]
    ind2 = np.where(ebaAcc['txSummer']>i)[0]
    
    if len(ind1) < 10 or len(ind2) < 10: continue
    
    mdlX1 = sm.add_constant(ebaAcc['txSummer'][ind1])
    mdl1 = sm.OLS(ebaAcc['capacitySummer'][ind1], mdlX1).fit()
    
    mdlX2 = sm.add_constant(ebaAcc['txSummer'][ind2])
    mdl2 = sm.OLS(ebaAcc['capacitySummer'][ind2], mdlX2).fit()
    print('t = %d, slope1 = %.6f, p1 = %.2f, slope1 = %.6f, p1 = %.2f'%(i,mdl1.params[1], mdl1.pvalues[1], \
                                                                        mdl2.params[1], mdl2.pvalues[1]))


thresh = 29

if useEra:
    thresh = 34

ind1 = np.where(ebaAcc['txSummer']<thresh)[0]
ind2 = np.where(ebaAcc['txSummer']>thresh)[0]

z1 = np.polyfit(ebaAcc['txSummer'][ind1], ebaAcc['capacitySummer'][ind1], 1)
p1 = np.poly1d(z1)

z2 = np.polyfit(ebaAcc['txSummer'][ind2], ebaAcc['capacitySummer'][ind2], 1)
p2 = np.poly1d(z2)

plt.figure(figsize=(3,3))

plt.scatter(ebaAcc['txSummer'], ebaAcc['capacitySummer'], s = 30, edgecolors = [.6, .6, .6], color = [.8, .8, .8])
plt.plot(range(20, thresh+1), p1(range(20, thresh+1)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot(range(thresh, 44), p2(range(thresh, 44)), "--", linewidth = 3, color = [234/255., 49/255., 49/255.])
plt.plot([thresh, thresh], [-10, 100], '--k')
plt.ylim([-5,105])
#sns.regplot(x='x', y='y', data=df, order=3, \
#            scatter_kws={"color": [.5, .5, .5], "facecolor":[.75, .75, .75], "s":30}, \
#            line_kws={"color": [234/255., 49/255., 49/255.]})
#plt.scatter(xtotal, ytotal, 5, facecolors = 'none', edgecolors = [.75, .75, .75])
#z = [model.params[1], model.params[0]]
#p = np.poly1d(z)
#plt.plot(range(20, 42), p(range(20, 42)), "--", linewidth = 2, color = [234/255., 49/255., 49/255.])
plt.xlim([19, 45])
plt.ylim([-5, 105])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica') 
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plant capacity (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks(range(20,45,4))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

#plt.title('July - August', fontname = 'Helvetica', fontsize=16)
if plotFigs:
    plt.savefig('nuke-cap-reduction.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)


binstep = 4
binnedOutageData = []
allOutageData = []
allTxData = []
for i in range(ebaAcc['percCapacity'].shape[0]):
    binnedOutageData.append([])
    
    y = ebaAcc['percCapacity'][i]
    x = tx[i,1:]

    if len(y) == len(x):
        y = y[ebaAcc['summerInds']]
        x = x[ebaAcc['summerInds']]
        nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
        
        # convert to boolean: 0 = no outage, > 0 = outage
        y = 100-y[nn]
        x = x[nn]
        y[y>0] = 100
        
        
        for t in range(20, 44, binstep):
            tempInds = np.where((x >= t) & (x < t+binstep))[0]
            if len(tempInds) > 0:
                binnedOutageData[i].append(np.nanmean(y[tempInds]))
                allOutageData.append(np.nanmean(y[tempInds]))
                allTxData.append(t)
            else:
                binnedOutageData[i].append(np.nan)
    binnedOutageData[-1] = np.array(binnedOutageData[-1])

binnedOutageData = np.array(binnedOutageData)

z = np.polyfit(allTxData, allOutageData, 3)
p = np.poly1d(z)

plt.figure(figsize=(3,3))
plt.bar(range(20, 44, binstep), np.nanmean(binnedOutageData,axis=0), yerr = np.nanstd(binnedOutageData, axis=0)/2, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], alpha = .5, width = 4, align = 'edge', \
        error_kw=dict(lw=2, capsize=3, capthick=2), ecolor = [.25, .25, .25])
plt.plot(range(20, 44), p(range(18, 42)), "--", linewidth = 2, color = [234/255., 49/255., 49/255.])
plt.xlim([19, 45])
plt.ylim([0, 50])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily maximum temperature ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Plants with outages (%)', fontname = 'Helvetica', fontsize=16)

plt.gca().set_xticks(range(20,45,4))

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

#plt.title('July - August', fontname = 'Helvetica', fontsize=16)
if plotFigs:
    plt.savefig('nuke-outage-chance.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
#X = sm.add_constant(xtotal)
#model = sm.OLS(ytotal, X).fit() 


#i = 0
#with open('nuke-lat-lon.csv', 'w') as f:
#    csvWriter = csv.writer(f)    
#    for pp in eba:
#        if 'lat' in pp.keys() and 'Nuclear generating capacity outage' in pp['name'] and not 'for generator' in pp['name']:
#            print(pp['name'])
#            csvWriter.writerow([i, float(pp['lat']), float(pp['lon'])])
#        i += 1
#
