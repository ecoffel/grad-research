models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

modelLeg = {};
figure('Color', [1,1,1]);
hold on;
axis off;
for m = 1:length(models)
    plot(0, 0, 'k');
    modelLeg{m} = [num2str(m) ' ' models{m}];
end
set(gca, 'FontSize', 20);
legend(modelLeg)