# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 15:40:40 2019

@author: Ethan
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn import linear_model
import statsmodels.api as sm
import el_build_temp_pp_model
import pickle

plotFigs = True

tempVar = 'txSummer'
qsVar = 'qsAnomSummer'

models = el_build_temp_pp_model.buildNonlinearTempQsPPModel(tempVar, qsVar, 100)

qsrange = np.arange(-3, 3.1, .1)
#qsrange = np.arange(0,10, .1)

yds = []

for m in range(len(models)):
    # current contour surface for this model
    curCont = []
    
    for q in qsrange:
        xd = np.linspace(20,50,40)
        
        yd = []    
        for i in range(len(xd)):
            yd.append(models[m].predict([1, xd[i], xd[i]**2, xd[i]**3, \
                                        q, q**2, q**3, q**4, q**5, q*xd[i], 0])[0])
        curCont.append(yd)
        
    yds.append(curCont)

yds = np.array(yds)
yds = np.squeeze(np.nanmedian(yds, axis=0))
yds[yds<75] = 75

plt.contourf(xd, qsrange, yds, levels=np.arange(75,100,1), cmap = 'Reds_r')
cb = plt.colorbar()

plt.plot([20, 50], [0, 0], '--k', lw=2)
plt.plot([35, 35], [-3, 3], '--k', lw=2)

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Runoff anomaly (SD)', fontname = 'Helvetica', fontsize=16)
cb.set_label('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)
for tick in cb.ax.yaxis.get_ticklabels():
    tick.set_fontname('Helvetica')    
    tick.set_fontsize(14)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-pc-%s-%s-regression-contour.eps'%(tempVar,qsVar), format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()


