#%load_ext autoreload
#%autoreload 2
# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 15:09:30 2019

@author: Ethan
"""

import json
import el_readUSCRN

dataDir = '/dartfs-hpc/rc/lab/C/CMIG/'


filePath = dataDir + 'USCRN/2014/CRNH0203-2014-IA_Des_Moines_17_E.txt'
uscrn = el_readUSCRN.readUSCRN(filePath)

print('test = ', uscrn)

#eba = []
#
#for line in open(dataDir + 'projects/electricity/EBA.txt', 'r'):
#    print('loading line ', (len(eba)+1))
#    eba.append(json.loads(line))
#
##for e in range(len(eba)):
##    print(eba[e]['name'], e)
#    
#series = []
#for d in eba[585]['data']:
#    series.append(d[1])
#    
#series2 = []
#for d in eba[586]['data']:
#    series2.append(d[1])