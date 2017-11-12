% plot monthly max temperature change alongside mean monthly bowen ratio changes

dataset = 'reanalysis';

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';

models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

% show the percentage change in bowen ratio or the absolute change
showPercentChange = true;

showLegend = false;

% show correlation between Tx and Bowen
showCorr = true;

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

bowenBaseDir = 'e:\data\projects\bowen\temp-chg-data\';
tempBaseDir = 'e:\data\projects\bowen\temp-chg-data\';

% all available models for both bowen and tasmax
availModels = {};



regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa

       
% load cmip5 historical data
if ~exist('tasmaxCmip5', 'var')
    fprintf('loading cmip5 data...\n');
    
    % dimensions: x, y, month, model
    bowenCmip5 = [];
    tasmaxCmip5 = [];

    bowenRegionsCmip5 = {};
    tasmaxRegionsCmip5 = {};

    for m = 1:length(models)

        load([tempBaseDir 'monthly-mean-tasmax-cmip5-historical-' models{m} '-all-years-.mat']);
        tasmaxCmip5(:, :, m, :, :) = monthlyMeans;

        load([bowenBaseDir 'monthly-mean-bowen-cmip5-historical-' models{m} '-all-years-.mat']);
        bowenCmip5(:, :, m, :, :) = monthlyMeans;

        bowenCmip5(bowenCmip5 > 100) = NaN;
        %bowenCmip5(bowenCmip5 < 0) = NaN;

    end
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% find hottest historical month in each cmip5 model
hottestSeason = zeros(size(lat,1), size(lat,2), length(models));
hottestSeason(hottestSeason == 0) = NaN;

% temp/bowen correlation during hottest month
hottestSeasonCorr = zeros(size(lat,1), size(lat,2), length(models));
hottestSeasonCorr(hottestSeasonCorr == 0) = NaN;

% less than 75% models agree on sign of corr
hottestMonthCorrDisagree = zeros(size(lat));

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            continue;
        end
        for m = 1:length(models)
            curT = squeeze(tasmaxCmip5(xlat, ylon, m, :, :));
            curB = squeeze(bowenCmip5(xlat, ylon, m, :, :));

            % find hottest season
            sInd = -1;
            sTemp = -1;
            for s = 1:size(seasons, 1)
                curSTemp = nanmean(nanmean(curT(:,seasons(s,:))));
                if ~isnan(curSTemp) && (sInd == -1 || curSTemp > sTemp)
                    sInd = s;
                    sTemp = curSTemp;
                end
            end
            
            % a hottest season found
            if sInd ~= -1
                % store it
                hottestSeason(xlat, ylon, m) = sInd;
            else 
                continue;
            end

            % get all years during hottest season...
            hottestSeasonT = nanmean(curT(:, seasons(sInd, :)), 2);
            hottestSeasonB = nanmean(curB(:, seasons(sInd, :)), 2);

            % all non-nans
            nn = find(~isnan(hottestSeasonT) & ~isnan(hottestSeasonB));

            % at least 10 years data
            if length(nn) > 10
                % find temp/bowen corr
                hottestSeasonCorr(xlat, ylon, m) = corr(hottestSeasonT, hottestSeasonB);
            end

        end
        
        
        
        med = median(squeeze(hottestSeasonCorr(xlat, ylon, :)));
        % where < 75% models agree on sign
        if ~isnan(med)
            hottestMonthCorrDisagree(xlat, ylon) = length(find(sign(squeeze(hottestSeasonCorr(xlat, ylon, :))) == sign(med))) < round(.75*length(models));
            if ylon == 1
                ['hi']
            end
        end
        
    end
end

% save hottest season
save('2017-bowen/hottest-season.mat', 'hottestSeason');

% plot ----------------------------------------------------
    
result = {lat, lon, nanmedian(hottestSeasonCorr, 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-1 1], ...
                  'cbXTicks', -1:0.5:1, ...
                  'plotTitle', ['T_{max} - Bowen correlation'], ...
                  'fileTitle', ['tmax-bowen-corr-cmip5.png'], ...
                  'plotXUnits', ['Correlation'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'statData', hottestMonthCorrDisagree, ...
                  'stippleInterval', 5, ...
                  'magnify', '2');
plotFromDataFile(saveData);