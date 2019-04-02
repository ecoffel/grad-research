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
import csv
import el_entsoe_utils


dataDir = 'e:/data/'

entsoeData = el_entsoe_utils.loadEntsoe(dataDir)
entsoeNames = entsoeData['names']
for n in range(len(entsoeNames)):
    entsoeNames[n] = entsoeNames[n].lower()

entsoeCountries = []
entsoeCapacities = []
entsoePlantType = []
entsoeLat = []
entsoeLon = []
with open('%s/ecoffel/data/projects/electricity/global_power_plant_database.csv'%dataDir,encoding='latin-1') as f:
    csv_reader = csv.reader(f, delimiter=',')
    i = 0
    for line in csv_reader:
        
        if i == 0:
            i += 1
            continue
        
        country = line[0]
        ppType = line[7]
        cap = float(line[4])
        
        if country in el_entsoe_utils.get3LetterEUCountryCodes() and \
            not ppType in ['Hydro', 'Solar', 'Wind', 'Geothermal', 'Other', 'Wave and Tidal'] and \
            cap > 100:
            name = line[2]
            entsoeCountries.append(country)
            entsoeCapacities.append(cap)
            entsoePlantType.append(ppType)
            entsoeLat.append(float(line[5]))
            entsoeLon.append(float(line[6]))
            
            ppCap = float(line[4])
            
        i += 1


entsoeLat = np.array(entsoeLat)
entsoeLon = np.array(entsoeLon)
nukeLatLon = np.genfromtxt('nuke-lat-lon.csv', delimiter=',')


fig = plt.figure(figsize=(6,6))
ax = plt.axes([0,0,1,1]) 
# A basic map
m=Basemap(llcrnrlon=-130, llcrnrlat=20,urcrnrlon=40,urcrnrlat=70)

m.drawmapboundary(fill_color='#A6CAE0', linewidth=0)
m.fillcontinents(color='grey', alpha=0.7, lake_color='grey')
m.drawcoastlines(linewidth=0.1, color="white")
m.drawstates()
m.drawcountries()

mSize = 15

# Add a marker per city of the data frame!
xpt, ypt = m(nukeLatLon[:,1], nukeLatLon[:,2])
m.scatter(ypt, xpt, s=mSize, color="orange", edgecolors="black", zorder=10)

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
     
    color = 'blue'
    if entsoePlantType[i] == 'Coal':
        coalInds.append(i)
        color = 'brown'
    elif entsoePlantType[i] == 'Gas':
        gasInds.append(i)
        color = 'red'
    elif entsoePlantType[i] == 'Oil':
        oilInds.append(i)
        color = 'black'
    elif entsoePlantType[i] == 'Nuclear':
        nukeInds.append(i)
        color = 'orange'
    elif entsoePlantType[i] == 'Biomass':
        bioInds.append(i)
        color = 'green'
    elif entsoePlantType[i] == 'Cogeneration':
        cogenInds.append(i)
        color = 'pink'



xpt, ypt = m(entsoeLat[np.array(coalInds)], entsoeLon[np.array(coalInds)])
m.scatter(ypt, xpt, s=mSize, color='brown', edgecolors="black", label='Coal', zorder=10)

xpt, ypt = m(entsoeLat[np.array(gasInds)], entsoeLon[np.array(gasInds)])
m.scatter(ypt, xpt, s=mSize, color='red', edgecolors="black", label='Gas', zorder=10)

xpt, ypt = m(entsoeLat[np.array(oilInds)], entsoeLon[np.array(oilInds)])
m.scatter(ypt, xpt, s=mSize, color='black', edgecolors="black", label='Oil', zorder=10)

xpt, ypt = m(entsoeLat[np.array(nukeInds)], entsoeLon[np.array(nukeInds)])
m.scatter(ypt, xpt, s=mSize, color='orange', edgecolors="black", label='Nuclear', zorder=10)

xpt, ypt = m(entsoeLat[np.array(bioInds)], entsoeLon[np.array(bioInds)])
m.scatter(ypt, xpt, s=mSize, color='green', edgecolors="black", label='Biomass', zorder=10)

xpt, ypt = m(entsoeLat[np.array(cogenInds)], entsoeLon[np.array(cogenInds)])
m.scatter(ypt, xpt, s=mSize, color='pink', edgecolors="black", label='Cogen', zorder=10)
plt.legend(markerscale=2, prop = {'size':8, 'family':'Helvetica'})
plt.savefig('pp-outage-map.png', format='png', dpi=1000, bbox_inches = 'tight', pad_inches = 0)