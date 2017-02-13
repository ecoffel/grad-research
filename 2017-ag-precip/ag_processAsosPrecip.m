% this reads pre-processed state-station ASOS hourly wx files, processed by
% ag_processAsosPrecip.py

baseDir = 'e:/data/asos/wx-data/';
%baseDir = '2017-ag-precip/wx-data/';

states = {'ia', 'il', 'in', 'mo'};

% this is for comma delimited ASOS data with the format:
% station, time, lon, lat, tempC, relH, precipH
fileFormatStr = '%n %n %n %n %n %n %n %n %n %*[^\n]';

% process all files
for s = 1:length(states)
    state = states{s};
    
    asosData = {};
    
    curDir = [baseDir state];
    txtFileNames = dir([curDir, '/*.txt']);
    txtFileNames = {txtFileNames.name};
    
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
        % 1 - station
        % 2 - date/time
        % 3 - lon
        % 4 - lat
        % 5 - temp (C)
        % 6 - rel humidity (%)
        % 7 - precip (hourly, mm, M = none)

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
    
    save(['asos-' state '.mat'], 'asosData');
end
