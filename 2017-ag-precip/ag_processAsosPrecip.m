% this reads pre-processed state-station ASOS hourly wx files, processed by
% ag_processAsosPrecip.py

baseDir = 'e:/data/asos/wx-data/';
%baseDir = '2017-ag-precip/wx-data/';

states = {'ia', 'il', 'in', 'mo', 'ks', 'mn', 'ne', 'oh', 'sd', 'wi', 'tx', 'ok', 'ar', 'tn', 'nc'};

% this is for comma delimited ASOS data with the format:
% year, month, day, hour, lon, lat, tempC, relH, precipH
% -999 indicates a missing value
fileFormatStr = '%n %n %n %n %n %n %n %n %n %*[^\n]';

% process all files
for s = 1:length(states)
    state = states{s};
    
    asosData = {};
    
    curDir = [baseDir state];
    txtFileNames = dir([curDir, '/*.txt']);
    txtFileNames = {txtFileNames.name};
    
    if exist([baseDir 'asos-' state '.mat'], 'file')
        continue;
    end
    
    for f = 1:length(txtFileNames)
        fileName = txtFileNames{f};
        
        % split the file name at the . and take the first part to get the
        % station code
        fileNameParts = strsplit(fileName, '.');
        code = fileNameParts{1};
        
        ['processing ' state '/' code '...']
        
        fin = fopen([curDir '/' fileName]);
    
        [data, pos] = textscan(fin, fileFormatStr, 'Delimiter', ',');

        % columns:
        % 1 - year
        % 2 - month
        % 3 - day
        % 4 - hour
        % 5 - lon
        % 6 - lat
        % 7 - temp (C, -999 = missing value)
        % 8 - rel humidity (%, -999 = missing value)
        % 9 - precip (hourly, mm, -999 = missing value)

        years = data{1};
        months = data{2};
        days = data{3};
        hours = data{4};
        
        lons = data{5};
        lats = data{6};
        temps = data{7};
        relHs = data{8};
        precips = data{9};
        precips(precips == -999) = NaN;
        
        asosData{end+1} = {code, lons(1), lats(1), years, months, days, hours, temps, relHs, precips};
    end
    
    save([baseDir 'asos-' state '.mat'], 'asosData', '-v7.3');
end
