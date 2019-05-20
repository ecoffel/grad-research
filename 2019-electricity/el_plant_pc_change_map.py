# -*- coding: utf-8 -*-
"""
Created on Wed May 15 18:33:47 2019

@author: Ethan
"""

# -*- coding: utf-8 -*-
"""
Created on Mon Apr  1 11:10:50 2019

@author: Ethan
"""

import os
os.environ['PROJ_LIB'] = r'C:\Users\Ethan\Anaconda3\pkgs\proj4-5.2.0-ha925a31_1\Library\share'
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt
import matplotlib.cm as cmx
from matplotlib.colors import Normalize
import numpy as np
import pandas as pd
import sys
import pickle

dataDir = 'e:/data/'


class MidpointNormalize(Normalize):
    def __init__(self, vmin=None, vmax=None, midpoint=None, clip=False):
        self.midpoint = midpoint
        Normalize.__init__(self, vmin, vmax, clip)

    def __call__(self, value, clip=None):
        # I'm ignoring masked values and all kinds of edge cases to make a
        # simple example...
        x, y = [self.vmin, self.midpoint, self.vmax], [0, 0.5, 1]
        return np.ma.masked_array(np.interp(value, x, y))


if not 'plantPcChange' in locals():
    plantPcChange = {}
    with open('plantPcChange.dat', 'rb') as f:
        plantPcChange = pickle.load(f)


pcChg = np.nanmean(plantPcChange['pCapTxx50'][0,:,33:],axis=1) - \
        np.nanmean(plantPcChange['pCapTxx50'][0,:,0:5],axis=1)
        

if not 'eData' in locals():
    eData = {}
    with open('eData.dat', 'rb') as f:
        eData = pickle.load(f)
entsoeData = eData['entsoeData']

uniqueLat, uniqueLatInds = np.unique(entsoeData['lats'], return_index=True)
entsoeLat = np.array(entsoeData['lats'][uniqueLatInds])
entsoeLon = np.array(entsoeData['lons'][uniqueLatInds])
entsoePlantType = []    
for l in list(set(entsoeLat)):
    ind = np.where(entsoeData['lats'] == l)[0]
    entsoePlantType.append(entsoeData['fuelTypes'][ind[0]]) 

nukeLatLon = np.genfromtxt('nuke-lat-lon.csv', delimiter=',')

fig = plt.figure(figsize=(6,6))
ax = plt.axes([0,0,1,1]) 
# A basic map
m=Basemap(llcrnrlon=-130, llcrnrlat=20,urcrnrlon=40,urcrnrlat=70)

m.drawmapboundary(fill_color='#deebf7', linewidth=0)
m.fillcontinents(color='#bdbdbd', alpha=0.7, lake_color='grey')
m.drawcoastlines(linewidth=0.1, color="black")
m.drawstates()
m.drawcountries()

mSize = 25

norm = MidpointNormalize(vmin=-0.5, midpoint=0, vmax=0.5)

xpts = []
ypts = []


for i in range(nukeLatLon.shape[0]):
    xpt, ypt = m(nukeLatLon[i,1], nukeLatLon[i,2])
    xpts.append(xpt)
    ypts.append(ypt)

for i in range(entsoeLat.shape[0]):
    xpt, ypt = m(entsoeLat[i], entsoeLon[i])
    xpts.append(xpt)
    ypts.append(ypt)

sc = m.scatter(ypts, xpts, s=mSize, marker='o', \
          c=pcChg, norm=norm, cmap=plt.cm.get_cmap('RdBu'), edgecolors='black', zorder=10)
plt.clim(-0.5, 0.5)
cb = m.colorbar(sc, location='bottom')
cb.set_ticks(np.arange(-.5, .51, .25))
cb.set_label(label="Historical plant capacity change on TXx day (%)", size=14, family='Helvetica')

for l in cb.ax.xaxis.get_ticklabels():
    l.set_family("Helvetica")
    l.set_size(14)

plt.savefig('pp-hist-pc-change-map.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)