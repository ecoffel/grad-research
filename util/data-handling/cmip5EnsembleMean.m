% Calculates the ensemble mean for a specific variable over a specific time
% period.
% Notes: This must be run with different yearStart/yearEnd values for the
% base and future time periods, otherwise the ensemble mean files will be
% an average of the two.

baseDir = 'e:/data/';
var = 'tasmax';
isRegridded = true;
skipExistingFiles = false;

ensemble = 'r1i1p1';
rcp = 'rcp85';

% base period [1981-1999], future period [2051-2071]
if strcmp(rcp, 'historical')
    yearStart = 1981;
    yearEnd = 2005;
else
    yearStart = 2021;
    yearEnd = 2069;
end

modelBaseDir = 'cmip5/output';
models = {'ccsm4', 'cesm1-bgc', ...
          'gfdl-cm3', 'mpi-esm-mr', ...
          'gfdl-esm2m', 'gfdl-esm2g', ...
          'canesm2', 'noresm1-m', ...
          'hadgem2-es', 'cesm1-cam5', ...
          'cmcc-cm', 'cmcc-cms', ...
          'cnrm-cm5', 'ipsl-cm5a-mr', ...
          'bnu-esm', 'miroc-esm', ...
          'mri-cgcm3'};

% models = {'ccsm4', 'cesm1-bgc', ...
%           'gfdl-cm3', 'mpi-esm-mr', ...
%           'gfdl-esm2m', 'gfdl-esm2g', ...
%           'canesm2', 'noresm1-m', 'cesm1-cam5', ...
%           'cmcc-cm', 'cmcc-cms', ...
%           'cnrm-cm5', 'ipsl-cm5a-mr', ...
%           'bnu-esm'};

outputDir = ['cmip5/output/ensemble-mean/' ensemble '/' rcp];

allMatFiles = {};
allMatFileNames = {};
allMatFileNamesUniq = {};

% generate list of all .mat file names and directories for specified models
for v = 1:length(models)
    if isRegridded
        curDir = [baseDir, modelBaseDir, '/', models{v}, '/', ensemble, '/', rcp, '/', var, '/regrid'];
    else
        curDir = [baseDir, modelBaseDir, '/', models{v}, '/', ensemble, '/', rcp, '/', var];
    end
    dirNames = dir(curDir);
    dirIndices = [dirNames(:).isdir];
    dirNames = {dirNames(dirIndices).name}';
    
    if length(dirNames) == 0
        dirNames(1) = '';
    end
    
    for d = 1:length(dirNames)
        if strcmp(dirNames{d}, '.') | strcmp(dirNames{d}, '..') | strcmp(dirNames{d}, 'regrid')
            continue;
        end
        
        matFileNames = dir([curDir, '/', dirNames{d}, '/*.mat']);
        matFileNames = {matFileNames.name}';
        
        for n = 1:length(matFileNames)
            matFileParts = strsplit(matFileNames{n}, '_');
            fileYear = str2num(matFileParts{2});
            
            if fileYear >= yearStart & fileYear <= yearEnd
                allMatFiles = {allMatFiles{:} [curDir, '/', dirNames{d}, '/', matFileNames{n}]};
                allMatFileNamesUniq = {allMatFileNamesUniq{:} matFileNames{n}(1:end-7)};
                allMatFileNames = {allMatFileNames{:} matFileNames{n}};
            end
        end
    end
end

cnt = 0;
for n = 1:length(allMatFileNames)
    if length(allMatFileNames{n}) > 1
        ind = find(ismember(allMatFileNamesUniq, allMatFileNamesUniq{n}));
        
        outputDateFolder = [num2str(yearStart) '0101-' num2str(yearEnd) '1231'];
        %outputDateFolder = strsplit(allMatFiles{n}, '/');
        %outputDateFolder = outputDateFolder{end-1};
        targetDir = [baseDir, outputDir, '/', var, '/', outputDateFolder];
        
        if ~exist(targetDir)
            mkdir(targetDir);
        end
        
        if skipExistingFiles
            if exist([targetDir '/' allMatFileNames{n}], 'file') == 2
                continue;
            end
        end
        
        ensembleData = [];
        ensembleLat = [];
        ensembleLon = [];
        
        for i = 1:length(ind)
            load(allMatFiles{ind(i)});
            
            curMatName = strsplit(allMatFileNames{ind(i)}, '.');
            curMatName = curMatName{1};
            
            if length(ensembleLat) == 0 | length(ensembleLon) == 0
                ensembleLat = eval([curMatName, '{1}']);
                ensembleLon = eval([curMatName, '{2}']);
            end
            
            curData = eval([curMatName, '{3}']);
            if size(curData, 3) < 31
                curData = padarray(curData, [0 0 31-size(curData,3)], 'post');
            % if it is more than daily, take the mean
            elseif size(curData, 3) > 31 & mod(size(curData, 3), 31) == 0
                tmpCurData = [];
                mult = size(curData, 3)/31;
                for k = mult:mult:size(curData, 3)
                    tmpCurData(:, :, k/mult) = nanmean(curData(:,:,k-mult+1:k), 3);
                end
                curData = tmpCurData;
            end
            ensembleData(:,:,:,i) = curData(:,:,1:31);
            
            clear curData;
            eval(['clear ' curMatName ';']);
        end
        
        ensembleData(ensembleData == 0) = NaN;
        ensembleData = squeeze(nanmean(ensembleData, 4));
        ensembleData = {ensembleLat, ensembleLon, ensembleData};
        
        matVarName = strsplit(allMatFileNames{n}, '.');
        matVarName = matVarName{1};
        
        eval([matVarName ' = ensembleData;']);
        save([targetDir, '/', allMatFileNames{n}], matVarName, '-v7.3');
        
        [allMatFileNames{ind}] = deal('');
        [allMatFiles{ind}] = deal('');
        
        clear ensembleLat ensembleLon ensembleData;
        eval(['clear ' matVarName ';']);
        
        cnt = cnt+1;
        
        if mod(cnt, 50) == 0
            ['written ' num2str(cnt) ' files...']
        end
        
    end
end














