
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 11 16:39:29 2019

@author: Ethan
"""

import numpy as np

#1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 
#WBANNO UTC_DATE UTC_TIME LST_DATE LST_TIME CRX_VN LONGITUDE LATITUDE T_CALC T_HR_AVG T_MAX T_MIN P_CALC SOLARAD SOLARAD_FLAG SOLARAD_MAX SOLARAD_MAX_FLAG SOLARAD_MIN SOLARAD_MIN_FLAG SUR_TEMP_TYPE SUR_TEMP SUR_TEMP_FLAG SUR_TEMP_MAX SUR_TEMP_MAX_FLAG SUR_TEMP_MIN SUR_TEMP_MIN_FLAG RH_HR_AVG RH_HR_AVG_FLAG SOIL_MOISTURE_5 SOIL_MOISTURE_10 SOIL_MOISTURE_20 SOIL_MOISTURE_50 SOIL_MOISTURE_100 SOIL_TEMP_5 SOIL_TEMP_10 SOIL_TEMP_20 SOIL_TEMP_50 SOIL_TEMP_100 
#XXXXX YYYYMMDD HHmm YYYYMMDD HHmm XXXXXX Decimal_degrees Decimal_degrees Celsius Celsius Celsius Celsius mm W/m^2 X W/m^2 X W/m^2 X X Celsius X Celsius X Celsius X % X m^3/m^3 m^3/m^3 m^3/m^3 m^3/m^3 m^3/m^3 Celsius Celsius Celsius Celsius Celsius 

def readUSCRN(path):
    data = {'year':[], 'month':[], 'day':[], 'hour':[], 'station':[], 'lat':0, 'lon':0, 'temp':[], 'rh':[]}
    with open(path, 'r') as f:
        for line in f:
            parts = line.split()
            
            data['year'].append(int(parts[1][0:4]))
            data['month'].append(int(parts[1][4:6]))
            data['day'].append(int(parts[1][6:8]))
            data['hour'].append(int(parts[2][0:2]))
            data['lon'] = float(parts[6])
            data['lat'] = float(parts[7])
            data['temp'].append(float(parts[9]))
            data['rh'].append(float(parts[26]))
            
    data['year'] = np.array(data['year'])
    data['month'] = np.array(data['month'])
    data['day'] = np.array(data['day'])
    data['hour'] = np.array(data['hour'])
    data['temp'] = np.array(data['temp'])
    data['rh'] = np.array(data['rh'])

    return data