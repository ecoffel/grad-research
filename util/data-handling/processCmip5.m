vars = {'tas','pr'};

modelBaseDir = 'cmip5/raw';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

ensembles = {'r1i1p1', 'r2i1p1', 'r3i1p1', 'r4i1p1', 'r5i1p1', 'r6i1p1', 'r7i1p1', 'r8i1p1', 'r9i1p1', 'r10i1p1', 'r11i1p1', 'r12i1p1'};
rcps = {'historical', 'rcp45', 'rcp85'};
      
for m = 1:length(models)
    for e = 1:length(ensembles)
        for r = 1:length(rcps)
            for v = 1:length(vars)
                %cmip5NcToMat_monthly(['d:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' vars{v}], 'd:/data/cmip5/output', vars{v}, -1);
                cmip5NcToMat_monthly_v2(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' vars{v}], 'e:/data/cmip5/output', vars{v});
                %cmip5NcToMat(['e:/data/' modelBaseDir '/' models{m} '/' ensembles{e} '/' rcps{r} '/' vars{v}], 'e:/data/cmip5/output', vars{v}, -1);
            end
        end
    end
end