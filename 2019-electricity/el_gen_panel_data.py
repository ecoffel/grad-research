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
import sys
import pickle

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'



    
if not 'entsoeData' in locals():
    entsoeData = el_entsoe_utils.loadEntsoeWithLatLon(dataDir, forced=False)
    
    entsoePlantDataEra = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='era', forced=False)
    entsoePlantDataCpc = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='cpc', forced=False)
    entsoePlantDataNcep = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='ncep', forced=False)
    entsoePlantDataAll = el_entsoe_utils.matchEntsoeWxPlantSpecific(entsoeData, wxdata='all', forced=False)
    
#    entsoePlantData = el_entsoe_utils.matchEntsoeWxCountry(entsoeData, useEra=useEra)
    entsoeAgDataEra = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataEra)
    entsoeAgDataCpc = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataCpc)
    entsoeAgDataNcep = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataNcep)
    entsoeAgDataAll = el_entsoe_utils.aggregateEntsoeData(entsoePlantDataAll)

if not 'nukeData' in locals():
    nukeData = el_nuke_utils.loadNukeData(dataDir)
    
    nukeMatchDataEra = el_nuke_utils.loadWxData(nukeData, wxdata='era')
    nukeMatchDataCpc = el_nuke_utils.loadWxData(nukeData, wxdata='cpc')
    nukeMatchDataNcep = el_nuke_utils.loadWxData(nukeData, wxdata='ncep')
    nukeMatchDataAll = el_nuke_utils.loadWxData(nukeData, wxdata='all')
    
    nukeAgDataEra = el_nuke_utils.accumulateNukeWxData(nukeData, nukeMatchDataEra)
    nukeAgDataCpc = el_nuke_utils.accumulateNukeWxData(nukeData, nukeMatchDataCpc)
    nukeAgDataNcep = el_nuke_utils.accumulateNukeWxData(nukeData, nukeMatchDataNcep)
    nukeAgDataAll = el_nuke_utils.accumulateNukeWxData(nukeData, nukeMatchDataAll)
    
    nukePlantDataEra = el_nuke_utils.accumulateNukeWxDataPlantLevel(nukeData, nukeMatchDataEra)
    nukePlantDataCpc = el_nuke_utils.accumulateNukeWxDataPlantLevel(nukeData, nukeMatchDataCpc)
    nukePlantDataNcep = el_nuke_utils.accumulateNukeWxDataPlantLevel(nukeData, nukeMatchDataNcep)
    nukePlantDataAll = el_nuke_utils.accumulateNukeWxDataPlantLevel(nukeData, nukeMatchDataAll)


eData = {'entsoeData':entsoeData, \
         'entsoePlantDataEra':entsoePlantDataEra, \
         'entsoePlantDataCpc':entsoePlantDataCpc, \
         'entsoePlantDataNcep':entsoePlantDataNcep, \
         'entsoePlantDataAll':entsoePlantDataAll, \
         'entsoeAgDataEra':entsoeAgDataEra, \
         'entsoeAgDataCpc':entsoeAgDataCpc, \
         'entsoeAgDataNcep':entsoeAgDataNcep, \
         'entsoeAgDataAll':entsoeAgDataAll, \
         
         'nukeData':nukeData, \
         'nukeMatchDataEra':nukeMatchDataEra, \
         'nukeMatchDataCpc':nukeMatchDataCpc, \
         'nukeMatchDataNcep':nukeMatchDataNcep, \
         'nukeMatchDataAll':nukeMatchDataAll, \
         'nukeAgDataEra':nukeAgDataEra, \
         'nukeAgDataCpc':nukeAgDataCpc, \
         'nukeAgDataNcep':nukeAgDataNcep, \
         'nukeAgDataAll':nukeAgDataAll, \
         'nukePlantDataEra':nukePlantDataEra, \
         'nukePlantDataCpc':nukePlantDataCpc, \
         'nukePlantDataNcep':nukePlantDataNcep, \
         'nukePlantDataAll':nukePlantDataAll}

with open('e:/data/ecoffel/data/projects/electricity/script-data/eData.dat', 'wb') as f:
    pickle.dump(eData, f)

sys.exit()
df = pd.DataFrame()

temp = []
temp.extend(nukeAgDataAll['txSummer'])
df['Temp'] = temp

qs = []
qs.extend(nukeAgDataAll['qsAnomSummer'])
df['QS'] = qs

pc = []
pc.extend(nukeAgDataAll['capacitySummer'])
df['PCAll'] = pc

df.to_csv('nuke-panel-data.csv', header = False, index = False, index_label = False)











