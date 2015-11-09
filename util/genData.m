vars = {'tasmin', 'tasmax'};
ensembles = {'r6i1p1', 'r7i1p1', 'r8i1p1', 'r9i1p1', 'r10i1p1'};

models = {'csiro-mk3-6-0'};
%     models = {'bnu-esm', 'canesm2', 'cnrm-cm5', 'gfdl-cm3', ...
%               'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m', 'cmcc-cm', 'cmcc-cms'};

regions = {'usne'};
rcps = {'historical', 'rcp85'};

for e = 1:length(ensembles)
    ensemble = ensembles{e};
    for v = 1:length(vars)
        var = vars{v};

        baseYears = 1980:2005;
        futureYears = 2006:2060;    
        futureDecades = [2006, 2010, 2020, 2030, 2040, 2050, 2060];

        regridded = true;
        skipExisting = false;
        biasCorrect = true;
        v7 = false;

        bcStr = '';
        if biasCorrect
            bcStr = 'bc';
        else
            bcStr = 'nbc';
        end

        for m = 1:length(models)
            for r = 1:length(regions)
                for rcp = 1:length(rcps)
                    baseDir = ['E:\data\cmip5\output\' models{m} '\' ensemble '\' rcps{rcp} '\' var '\regrid'];
                    dirNames = dir(baseDir);
                    dirIndices = [dirNames(:).isdir];
                    dirNames = {dirNames(dirIndices).name}';

                    if length(dirNames) == 0
                        dirNames(1) = '';
                    end

                    for d = 1:length(dirNames)
                        curDir = [baseDir '/' dirNames{d}];

                        if strcmp(dirNames{d}, '.') || strcmp(dirNames{d}, '..') || ismember(dirNames{d}, [regions '-' bcStr])
                            continue;
                        end

                        newDir = [baseDir '/' regions{r} '-' bcStr '/' dirNames{d}];
                        if ~isdir(newDir) && length(find(isstrprop(dirNames{d},'digit'))) > 0
                            mkdir(newDir);
                        end

                        ['processing ' models{m} '/' regions{r} '-' bcStr '/' rcps{rcp} '...']
                        selectDataRegion(curDir, newDir, baseYears, futureYears, futureDecades, var, models{m}, regions{r}, biasCorrect, v7, skipExisting);

                    end
                end
            end
        end
    end
end