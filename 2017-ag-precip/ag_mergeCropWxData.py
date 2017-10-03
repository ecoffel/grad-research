# -*- coding: utf-8 -*-
"""
Created on Sat Sep 30 07:39:39 2017

@author: Ethan

Merges crop and asos data to create a dictionary with weather & yield data for each county
"""

import ag_utils
import pickle
import gzip
import sys
import geopy.distance
import numpy

baseDirCrop = '2017-ag-precip/'
baseDirWx = 'E:/data/projects/ag/wx-data/'

# leave blank to use all states
selectedStates = []

countyDb = ag_utils.loadCountyDb('E:/data/projects/ag/crop/counties.txt')

# max of 40 km between county center and asos station
distThresh = 40

# load the yield db
f = open(baseDirCrop + 'yield-db.dat', 'rb')
yieldDb = pickle.load(f)
f.close()

# the percentage of matched counties for each state
successRate = {}

# if no specific states selected, use all
if len(selectedStates) == 0:
    selectedStates = yieldDb.keys()

# loop over states
for state in selectedStates:

    # check if file already exists...
    if os.path.exists(baseDirCrop + 'merged-crop-wx-' + state + '.pgz'):
        continue
    
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
                
                # load the weather data for this station
                wxData = ag_utils.loadStationWx(baseDirWx, state, station)
                
                # find missing data
                tempMissingInd = numpy.where(wxData['temp'] == -999)
                precipMissingInd = numpy.where(wxData['precip'] == -999)
                
                # convert missing temp/precip to nan
                wxData['temp'] = wxData['temp'].astype('float')
                wxData['temp'][tempMissingInd] = numpy.nan
                
                wxData['precip'] = wxData['precip'].astype('float')
                wxData['precip'][precipMissingInd] = numpy.nan
                
                # calculate missing percentage
                tempMissingPercentage = numpy.size(tempMissingInd) / numpy.size(wxData['temp'])
                precipMissingPercentage = numpy.size(precipMissingInd) / numpy.size(wxData['precip'])
                
                # no data yet for this county or current station is closer...
                if len(mergedCropData[county]) == 0 or dist < mergedCropData[county]['distance'] or \
                   (tempMissingPercentage < mergedCropData[county]['tempMissingPercentage'] and precipMissingPercentage < mergedCropData[county]['precipMissingPercentage']):
                    
                    # a new county
                    if len(mergedCropData[county]) == 0:
                        numCountiesMatched += 1
                    
                    # record distance to this station
                    mergedCropData[county]['distance'] = dist
                    mergedCropData[county]['station'] = station
                    
                    mergedCropData[county]['tempMissingPercentage'] = tempMissingPercentage;
                    mergedCropData[county]['precipMissingPercentage'] = precipMissingPercentage;
                    
                    # add yield data
                    mergedCropData[county]['yield'] = yieldDb[state][county]
                    
                    # add hourly temp/precip data (dictionaries, key = year, value = list of hourly values)
                    mergedCropData[county]['year'] = wxData['year']
                    mergedCropData[county]['month'] = wxData['month']
                    mergedCropData[county]['day'] = wxData['day']
                    mergedCropData[county]['hour'] = wxData['hour']
                    mergedCropData[county]['temp'] = wxData['temp']
                    mergedCropData[county]['precip'] = wxData['precip']

    success = round(float(numCountiesMatched)/numCounties*100)
    successRate[state] = success
    print('matched ' + str(success) + '% of counties...')
    
    with gzip.GzipFile(baseDirCrop + '/merged-crop-wx-' + state + '.pgz', 'w') as fout:
        pickle.dump(mergedCropData, fout)
    
    del mergedCropData
            
    
    
