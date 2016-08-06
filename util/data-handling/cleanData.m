% delete un-regridded data folders

% models = {'ccsm4', 'cesm1-bgc', ...
%           'gfdl-cm3', 'mpi-esm-mr', ...
%           'gfdl-esm2m', 'gfdl-esm2g', ...
%           'canesm2', 'noresm1-m', ...
%           'hadgem2-es', 'cesm1-cam5', ...
%           'cmcc-cm', 'cmcc-cms', ...
%           'cnrm-cm5', 'ipsl-cm5a-mr', ...
%           'bnu-esm', 'miroc-esm', ...
%           'mri-cgcm3'};
models = {'csiro-mk3-6-0'};    
vars = {'huss', 'psl'};
rcps = {'historical', 'rcp45', 'rcp85'};
ensembles = {'r1i1p1', 'r2i1p1', 'r3i1p1', 'r4i1p1', 'r5i1p1', 'r6i1p1', 'r7i1p1', 'r8i1p1', 'r9i1p1', 'r10i1p1',};

% should we just remove the regridded data or the whole variable
removeAll = true;

baseDir = 'e:\data\cmip5\output';

for m = 1:length(models)
    for e = 1:length(ensembles)
        for r = 1:length(rcps)
            for v = 1:length(vars)
                
                % select base folder for scenario
                if removeAll
                    curDir = [baseDir '\' models{m} '\' ensembles{e} '\' rcps{r}];
                % select folder for variable to select regrid dir
                else
                    curDir = [baseDir '\' models{m} '\' ensembles{e} '\' rcps{r} '\' vars{v}];
                end
                
                if ~isdir(curDir)
                    continue;
                end
                
                subDirs = dir(curDir);
                subDirInd = [subDirs(:).isdir];
                subDirs = {subDirs(subDirInd).name}';

                for d = 1:length(subDirs)
                    
                    if removeAll
                        % kill everything
                        if ~strcmp(subDirs{d}, vars{v})
                            continue;
                        else
                            delDir = [curDir '\' subDirs{d}]
                            rmdir(delDir, 's');
                        end
                    else
                        % keep everything in regrid
                        if strcmp(subDirs{d}, 'regrid') || strcmp(subDirs{d}, '.') || strcmp(subDirs{d}, '..')
                            continue;
                        % delete everything else
                        else
                            delDir = [curDir '\' subDirs{d}]
                            rmdir(delDir, 's');
                        end
                    end
                end
            end
        end
    end
end
