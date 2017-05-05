
% mean bowen ratio at each temperature bin
bowenTempRelHistorical = [];
bowenTempRelRcp85 = [];

% number of data points in each temperatuer bin
bowenTempCntHistorical = [];
bowenTempCntRcp85 = [];

% all models with bowen-temp relationships
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};


load lat;
load lon;
              
% loop over all models and load bowen-temp relationship files
for model = 1:length(models)
    load(['2017-concurrent-heat\bowen-temp\bowenTemp-' models{model} '-historical-1985-2004.mat']);
    
    % calculate mean at each bin and store current model
    curBowenTempRel = bowenTemp{1} ./ bowenTemp{2};
    
    % save number of temperature points in each bin
    curBowenTempCnt = bowenTemp{2};
    
    % save current data
    bowenTempRelHistorical(:, :, :, model) = curBowenTempRel;
    bowenTempCntHistorical(:, :, :, model) = curBowenTempCnt;
    
    % load future data
    load(['2017-concurrent-heat\bowen-temp\bowenTemp-' models{model} '-rcp85-2060-2080.mat']);
    
    % calculate mean at each bin and store current model
    curBowenTempRel = bowenTemp{1} ./ bowenTemp{2};
    
    % save number of temperature points in each bin
    curBowenTempCnt = bowenTemp{2};
    
    bowenTempRelRcp85(:, :, :, model) = curBowenTempRel;
    bowenTempCntRcp85(:, :, :, model) = curBowenTempCnt;
end
              
% temperature bins in bowen-temp relationship files
binsHistorical = -50:5:60;
binsRcp85 = 0:5:50;

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Western Europe', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'china', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 55], [-100 -62] + 360]; ...     % USNE
           [[35, 60], [-10+360, 20]]; ...       % Europe
           [[-10, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 28], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-20 20], [0 360]]];                % Tropics
           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

% bin indices above 20C
indHistorical = find(binsHistorical > 0 & binsHistorical <= 50);
indRcp85 = find(binsRcp85 > 0 & binsRcp85 <= 50);

% select region
regionInd = 6;

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

historicalRel = squeeze(nanmean(nanmean(nanmean(bowenTempRelHistorical(curLat, curLon, indHistorical, :), 4), 2), 1));
futureRel = squeeze(nanmean(nanmean(nanmean(bowenTempRelRcp85(curLat, curLon, indRcp85, :), 4), 2), 1));

changeRel = squeeze(nanmean(nanmean(nanmean(bowenTempRelRcp85(curLat, curLon, indRcp85, :) - ...
                                            bowenTempRelHistorical(curLat, curLon, indHistorical, :), 4), 2), 1));

changeRelPercent = squeeze(nanmean(nanmean(nanmean((bowenTempRelRcp85(curLat, curLon, indRcp85, :) - ...
                                                    bowenTempRelHistorical(curLat, curLon, indHistorical, :)) ./ ...
                                                    bowenTempRelHistorical(curLat, curLon, indHistorical, :) .* 100, 4), 2), 1));

%plotModelData({lat(curLat, curLon),lon(curLat, curLon),nanmean(meanBowen(curLat, curLon, ind), 3)},'world');

figure('Color', [1,1,1]);
hold on;
grid on;

[ax, p1, p2] = plotyy(binsHistorical(indHistorical), changeRel, binsRcp85(indRcp85), changeRelPercent);
hold(ax(1));
hold(ax(2));

%plot(ax(1), 1:12, zeros(1,12), 'k--', 'LineWidth', 2);

set(p1, 'Color', 'k', 'LineWidth', 2);
set(p2, 'Color', 'r', 'LineWidth', 2);

box(ax(1), 'on');
axis(ax(1), 'square');
axis(ax(2), 'square');

set(ax(1), 'XTick', binsHistorical(indHistorical));
set(ax(2), 'XTick', []);
set(ax(1), 'XLim', [5 50]);
set(ax(2), 'XLim', [5 50]);
set(ax(1), 'YLim', [-5 5], 'YTick', [-5 -3 -1 0 1 3 5]);
set(ax(2), 'YLim', [-50 250], 'YTick', [-50 0 50 100 150 200 250]);
set(ax(2), 'YColor', 'r', 'FontSize', 24);
set(ax(1), 'YColor', 'k', 'FontSize', 24);

xlabel(['Temperature, ' char(176) 'C'], 'FontSize', 24);
ylabel(ax(1), 'Change in mean bowen ratio', 'FontSize', 24);
ylabel(ax(2), 'Change in mean bowen ratio (percent)', 'FontSize', 24);
set(gca, 'FontSize', 24);
title(regionNames{regionInd}, 'FontSize', 24);



