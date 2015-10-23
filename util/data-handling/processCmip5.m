vars = {'tasmax', 'tasmin', 'ta', 'huss', 'psl', 'rhs', 'pr', 'uas', 'vas'};

modelBaseDir = 'cmip5/raw';
models = {'csiro-mk3-6-0', 'ccsm4', 'cesm1-bgc', ...
          'gfdl-cm3', 'mpi-esm-mr', ...
          'gfdl-esm2m', 'gfdl-esm2g', ...
          'canesm2', 'noresm1-m', ...
          'hadgem2-es', 'hadgem2-cc', 'cesm1-cam5', ...
          'cmcc-cm', 'cmcc-cms', ...
          'cnrm-cm5', 'ipsl-cm5a-mr', ...
          'bnu-esm', 'miroc-esm', ...
          'mri-cgcm3'};

ensembles = {'r1i1p1', 'r2i1p1', 'r3i1p1', 'r4i1p1', 'r5i1p1'};
rcps = {'historical', 'rcp85', 'rcp45'};
      
for m = 1:length(models)
    for e = 1:length(ensembles)
        for r = 1:length(rcps)
            for v = 1:length(vars)
                cmip5NcToMat(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' vars{v}], 'e:/data/cmip5/output', vars{v}, -1);
            end
        end
    end
end