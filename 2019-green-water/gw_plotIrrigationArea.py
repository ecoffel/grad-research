# -*- coding: utf-8 -*-
"""
Created on Fri May 17 17:18:21 2019

@author: Ethan
"""

import os
os.environ['PROJ_LIB'] = r'C:\Users\Ethan\Anaconda3\pkgs\proj4-5.2.0-ha925a31_1\Library\share'
from mpl_toolkits.basemap import Basemap, cm
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np

nlon = 4320
nlat = 2160
xllLon = -180
yllLat = -90


lat = np.linspace(90, -90, nlat)
lon = np.linspace(-180, 180, nlon)
lon, lat = np.meshgrid(lon, lat)

if not 'irr' in locals():
    aai_aei = np.genfromtxt('irrigation-data/gmia_v5_aai_pct_aei_asc/gmia_v5_aai_pct_aei.asc', delimiter=' ', skip_header=6)
    aei = np.genfromtxt('irrigation-data/gmia_v5_aei_pct_asc/gmia_v5_aei_pct.asc', delimiter=' ', skip_header=6)



fig = plt.figure(figsize=(10, 8))
m = Basemap(projection='merc', llcrnrlat=-60, urcrnrlat=60, \
            llcrnrlon=-180, urcrnrlon=180, resolution='c')

m.drawcoastlines(color='lightgray')
m.contourf(lon, lat, aai_aei, latlon=True, cmap='Greens')
m.colorbar()




fig = plt.figure(figsize=(10, 8))
m = Basemap(projection='merc', llcrnrlat=-60, urcrnrlat=60, \
            llcrnrlon=-180, urcrnrlon=180, resolution='c')

m.drawcoastlines(color='lightgray')
m.contourf(lon, lat, aei, latlon=True, cmap='Greens')
m.colorbar()


