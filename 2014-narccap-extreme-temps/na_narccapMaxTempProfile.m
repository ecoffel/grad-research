function narccapMaxTempProfile(dataDir, outputDir)

ta1000subDir = '/ta1000/regrid';
ta1000dirNames = dir([dataDir ta1000subDir]);
ta1000dirIndices = [ta1000dirNames(:).isdir];
ta1000dirNames = {ta1000dirNames(ta1000dirIndices).name}';

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

if length(ta1000dirNames) == 0
    ta1000dirNames(1) = '';
end

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

for d = 1:length(ta1000dirNames)
    if strcmp(ta1000dirNames{d}, '.') | strcmp(ta1000dirNames{d}, '..')
        continue;
    end
    
    folDataTarget = [outputDir, '/airmax/regrid/', ta1000dirNames{d}];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        continue;
    end
    
    ta1000curDir = [dataDir ta1000subDir '/' ta1000dirNames{d}];
    ta1000matFileNames = dir([ta1000curDir, '/*.mat']);
	ta1000matFileNames = {ta1000matFileNames.name};
    
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
    
    for k = 1:length(ta1000matFileNames)
        ta1000matFileName = ta1000matFileNames{k};
        ta1000matFileNameParts = strsplit(ta1000matFileName, '.');
        ta1000matFileNameNoExt = ta1000matFileNameParts{1};
        ta1000curFileName = [ta1000curDir, '/', ta1000matFileName];
        load(ta1000curFileName);
        eval(['lat = ' ta1000matFileNameNoExt '{1};']);
        eval(['lon = ' ta1000matFileNameNoExt '{2};']);
        eval(['ta1000data3Hr = ' ta1000matFileNameNoExt '{3};']);
        eval(['clear ' ta1000matFileNameNoExt ';']);
        
        ta850matFileName = ta850matFileNames{k};
        ta850matFileNameParts = strsplit(ta850matFileName, '.');
        ta850matFileNameNoExt = ta850matFileNameParts{1};
        ta850curFileName = [ta850curDir, '/', ta850matFileName];
        load(ta850curFileName);
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
        
        curMonthMax = [];
        
        find time of max surface temperature
        for xlat = 1:size(ta1000data3Hr, 1)
            for ylon = 1:size(ta1000data3Hr, 2)
                for h = 0:8:size(ta1000data3Hr, 3)-8
                    maxSurfIndex = -1;
                    maxSurfTemp = -1;   
                    for i = h+1:h+8
                        if maxSurfTemp < ta1000data3Hr(xlat, ylon, i) | maxSurfTemp == -1
                            maxSurfTemp = ta1000data3Hr(xlat, ylon, i);
                            maxSurfIndex = i;
                        end
                    end
                    
                    assign different plevels
                    curMonthMax(xlat, ylon, 1, (h+8)/8) = ta1000data3Hr(xlat, ylon, maxSurfIndex);
                    curMonthMax(xlat, ylon, 2, (h+8)/8) = ta850data3Hr(xlat, ylon, maxSurfIndex);
                    curMonthMax(xlat, ylon, 3, (h+8)/8) = ta500data3Hr(xlat, ylon, maxSurfIndex);
                    curMonthMax(xlat, ylon, 4, (h+8)/8) = ta300data3Hr(xlat, ylon, maxSurfIndex);
                    curMonthMax(xlat, ylon, 5, (h+8)/8) = ta200data3Hr(xlat, ylon, maxSurfIndex);
                    
                    for p = 1:size(ta1000data3Hr, 3)
                        curMonthMax(xlat, ylon, p, (h+8)/8) = data3Hr(xlat, ylon, p, maxSurfIndex);
                    end
                end
            end
        end
            
        
        curFileNameParts = strsplit(ta1000matFileNameNoExt, '_');
        yearStr = curFileNameParts{2};
        monthStr = curFileNameParts{3};
        
        fileName = ['airmax_', yearStr, '_', monthStr, '_01']
        eval([fileName ' = {lat, lon, curMonthMax};']);
        save([folDataTarget, '/', fileName, '.mat'], fileName, '-v7.3');
        
        monthIndex = monthIndex+1;
        
        if monthIndex > 12
            monthIndex = 1;
            yearIndex = yearIndex + 1;
        end
        
        eval(['clear ', fileName], ';');
        clear lat lon ta1000data3Hr ta850data3Hr ta500data3Hr ta300data3Hr ta200data3Hr curMonthMax;
    end
    
    yearIndex = yearIndex + 1;
end
