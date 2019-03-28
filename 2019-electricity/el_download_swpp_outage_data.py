# -*- coding: utf-8 -*-
"""
Created on Tue Mar 26 12:51:01 2019

@author: Ethan
"""

import urllib.request
import ssl
import os

for year in range(2016, 2019):
    for month in range(1, 13):
        if year == 2016 and month < 10: continue
        for day in range(1, 32):
            url = 'http://marketplace.spp.org/file-api/download/capacity-of-generation-on-outage?path=%02d/%02d/Capacity-Gen-Outage-%d%02d%02d.csv' % (year, month, year, month, day)
            
            if os.path.isfile('e:/data/ecoffel/data/projects/electricity/swpp/swpp_%d_%d_%d.csv' % (year, month, day)):
                continue
            
            ssl._create_default_https_context = ssl._create_unverified_context
            try:
                urllib.request.urlretrieve(url, 'e:/data/ecoffel/data/projects/electricity/swpp/swpp_%d_%d_%d.csv' % (year, month, day))
                print('downloaded %d/%d/%d' % (year, month, day))
            except:
                print('failed %d/%d/%d' % (year, month, day))
                continue
            