function [monthlyData] = loadMonthlyData(dataDir, varName, varargin)

monthlyData = [];

if mod(length(varargin), 2) ~= 0
    'Error: must have an even number of arg/val pairs'    
    return
end

plev = -1;
yearstart = -1;
yearend = -1;

for i=1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    switch key
        case 'plev'
            plev = val;
        case 'yearStart'
            yearstart = val;
        case 'yearEnd'
            yearend = val;
    end
end

dirNames = dir(dataDir);
dirIndices = [dirNames(:).isdir];
dirNames = {dirNames(dirIndices).name}';

if length(dirNames) == 0
    dirNames(1) = '';
end

startMonth = -1;
monthIndex = 1;

monthlyData = {};
lat = [];
lon = [];

for d = 1:length(dirNames)
    curDir = [dataDir '/' dirNames{d}];
    
    matFileNames = dir([curDir, '/*.mat']);
    matFileNames = {matFileNames.name};

    narccap = false;
    ncep = false;
    cmip5 = false;
    narr = false;
    hadex2 = false;
    
    if strfind(curDir, 'cmip5') ~= 0
        cmip5 = true;
    elseif strfind(curDir, 'narccap') ~= 0
        narccap = true;
    elseif strfind(curDir, 'ncep') ~= 0
        ncep = true;
    elseif strfind(curDir, 'narr') ~= 0
        narr = true;
    elseif strfind(curDir, 'hadex2') ~= 0
        hadex2 = true;
    end

    for k = 1:length(matFileNames)
        matFileName = matFileNames{k};

        % check if this file contains the target variable
        matFileNameParts = strsplit(matFileName, '_');
        if length(strfind(matFileNameParts{1}, varName)) == 0
            continue
        end

        matFileNameParts = strsplit(matFileName, '.');
        matFileNameNoExt = matFileNameParts{1};
        matFileNameParts = strsplit(matFileNameNoExt, '_');

        dataYear = 0;
        dataMonth = 0;

        if narccap
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
        elseif cmip5
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
        elseif ncep
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
        elseif narr
            if length(findstr('air_2m', matFileNameNoExt)) ~= 0
                dataYear = str2num(matFileNameParts{3});
                dataMonth = str2num(matFileNameParts{4});
            else
                dataYear = str2num(matFileNameParts{2});
                dataMonth = str2num(matFileNameParts{3});
            end
        elseif hadex2
            dataYear = -1;
            
            if strcmp(matFileNameParts{2}, 'ann')
                continue;
            end
            
            dataMonth = str2num(matFileNameParts{2});
        end
        
        if yearstart ~= -1 & dataYear < yearstart
            continue;
        elseif yearend ~= -1 & dataYear > yearend
            continue;
        end
        
        if dataMonth == startMonth
            monthIndex = monthIndex + 1;
        end

        if startMonth == -1
            startMonth = dataMonth;
        end

        curFileName = [curDir, '/', matFileName];
        load(curFileName);
        
        lat = double(eval([matFileNameNoExt, '{1}']));
        lon = double(eval([matFileNameNoExt, '{2}']));
        
        curMonthlyData = double(eval([matFileNameNoExt, '{3}']));
        
        if ~hadex2
            if plev ~= -1
                curMonthlyData = mean(squeeze(curMonthlyData(:,:,plev,:)), 3);
            else
                curMonthlyData = mean(squeeze(curMonthlyData(:,:,:)), 3);
            end

            monthlyData{dataMonth}{monthIndex} = {lat, lon, curMonthlyData(:,:)};
        else
            for y = 1:size(curMonthlyData, 3)
                monthlyData{dataMonth}{y} = {lat, lon, squeeze(curMonthlyData(:,:,y))};
            end
        end
        

        if length(lat) == 0
            lat = eval([matFileNameNoExt, '{1}']);
            lon = eval([matFileNameNoExt, '{2}']);
        end

        clear(matFileNameNoExt);
    end
end




