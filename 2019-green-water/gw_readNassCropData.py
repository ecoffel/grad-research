# -*- coding: utf-8 -*-
"""
Created on Thu Apr  4 14:05:37 2019

@author: Ethan
"""

import numpy as np
import matplotlib.pyplot as plt

dataDir = 'e:/data/ecoffel/data/projects/green-water/nass'

files = ['nass-corn-production-1961-1979.csv', 'nass-corn-production-1980-1999.csv', \
         'nass-corn-production-2000-2010.csv']

years = []
statesANSI = []
countiesANSI = []
productions = []

for f in range(len(files)):
    with open('%s/%s' % (dataDir, files[f]), 'r') as curFile:
        i = 0
        for line in curFile:
            if i == 0:
                i += 1
                continue
            parts = line.split('"')
            
            inds = []
            for j in range(len(parts)):
                if parts[j] == ',':
                    continue
                inds.append(inds)
            
                years.append(int(parts[inds[2]]))
                statesANSI.append(int(parts[7]))
                countiesANSI.append(int(parts[11]))

                productions.append(int(parts[inds[19]]))