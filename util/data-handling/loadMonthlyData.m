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

yearInd = 1;
lastYear = -1;

monthlyData = {[],[],[]};
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
    gpcp = false;
    gldas = false;
    
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
    elseif strfind(curDir, 'gpcp') ~= 0
        gpcp = true;
    elseif strfind(curDir, 'gldas') ~= 0
        gldas = true;
    end
        

    for k = 1:length(matFileNames)
        matFileName = matFileNames{k};

        % check if this file contains the target variable
        matFileNameParts = strsplit(matFileName, '_');
        if length(strfind(matFileName, varName)) == 0
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
        elseif gpcp
            dataYear = str2num(matFileNameParts{2});
            dataMonth = str2num(matFileNameParts{3});
        elseif gldas
            dataYear = str2num(matFileNameParts{end-2});
            dataMonth = str2num(matFileNameParts{end-1});
        end
        
        if yearstart ~= -1 & dataYear < yearstart
            continue;
        elseif yearend ~= -1 & dataYear > yearend
            continue;
        end
        
        % first year
        if lastYear == -1
            lastYear = dataYear;
        end
        
        % new year
        if dataYear ~= lastYear
            lastYear = dataYear;
            yearInd = yearInd + 1;
        end

        curFileName = [curDir, '/', matFileName];
        load(curFileName);
        
        lat = double(eval([matFileNameNoExt, '{1}']));
        lon = double(eval([matFileNameNoExt, '{2}']));
        
        % first file - set lat/lon
        if length(monthlyData{1}) == 0
            monthlyData{1} = lat;
            monthlyData{2} = lon;
        end
        
        curMonthlyData = double(eval([matFileNameNoExt, '{3}']));
        
        if gpcp
            monthlyData{3}(:,:,yearInd,dataMonth) = squeeze(curMonthlyData);
        elseif gldas
            monthlyData{3}(:,:,yearInd,dataMonth) = squeeze(curMonthlyData);
        elseif ~hadex2
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




