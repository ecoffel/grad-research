
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
           [[30 48], [-97 -62] + 360]; ...     % USNE
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

% select bin indices
indHistorical = find(binsHistorical >= 30 & binsHistorical < 40);
indRcp85 = find(binsRcp85 >= 30 & binsRcp85 < 40);

% select region
regionInd = 2;

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

bowenTempMeanHistorical = squeeze(nanmean(nanmean(nanmean(bowenTempRelHistorical(curLat, curLon, :, :), 4), 2), 1));
bowenTempMeanHistoricalCnt = squeeze(nanmean(nanmean(nanmean(bowenTempCntHistorical(curLat, curLon, :, :), 4), 2), 1));

bowenTempMeanRcp85 = squeeze(nanmean(nanmean(nanmean(bowenTempRelRcp85(curLat, curLon, :, :), 4), 2), 1));
bowenTempMeanRcp85Cnt = squeeze(nanmean(nanmean(nanmean(bowenTempCntRcp85(curLat, curLon, :, :), 4), 2), 1));

% bins w/ less than 50 points
nonRobustIndHistorical = find(bowenTempMeanHistoricalCnt < 50);
nonRobustIndRcp85 = find(bowenTempMeanRcp85Cnt < 50);

bowenTempMeanHistorical(nonRobustIndHistorical) = NaN;
bowenTempMeanRcp85(nonRobustIndRcp85) = NaN;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;
plot(binsHistorical(11:21), bowenTempMeanHistorical(11:21), 'k', 'LineWidth', 2);
plot(binsRcp85, bowenTempMeanRcp85, 'r', 'LineWidth', 2);
xlabel('Temperature', 'FontSize', 20);
ylabel('Bowen ratio', 'FontSize', 20);
title(regionNames{regionInd}, 'FontSize', 24);

plotModelData({lat(curLat, curLon), lon(curLat, curLon), nanmean(nanmean(bowenTempRelHistorical(curLat, curLon, :, :), 4), 3)}, 'world');




% SPATIAL ANOMALY ---------------------------------------------------------

% require at least this fraction of models to be non-nan
% modelFraction = 0.5;

% find grid cells in selelected temp bins with required model agreement
% modelAgreement = [];
% for xlat = 1:size(bowenTempRelHistorical, 1)
%     for ylon = 1:size(bowenTempRelHistorical, 2)
%         
%         % number of models with full data at this grid cell
%         cnt = 1;
%         
%         for model = 1:size(bowenTempRelHistorical, 4)
%             % calculate mean across indicies - will be nan if any nans at
%             % any selected index
%             gridcellMean = mean(squeeze(bowenTempRelHistorical(xlat, ylon, indHistorical, model)));
%             
%             % if current cell is non-nan, add one to count of models with
%             % data
%             if ~isnan(gridcellMean)
%                 cnt = cnt + 1;
%             end
%         end
%         
%         % if there are enough models in agreement
%         if cnt > modelFraction * length(models)
%             modelAgreement(xlat, ylon) = 1;
%         else
%             modelAgreement(xlat, ylon) = 0;
%         end
%         
%     end
% end

% historical mean bowen over all temp bins (dims: x, y)
% bowenMean = nanmean(nanmean(bowenTempRelHistorical, 4), 3);
% 
% % historical bowen anomaly in selected temp bins (dims: x, y)
% bowenSelected = nanmean(nanmean(bowenTempRelHistorical(:, :, indHistorical, :), 4), 3);
% 
% % calculate anomaly for gridcells with enough model agreement (dims: x, y)
% bowenAnom = bowenSelected - bowenMean;
% bowenAnom(~modelAgreement) = NaN;
% bowenMean(~modelAgreement) = NaN;
% 
% % plot mean
% plotModelData({lat, lon, bowenMean}, 'europe', 'caxis', [0 10]);
%            
% % plot anomalies
% plotModelData({lat(curLat, curLon), lon(curLat, curLon), bowenAnom}, 'europe', 'caxis', [-5 5]);



