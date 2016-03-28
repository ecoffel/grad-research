bc = true;

ensembles = 1:10;
% models = {'bnu-esm', 'canesm2', 'cnrm-cm5', 'cmcc-cm', 'cmcc-cms', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
%           'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};

models = {'inmcm4', 'mri-cgcm3', 'cesm1-cam5'};

for m = 1:length(models)
    curModel = models{m};
    for e = ensembles
        curEnsemble = ['r' num2str(e) 'i1p1'];

        %be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\historical'], true, 'usne', bc);
        %be_barkTemp(['E:\data\cmip5\output\ ' curModel '\' curEnsemble '\rcp45'], true, 'usne', bc);
        %be_barkTemp(['E:\data\cmip5\output\' curModel '\' curEnsemble '\rcp85'], true, 'usne', bc);

    end
end