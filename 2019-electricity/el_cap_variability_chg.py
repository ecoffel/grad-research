# -*- coding: utf-8 -*-
"""
Created on Tue May 21 15:02:47 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import seaborn as sns
import el_temp_pp_model
import pickle
import sys

plotFigs = True

pcChg = {}
with open('plantPcChange.dat', 'rb') as f:
    pcChg = pickle.load(f)

pCapTx10 = pcChg['pCapTx10']
pCapTx50 = pcChg['pCapTx50']
pCapTx90 = pcChg['pCapTx90']

cv10 = np.nanstd(pCapTx10, axis=2)/np.nanmean(pCapTx10, axis=2)
cv50 = np.nanstd(pCapTx50, axis=2)/np.nanmean(pCapTx50, axis=2)
cv90 = np.nanstd(pCapTx90, axis=2)/np.nanmean(pCapTx90, axis=2)


snsColors = sns.color_palette(["#3498db", "#e74c3c"])

boxy = [(cv10[2,:])/cv10[0,:], \
        (cv10[4,:])/cv10[0,:], \
        (cv50[2,:])/cv50[0,:], \
        (cv50[4,:])/cv50[0,:], \
        (cv90[2,:])/cv90[0,:], \
        (cv90[4,:])/cv90[0,:]]
boxy = np.array(boxy)

plt.figure(figsize=(4,4))
plt.grid(True, alpha=0.5)

medianprops = dict(linestyle='-', linewidth=1.5, color='black')
meanpointprops = dict(marker='D', markeredgecolor='black',
                      markerfacecolor='white')
bplot = plt.boxplot(boxy.T, positions = [.9, 1.1, 1.9, 2.1, 2.9, 3.1], showmeans=True, widths=.1, sym='.', patch_artist=True, \
                    medianprops=medianprops, meanprops=meanpointprops, zorder=0)

colors = ['lightgray']
n = 1
for patch in bplot['boxes']:
    if n in [1, 3, 5]:
        patch.set_facecolor(snsColors[0])
    elif n in [2, 4, 6]:
        patch.set_facecolor(snsColors[1])
    n += 1
    
plt.plot([0, 4], [1, 1], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 2, 3])
plt.gca().set_xticklabels(['10th', '50th', '90th'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Fit percentile', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Change in CV (Fraction)', fontname = 'Helvetica', fontsize=16)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))


if plotFigs:
    plt.savefig('plant-cap-cv-change.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)
