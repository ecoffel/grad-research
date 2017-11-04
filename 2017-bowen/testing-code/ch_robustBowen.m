% look at places where monthly mean bowen ratios are similar

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};


bowenBaseDir = '2017-concurrent-heat\bowen\';
monthlyBowen = [];

% load monthly bowen data for all models
for m = 1:length(models)
    
    % load pre-computed monthly bowen data for historical period
    if exist([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat']);
        curBowen = monthlyMeans;

        % NaN-out all water gridcells
        for month = 1:size(curBowen, 3)
            % historical bowen
            curGrid = curBowen(:, :, month);
            curGrid(waterGrid) = NaN;
            curBowen(:, :, month) = curGrid;
        end

        monthlyBowen(:, :, m, :) = curBowen;
    end

    clear monthlyMeans;
end

% std for for each gridcell and month across models
bowenStd = squeeze(nanstd(monthlyBowen, [], 3));

bowenRange = squeeze(range(monthlyBowen, 3));

% mean for for each gridcell and month across models
bowenMean = squeeze(nanmean(monthlyBowen, 3));

bowenRobust = bowenRange ./ bowenMean;

for month = 1:size(bowenRobust, 3)
    
    result = {lat, lon, bowenRobust(:,:,month)};

    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [0 10], ...
                      'cbXTicks', 0:2:10, ...
                      'plotTitle', ['Bowen Robustness (month ' num2str(month) ')'], ...
                      'fileTitle', ['bowenRobust-historical-month-' num2str(month) '-cmip5-.png'], ...
                      'plotXUnits', ['Range / Mean'], ...
                      'blockWater', true, ...
                      'magnify', '2');
    plotFromDataFile(saveData);
end
%plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);

