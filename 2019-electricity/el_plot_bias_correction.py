
import matplotlib.pyplot as plt 
import pandas as pd
import seaborn as sns
import numpy as np
import statsmodels.api as sm
import el_find_best_runoff_dist
import scipy.stats as st
import pickle, gzip
import sys, os

import warnings
warnings.filterwarnings('ignore')

dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

plotFigs = True

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

modelBc = []

for model in models:
    if not os.path.isfile('%s/bias-correction/bc-world-pp-rcp85-tx-cmip5-%s.csv'%(dataDirDiscovery, model)):
        continue
    
    curBc = np.genfromtxt('%s/bias-correction/bc-world-pp-rcp85-tx-cmip5-%s.csv'%(dataDirDiscovery, model), delimiter=',')
    
    modelBc.append(np.nanmean(curBc,axis=0))

modelBc = np.array(modelBc)
    
snsColors = sns.color_palette(["#3498db", "#e74c3c"])


fig = plt.figure(figsize=(4,4))
plt.grid(True, color=[.9,.9,.9])

for m in range(modelBc.shape[0]):
    plt.plot(modelBc[m,:], label=models[m])

plt.plot([0, 9], [0, 0], '--k')
    
plt.xticks(list(range(0,10)))
plt.gca().set_xticklabels(list(range(10, 100+1, 10)))

plt.xlabel('Tx percentile', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Model bias ($\degree$C)', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':10, 'family':'Helvetica'}, bbox_to_anchor=(1.025, 1.03))
leg.get_frame().set_linewidth(0.0)

if plotFigs:
    plt.savefig('bias-correction.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)

plt.show()
    