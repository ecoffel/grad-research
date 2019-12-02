# -*- coding: utf-8 -*-
"""
Created on Mon May 13 11:59:04 2019

@author: Ethan
"""


import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import statsmodels.api as sm
from sklearn import linear_model
import seaborn as sns
import el_entsoe_utils
import el_nuke_utils
import sys, os
import pickle

import warnings
warnings.filterwarnings('ignore')

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity'

if not 'nukeData' in locals():
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    
#     nukeMatchDataEra = el_nuke_utils.loadWxData(nukeData, wxdata='era')
#     nukeMatchDataCpc = el_nuke_utils.loadWxData(nukeData, wxdata='cpc')
#     nukeMatchDataNcep = el_nuke_utils.loadWxData(nukeData, wxdata='ncep')
    nukeMatchDataAll = el_nuke_utils.loadWxData(nukeData, wxdata='all')
    
#     nukeAgDataEra = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataEra)
#     nukeAgDataCpc = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataCpc)
#     nukeAgDataNcep = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataNcep)
    nukeAgDataAll = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataAll)
    
#     nukePlantDataEra = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataEra)
#     nukePlantDataCpc = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataCpc)
#     nukePlantDataNcep = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataNcep)
    nukePlantDataAll = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataAll)


if not 'entsoeData' in locals():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir, forced=False)
    
#     entsoePlantDataEra = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='era', forced=False)
#     entsoePlantDataCpc = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='cpc', forced=False)
#     entsoePlantDataNcep = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='ncep', forced=False)
    entsoePlantDataAll = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='all', forced=False)
    
#    entsoePlantData = el_entsoe_utils.matchEntsoeWxCountry(entsoeData, useEra=useEra)
#     entsoeAgDataEra = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataEra)
#     entsoeAgDataCpc = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataCpc)
#     entsoeAgDataNcep = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataNcep)
    entsoeAgDataAll = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataAll)


eData = {'entsoeData':entsoeData, \
         'entsoePlantDataAll':entsoePlantDataAll, \
         'entsoeAgDataAll':entsoeAgDataAll, \
         
         'nukeData':nukeData, \
         'nukeMatchDataAll':nukeMatchDataAll, \
         'nukeAgDataAll':nukeAgDataAll, \
         'nukePlantDataAll':nukePlantDataAll}

with open('%s/script-data/eData.dat'%dataDir, 'wb') as f:
    pickle.dump(eData, f)
    
sys.exit()











