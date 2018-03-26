# -*- coding: utf-8 -*-
"""
Created on Thu Mar  1 15:37:15 2018

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Tue Feb 27 18:08:27 2018

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Tue Feb  6 18:03:53 2018

@author: Ethan
"""
import os
import sys
import glob
from subprocess import call
from netCDF4 import Dataset
import numpy as np
import scipy
from scipy import ndimage
import pickle
import gzip
import matplotlib.pyplot as plt

bins = np.array([0, 0.1, 1, 2.5, 5,10,15,20,25,30,35,40,45,50,55, 60,65, 70,75,80,85,90,95,100, 125,150,175,200,225,250])

baseDir = 'data\\stage4-hourly-pr\\counts'
inputDrive = 'E:\\'
outputDrive = 'E:\\'



filenames = glob.glob(inputDrive + baseDir+'\\*counts.dat')
find = 0
monthlyTotals = np.zeros([881, 1121, len(filenames)])
monthlyTotals[:] = np.nan

for filename in filenames:
    
    f = gzip.open(filename, 'rb')
    data = pickle.load(f)
    
    shp = np.shape(data)
    
    for x in range(shp[0]):
        for y in range(shp[1]):
            for b in range(shp[2]):
                if np.isnan(monthlyTotals[x,y,find]) and data[x,y,b] > 0:
                    monthlyTotals[x,y,find] = bins[b] * data[x,y,b]
                elif data[x,y,b] > 0:
                    monthlyTotals[x,y,find] += bins[b] * data[x,y,b]
    find += 1
    
    print('processed', filename)
    if find>5:break

plt.figure(figsize=(20,20))
plt.imshow(monthlyTotals[:,:,5],clim=(0.0,300.0));
plt.colorbar()
plt.savefig('201106.png')
            
    
            
