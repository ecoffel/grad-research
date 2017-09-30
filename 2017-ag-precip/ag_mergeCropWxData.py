# -*- coding: utf-8 -*-
"""
Created on Sat Sep 30 07:39:39 2017

@author: Ethan

Merges crop and asos data to create a dictionary with weather & yield data for each county
"""

import ag_utils
import pickle
import sys
import geopy.distance

baseDirCrop = '2017-ag-precip/'
baseDirWx = 'E:/data/projects/ag/wx-data/'

countyDb = ag_utils.loadCountyDb('E:/data/projects/ag/crop/counties.txt')

# max of 40 km between county center and asos station
distThresh = 40

# load the yield db
f = open(baseDirCrop + 'yield-db.dat', 'rb')
yieldDb = pickle.load(f)
f.close()

# the percentage of matched counties for each state
successRate = {}

# loop over states
for state in yieldDb.keys():

    # final result: dictionary(key = county name, 
    # value = dictionary(key = 'yield', 'temp', 'precip', value = data)
    mergedCropData = {}
    
    # try to load weather station locations for this state, skip if not found...
    fwx = 0
    wxDb = {}
    try:
        fwx = open(baseDirWx + 'asos-station-locations-' + state + '.dat', 'rb')
        wxDb = pickle.load(fwx)
    except:
        print('wx data for ' + state + ' not found, skipping...')
        continue

    # total number of counties in this state
    numCounties = len(yieldDb[state].keys())
    # how many have been matched with wx stations
    numCountiesMatched = 0
    
    # loop over all counties
    for county in yieldDb[state].keys():
        
        print('processing ' + state + '/' + county + '...')
        
        # create sub-dict for this county
        mergedCropData[county] = {}
        
        # search for the lat/lon of this county        
        [lat, lon] = ag_utils.getCountyLatLon(countyDb, state, county)
        
        # loop over all wx stations
        for station in wxDb.keys():
            # get lat/lon tuple of current station
            wxStationLocation = wxDb[station]
            
            # calculate distance (km) between station & county center
            dist = geopy.distance.distance((lat, lon), wxStationLocation).km
            
            # if station close enough to county
            if dist < distThresh:
                
                # no data yet for this county or current station is closer...
                if len(mergedCropData[county]) == 0 or dist < mergedCropData[county]['distance']:
                    
                    # a new county
                    if len(mergedCropData[county]) == 0:
                        numCountiesMatched += 1
                    
                    # record distance to this station
                    mergedCropData[county]['distance'] = dist
                    
                    # add yield data
                    mergedCropData[county]['yield'] = yieldDb[state][county]
                    
                    # load the weather data for this station
                    wxData = ag_utils.loadStationWx(baseDirWx, state, station)
                    
                    # add hourly temp/precip data (dictionaries, key = year, value = list of hourly values)
                    mergedCropData[county]['temp'] = wxData['temp']
                    mergedCropData[county]['precip'] = wxData['precip']

    success = round(float(numCountiesMatched)/numCounties*100)
    successRate[state] = success
    print('matched ' + str(success) + '% of counties...')
    
    fout = open(baseDirCrop + '/merged-crop-wx-' + state + '.dat', 'wb')
    pickle.dump(mergedCropData, fout)
    fout.close()
    
    del mergedCropData
            
    
    
