% this reads pre-processed state-station ASOS hourly wx files, processed by
% ag_processAsosPrecip.py

baseDir = '2015-weight-restriction-v2/airport-wx/processed/';
%baseDir = '2017-ag-precip/wx-data/';

stations = {'LHR'};

% this is for comma delimited ASOS data with the format:
% year, month, day, tmax, tmin
% -999 indicates a missing value
fileFormatStr = '%n %n %n %n %n %*[^\n]';

% process all files
for s = 1:length(stations)
    station = stations{s};
    
    obsData = {};
    
    if exist([baseDir 'airport-wx-obs-' station '.mat'], 'file')
        %continue;
    end
    
    fileName = [station '.txt'];

    % split the file name at the . and take the first part to get the
    % station code
    fileNameParts = strsplit(fileName, '.');
    code = fileNameParts{1};

    ['processing ' station '...']

    fin = fopen([baseDir '/' station '/' fileName]);

    % read weather file
    [data, pos] = textscan(fin, fileFormatStr, 'Delimiter', ',');

    % close current file
    fclose(fin);

    % columns:
    % 1 - year
    % 2 - month
    % 3 - day
    % 4 - tmax (C, -999 = missing value)
    % 5 - tmin (C, -999 = missing value)

    years = data{1};
    months = data{2};
    days = data{3};
    tmax = data{4};
    tmin = data{5};

    % remove missing values
    tmax(tmax == -999) = NaN;
    tmin(tmin == -999) = NaN;

    % find the daily max/min temps from the hourly data
    dailyMax = zeros(years(end)-years(1), 12, 31);
    dailyMin = zeros(years(end)-years(1), 12, 31);

    % set all inital values to nan
    dailyMax(dailyMax == 0) = NaN;
    dailyMin(dailyMin == 0) = NaN;

    % build year x month x day matrix of tmax/tmin
    for i = 1:length(tmax)
        dailyMax(years(i)-years(1)+1, months(i), days(i)) = tmax(i);
        dailyMin(years(i)-years(1)+1, months(i), days(i)) = tmin(i);
    end

    obsData = {station, years(1), months(1), days(1), dailyMax, dailyMin};
    save([baseDir 'airport-wx-obs-' station '.mat'], 'obsData', '-v7.3');

end
