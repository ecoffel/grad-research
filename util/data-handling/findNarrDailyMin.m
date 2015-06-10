function findNarrDailyMin(dataDir, outputDir)

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
    
    folDataTarget = [outputDir, '/tasmin/', dirNames{d}];
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
        
        curMonthMin = [];%zeros(277, 349, 30);
        
        for h = 0:8:size(data3Hr, 3)-8
            curMonthMin(:,:,(h+8)/8) = nanmin(data3Hr(:, :, h+1:h+8), [], 3);
        end
        
        monthStr = '';
        if monthIndex < 10
            monthStr = ['0', num2str(monthIndex)];
        else
            monthStr = num2str(monthIndex);
        end
        
        fileName = ['tasmin_', dirNames{d}, '_', monthStr, '_01'];
        eval([fileName ' = {lat, lon, curMonthMin};']);
        save([folDataTarget, '/', fileName, '.mat'], fileName, '-v7.3');
        
        monthIndex = monthIndex+1;
        eval(['clear ', fileName], ';');
        clear lat lon data3Hr curMonthMin;
    end
    
    yearIndex = yearIndex + 1;
end
