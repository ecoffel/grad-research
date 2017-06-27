
% should we look at change between rcp & historical (only for cmip5)
change = false;

% look at monthly mean temp/bowen fit or daily
monthlyMean = true;

% plot curves for each model separately
plotEachModel = false;

% type of model to fit to data
fitType = 'poly2';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2060-2080';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'daily';
end

load lat;
load lon;

regionInd = 2;
months = 1:12;

if regionInd == 4
    % in amazon leave out csiro, canesm2, ipsl
    models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
elseif regionInd == 5
    % in india leave out csiro and mri-cgcm3
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
elseif regionInd == 6
    % leave out 'mri-cgcm3'
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
else
    % leave out 'bcc-csm1-1-m' and 'inmcm4' due to bad bowen performance
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
end

models={'ncep-reanalysis'};

dataset = 'cmip5';
if length(models) == 1 && strcmp(models{1}, 'ncep-reanalysis')
    dataset = 'ncep';
end

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa
           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

% temp/bowen pairs for this region, by months
meanTemp = [];
meanBowen = [];

% loop over all models
for model = 1:length(models)
    ['processing ' models{model} '...']

    load(['f:\data\daily-bowen-temp\dailyBowenTemp-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    bowenTemp=dailyBowenTemp;
    clear dailyBowenTemp;

    if change
        ['loading future ' models{model} '...']

        % load historical bowen data for comparison
        load(['f:\data\daily-bowen-temp\dailyBowenTemp-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
        bowenTempFuture=dailyBowenTemp;
        clear dailyBowenTemp;
    end

    temp = [];
    bowen = [];

    if change
        tempFuture = [];
        bowenFuture = [];
    end
    
    for month = months
        ['month = ' num2str(month) '...']
        
        for xlat = 1:length(curLat)
            for ylon = 1:length(curLon)
                % get all temp/bowen daily points for current region
                % into one list (combines gridboxes & years for current model)
                if monthlyMean
                    temp = [temp; nanmean(bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}')];
                    bowen = [bowen; nanmean(abs(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}'))];
                else
                    temp = [temp; bowenTemp{1}{month}{curLat(xlat)}{curLon(ylon)}'];
                    bowen = [bowen; abs(bowenTemp{2}{month}{curLat(xlat)}{curLon(ylon)}')];
                end

                if change
                    % and do the same for future data if we're looking
                    % at a change
                    if monthlyMean
                        tempFuture = [tempFuture; nanmean(bowenTempFuture{1}{month}{curLat(xlat)}{curLon(ylon)}')];
                        bowenFuture = [bowenFuture; nanmean(abs(bowenTempFuture{2}{month}{curLat(xlat)}{curLon(ylon)}'))];
                    else
                        tempFuture = [tempFuture; bowenTempFuture{1}{month}{curLat(xlat)}{curLon(ylon)}'];
                        bowenFuture = [bowenFuture; abs(bowenTempFuture{2}{month}{curLat(xlat)}{curLon(ylon)}')];
                    end

                end
            end
        end

        %clear temp bowen;
    end
    
    % find indicies where temp and bowen are non-nan
    indHistorical = intersect(find(~isnan(temp)), find(~isnan(bowen)));
    temp = temp(indHistorical);
    bowen = bowen(indHistorical);
    
    clear bowenTemp bowenTempFuture;
end
