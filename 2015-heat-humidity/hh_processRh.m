
% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

models = {'ipsl-cm5a-mr'};

rcps = {'historical'};
ensembles = 1;

for m = 1:length(models)
    for r = 1:length(rcps)
        for e = ensembles
            hh_relHumidity(['e:/data/cmip5/output/' models{m} '/r' num2str(e) 'i1p1/' rcps{r}], true, 'world', true);
        end
    end
end