% plot monthly max temperature change alongside mean monthly bowen ratio changes

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};

bowenBaseDir = '2017-concurrent-heat\bowen\';
bowenModels = {};

% dimensions: x, y, month, model
bowenChg = [];
% how many models have historical and rcp85 bowen data
bowenModelCnt = 1;

for m = 1:length(models)
    % load historical bowen ratio for this model if it exists
    if exist([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat']);
        curBowenHistorical = monthlyMeans;
    end
    
    % load rcp85 bowen ratio for this model if it exists
    if exist([bowenBaseDir 'monthly-mean-rcp85-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-rcp85-' models{m} '.mat']);
        curBowenRcp85 = monthlyMeans;
    end
    
    % if both historical and rcp85 data exist and were loaded for this
    % model, add them to the change data
    if exist('curBowenHistorical') && exist('curBowenRcp85')
        bowenModels{end+1} = models{m};
        
        % take difference between rcp85 and historical
        % dimensions: x, y, month, model
        bowenChg(:, :, bowenModelCnt, :) = curBowenRcp85 - curBowenHistorical;
        
        % increment number of models loaded
        bowenModelCnt = bowenModelCnt + 1;
    end
    
end
          
load waterGrid;
load lat;
load lon;
waterGrid=logical(waterGrid);

[latIndexRangeWorld, lonIndexRangeWorld] = latLonIndexRange({lat,lon,[]}, [-90 90], [0 360]);
[latIndexRangeUsne, lonIndexRangeUsne] = latLonIndexRange({lat,lon,[]}, [30 55], [-100 -62] + 360);
[latIndexRangeEurope, lonIndexRangeEurope] = latLonIndexRange({lat,lon,[]}, [35, 60], [-10+360, 40]);
[latIndexRangeAmazon, lonIndexRangeAmazon] = latLonIndexRange({lat,lon,[]}, [-20, 10], [-70, -40]+360);
[latIndexRangeIndia, lonIndexRangeIndia] = latLonIndexRange({lat,lon,[]}, [8, 34], [67, 90]);
[latIndexRangeTropics, lonIndexRangeTropics] = latLonIndexRange({lat,lon,[]}, [-20 20], [0 360]);

load chg-data\chgData-cmip5-seasonal-monthly-max-rcp85-2070-2080.mat
seaMax = chgData;

load chg-data\chgData-cmip5-seasonal-monthly-mean-max-rcp85-2070-2080.mat
seaMeanMax = chgData;

load chg-data\chgData-cmip5-ann-max-rcp85-2070-2080.mat
annMax = chgData;

maps = false;

if maps
    figure;
    hold on;
    for m=1:12
        subplot(3,4,m);
        hold on;
        a=annMax-meanMax(:,:,:,m);
        plotModelData({lat,lon,nanmean(a,3)},'world', 'caxis', [-3 3],'nonewfig',true);
        title(num2str(m),'FontSize',30);
    end
    tightfig;

    figure;
    hold on;
    for m=1:12
        subplot(3,4,m);
        hold on;
        plotModelData({lat,lon,nanmean(seaMeanMax(:,:,:,m),3)},'world', 'caxis', [0 9],'nonewfig',true);
        title(num2str(m),'FontSize',30);
    end
    tightfig;

    figure;
    hold on;
    for m=1:12
        subplot(3,4,m);
        hold on;
        plotModelData({lat,lon,nanmean(seaMax(:,:,:,m),3)},'world', 'caxis', [0 9],'nonewfig',true);
        title(num2str(m),'FontSize',30);
    end
    tightfig;
end

% mean monthly maximum temperatures for each region (2D)
usDataSeaMax = [];
europeDataSeaMax = [];
amazonDataSeaMax = [];
indiaDataSeaMax = [];

% mean annual maximum temperatures for each region (1D)
usDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeUsne, lonIndexRangeUsne, :), 2), 1));
europeDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeEurope, lonIndexRangeEurope, :), 2), 1));
amazonDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeAmazon, lonIndexRangeAmazon, :), 2), 1));
indiaDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeIndia, lonIndexRangeIndia, :), 2), 1));;

for m = 1:12
    usDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeUsne, lonIndexRangeUsne, :, m), 2), 1));
    europeDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeEurope, lonIndexRangeEurope, :, m), 2), 1));
    amazonDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeAmazon, lonIndexRangeAmazon, :, m), 2), 1));
    indiaDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeIndia, lonIndexRangeIndia, :, m), 2), 1));
end

% sort models by their monthly maximum temperature
usDataSeaMax = sort(usDataSeaMax, 2);
europeDataSeaMax = sort(europeDataSeaMax, 2);
amazonDataSeaMax = sort(amazonDataSeaMax, 2);
indiaDataSeaMax = sort(indiaDataSeaMax, 2);

