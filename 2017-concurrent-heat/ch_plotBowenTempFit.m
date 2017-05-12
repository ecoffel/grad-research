
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

load lat;
load lon;

regionInd = 3;
months = 1:12;

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Western Europe', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Central Africa', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'china', ...
            'africa', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 48], [-97 -62] + 360]; ...     % USNE
           [[35, 60], [-10+360, 20]]; ...       % Europe
           [[-10, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 28], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics
           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

% temp/bowen pairs for this region, by months
linModels = {};

meanTemp = [];
meanBowen = [];
r2 = [];

for model = 1:length(models)
    ['processing ' models{model} '...']
    load(['f:\data\daily-bowen-temp\dailyBowenTemp-historical-' models{model} '-1985-2004.mat']);
    bowenTempHistorical=dailyBowenTemp;
    clear dailyBowenTemp;

    linModels{model} = {};
    
    for month = months
        ['month = ' num2str(month) '...']
        temp = [];
        bowen = [];
        for xlat = 1:length(curLat)
            for ylon = 1:length(curLon)
                temp = [temp; bowenTempHistorical{1}{month}{curLat(xlat)}{curLon(ylon)}'];
                bowen = [bowen; bowenTempHistorical{2}{month}{curLat(xlat)}{curLon(ylon)}'];
            end
        end
        linModels{model}{month} = fitlm(temp, bowen, 'poly2');
        r2(model, month) = linModels{model}{month}.Rsquared.Ordinary;
        meanTemp(model, month) = nanmean(temp);
        meanBowen(model, month) = nanmean(bowen);
        
        clear temp bowen;
    end
    clear bowenTempHistorical;
end

figure('Color',[1,1,1]);
subplot(1,2,1);
hold on;
axis square;
grid on;
box on;
[ax,p1,p2] = plotyy(1:12,meanTemp,1:12,meanBowen)
hold(ax(1));
hold(ax(2));
box(ax(1), 'on');
axis(ax(1), 'square');
axis(ax(2), 'square');
set(p1, 'Color', 'r');
set(p2, 'Color', 'b');
set(ax(1), 'XLim', [1 12], 'XTick', 1:12);
set(ax(2), 'XLim', [1 12], 'XTick', []);
set(ax(1), 'YLim', [0 40], 'YTick', [0 10 20 30 40]);
set(ax(2), 'YLim', [0 5], 'YTick', [0 1 2 3 4 5]);
xlabel('month');
ylabel(ax(1), 'temp');
ylabel(ax(2), 'bowen');
subplot(1,2,2);
hold on;
axis square;
grid on;
box on;
plot(1:12,r2, 'Color', [0.4 0.4 0.4])
xlabel('month');
ylabel('r2');
ylim([0 1]);



% for xlat = 1:length(curLat)
%     linModels{xlat} = {};
%     for ylon = 1:length(curLon)
%         
%         if length(linModels{xlat}) < ylon
%             linModels{xlat}{ylon} = [];
%         end
%         
%         ind = find(~isnan(bowenTempHistorical{1}{month}{curLat(xlat)}{curLon(ylon)}));
%         if length(ind) > 100
%             lm = fitlm(bowenTempHistorical{1}{month}{curLat(xlat)}{curLon(ylon)}(ind)', bowenTempHistorical{2}{month}{curLat(xlat)}{curLon(ylon)}(ind)', 'poly2');
%             linModels{xlat}{ylon} = lm;
%         else
%             linModels{xlat}{ylon} = [];
%         end
%     end
% end
% 
% gcmBpred = {};
% lmBpred = {};
% r2 = [];
% rmse = [];
% sig = [];
% diff = []
% 
% for xlat = 1:length(curLat)
%     lmBpred{xlat} = {};
%     gcmBpred{xlat} = {};
%     for ylon = 1:length(curLon)
%         if length(lmBpred{xlat}) < ylon
%             lmBpred{xlat}{ylon} = [];
%             gcmBpred{xlat}{ylon} = [];
%         end
%         
%         if length(linModels{xlat}{ylon}) > 0
%             r2(xlat, ylon) = linModels{xlat}{ylon}.Rsquared.Ordinary;
%             rmse(xlat, ylon) = linModels{xlat}{ylon}.RMSE;
%             
%             gcmBpred{xlat}{ylon} = bowenTempRcp85{2}{month}{curLat(xlat)}{curLon(ylon)};
%             t2 = bowenTempRcp85{1}{month}{curLat(xlat)}{curLon(ylon)};
%             lmBpred{xlat}{ylon} = predict(linModels{xlat}{ylon}, t2');
%             sig(xlat, ylon) = ttest(gcmBpred{xlat}{ylon}, lmBpred{xlat}{ylon}', 0.01);
%             diff(xlat,ylon) = nanmean(gcmBpred{xlat}{ylon}-lmBpred{xlat}{ylon}') / nanmean(bowenTempHistorical{2}{month}{curLat(xlat)}{curLon(ylon)});
%             
%         else
%             r2(xlat, ylon) = NaN;
%             rmse(xlat, ylon) = NaN;
%             sig(xlat, ylon) = 0;
%             diff(xlat, ylon) = NaN;
%         end
%     end
% end
% 
% sig(isnan(sig)) = 0;
% 
% result = {lat(curLat,curLon), lon(curLat,curLon), r2};
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [0 1], ...
%                   'cbXTicks', [0 .25 .5 .75 1], ...
%                   'plotTitle', 'R2', ...
%                   'fileTitle', ['r2-' num2str(month) '.png'], ...
%                   'plotXUnits', 'R2', ...
%                   'blockWater', true, ...
%                   'magnify', '2', ...
%                   'statData', sig, ...
%                   'stippleInterval', 1);
% plotFromDataFile(saveData);        
% 
% 
% 
% 
% 
% 
% 
