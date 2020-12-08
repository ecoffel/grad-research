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
    
    nukeMatchDataEra = el_nuke_utils.loadWxData(nukeData, wxdata='era')
    nukeMatchDataCpc = el_nuke_utils.loadWxData(nukeData, wxdata='cpc')
    nukeMatchDataNcep = el_nuke_utils.loadWxData(nukeData, wxdata='ncep')
    nukeMatchDataAll = el_nuke_utils.loadWxData(nukeData, wxdata='all')
    
    nukeAgDataEra = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataEra)
    nukeAgDataCpc = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataCpc)
    nukeAgDataNcep = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataNcep)
    nukeAgDataAll = el_nuke_utils.accumulateNukeWxData(dataDir, nukeData, nukeMatchDataAll)
    
    nukePlantDataEra = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataEra)
    nukePlantDataCpc = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataCpc)
    nukePlantDataNcep = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataNcep)
    nukePlantDataAll = el_nuke_utils.accumulateNukeWxDataPlantLevel(dataDir, nukeData, nukeMatchDataAll)

if not 'entsoeData' in locals():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir, forced=False)
    
    entsoePlantDataEra = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='era', forced=False)
    entsoePlantDataCpc = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='cpc', forced=False)
    entsoePlantDataNcep = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='ncep', forced=False)
    entsoePlantDataAll = el_entsoe_utils.matchEntsoeWxPlantSpecific(dataDir, entsoeData, wxdata='all', forced=False)
    
#    entsoePlantData = el_entsoe_utils.matchEntsoeWxCountry(entsoeData, useEra=useEra)
    entsoeAgDataEra = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataEra)
    entsoeAgDataCpc = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataCpc)
    entsoeAgDataNcep = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataNcep)
    entsoeAgDataAll = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataAll)


eData_all = {'entsoeData':entsoeData, \
         'entsoePlantDataAll':entsoePlantDataAll, \
         'entsoeAgDataAll':entsoeAgDataAll, \
         
         'nukeData':nukeData, \
         'nukeMatchDataAll':nukeMatchDataAll, \
         'nukeAgDataAll':nukeAgDataAll, \
         'nukePlantDataAll':nukePlantDataAll}

eData_cpc = {'entsoeData':entsoeData, \
         'entsoePlantDataCpc':entsoePlantDataCpc, \
         'entsoeAgDataCpc':entsoeAgDataCpc, \
         
         'nukeData':nukeData, \
         'nukeMatchDataCpc':nukeMatchDataCpc, \
         'nukeAgDataCpc':nukeAgDataCpc, \
         'nukePlantDataCpc':nukePlantDataCpc}

eData_era = {'entsoeData':entsoeData, \
         'entsoePlantDataEra':entsoePlantDataEra, \
         'entsoeAgDataEra':entsoeAgDataEra, \
         
         'nukeData':nukeData, \
         'nukeMatchDataEra':nukeMatchDataEra, \
         'nukeAgDataEra':nukeAgDataEra, \
         'nukePlantDataEra':nukePlantDataEra}

eData_ncep = {'entsoeData':entsoeData, \
         'entsoePlantDataNcep':entsoePlantDataNcep, \
         'entsoeAgDataNcep':entsoeAgDataNcep, \
         
         'nukeData':nukeData, \
         'nukeMatchDataNcep':nukeMatchDataNcep, \
         'nukeAgDataNcep':nukeAgDataNcep, \
         'nukePlantDataNcep':nukePlantDataNcep}

# with open('%s/script-data/eData.dat'%dataDir, 'wb') as f:
#     pickle.dump(eData, f)

with open('%s/script-data/eData_cpc.dat'%dataDir, 'wb') as f:
    pickle.dump(eData_cpc, f)
    
with open('%s/script-data/eData_era.dat'%dataDir, 'wb') as f:
    pickle.dump(eData_era, f)
    
with open('%s/script-data/eData_ncep.dat'%dataDir, 'wb') as f:
    pickle.dump(eData_ncep, f)
    

