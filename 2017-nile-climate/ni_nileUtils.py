# -*- coding: utf-8 -*-
"""
Created on Sat Oct  7 14:23:57 2017

@author: Ethan
"""

import csv
import numpy

def readModelData(path):
    models = []
    tempHistorical = {}

    with open(path, 'r') as csvfile:
        data = csv.reader(csvfile, delimiter=',')

        line = 1

        for row in data:
            # on the header line
            if line == 1:
                # break apart the date and store it
                tempHistorical['Year'] = []
                tempHistorical['Month'] = []
                tempHistorical['Day'] = []
                
                # loop over all model header cols
                for i in range(1, len(row)):
                    row[i] = row[i].replace('"', '').replace("'", '').strip()
                    # if it's not a blank col, store it in the model list and as a new key in the dict
                    if len(row[i]) > 0:
                        models.append(row[i])
                        tempHistorical[row[i]] = []
            else:
                # if not on first line, grab data for time
                timeParts = row[0].replace("'", '').strip().split('/')
                if len(timeParts) == 3:
                    tempHistorical['Month'].append(float(timeParts[0]))
                    tempHistorical['Year'].append(float(timeParts[2]))
                
                    # and for each model
                    for i in range(2, len(models)+2):
                        value = None
                        # try to convert to float, keep as None if it fails
                        try:
                            value = float(row[i].replace("'", '').replace('"', '').strip())
                        except:
                            pass
                        tempHistorical[models[i-2]].append(value)
            line += 1


    # convert all cols to numpy arrays
    for key in list(tempHistorical.keys()):
        tempHistorical[key] = numpy.array(tempHistorical[key])
        
        # convert any None values into numpy.nan
        ind = numpy.where(tempHistorical[key] == None)
        tempHistorical[key][ind] = numpy.nan
    
    return [tempHistorical, models]
