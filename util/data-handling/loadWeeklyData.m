    function [weeklyData] = loadWeeklyData(dataDir, varargin)

lat = [];
lon = [];

weeklyData=[];
weeklyIndex = 1;

if mod(length(varargin), 2) ~= 0
    'Error: must have an even number of arg/val pairs'
    return
end

plev = -1;
curYear = -1;
yearEnd = -1;

for i=1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    switch key
        case 'plev'
            plev = val;
        case 'yearStart'
            curYear = val;
        case 'yearEnd'
            yearEnd = val;
        case 'initSize'
            weeklyData = nan(val);
    end
end

regridPlev = -1;

dirNames = dir(dataDir);
dirIndices = [dirNames(:).isdir];
dirNames = {dirNames(dirIndices).name}';

if length(dirNames) == 0
    dindirNames(1) = '';
end

for d = 1:length(dirNames)
    if length(find(isstrprop(dirNames{d}, 'digit'))) == 0
        continue;
    end

    curDir = [dataDir '/' dirNames{d}];
    matFileNames = dir([curDir, '/*.mat']);
    matFileNames = {matFileNames.name};

    narccap = false;
    ncep = false;
    cmip3 = false;
    cmip5 = false;
    narr = false;

    if strfind(curDir, 'cmip5') ~= 0
        cmip5 = true;
    elseif strfind(curDir, 'cmip3') ~= 0
        cmip3 = true;
    elseif strfind(curDir, 'narccap') ~= 0
        narccap = true;
    elseif strfind(curDir, 'ncep') ~= 0
        ncep = true;
    elseif strfind(curDir, 'narr') ~= 0
        narr = true;
    end

    if strfind(curDir, 'regrid') & plev ~= -1
        regridPlev = plev;
        plev = -1;
    end

    for k = 1:length(matFileNames)
        matFileName = matFileNames{k};

        matFileNameParts = strsplit(matFileName, '.');
        matFileNameNoExt = matFileNameParts{1};
        matFileNameParts = strsplit(matFileNameNoExt, '_');

        if regridPlev ~= -1 & length(matFileNameParts) > 4
            if regridPlev ~= str2num(matFileNameParts{5})
                continue;
            end
        end

        if narccap
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
            dataDay = str2num(matFileNameParts{4});
        elseif cmip5
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
            dataDay = str2num(matFileNameParts{4});
        elseif cmip3
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
            dataDay = str2num(matFileNameParts{4});
        elseif ncep
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
            dataDay = str2num(matFileNameParts{4});
        elseif narr
            if length(strfind(matFileNameNoExt, 'air_2m')) ~= 0
                dataYear = str2num(matFileNameParts{3});
                dataMonth = str2num(matFileNameParts{4});
                dataDay = str2num(matFileNameParts{5});
            else
                dataYear = str2num(matFileNameParts{2});
                dataMonth = str2num(matFileNameParts{3});
                dataDay = str2num(matFileNameParts{4});
            end
        end

        if curYear ~= -1 & dataYear < curYear
            continue;
        elseif yearEnd ~= -1 & dataYear > yearEnd
            continue;
        end

        if curYear == -1
            curYear = dataYear;
        elseif dataYear ~= curYear
            weeklyIndex = 1;
            curYear = dataYear;
        end

        curFileName = [curDir, '/', matFileName];
        load(curFileName);

        if length(lat) == 0 | length(lon) == 0
            lat = eval([matFileNameNoExt, '{1}']);
            lon = eval([matFileNameNoExt, '{2}']);
        end

        curWeeklyData = eval([matFileNameNoExt, '{3}']);

        if plev == -1 && regridPlev == -1
            weeklyData(:,:,weeklyIndex) = curWeeklyData(:,:);
        else
            if regridPlev ~= -1
                weeklyData(:,:,weeklyIndex) = curWeeklyData(:,:,regridPlev);
            else
                weeklyData(:,:,weeklyIndex) = curWeeklyData(:,:,plev);
            end
        end


        eval(['clear ' matFileNameNoExt]);
        clear curMonthlyData;
        weeklyIndex = weeklyIndex+1;
    end
end

weeklyData(weeklyData==0) = NaN;
weeklyData = {lat, lon, weeklyData};
