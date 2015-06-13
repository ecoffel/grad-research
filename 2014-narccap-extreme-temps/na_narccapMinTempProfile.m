function narccapMinTempProfile(dataDir, outputDir)

ta850subDir = '/ta850/regrid';
ta850dirNames = dir([dataDir ta850subDir]);
ta850dirIndices = [ta850dirNames(:).isdir];
ta850dirNames = {ta850dirNames(ta850dirIndices).name}';

ta500subDir = '/ta500/regrid';
ta500dirNames = dir([dataDir ta500subDir]);
ta500dirIndices = [ta500dirNames(:).isdir];
ta500dirNames = {ta500dirNames(ta500dirIndices).name}';

ta300subDir = '/ta300/regrid';
ta300dirNames = dir([dataDir ta300subDir]);
ta300dirIndices = [ta300dirNames(:).isdir];
ta300dirNames = {ta300dirNames(ta300dirIndices).name}';

ta200subDir = '/ta200/regrid';
ta200dirNames = dir([dataDir ta200subDir]);
ta200dirIndices = [ta200dirNames(:).isdir];
ta200dirNames = {ta200dirNames(ta200dirIndices).name}';

if length(ta850dirNames) == 0
    ta850dirNames(1) = '';
end

if length(ta500dirNames) == 0
    ta500dirNames(1) = '';
end

if length(ta300dirNames) == 0
    ta300dirNames(1) = '';
end

if length(ta200dirNames) == 0
    ta200dirNames(1) = '';
end

yearIndex = 1981;
monthIndex = 1;

for d = 1:length(ta850dirNames)
    if strcmp(ta850dirNames{d}, '.') | strcmp(ta850dirNames{d}, '..')
        continue;
    end
    
    folDataTarget = [outputDir, '/airmin/regrid/', ta850dirNames{d}];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        continue;
    end
    
    ta850curDir = [dataDir ta850subDir '/' ta850dirNames{d}];
    ta850matFileNames = dir([ta850curDir, '/*.mat']);
	ta850matFileNames = {ta850matFileNames.name};
    
    ta500curDir = [dataDir ta500subDir '/' ta500dirNames{d}];
    ta500matFileNames = dir([ta500curDir, '/*.mat']);
	ta500matFileNames = {ta500matFileNames.name};
    
    ta300curDir = [dataDir ta300subDir '/' ta300dirNames{d}];
    ta300matFileNames = dir([ta300curDir, '/*.mat']);
	ta300matFileNames = {ta300matFileNames.name};
    
    ta200curDir = [dataDir ta200subDir '/' ta200dirNames{d}];
    ta200matFileNames = dir([ta200curDir, '/*.mat']);
	ta200matFileNames = {ta200matFileNames.name};
    
    monthIndex = 1;
    
    for k = 1:length(ta850matFileNames)
        ta850matFileName = ta850matFileNames{k};
        ta850matFileNameParts = strsplit(ta850matFileName, '.');
        ta850matFileNameNoExt = ta850matFileNameParts{1};
        ta850curFileName = [ta850curDir, '/', ta850matFileName];
        load(ta850curFileName);
        eval(['lat = ' ta850matFileNameNoExt '{1};']);
        eval(['lon = ' ta850matFileNameNoExt '{2};']);
        eval(['ta850data3Hr = ' ta850matFileNameNoExt '{3};']);
        eval(['clear ' ta850matFileNameNoExt ';']);
        
        ta500matFileName = ta500matFileNames{k};
        ta500matFileNameParts = strsplit(ta500matFileName, '.');
        ta500matFileNameNoExt = ta500matFileNameParts{1};
        ta500curFileName = [ta500curDir, '/', ta500matFileName];
        load(ta500curFileName);
        eval(['ta500data3Hr = ' ta500matFileNameNoExt '{3};']);
        eval(['clear ' ta500matFileNameNoExt ';']);
        
        ta300matFileName = ta300matFileNames{k};
        ta300matFileNameParts = strsplit(ta300matFileName, '.');
        ta300matFileNameNoExt = ta300matFileNameParts{1};
        ta300curFileName = [ta300curDir, '/', ta300matFileName];
        load(ta300curFileName);
        eval(['ta300data3Hr = ' ta300matFileNameNoExt '{3};']);
        eval(['clear ' ta300matFileNameNoExt ';']);
        
        ta200matFileName = ta200matFileNames{k};
        ta200matFileNameParts = strsplit(ta200matFileName, '.');
        ta200matFileNameNoExt = ta200matFileNameParts{1};
        ta200curFileName = [ta200curDir, '/', ta200matFileName];
        load(ta200curFileName);
        eval(['ta200data3Hr = ' ta200matFileNameNoExt '{3};']);
        eval(['clear ' ta200matFileNameNoExt ';']);
        
        curMonthMin = [];
        
        % find time of min surface temperature
        for xlat = 1:size(ta850data3Hr, 1)
            for ylon = 1:size(ta850data3Hr, 2)
                for h = 0:8:size(ta850data3Hr, 3)-8
                    minSurfIndex = -1;
                    minSurfTemp = -1;   
                    for i = h+1:h+8
                        if minSurfTemp > ta850data3Hr(xlat, ylon, i) | minSurfTemp == -1
                            minSurfTemp = ta850data3Hr(xlat, ylon, i);
                            minSurfIndex = i;
                        end
                    end
                    
                    % assign different plevels
                    curMonthMin(xlat, ylon, 2, (h+8)/8) = ta850data3Hr(xlat, ylon, minSurfIndex);
                    curMonthMin(xlat, ylon, 3, (h+8)/8) = ta500data3Hr(xlat, ylon, minSurfIndex);
                    curMonthMin(xlat, ylon, 4, (h+8)/8) = ta300data3Hr(xlat, ylon, minSurfIndex);
                    curMonthMin(xlat, ylon, 5, (h+8)/8) = ta200data3Hr(xlat, ylon, minSurfIndex);
                end
            end
        end
            
        
        curFileNameParts = strsplit(ta850matFileNameNoExt, '_');
        yearStr = curFileNameParts{2};
        monthStr = curFileNameParts{3};
        
        fileName = ['airmin_', yearStr, '_', monthStr, '_01']
        eval([fileName ' = {lat, lon, curMonthMin};']);
        save([folDataTarget, '/', fileName, '.mat'], fileName, '-v7.3');
        
        monthIndex = monthIndex+1;
        
        if monthIndex > 12
            monthIndex = 1;
            yearIndex = yearIndex + 1;
        end
        
        eval(['clear ', fileName], ';');
        clear lat lon ta850data3Hr ta500data3Hr ta300data3Hr ta200data3Hr curMonthMin;
    end
    
    yearIndex = yearIndex + 1;
end
