function [dailyData] = loadDailyData(dataDir, varargin)

lat = [];
lon = [];

dailyData=[];
dailyIndex = 1;
monthlyIndex = 1;
yearlyIndex = 1;

if mod(length(varargin), 2) ~= 0
    'Error: must have an even number of arg/val pairs'
    return
end

plev = -1;
curYear = -1;
yearEnd = -1;
obs = false;
obsAirport = '';
mult = -1;
multMethod = '';

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
            dailyData = nan(val);
        case 'obs'
            obs = val;
        case 'obsAirport'
            obsAirport = val;
        case 'mult'
            mult = val;
        case 'multMethod'
            multMethod = val;
    end
end

regridPlev = -1;

if ~obs
    dirNames = dir(dataDir);
    dirIndices = [dirNames(:).isdir];
    dirNames = {dirNames(dirIndices).name}';

    if length(dirNames) == 0
        dirNames(1) = '';
    end

    for d = 1:length(dirNames)
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
                yearlyIndex = yearlyIndex+1;
                monthlyIndex = 1;
                curYear = dataYear;
            end

            curFileName = [curDir, '/', matFileName];
            load(curFileName);

            if length(lat) == 0 | length(lon) == 0
                lat = eval([matFileNameNoExt, '{1}']);
                lon = eval([matFileNameNoExt, '{2}']);
            end

            curMonthlyData = eval([matFileNameNoExt, '{3}']);
            
            % if we have more than 31 observations, determinine the length
            % of the month and then average over values for each day
            if mult ~= -1 & mult ~= 1
                tmpCurData = [];
                if strcmp(multMethod, 'mean')
                    for k = mult:mult:size(curMonthlyData, 3)
                        tmpCurData(:, :, k/mult) = nanmean(curMonthlyData(:,:,k-mult+1:k), 3);
                    end
                elseif strcmp(multMethod, 'sum')
                    for k = mult:mult:size(curMonthlyData, 3)
                        tmpCurData(:, :, k/mult) = nansum(curMonthlyData(:,:,k-mult+1:k), 3);
                    end
                end
                curMonthlyData = tmpCurData;
            end

            for d=1:size(curMonthlyData,length(size(curMonthlyData)))
                if d <= size(curMonthlyData, length(size(curMonthlyData)))
                    if plev == -1 && regridPlev == -1
                        dailyData(:,:,yearlyIndex, monthlyIndex, dailyIndex) = curMonthlyData(:,:,d);
                    else
                        if regridPlev ~= -1
                            dailyData(:,:,yearlyIndex, monthlyIndex, dailyIndex) = curMonthlyData(:,:,regridPlev,d);
                        else
                            dailyData(:,:,yearlyIndex, monthlyIndex, dailyIndex) = curMonthlyData(:,:,plev,d);
                        end
                    end
                else
                    dailyData(:,:,yearlyIndex, monthlyIndex, dailyIndex) = NaN(size(curMonthlyData,1), size(curMonthlyData,2));
                end
                dailyIndex=dailyIndex+1;
            end

            eval(['clear ' matFileNameNoExt]);
            clear curMonthlyData;
            monthlyIndex = monthlyIndex+1;
            dailyIndex = 1;
        end
    end
    dailyData(dailyData==0) = NaN;
    dailyData = {lat, lon, dailyData};
elseif strcmp(obs, 'asos-5')
    dailyData = {};
    for y = curYear:yearEnd
        for m = 1:12
            eval(['load(''', dataDir, '/wx_', obsAirport, '_', num2str(y), '_', sprintf('%02d', m), ''');']);
            eval(['curData = wx_', obsAirport, '_', num2str(y), '_', sprintf('%02d', m), ';']);
            if length(dailyData) > 0
                dailyData = {[dailyData{1}; cell2mat(cellfun(@(x) x{3}, curData, 'UniformOutput', false))'], ...
                              [dailyData{2}; cell2mat(cellfun(@(x) x{4}, curData, 'UniformOutput', false))'], ...
                              [dailyData{3}; cell2mat(cellfun(@(x) x{5}, curData, 'UniformOutput', false))'], ...
                              [dailyData{4}; cell2mat(cellfun(@(x) x{6}, curData, 'UniformOutput', false))'], ...
                              [dailyData{5}; cell2mat(cellfun(@(x) x{7}, curData, 'UniformOutput', false))']};
            else
                dailyData = {cell2mat(cellfun(@(x) x{3}, curData, 'UniformOutput', false))', ...
                              cell2mat(cellfun(@(x) x{4}, curData, 'UniformOutput', false))', ...
                              cell2mat(cellfun(@(x) x{5}, curData, 'UniformOutput', false))', ...
                              cell2mat(cellfun(@(x) x{6}, curData, 'UniformOutput', false))', ...
                              cell2mat(cellfun(@(x) x{7}, curData, 'UniformOutput', false))'};
            end
            eval(['clear wx_', obsAirport, '_', num2str(y), '_', sprintf('%02d', m), ';']);
            clear curData;
        end
    end
elseif strcmp(obs, 'daily')
    dailyData = [];
    
    curDir = [dataDir];
    matFileNames = dir([curDir, '/*.mat']);
    matFileNames = {matFileNames.name};
    
    for i = 1:length(matFileNames)
        curFile = matFileNames{i};
        curFileExt = strsplit(curFile, '.');
        curFileParts = strsplit(curFileExt{1}, '_');
        
        fileYear = str2num(curFileParts{3});
        fileMonth = str2num(curFileParts{4});
        fileCode = curFileParts{2};
        
        if fileYear >= curYear & fileYear <= yearEnd & strcmp(fileCode, obsAirport)
            eval(['load(''', dataDir, '/', curFileExt{1}, '.mat', ''');']);
            eval(['curData = ', curFileExt{1}, ';']);
            
            for d = 1:31
                if d <= length(curData)
                    dailyData(fileYear-curYear+1, fileMonth, d) = curData(d);
                else
                    dailyData(fileYear-curYear+1, fileMonth, d) = NaN;
                end
            end
            
            eval(['clear ', curFileExt{1}, ';']);
            clear curData;
        else
            continue;
        end
        
    end
end
end
