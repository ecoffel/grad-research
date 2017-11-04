
dataset = 'era';

if strcmp(dataset, 'cmip5')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

    rcps = {'historical', 'rcp85'};
    ensembles = 1;
elseif strcmp(dataset, 'ncep') || strcmp(dataset, 'era')
    models = {''};
    rcps = {''};
    ensembles = {''};
end

for m = 1:length(models)
    for r = 1:length(rcps)
        for e = ensembles
            if strcmp(dataset, 'ncep')
                ch_calcBowenRatio(['f:/data/ncep-reanalysis/output']);
            elseif strcmp(dataset, 'era')
                ch_calcBowenRatio(['e:/data/era-interim/output']);
            else
                ch_calcBowenRatio(['e:/data/cmip5/output/' models{m} '/r' num2str(e) 'i1p1/' rcps{r}]);
            end
        end
    end
end