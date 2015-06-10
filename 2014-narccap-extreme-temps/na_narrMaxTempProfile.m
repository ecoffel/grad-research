function na_narrMaxTempProfile(dataDir, outputDir)

dirNames = dir(dataDir);
dirIndices = [dirNames(:).isdir];
dirNames = {dirNames(dirIndices).name}';

if length(dirNames) == 0
    dirNames(1) = '';
end

yearIndex = 1;
monthIndex = 1;

for d = 1:length(dirNames)
    if strcmp(dirNames{d}, '.') | strcmp(dirNames{d}, '..')
        continue;
    end
    
    folDataTarget = [outputDir, '/airmax/', dirNames{d}];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        continue;
    end
    
    curDir = [dataDir '/' dirNames{d}]
    matFileNames = dir([curDir, '/*.mat']);
	matFileNames = {matFileNames.name};
    
    monthIndex = 1;
    
    for k = 1:length(matFileNames)
        matFileName = matFileNames{k};
        matFileNameParts = strsplit(matFileName, '.');
        matFileNameNoExt = matFileNameParts{1};
        
        curFileName = [curDir, '/', matFileName];
        
        load(curFileName);

        eval(['lat = ' matFileNameNoExt '{1};']);
        eval(['lon = ' matFileNameNoExt '{2};']);
        eval(['data3Hr = ' matFileNameNoExt '{3};']);
        eval(['clear ' matFileNameNoExt ';']);
        
        curMonthMax = [];
        
        
        % find time of max surface temperature
        for xlat = 1:size(data3Hr, 1)
            for ylon = 1:size(data3Hr, 2)
                for h = 0:8:size(data3Hr, 4)-8
                    maxSurfIndex = -1;
                    maxSurfTemp = -1;   
                    for i = h+1:h+8
                        if maxSurfTemp < data3Hr(xlat, ylon, 1, i) | maxSurfTemp == -1
                            maxSurfTemp = data3Hr(xlat, ylon, 1, i);
                            maxSurfIndex = i;
                        end
                    end
                    
                    for p = 1:size(data3Hr, 3)
                        curMonthMax(xlat, ylon, p, (h+8)/8) = data3Hr(xlat, ylon, p, maxSurfIndex);
                    end
                end
            end
        end
            
        
        monthStr = '';
        if monthIndex < 10
            monthStr = ['0', num2str(monthIndex)];
        else
            monthStr = num2str(monthIndex);
        end
        
        fileName = ['airmax_', dirNames{d}, '_', monthStr, '_01'];
        eval([fileName ' = {lat, lon, curMonthMax};']);
        save([folDataTarget, '/', fileName, '.mat'], fileName, '-v7.3');
        
        monthIndex = monthIndex+1;
        eval(['clear ', fileName], ';');
        clear lat lon data3Hr curMonthMax;
    end
    
    yearIndex = yearIndex + 1;
end
