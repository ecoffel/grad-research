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
import el_temp_pp_model
import pickle

plotFigs = True

models = el_temp_pp_model.buildNonlinearTempQsPPModel('txSummer', 'qsAnomSummer', 1000)

qsrange = np.arange(-2, 2.1, .1)

yds = []

for q in qsrange:
    qs = np.array([q]*200)
    xd = np.linspace(20,50,40)
    
    yd = []
    
    for i in range(len(xd)):
        yd.append(models[0].predict([1, xd[i], xd[i]**2, xd[i]**3, \
                                    qs[i], qs[i]**2, qs[i]**3, qs[i]**4, qs[i]**5, 2])[0])
    
    yds.append(yd)

yds = np.array(yds)



plt.contourf(xd, qsrange, yds, levels=np.arange(70,100,1), cmap = 'Reds_r')
cb = plt.colorbar()

plt.plot([20, 50], [0, 0], '--k', lw=2)
plt.plot([35, 35], [-2, 2], '--k', lw=2)

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
    plt.savefig('hist-pc-temp-qs-regression-contour.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)














qsrange = np.arange(-2, 2.1, .1)

yds = []

for m in range(len(models)):
    qs = np.array([0]*200)
    xd = np.linspace(20,50,40)
    
    yd = []
    
    for i in range(len(xd)):
        yd.append(models[m].predict([1, xd[i], xd[i]**2, xd[i]**3, \
                                    qs[i], qs[i]**2, qs[i]**3, qs[i]**4, qs[i]**5, 2])[0])
    
    yds.append(yd)

yds = np.array(yds)


plt.figure(figsize=(4,4))
plt.xlim([19, 51])
plt.ylim([75, 100])
plt.grid(True)

plt.plot(xd, yds.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)

plt.gca().set_xticks(range(20, 51, 5))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'center left')
#leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))






yds = []

for m in range(len(models)):
    qs = np.linspace(-3, 3, 50)
    xd = np.array([35]*50)
    
    yd = []
    
    for i in range(len(xd)):
        yd.append(models[m].predict([1, xd[i], xd[i]**2, xd[i]**3, \
                                    qs[i], qs[i]**2, qs[i]**3, qs[i]**4, qs[i]**5, 2])[0])
    
    yds.append(yd)

yds = np.array(yds)


plt.figure(figsize=(4,4))
plt.xlim([-3.1, 3.1])
plt.ylim([75, 100])
plt.grid(True)

plt.plot(qs, yds.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)

plt.gca().set_xticks(np.arange(-3, 3.1, 1))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Runoff anomaly (SD)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Mean plant capacity (%)', fontname = 'Helvetica', fontsize=16)

#leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc = 'center left')
#leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

