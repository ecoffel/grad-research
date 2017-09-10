% this reads pre-processed state-station ASOS hourly wx files, processed by
% ag_processAsosPrecip.py

baseDir = 'e:/data/projects/heat/asos/wx-data/';
%baseDir = '2017-ag-precip/wx-data/';

states = {'in', 'india'};

% this is for comma delimited ASOS data with the format:
% year, month, day, hour, lon, lat, tempC, relH, surf pressure, mslp
% -999 indicates a missing value
fileFormatStr = '%n %n %n %n %n %n %n %n %n %n %*[^\n]';

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
    
        % read weather file
        [data, pos] = textscan(fin, fileFormatStr, 'Delimiter', ',');

        % close current file
        fclose(fin);
        
        % columns:
        % 1 - year
        % 2 - month
        % 3 - day
        % 4 - hour
        % 5 - lon
        % 6 - lat
        % 7 - temp (C, -999 = missing value)
        % 8 - rel humidity (%, -999 = missing value)
        % 9 - surface pressure (in)
        % 10 - mslp (mb)

        years = data{1};
        months = data{2};
        days = data{3};
        hours = data{4};
        
        lons = data{5};
        lats = data{6};
        
        temps = data{7};
        temps(temps == -999) = NaN;
        
        relHs = data{8};
        relHs(relHs == -999) = NaN;
        
        % convert in to Pa
        surf = data{9} ;
        surf(surf == -999) = NaN;
        surf = surf .* 3386.39;
        
        % convert mb to Pa
        mslp = data{10};
        mslp(mslp == -999) = NaN;
        mslp = mslp .* 133.322;
        
        wb = [];
        
        % now calculate wet bulb for all obs
        ['computing wet bulb...']
        for i = 1:length(temps)
            % if we have all data for this timestep...
            if ~isnan(temps(i)) && ~isnan(relHs(i)) && ~isnan(surf(i))
                wb(i) = kopp_wetBulb(temps(i), surf(i), relHs(i), 1);
            else
                wb(i) = NaN;
            end
        end
        
        asosData{end+1} = {code, lons(1), lats(1), years, months, days, hours, temps, relHs, surf, mslp, wb};
    end
    
    save([baseDir 'asos-' state '.mat'], 'asosData', '-v7.3');
end
