bc = true;

ensembles = 1:10;
% models = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
%           'mri-cgcm3', 'noresm1-m'};

models = {'csiro-mk3-6-0'};

for m = 1:length(models)
    curModel = models{m};
    for e = ensembles
        curEnsemble = ['r' num2str(e) 'i1p1'];

        be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\historical'], true, 'usne', bc);
        be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\rcp85'], true, 'usne', bc);

    end
end