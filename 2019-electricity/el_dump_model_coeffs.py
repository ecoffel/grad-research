# -*- coding: utf-8 -*-
"""
Created on Thu May  2 16:56:07 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import pandas as pd
import seaborn as sns
import el_build_temp_pp_model
import pickle, gzip
import random
import sys, os

#dataDir = '
dataDirDiscovery = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

tempVar = 'txSummer'
qsVar = 'qsGrdcAnomSummer'

modelPower = 'pow2'

prcStr = ''
if 'percentile' in qsVar.lower():
    prcStr = '-perc'
if 'grdc' in qsVar.lower():
    polyDataTitle = 'pPolyData-grdc-pow2%s'%prcStr
elif 'nldas' in qsVar.lower():
    polyDataTitle = 'pPolyData-nldas-pow2%s'%prcStr
else:
    polyDataTitle = 'pPolyData-gldas-pow2%s'%prcStr
    
with gzip.open('%s/script-data/%s.dat'%(dataDirDiscovery, polyDataTitle), 'rb') as f:
    pPolyData = pickle.load(f)

mdl10 = pPolyData['pcModel50'][0]
mdl50 = pPolyData['pcModel50'][0]
mdl90 = pPolyData['pcModel50'][0]

# -------------------------------------------------------------------------

results = mdl10

pvals = results.pvalues
coeff = results.params
conf_lower = results.conf_int()[0]
conf_higher = results.conf_int()[1]

results_df = pd.DataFrame({"PValue":pvals,
                           "Coefficient":coeff,
                           "ConfIntLow":conf_lower,
                           "ConfIntHigh":conf_higher
                            })

#Reordering...
results_df = results_df[["Coefficient", "PValue", "ConfIntLow", "ConfIntHigh"]]

results_df.to_csv('model-coeffs-10.csv')

# -------------------------------------------------------------------------

results = mdl50

pvals = results.pvalues
coeff = results.params
conf_lower = results.conf_int()[0]
conf_higher = results.conf_int()[1]

results_df = pd.DataFrame({"PValue":pvals,
                           "Coefficient":coeff,
                           "ConfIntLow":conf_lower,
                           "ConfIntHigh":conf_higher
                            })
#Reordering...
results_df = results_df[["Coefficient", "PValue", "ConfIntLow", "ConfIntHigh"]]
results_df.to_csv('model-coeffs-50.csv')

# -------------------------------------------------------------------------

results = mdl90

pvals = results.pvalues
coeff = results.params
conf_lower = results.conf_int()[0]
conf_higher = results.conf_int()[1]

results_df = pd.DataFrame({"PValue":pvals,
                           "Coefficient":coeff,
                           "ConfIntLow":conf_lower,
                           "ConfIntHigh":conf_higher
                            })

#Reordering...
results_df = results_df[["Coefficient", "PValue", "ConfIntLow", "ConfIntHigh"]]

results_df.to_csv('model-coeffs-90.csv')