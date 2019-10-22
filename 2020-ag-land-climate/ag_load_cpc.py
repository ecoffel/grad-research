# -*- coding: utf-8 -*-
"""
Created on Sun Oct 20 18:58:17 2019

@author: Ethan
"""

import numpy as np
import xarray as xr

dataDir = 'E:/data/cpc-temp/raw/tmax.1979.nc'
ds = xr.open_dataset(dataDir)
