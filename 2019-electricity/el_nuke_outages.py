# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 11:25:12 2019

@author: Ethan
"""


import json
import el_readUSCRN
import el_wet_bulb
import el_cooling_tower_model
from matplotlib import font_manager
import seaborn as sns
import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import glob
import statsmodels.api as sm
import math
import sys
import csv

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

months = range(1,13)

if not 'eba' in locals():
    print('loading eba...')
    eba = []
    for line in open('%s/ecoffel/data/projects/electricity/NUC_STATUS.txt' % dataDir, 'r'):
        if (len(eba)+1) % 100 == 0:
            print('loading line ', (len(eba)+1))
            
        curLine = json.loads(line)

        #if 'Demand for' in curLine['name']: print(ln)
        
        if 'data' in curLine.keys():
            curLine['data'].reverse()
            curLineNew = curLine.copy()
            
            del curLineNew['data']
            curLineNew['year'] = []
            curLineNew['month'] = []
            curLineNew['day'] = []
            curLineNew['data'] = []
            
            for datapt in curLine['data']:
                # restrict to summer months
                if not int(datapt[0][4:6]) in months or \
                    int(datapt[0][0:4]) > 2018:
                    continue
                
                curLineNew['year'].append(int(datapt[0][0:4]))
                curLineNew['month'].append(int(datapt[0][4:6]))
                curLineNew['day'].append(int(datapt[0][6:8]))
                if not datapt[1] == None:
                    curLineNew['data'].append(float(datapt[1]))
                else:
                    curLineNew['data'].append(np.nan)
                    
            curLineNew['year'] = np.array(curLineNew['year'])
            curLineNew['month'] = np.array(curLineNew['month'])
            curLineNew['day'] = np.array(curLineNew['day'])
            curLineNew['data'] = np.array(curLineNew['data'])

            eba.append(curLineNew)


# read tw time series
tw = np.genfromtxt('nuke-tx-era.csv', delimiter=',')
ids = []
for i in range(tw.shape[0]):
    # current facility outage name
    outageId = int(tw[i,0])
    name = eba[outageId]['name']
    
    if 'for generator' in name: 
        continue
    
    nameParts = name.split(' at ')
    for n in range(len(eba)):
        if 'Nuclear generating capacity' in eba[n]['name'] and \
           not 'outage' in eba[n]['name'] and \
           not 'for generator' in eba[n]['name'] and \
           nameParts[1] in eba[n]['name']:
               capacityId = n
               ids.append([outageId, capacityId])

ids = np.array(ids)
percOutage = []
totalOut = []
totalCap = []
for i in range(ids.shape[0]):
    out = np.array(eba[ids[i,0]]['data'])
    cap = np.array(eba[ids[i,1]]['data'])
    
    
    if len(out) == 4383 and len(cap) == 4383:
        percOutage.append(100*(1-out/cap))
        if len(totalOut) == 0:
            totalOut = out
            totalCap = cap
        else:
            totalOut += out
            totalCap += cap

#summerInds = np.where((eba[0]['month'] >= 6) & (eba[0]['month'] <= 8))[0]

percOutage = np.array(percOutage)
percOutageMean = np.nanmean(percOutage, axis=0)

#for m in range(1,13):

summerInds = np.where((eba[0]['month'] == 7) | (eba[0]['month'] == 8))[0]

#    print('mean outage in month %d = %.2f' % (m, np.nanmean(percOutageMean[summerInds])))
#    continue

xtotal = []
ytotal = []
for i in range(percOutage.shape[0]):
    
    y = percOutage[i]
    x = tw[i,1:]
    
    if len(y)==len(x):
        y = y[summerInds]
        x = x[summerInds]
        nn = np.where((~np.isnan(y)) & (~np.isnan(x)) & (y < 100))[0]
        y = y[nn]
        x = x[nn]
        ytotal.extend(y)
        xtotal.extend(x)

df = pd.DataFrame({'x':xtotal, 'y':ytotal})

z = np.polyfit(xtotal, ytotal, 3)
plt.figure(figsize=(5,5))

plt.xlim([20, 42])
sns.regplot(x='x', y='y', data=df, order=3, \
            scatter_kws={"color": [.75, .75, .75], "s":10}, \
            line_kws={"color": [234/255., 49/255., 49/255.]})
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
plt.ylabel('Nuclear plant operating capacity (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

#plt.title('July - August', fontname = 'Helvetica', fontsize=16)
plt.savefig('nuke-cap-reduction.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
X = sm.add_constant(xtotal)
model = sm.OLS(ytotal, X).fit() 






binstep = 4
ydata = []
ytotal = []
xtotal = []
for i in range(percOutage.shape[0]):
    ydata.append([])
    
    y = percOutage[i]
    x = tw[i,1:]

    if len(y) == len(x):
        y = y[summerInds]
        x = x[summerInds]
        nn = np.where((~np.isnan(y)) & (~np.isnan(x)))[0]
        y = 100-y[nn]
        x = x[nn]
        y[y>0] = 100
        
        #ytotal.extend(y)
        #xtotal.extend(x)
        
        for t in range(20, 44, binstep):
            tempInds = np.where((x >= t) & (x < t+binstep))[0]
            if len(tempInds) > 0:
                ydata[i].append(np.nanmean(y[tempInds]))
                ytotal.append(np.nanmean(y[tempInds]))
                xtotal.append(t)
            else:
                ydata[i].append(np.nan)
    ydata[-1] = np.array(ydata[-1])

ydata = np.array(ydata)

z = np.polyfit(xtotal, ytotal, 3)
p = np.poly1d(z)

plt.figure(figsize=(5,5))
plt.bar(range(20, 44, binstep), np.nanmean(ydata,axis=0), yerr = np.nanstd(ydata, axis=0)/2, \
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
plt.ylabel('Nuclear plants with outages (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

#plt.title('July - August', fontname = 'Helvetica', fontsize=16)
plt.savefig('nuke-outage-chance.eps', format='eps', dpi=1000, bbox_inches = 'tight', pad_inches = 0)
X = sm.add_constant(xtotal)
model = sm.OLS(ytotal, X).fit() 


i = 0
with open('nuke-lat-lon.csv', 'w') as f:
    csvWriter = csv.writer(f)    
    for pp in eba:
        if 'lat' in pp.keys() and 'Nuclear generating capacity outage' in pp['name'] and not 'for generator' in pp['name']:
            print(pp['name'])
#            csvWriter.writerow([i, float(pp['lat']), float(pp['lon'])])
        i += 1

