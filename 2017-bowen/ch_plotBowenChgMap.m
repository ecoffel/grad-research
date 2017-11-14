% plot monthly max temperature change alongside mean monthly bowen ratio changes

dataset = 'reanalysis';

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

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

        curBowen = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/bowen/regrid/world'], 'bowen', 'yearStart', 1985, 'yearEnd', 2004);
        bowenHistorical = squeeze(nanmean(curBowen{3}, 3));

        curBowen = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/bowen/regrid/world'], 'bowen', 'yearStart', 2060, 'yearEnd', 2079);
        bowenRcp85 = squeeze(nanmean(curBowen{3}, 3));

        %bowenHistorical(bowenHistorical > 100) = NaN;
        %bowenRcp85(bowenRcp85 > 100) = NaN;
        
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
        
        if length(find(~isnan(squeeze(hotSeasonBowenChg(xlat, ylon, :))))) >= .75*size(hotSeasonBowenChg, 3)
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
                  'plotRange', [-100 100], ...
                  'cbXTicks', -100:25:100, ...
                  'plotTitle', ['Bowen ratio change'], ...
                  'fileTitle', ['bowen-chg-hottest-cmip5.pdf'], ...
                  'plotXUnits', ['%'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*BrBG'), ...
                  'statData', hotSeasonBowenChgDisagree, ...
                  'stippleInterval', 5, ...
                  'boxCoords', {regions([2,4,7], :)});
plotFromDataFile(saveData);