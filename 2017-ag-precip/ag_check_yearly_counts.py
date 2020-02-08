# -*- coding: utf-8 -*-
"""
Created on Mon Jan 27 13:30:27 2020

@author: HAL 9000
"""


import xarray as xr
import os
import glob
import gzip
import numpy as np
import pickle
import sys, os

curYear = 2003

months = [3,4,5]
inputDir = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/rain-crops/'
outputDir = inputDir + 'output/counts_redrizzle/' + str(curYear) + '/'

bins = np.array([0,0.1,0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4,2.5])

totalCounts = []

for m in months:
    #save count file for year/month        
    f = gzip.open(outputDir + 'counts' + str(curYear) + '0' + str(m) + '.dat', 'rb')
    counts = pickle.load(f)
    if len(totalCounts) == 0:
        totalCounts = counts
    else:
        totalCounts += counts
    
    
    
