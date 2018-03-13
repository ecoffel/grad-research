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
import pickle
import gzip


baseDir = 'data\\stage4-hourly-pr'
inputDrive = 'E:\\'
outputDrive = 'E:\\'

dirs = os.listdir(inputDrive + baseDir)
for dirname in dirs:
    if os.path.isdir(inputDrive + baseDir + "\\" + dirname):
        filenames = glob.glob(inputDrive + baseDir+'\\'+dirname+'\\counts.dat')
        for filename in filenames:
            os.rename(filename, inputDrive + baseDir + "\\counts\\"+dirname+'counts.dat')
            print(filename)
            
