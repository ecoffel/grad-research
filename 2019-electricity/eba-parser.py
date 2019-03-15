
# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 15:09:30 2019

@author: Ethan
"""

import json
import el_readUSCRN
import el_cooling_tower_model
import matplotlib.pyplot as plt 
import numpy as np
import math
import sys

dataDir = '/dartfs-hpc/rc/lab/C/CMIG'

if not 'eba' in locals():
    print('loading eba...')
    eba = []

    for line in open('%s/ecoffel/data/projects/electricity/EBA.txt' % dataDir, 'r'):
        if (len(eba)+1) % 100 == 0:
            print('loading line ', (len(eba)+1))
        eba.append(json.loads(line))

temp = []
rh = []

netGenTx = []
netIntTx = []

for year in range(2015, 2016):
    filePath = '%s/USCRN/%d/CRNH0203-%d-TX_Austin_33_NW.txt' % (dataDir, year, year)
    uscrn = el_readUSCRN.readUSCRN(filePath)
    
    print('matching year %d' % year)

    lastDind = 0

    # loop through all obs from the uscrn file for current year
    for o in range(len(uscrn['year'])):

        if o % 1000 == 0:
            print('o = %d' % o)

        for dind in range(lastDind, len(eba[547]['data'])):
            d = eba[547]['data'][dind]
            ebaYr = int(d[0][0:4])
            ebaMn = int(d[0][4:6])
            ebaDay = int(d[0][6:8])
            ebaHr = int(d[0][9:11])

            # found a matching obs with current generation data point
            if ebaYr == uscrn['year'][o] and \
               ebaMn == uscrn['month'][o] and \
               ebaDay == uscrn['day'][o] and \
               ebaHr == uscrn['hour'][o]:

                print('added %d/%d/%d/%d' % (ebaYr, ebaMn, ebaDay, ebaHr))
                netGenTx.append(d[1])
                temp.append(uscrn['temp'][o])
                rh.append(uscrn['rh'][o])
                lastDind = dind

        # for d in eba[586]['data']:
        #     ebaYr = int(d[0][0:4])
        #     ebaMn = int(d[0][5:6])
        #     ebaDay = int(d[0][7:8])
        #     ebaHr = int(d[0][10:11])
        #
        #     # found a matching obs with current interchange data point
        #     if ebaYr == obs['year'] and \
        #        ebaMn == obs['month'] and \
        #        ebaDay == obs['day'] and \
        #        ebaHr == obs['hour']:
        #
        #         netIntTx.append(d[1])

        #temp = np.append(temp, np.array(uscrn['temp']))
        #rh = np.append(rh, np.array(uscrn['rh']))

sys.exit()
print('done')

#temp[temp<-100] = np.nan
tempNan = np.isnan(temp)
#rh[rh<-100] = np.nan
rhNan = np.isnan(rh)

nn = np.where(rhNan | tempNan == False)
tempNn = temp[nn[0]]
rhNn = rh[nn[0]]

t99 = np.nanpercentile(tempNn, 99)
t99Ind = np.where(tempNn>t99)[0]
rh99Mean = np.mean(rhNn[np.where(tempNn>t99)[0]])

eff = []
curtail = []

for i in t99Ind:
    (e, c) = el_cooling_tower_model.coolingTowerEfficiency(tempNn[i], rhNn[i], t99, rh99Mean)
    eff.append(e)
    curtail.append(c)




#for e in range(len(eba)):
#    print(eba[e]['name'], e)
#    


print('done')