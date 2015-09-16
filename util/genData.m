vars = {'tasmin'};

for v = 1:length(vars)
    var = vars{v};
    models = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
              'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};

    regions = {'usne'};
    rcps = {'historical', 'rcp85'};

    baseYears = 1980:2005;
    futureYears = 2020:2050;    
    futureDecades = 2020:10:2050;


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
                    if ~isdir(newDir) && length(find(isstrprop(dirNames{d},'digit'))) > 0
                        mkdir(newDir);
                    end

                    ['processing ' models{m} '/' regions{r} '/' rcps{rcp} '...']
                    selectDataRegion(curDir, newDir, baseYears, futureYears, futureDecades, var, models{m}, regions{r}, biasCorrect, v7, skipExisting);

                end
            end
        end
    end
end