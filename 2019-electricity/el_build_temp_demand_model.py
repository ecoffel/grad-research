# -*- coding: utf-8 -*-
"""
Created on Wed Jun 19 14:09:56 2019

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:32:08 2019

@author: Ethan
"""


import numpy as np
import pandas as pd
from sklearn import linear_model
import statsmodels.api as sm
import el_entsoe_utils
import el_nuke_utils
import pickle, gzip
import os

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

def buildNonlinearDemandModel(nBootstrap):
    
    genData = {}
    with open('%s/script-data/genData.dat'%dataDirDiscovery, 'rb') as f:
        genData = pickle.load(f)
        
    tx = genData['txScatter']
    dem = genData['demTxScatter']


    txall = []
    demall = []

    for s in range(tx.shape[0]):
        txall.extend(tx[s])
        demall.extend(dem[s])

    txall = np.array(txall)
    demall = np.array(demall)
    
    ind = np.where((~np.isnan(txall)) & (~np.isnan(demall)))[0]
            
    txall = txall[ind]
    demall = demall[ind]
    
    np.random.seed(1024)
    
    models = []
    
    for i in range(nBootstrap):
        ind = np.random.choice(len(txall), int(len(txall)))
    
        data = {'T':txall[ind], 'T2':txall[ind]**2, 'T3':txall[ind]**3, \
                'D':demall[ind]}
        
        df = pd.DataFrame(data, columns=['T', 'T2', 'T3', 'D'])
        
        df = df.dropna()
        
        X = sm.add_constant(df[['T', 'T2']])
        mdl = sm.OLS(df['D'], X).fit()
        models.append(mdl)
    
    models = np.array(models)

    return models


