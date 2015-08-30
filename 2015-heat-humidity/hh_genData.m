models = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};

regions = {'west_africa'};
rcps = {'historical', 'rcp85'};
var = 'tasmax';

baseYears = 1980:2005;
futureYears = 2020:2070;

regridded = true;
skipExisting = true;
biasCorrect = true;
v7 = false;

for m = 1:length(models)
    for r = 1:length(regions)
        for rcp = 1:length(rcps)
            baseDir = ['E:\data\cmip5\output\' models{m} '\r1i1p1\' rcps{rcp} '\' var '\regrid'];
            dirNames = dir(baseDir);
            dirIndices = [dirNames(:).isdir];
            dirNames = {dirNames(dirIndices).name}';

            if length(dirNames) == 0
                dirNames(1) = '';
            end
            
            for d = 1:length(dirNames)
                curDir = [baseDir '/' dirNames{d}];
    
                if strcmp(dirNames{d}, '.') || strcmp(dirNames{d}, '..') || ismember(dirNames{d}, regions)
                    continue;
                end

                newDir = [baseDir '/' regions{r} '/' dirNames{d}];
                if ~isdir(newDir)
                    mkdir(newDir);
                end
                
                ['processing ' models{m} '/' regions{r} '/' rcps{rcp} '...']
                selectDataRegion(curDir, newDir, baseYears, futureYears, var, models{m}, regions{r}, biasCorrect, v7, skipExisting);
                
            end
        end
    end
end