% sort bowen change data by model
bowenChg = sort(bowenChg, 3);

% average bowen change over region
bowenChgUsne = squeeze(nanmean(nanmean(bowenChg(latIndexRangeUsne, lonIndexRangeUsne, :, :), 2), 1));
bowenChgEurope = squeeze(nanmean(nanmean(bowenChg(latIndexRangeEurope, lonIndexRangeEurope, :, :), 2), 1));
bowenChgAmazon = squeeze(nanmean(nanmean(bowenChg(latIndexRangeAmazon, lonIndexRangeAmazon, :, :), 2), 1));
bowenChgIndia = squeeze(nanmean(nanmean(bowenChg(latIndexRangeIndia, lonIndexRangeIndia, :, :), 2), 1));

% calculate indices for 25th/75th percentile bowen across models
lowIndBowen = round(0.25 * size(bowenChg, 3));
highIndBowen = round(0.75 * size(bowenChg, 3));

% show 25th - 75th percentile range for temperature
lowInd = round(0.25 * size(usDataSeaMax, 2));
highInd = round(0.75 * size(usDataSeaMax, 2));

% plot ----------------------------------------------------
f = figure('Color',[1,1,1]);
hold on;
grid on;
box on;

[ax, p1, p2] = shadedErrorBaryy(1:12, nanmean(usDataSeaMax, 2), range(usDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, 'r', ...
                                1:12, squeeze(nanmean(bowenChgUsne, 1)), squeeze(range(bowenChgUsne(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, 'g');
hold(ax(1));
hold(ax(2));
box(ax(1), 'on');
set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p1.edge, 'Color', 'w');
set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
axis(ax(1), 'square');
axis(ax(2), 'square');

%plot(1:12, ones(1,12) .* nanmean(usDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);

% plot bowen zero line 
plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

xlabel('Month', 'FontSize', 24);
set(ax(1), 'XTick', 1:12);
set(ax(2), 'XTick', []);
set(ax(1), 'YLim', [0 8], 'YTick', 0:8);
set(ax(2), 'YLim', [-2 5], 'YTick', -2:5);
set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
ylabel(ax(2), 'Bowen ratio change', 'FontSize', 24);
title('Eastern U.S.', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
export_fig seasonal-analysis-us.png -m2;



figure('Color', [1,1,1]);
hold on;
grid on;
box on;

[ax, p1, p2] = shadedErrorBaryy(1:12, nanmean(europeDataSeaMax, 2), range(europeDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, 'r', ...
                                1:12, squeeze(nanmean(bowenChgEurope, 1)), squeeze(range(bowenChgEurope(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, 'g');

hold(ax(1));
hold(ax(2));
box(ax(1), 'on');
set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p1.edge, 'Color', 'w');
set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
axis(ax(1), 'square');
axis(ax(2), 'square');

%plot(1:12, ones(1,12) .* nanmean(europeDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);

% plot bowen zero line 
plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

xlabel('Month', 'FontSize', 24);
set(ax(1), 'XTick', 1:12);
set(ax(2), 'XTick', []);
set(ax(1), 'YLim', [0 8], 'YTick', 0:8);
set(ax(2), 'YLim', [-2 5], 'YTick', -2:5);
set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
ylabel(ax(2), 'Bowen ratio change', 'FontSize', 24);
title('Europe', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
export_fig seasonal-analysis-europe.png -m2;



figure('Color', [1,1,1]);
hold on;
grid on;
box on;

[ax, p1, p2] = shadedErrorBaryy(1:12, nanmean(amazonDataSeaMax, 2), range(amazonDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, 'r', ...
                                1:12, squeeze(nanmean(bowenChgAmazon, 1)), squeeze(range(bowenChgAmazon(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, 'g');
hold(ax(1));
hold(ax(2));
box(ax(1), 'on');
set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p1.edge, 'Color', 'w');
set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
axis(ax(1), 'square');
axis(ax(2), 'square');

%plot(1:12, ones(1,12) .* nanmean(amazonDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);

% plot bowen zero line 
plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

xlabel('Month', 'FontSize', 24);
set(ax(1), 'XTick', 1:12);
set(ax(2), 'XTick', []);
set(ax(1), 'YLim', [0 8], 'YTick', 0:8);
set(ax(2), 'YLim', [-2 5], 'YTick', -2:5);
set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
ylabel(ax(2), 'Bowen ratio change', 'FontSize', 24);
title('Amazon', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
export_fig seasonal-analysis-amazon.png -m2;


figure('Color', [1,1,1]);
hold on;
grid on;
box on;

[ax, p1, p2] = shadedErrorBaryy(1:12, nanmean(indiaDataSeaMax, 2), range(indiaDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, 'r', ...
                                1:12, squeeze(nanmean(bowenChgIndia, 1)), squeeze(range(bowenChgIndia(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, 'g');
hold(ax(1));
hold(ax(2));
box(ax(1), 'on');
set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p1.edge, 'Color', 'w');
set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
axis(ax(1), 'square');
axis(ax(2), 'square');

% plot ann max temp change
%plot(1:12, ones(1,12) .* nanmean(indiaDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);

% plot bowen zero line 
plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

xlabel('Month', 'FontSize', 24);
set(ax(1), 'XTick', 1:12);
set(ax(2), 'XTick', []);
set(ax(1), 'YLim', [0 8], 'YTick', 0:8);
set(ax(2), 'YLim', [-2 5], 'YTick', -2:5);
set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
ylabel(ax(2), 'Bowen ratio change', 'FontSize', 24);
title('India', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
export_fig seasonal-analysis-india.png -m2;

% p1Bowen = shadedErrorBar(1:12, squeeze(nanmean(bowenChgUsne, 1)), ...
%                                squeeze(range(bowenChgUsne(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, '-', 1);
% set(p1Bowen.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
% set(p1Bowen.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
% set(p1Bowen.edge, 'Color', 'w');


% ---------------------- old code, no double y axis -----------------------
% subplot(2, 2, 2);
% hold on;
% grid on;
% box on;
% axis square;
% p2 = shadedErrorBar(1:12, nanmean(europeDataSeaMax, 2), range(europeDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
% set(p2.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
% set(p2.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
% set(p2.edge, 'Color', 'w');
% plot(1:12, ones(1,12) .* nanmean(europeDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);
% xlabel('Month', 'FontSize', 24);
% ylabel(['Tx change (' char(176) 'C)'], 'FontSize', 24);
% set(gca, 'FontSize', 24);
% ylim([0 8]);
% xlim([1 12]);
% title('Western Europe', 'FontSize', 24);
% 
% p2Bowen = shadedErrorBar(1:12, squeeze(nanmean(bowenChgEurope, 1)), ...
%                                squeeze(range(bowenChgEurope(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, '-', 1);
% set(p2Bowen.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
% set(p2Bowen.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
% set(p2Bowen.edge, 'Color', 'w');
% 
% 
% 
% subplot(2, 2, 3);
% hold on;
% grid on;
% box on;
% axis square;
% p3 = shadedErrorBar(1:12, nanmean(amazonDataSeaMax, 2), range(amazonDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
% set(p3.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
% set(p3.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
% set(p3.edge, 'Color', 'w');
% plot(1:12, ones(1,12) .* nanmean(amazonDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);
% xlabel('Month', 'FontSize', 24);
% ylabel(['Tx change (' char(176) 'C)'], 'FontSize', 24);
% set(gca, 'FontSize', 24);
% ylim([0 8]);
% xlim([1 12]);
% title('Amazon', 'FontSize', 24);
% 
% p3Bowen = shadedErrorBar(1:12, squeeze(nanmean(bowenChgAmazon, 1)), ...
%                                squeeze(range(bowenChgAmazon(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, '-', 1);
% set(p3Bowen.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
% set(p3Bowen.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
% set(p3Bowen.edge, 'Color', 'w');
% 
% 
% subplot(2, 2, 4);
% hold on;
% grid on;
% box on;
% axis square;
% p4 = shadedErrorBar(1:12, nanmean(indiaDataSeaMax, 2), range(indiaDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
% set(p4.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
% set(p4.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
% set(p4.edge, 'Color', 'w');
% plot(1:12, ones(1,12) .* nanmean(indiaDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);
% xlabel('Month', 'FontSize', 24);
% ylabel(['Tx change (' char(176) 'C)'], 'FontSize', 24);
% set(gca, 'FontSize', 24);
% ylim([0 8]);
% xlim([1 12]);
% title('India', 'FontSize', 24);
% 
% p4Bowen = shadedErrorBar(1:12, squeeze(nanmean(bowenChgIndia, 1)), ...
%                                squeeze(range(bowenChgIndia(lowIndBowen:highIndBowen, :), 1)) ./ 2.0, '-', 1);
% set(p4Bowen.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
% set(p4Bowen.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
% set(p4Bowen.edge, 'Color', 'w');

% xlabel('Month', 'FontSize', 24);
% ylabel(['Maximum temperature change (' char(176) 'C)'], 'FontSize', 24);
% set(gca, 'FontSize', 24);
% ylim([0 8]);
% legend([p1.mainLine, p2.mainLine, p3.mainLine, p4.mainLine], 'Eastern U.S.', 'Western Europe', 'Amazon', 'India');