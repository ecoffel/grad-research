# -*- coding: utf-8 -*-
"""
Created on Fri May 24 15:47:09 2019

@author: Ethan
"""

import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
from sklearn import linear_model
import statsmodels.api as sm
import el_entsoe_utils
import el_nuke_utils
import pickle
import sys

plotFigs = False

eData = {}
with open('eData.dat', 'rb') as f:
    eData = pickle.load(f)


entsoeAgDataAll = eData['entsoeAgDataAll']
nukeAgDataAll = eData['nukeAgDataAll']

xtotal = []
xtotal.extend(nukeAgDataAll['txSummer'])
#    xtotal.extend(entsoeAgDataAll['txAvgSummer'])
xtotal = np.array(xtotal)


qstotal = []
qstotal.extend(nukeAgDataAll['qsAnomSummer'])
qstotal = np.array(qstotal)

ytotal = []
ytotal.extend(nukeAgDataAll['capacitySummer'])
#    ytotal.extend(100*entsoeAgDataAll['capacitySummer'])
ytotal = np.array(ytotal)



ind = np.where((ytotal <= 100.1))[0]
xtotal = xtotal[ind]
qstotal = qstotal[ind]
ytotal = ytotal[ind]

pBootstrap = []
zBootstrap = []

orders = [4,5,6]

for i in range(1000):
    resampleInd = np.random.choice(len(qstotal), int(len(qstotal)))
    
    data = {'Temp':xtotal[resampleInd], 'QS':qstotal[resampleInd], 'PC':ytotal[resampleInd]}
    df = pd.DataFrame(data, columns=['Temp', 'QS', 'PC'])
    
    df = df.dropna()
    
    z = np.polyfit(df['QS'], df['PC'], orders[i%len(orders)])
    p = np.poly1d(z)
    zBootstrap.append(z)
    pBootstrap.append(p)



xd = np.linspace(-3, 3, 200)
#xd = np.linspace(20, 50, 200)
yPolyAll = np.array([pBootstrap[i](xd) for i in range(len(pBootstrap))])






binstep = .25
bin_x1 = -3
bin_x2 = 3


bincounts = []
for t in np.arange(bin_x1, bin_x2+1, binstep):
    bincounts.append(len(qstotal[(qstotal >= t) & (qstotal < t+binstep)]))


# plot hist of days in each temp bin
plt.figure(figsize=(6,1))
plt.xlim([-3.1, 3.1])

plt.bar(np.arange(bin_x1, bin_x2+1, binstep), bincounts, \
        facecolor = [.75, .75, .75], \
        edgecolor = [0, 0, 0], width = binstep, align = 'edge', \
        zorder=0)

#plt.gca().set_xticks([])
#plt.gca().set_xticklabels([])
plt.gca().set_yticks([])
plt.gca().set_yticklabels([])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)
    

if plotFigs:
    plt.savefig('hist-pc-qs-hist.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)










plt.figure(figsize=(4,4))
plt.ylim([0,100])
plt.xlim([-3.1, 3.1])
plt.grid(True, alpha = 0.5)

plt.plot(xd, yPolyAll.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)
plt.plot(xd, np.nanmean(yPolyAll, axis=0), '-', linewidth = 3, color = 'black')

#plt.gca().set_xticks(range(20, 51, 5))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Runoff anomaly (SD)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)
#
#leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'center left')
#leg.get_frame().set_linewidth(0.0)
#    

plt.gca().set_yticks([0, 20, 40, 60, 80, 100])
plt.gca().set_yticklabels(['', 20, 40, 60, 80, 100])

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-qs-curve.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()
    