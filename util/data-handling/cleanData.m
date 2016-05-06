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
models = {'bcc-csm1-1-m'};      
vars = {'tasmax', 'tasmin'};
rcps = {'historical', 'rcp45', 'rcp85'};
ensembles = {'r1i1p1'};

baseDir = 'e:\data\cmip5\output';

for m = 1:length(models)
    for e = 1:length(ensembles)
        for r = 1:length(rcps)
            for v = 1:length(vars)
                curDir = [baseDir '\' models{m} '\' ensembles{e} '\' rcps{r} '\' vars{v}];
                
                if ~isdir(curDir)
                    continue;
                end
                
                subDirs = dir(curDir);
                subDirInd = [subDirs(:).isdir];
                subDirs = {subDirs(subDirInd).name}';

                for d = 1:length(subDirs)
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
