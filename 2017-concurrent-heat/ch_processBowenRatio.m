
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcps = {'historical', 'rcp85'};
ensembles = 1;

for m = 1:length(models)
    for r = 1:length(rcps)
        for e = ensembles
            ch_bowenRatio(['f:/data/cmip5/output/' models{m} '/r' num2str(e) 'i1p1/' rcps{r}]);
        end
    end
end