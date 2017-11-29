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
    mrsoCmip5 = [];

    bowenRegionsCmip5 = {};
    tasmaxRegionsCmip5 = {};

    for m = 1:length(models)

        curMrso = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/mrso/regrid/world'], 'mrso', 'yearStart', 1985, 'yearEnd', 2004);
        mrsoCmip5(:, :, m, :, :) = curMrso{3};

        curBowen = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/bowen/regrid/world'], 'bowen', 'yearStart', 1985, 'yearEnd', 2004);
        bowenCmip5(:, :, m, :, :) = curBowen{3};

        %bowenCmip5(bowenCmip5 > 100) = NaN;
        %bowenCmip5(bowenCmip5 < 0) = NaN;

    end
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

load('2017-bowen/hottest-season.mat');

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
            curM = squeeze(mrsoCmip5(xlat, ylon, m, :, :));
            curB = squeeze(bowenCmip5(xlat, ylon, m, :, :));

            % get all years during hottest season...
            hottestSeasonM = nanmean(curM(:, seasons(hottestSeason(xlat, ylon), :)), 2);
            hottestSeasonB = nanmean(curB(:, seasons(hottestSeason(xlat, ylon), :)), 2);

            % all non-nans
            nn = find(~isnan(hottestSeasonM) & ~isnan(hottestSeasonB));

            % at least 10 years data
            if length(nn) > 10
                % find temp/bowen corr
                hottestSeasonCorr(xlat, ylon, m) = corr(hottestSeasonM, hottestSeasonB);
            end

        end
        
        med = median(squeeze(hottestSeasonCorr(xlat, ylon, :)));
        % where < 75% models agree on sign
        if ~isnan(med)
            hottestMonthCorrDisagree(xlat, ylon) = length(find(sign(squeeze(hottestSeasonCorr(xlat, ylon, :))) == sign(med))) < round(.75*length(models));
        end
        
    end
end

% plot ----------------------------------------------------
    
result = {lat, lon, nanmedian(hottestSeasonCorr, 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-1 1], ...
                  'cbXTicks', -1:0.5:1, ...
                  'plotTitle', ['mrso - Bowen correlation'], ...
                  'fileTitle', ['mrso-bowen-corr-cmip5.png'], ...
                  'plotXUnits', ['Correlation'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'stippleInterval', 5, ...
                  'vector', true, ...
                  'boxCoords', {regions([2,4,7], :)});
plotFromDataFile(saveData);