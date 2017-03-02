% this reads pre-processed state-station ASOS hourly wx files, processed by
% ag_processAsosPrecip.py

baseDir = '2015-weight-restriction-v2/airport-wx/processed/';
%baseDir = '2017-ag-precip/wx-data/';

states = {'il', 'ny', 'co', 'ca', 'tx', 'fl', 'va'};

% this is for comma delimited ASOS data with the format:
% year, month, day, hour, lon, lat, tempC, relH, precipH
% -999 indicates a missing value
fileFormatStr = '%n %n %n %n %n %*[^\n]';

% process all files
for s = 1:length(states)
    state = states{s};
    
    asosData = {};
    
    curDir = [baseDir state];
    txtFileNames = dir([curDir, '/*.txt']);
    txtFileNames = {txtFileNames.name};
    
    if exist([baseDir 'asos-' state '.mat'], 'file')
        %continue;
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
        % 5 - temp (C, -999 = missing value)

        years = data{1};
        months = data{2};
        days = data{3};
        hours = data{4};
        temps = data{5};
        
        % remove missing values
        temps(temps == -999) = NaN;
        
        % find the daily max/min temps from the hourly data
        dailyMax = zeros(years(end)-years(1), 12, 31);
        dailyMin = zeros(years(end)-years(1), 12, 31);
        
        % set all inital values to nan
        dailyMax(dailyMax == 0) = NaN;
        dailyMin(dailyMin == 0) = NaN;
        
        lastHourInd = -1;
        for i = 1:length(hours)
            % found a new day...
            if hours(i) == 0
                % if we're not on the first reading
                if lastHourInd ~= -1
                    % take temp data for current day
                    tempsDay = temps(lastHourInd:i-1);
                    dailyMax(years(i-1) - years(1) + 1, months(i-1), days(i-1)) = nanmax(tempsDay);
                    dailyMin(years(i-1) - years(1) + 1, months(i-1), days(i-1)) = nanmin(tempsDay);
                end
                
                lastHourInd = i;
            end
        end
        
        asosData = {code, years(1), months(1), days(1), dailyMax, dailyMin};
        save([baseDir 'airport-wx-obs-' code '.mat'], 'asosData', '-v7.3');
    end
    
    
end
