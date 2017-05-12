
dataset = 'ncep';

if strcmp(dataset, 'cmip5')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

    rcps = {'historical', 'rcp85'};
    ensembles = 1;
elseif strcmp(dataset, 'ncep')
    models = {''};
    rcps = {''};
    ensembles = {''};
end

for m = 1:length(models)
    for r = 1:length(rcps)
        for e = ensembles
            if strcmp(dataset, 'ncep')
                ch_bowenRatio(['e:/data/ncep-reanalysis/output']);
            else
                ch_bowenRatio(['e:/data/cmip5/output/' models{m} '/r' num2str(e) 'i1p1/' rcps{r}]);
            end
        end
    end
end