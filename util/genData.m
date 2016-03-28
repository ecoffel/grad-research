vars = {'tasmax', 'tasmin'};
ensembles = {'r1i1p1'};

% models = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'gfdl-cm3', ...
% 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-es', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m'};
models = {'ccsm4', 'cesm1-bgc', 'csiro-mk3-6-0', 'miroc-esm', 'mpi-esm-mr'};
regions = {'usne'};
rcps = {'historical', 'rcp45', 'rcp85'};

for e = 1:length(ensembles)
    ensemble = ensembles{e};
    for v = 1:length(vars)
        var = vars{v};

        baseYears = 1980:2005;
        futureYears = 2006:2090;    
        futureDecades = [2006, 2010, 2020, 2030, 2040, 2050, 2060, 2070, 2080, 2090];

        regridded = true;
        skipExisting = false;
        biasCorrect = true;
        v7 = false;

        bcStr = '';
        if biasCorrect
            bcStr = '-bc';
        else
            bcStr = '';
        end

        for m = 1:length(models)
            for r = 1:length(regions)
                for rcp = 1:length(rcps)
                    baseDir = ['E:\data\cmip5\output\' models{m} '\' ensemble '\' rcps{rcp} '\' var '\regrid\' regions{r}];
                    newBaseDir = ['E:\data\cmip5\output\' models{m} '\' ensemble '\' rcps{rcp} '\' var '\regrid\'];
                    dirNames = dir(baseDir);
                    dirIndices = [dirNames(:).isdir];
                    dirNames = {dirNames(dirIndices).name}';

                    if length(dirNames) == 0
                        dirNames(1) = '';
                    end

                    for d = 1:length(dirNames)
                        curDir = [baseDir '/' dirNames{d}];

                        if strcmp(dirNames{d}, '.') || strcmp(dirNames{d}, '..') || ismember(dirNames{d}, [regions bcStr])
                            continue;
                        end

                        newDir = [newBaseDir '/' regions{r} bcStr '/' dirNames{d}];
                        if ~isdir(newDir) && length(find(isstrprop(dirNames{d},'digit'))) > 0
                            mkdir(newDir);
                        end

                        ['processing ' models{m} '/' regions{r} bcStr '/' rcps{rcp} '...']
                        selectDataRegion(curDir, newDir, baseYears, futureYears, futureDecades, var, models{m}, rcps{rcp}, regions{r}, biasCorrect, v7, skipExisting);

                    end
                end
            end
        end
    end
end