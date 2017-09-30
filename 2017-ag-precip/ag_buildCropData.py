import ag_utils
import pickle

baseDir = 'e:/data/projects/ag/crop/'
yieldFiles = ['corn-yield-al-ia-1970-2015.csv', \
             'corn-yield-ks-ne-1970-2015.csv', \
             'corn-yield-nj-wy-1970-2015.csv']

# load state db with the key as the name and value as abrev
stateDb = ag_utils.loadStateDb(baseDir + 'states.csv', True)

countyDb = ag_utils.loadCountyDb(baseDir + 'counties.txt')

# key = state ab
# val = dictionary(key = county name, value = dictionary(key = year, val = yield))
yieldDB = {}

for fileName in yieldFiles:
    print('processing ' + fileName + '...')

    f = open(baseDir + fileName, 'r')

    # columns:
    # 1 - year (int)
    # 5 - state name (str)
    # 6 - state ID (int)
    # 7 - ag district (str)
    # 8 - ag district ID (int)
    # 9 - county name (str)
    # 10 - county ID (int)
    # 21 - value (float)

    lineCnt = 1

    # loop over each line of yield file
    for line in f:
        # skip header line
        if lineCnt > 1:
            parts = line.split(',')
    
            # extract data from line
            year = int(parts[1].strip().strip('"'))
            stateName = parts[5].strip().strip('"').lower()
            countyName = parts[9].strip().strip('"').lower()
            yieldValue = float(parts[21].strip().strip('"'))
    
            # find the abreviation for current state using the db
            stateAb = stateDb[stateName]
    
            # add yield data to the db
            if stateAb in yieldDB:
                # if county already exists, add new year to yied dictionary
                if countyName in yieldDB[stateAb]:
                    yieldDB[stateAb][countyName][year] = yieldValue
                # no county, create new key for this county 
                else:
                    yieldDB[stateAb][countyName] = {year:yieldValue}
            # no state, create new dictionary for state that contains current county
            else:
                yieldDB[stateAb] = {countyName:{year:yieldValue}}
        lineCnt += 1

print('writing output file...')
f = open('yield-db.dat', 'wb')
pickle.dump(yieldDB, f)        
f.close()
        
