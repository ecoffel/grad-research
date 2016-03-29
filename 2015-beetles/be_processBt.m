bc = true;

ensembles = 1;
% models = {'bnu-esm', 'canesm2', 'cnrm-cm5', 'cmcc-cm', 'cmcc-cms', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
%           'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};

models = {'cesm1-cam5', 'ec-earth', 'inmcm4', 'miroc-esm', 'mpi-esm-mr'};

for m = 1:length(models)
    curModel = models{m};
    for e = ensembles
        curEnsemble = ['r' num2str(e) 'i1p1'];

        be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\historical'], true, 'usne', bc);
        be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\rcp45'], true, 'usne', bc);
        be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\rcp85'], true, 'usne', bc);

    end
end