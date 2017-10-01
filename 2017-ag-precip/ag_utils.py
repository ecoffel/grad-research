
def loadStateDb(path, nameKey):
    f = open(path, 'r')

    # key = ab, val = name
    db = {}

    # loop through state file - col 1 is the full name, col 2 is the abrev
    for line in f:
        # split at comma
        parts = line.split(',')

        # get parts, remove white space
        name = parts[0].strip().strip('"')
        ab = parts[1].strip().strip('"')

        # add to db
        if nameKey:
            db[name.lower()] = ab.lower()
        else:
            db[ab.lower()] = name.lower()
                  
    f.close()
    return db
        
def loadCountyDb(path):
    f = open(path, 'r')

    # key = state ab, val = list of county tuples (name, lat, lon)
    db = {}

    lineCnt = 0

    for line in f:
        # skip first line (header)
        if lineCnt > 0:
            parts = line.split('\t')

            # extract county parts from line
            state = parts[0].strip().lower()
            
            if state == 'la':
                name = parts[3].lower().replace('parish', '').strip().replace('st.', 'saint')
            else:
                name = parts[3].lower().replace('county', '').strip()
            
            lat = float(parts[10].strip())
            lon = float(parts[11].strip())

            # create county tuple
            county = (name, lat, lon)

            # add to county db
            if state in db:
                db[state].append(county)
            else:
                db[state] = [county]
        lineCnt += 1
        
    f.close()
    return db

def getCountyLatLon(countyDb, state, countyName):
    county = next((x for x in countyDb[state] if x[0] == countyName), (-1, -1,-1))
    return (county[1], county[2])

def loadStationWx(baseDir, state, station):
    
    f = open(baseDir + state + '/' + station + '.txt')
    
    wxData = {'year':[], 'month':[], 'day':[], 'hour':[], 'temp':[], 'precip':[]}
    
    for line in f:
        parts = line.split(',')
                
        year = int(parts[0].strip())
        month = int(parts[1].strip())
        day = int(parts[2].strip())
        hour = int(parts[3].strip())
        lon = float(parts[4].strip())
        lat = float(parts[5].strip())
        temp = float(parts[6].strip())
        precip = float(parts[7].strip())
        
        wxData['year'].append(year)
        wxData['month'].append(month)
        wxData['day'].append(day)
        wxData['hour'].append(hour)
        wxData['temp'].append(temp)
        wxData['precip'].append(precip)
    
    f.close()
    return wxData
    