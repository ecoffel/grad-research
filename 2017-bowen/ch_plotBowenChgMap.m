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

bowenBaseDir = 'e:\data\projects\bowen\bowen-chg-data\';

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

       
% load cmip5 data
if ~exist('bowenChg', 'var')
    fprintf('loading cmip5 data...\n');
    
    % dimensions: x, y, month, model
    bowenHistorical = [];
    bowenRcp85 = [];
    bowenChg = [];

    for m = 1:length(models)

        load([bowenBaseDir 'monthly-mean-bowen-cmip5-historical-' models{m} '.mat']);
        bowenHistorical(:, :, :) = monthlyMeans;

        load([bowenBaseDir 'monthly-mean-bowen-cmip5-rcp85-' models{m} '.mat']);
        bowenRcp85(:, :, :) = monthlyMeans;

        bowenHistorical(bowenHistorical > 100) = NaN;
        bowenRcp85(bowenRcp85 > 100) = NaN;
        
        bowenChg(:, :, :, m) = (squeeze(bowenRcp85) - squeeze(bowenHistorical)) ./ squeeze(bowenHistorical) .* 100;
    end
    
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];


% load hottest seasons
load('2017-bowen/hottest-season.mat');

hotSeasonBowenChg = zeros(size(bowenChg, 1), size(bowenChg, 2), length(models));
hotSeasonBowenChg(hotSeasonBowenChg == 0) = NaN;
hotSeasonBowenChgDisagree = zeros(size(lat));

for xlat = 1:size(bowenChg, 1)
    for ylon = 1:size(bowenChg, 2)
        for m = 1:length(models)
            if isnan(hottestSeason(xlat, ylon, m))
                hotSeasonBowenChg(xlat, ylon, m) = NaN;
                continue;
            else
                % get months of hottest season
                months = seasons(hottestSeason(xlat, ylon, m), :);
                
                % get bowen chg in that season
                hotSeasonBowenChg(xlat, ylon, m) = squeeze(nanmean(bowenChg(xlat, ylon, months, m), 3));
            end
        end
        
        if length(find(~isnan(squeeze(hotSeasonBowenChg(xlat, ylon, :))))) == size(hotSeasonBowenChg, 3)
            % compute median change
            med = nanmedian(squeeze(hotSeasonBowenChg(xlat, ylon, :)));
            % whether < 75% models agree
            hotSeasonBowenChgDisagree(xlat, ylon) = length(find(sign(squeeze(hotSeasonBowenChg(xlat, ylon, :))) == sign(med))) < round(.75*length(models));
        end
        
    end
end

% plot ----------------------------------------------------
    
result = {lat, lon, nanmedian(hotSeasonBowenChg, 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-200 200], ...
                  'cbXTicks', -200:50:200, ...
                  'plotTitle', ['Bowen ratio change'], ...
                  'fileTitle', ['bowen-chg-hottest-cmip5.png'], ...
                  'plotXUnits', ['%'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*BrBG'), ...
                  'statData', hotSeasonBowenChgDisagree, ...
                  'stippleInterval', 5, ...
                  'magnify', '2');
plotFromDataFile(saveData);