# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 17:49:10 2019

@author: Ethan
"""


import matplotlib.pyplot as plt 
import numpy as np
import statsmodels.api as sm
import el_entsoe_utils

#dataDir = '/dartfs-hpc/rc/lab/C/CMIG'
dataDir = 'e:/data/'

useEra = True
plotFigs = False


entsoeData = el_entsoe_utils.loadEntsoe(dataDir)
#entsoeMatchData = el_entsoe_utils.matchEntsoeWx(entsoeData, useEra=useEra)
#entsoeAgData = el_entsoe_utils.aggregateEntsoeData(entsoeMatchData)

for country in set(entsoeData['countries']):
    if country == None: continue
    
    print('%s: %d' % (country, sum(1 for s in entsoeData['countries'] if s == country)))