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
import numpy as np
import pandas as pd
import sys
import pickle

dataDir = 'e:/data/'

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

mSize = 15

# Add a marker per city of the data frame!
xpt, ypt = m(nukeLatLon[:,1], nukeLatLon[:,2])
m.scatter(ypt, xpt, s=mSize, color="orange", edgecolors="black", label='Nuclear', zorder=10)

coalInds = []
gasInds = []
oilInds = []
nukeInds = []
bioInds = []
wasteInds = []
cogenInds = []

for i in range(len(entsoeLat)):
    if entsoeLat[i] < 30:
        continue 
     
    if entsoePlantType[i] == 'coal':
        coalInds.append(i)
    elif entsoePlantType[i] == 'gas':
        gasInds.append(i)
    elif entsoePlantType[i] == 'oil':
        oilInds.append(i)
    elif entsoePlantType[i] == 'nuclear':
        nukeInds.append(i)
    elif entsoePlantType[i] == 'biomass':
        bioInds.append(i)
    elif entsoePlantType[i] == 'cogeneration':
        cogenInds.append(i)



xpt, ypt = m(entsoeLat[np.array(coalInds)], entsoeLon[np.array(coalInds)])
m.scatter(ypt, xpt, s=mSize, color='#f03b20', edgecolors="black", label='Coal', zorder=10)

xpt, ypt = m(entsoeLat[np.array(gasInds)], entsoeLon[np.array(gasInds)])
m.scatter(ypt, xpt, s=mSize, color='#3182bd', edgecolors="black", label='Gas', zorder=10)

xpt, ypt = m(entsoeLat[np.array(oilInds)], entsoeLon[np.array(oilInds)])
m.scatter(ypt, xpt, s=mSize, color='black', edgecolors="black", label='Oil', zorder=10)
##
#xpt, ypt = m(entsoeLat[np.array(nukeInds)], entsoeLon[np.array(nukeInds)])
#m.scatter(ypt, xpt, s=mSize, color='orange', edgecolors="black", label='Nuclear', zorder=10)
##
#xpt, ypt = m(entsoeLat[np.array(bioInds)], entsoeLon[np.array(bioInds)])
#m.scatter(ypt, xpt, s=mSize, color='green', edgecolors="black", label='Biomass', zorder=10)
#
#xpt, ypt = m(entsoeLat[np.array(cogenInds)], entsoeLon[np.array(cogenInds)])
#m.scatter(ypt, xpt, s=mSize, color='pink', edgecolors="black", label='Cogen', zorder=10)

plt.legend(markerscale=2, prop = {'size':8, 'family':'Helvetica'})

#plt.savefig('pp-outage-map-entsoe-locations.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)