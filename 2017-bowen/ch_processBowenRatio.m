
dataset = 'cmip5';

if strcmp(dataset, 'cmip5')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

    rcps = {'historical', 'rcp85'};
    ensembles = 1;
elseif strcmp(dataset, 'ncep') || strcmp(dataset, 'era')
    models = {''};
    rcps = {''};
    ensembles = {''};
end

models = {'bnu-esm', 'canesm2', 'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'miroc-esm', 'noresm1-m'};

isMonthly = true;
monthlyStr = '/mon';
if ~isMonthly
    monthlyStr = '';
end

for m = 1:length(models)
    for r = 1:length(rcps)
        for e = ensembles
            if strcmp(dataset, 'ncep')
                ch_calcBowenRatio(['f:/data/ncep-reanalysis/output'], true);
            elseif strcmp(dataset, 'era')
                ch_calcBowenRatio(['e:/data/era-interim/output'], true);
            else
                ch_calcBowenRatio(['e:/data/cmip5/output/' models{m} monthlyStr '/r' num2str(e) 'i1p1/' rcps{r}], true);
            end
        end
    end
end