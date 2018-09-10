% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';

excludeTropics = false;

hottestSeasonType = 'all-txx';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
% for wb
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};


baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';


% futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2005;

futurePeriodYears = 2061:2085;

% futurePeriods = [2070:2080];

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

load lat;
load lon;

% what change to look at:
% ann-max = annual max temperature
% ann-min = annual min temperature
% daily-max = mean daily max temperature
% daily-min = mean daily min temperature
% seasonal-monthly-max = monthly maximum temperature
% seasonal-monthly-min = monthly minimum temperature
% seasonal-monthly-mean-max = mean daily maximum temperature for each month
% seasonal-monthly-mean-min = mean daily minimum temperature for each month
% warm-season-tx-anom = change in Tx in local warm season minus Tx change over year
% warm-season-tx = change in Tx in local warm season
% no-warm-season-tx = change in non-warm season tx
% thresh = changes above temperature thresholds specified in thresh
% thresh-range = changes between two percentiles
changeMetric = 'thresh-range';

load(['2017-bowen/hottest-season-txx-rel-cmip5-' hottestSeasonType '.mat']);

if length(findstr(changeMetric, 'min')) > 0
    baseVar = 'tasmin';
    futureVar = 'tasmin';
else
    baseVar = 'wb-davies-jones-full';
    futureVar = 'wb-davies-jones-full';
end

% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = 0:10:100;

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

['loading base: ' baseDataset]
for m = 1:length(models)
    curModel = models{m};
    
    
    load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' curModel '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;
    
%     if exist(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-' changeMetric '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'file')
%         continue;
%     end
    
    % temperature data (thresh, ann-max, or daily-max)
    baseData = [];
   
    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'startYear', y, 'endYear', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDaily = baseDaily{3};
        
        % if any kelvin values, convert to C
        if nanmean(nanmean(nanmean(nanmean(nanmean(baseDaily))))) > 100
            baseDaily = baseDaily - 273.15;
        end

        % if we are not using a seasonal metric
        if ~strcmp(changeMetric, 'seasonal-monthly-max') && ~strcmp(changeMetric, 'seasonal-monthly-mean-max') && ...
           ~strcmp(changeMetric, 'seasonal-monthly-min') && ~strcmp(changeMetric, 'seasonal-monthly-mean-min') && ...
           ~strcmp(changeMetric, 'warm-season-tx-anom') && ~strcmp(changeMetric, 'warm-season-tx') && ...
           ~strcmp(changeMetric, 'surrounding-season-tx') && ~strcmp(changeMetric, 'no-warm-season-tx')
            % reshape to be 3D (x, y, day)
            baseDaily = reshape(baseDaily, [size(baseDaily, 1), size(baseDaily, 2), ...
                                                 size(baseDaily, 3)*size(baseDaily, 4)*size(baseDaily, 5)]);
            
        end

        % set water grid cells to NaN
        % include loops for month and day (5D) in case we are using
        % seasonal change metric
        for i = 1:size(baseDaily, 3)
            for j = 1:size(baseDaily, 4)
                for k = 1:size(baseDaily, 5)
                    curGrid = baseDaily(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDaily(:, :, i, j, k) = curGrid;
                end
            end
        end
        
        if strcmp(changeMetric, 'thresh') || strcmp(changeMetric, 'thresh-range')
            % calculate base period thresholds

            % loop over all thresholds
            for t = 1:length(thresh)
                % over x coords
                for xlat = 1:size(baseDaily, 1)
                    % over y coords
                    for ylon = 1:size(baseDaily, 2)

                        % skip if NaN (water)
                        if isnan(baseDaily(xlat, ylon, 1))
                            baseData(xlat, ylon, y-basePeriodYears(1)+1, t) = NaN;
                            continue;
                        end

                        % calculate threshold at current (x,y) and
                        % percentile 
                        baseData(xlat, ylon, y-basePeriodYears(1)+1, t) = prctile(squeeze(baseDaily(xlat, ylon, :)), thresh(t));
                    end
                end
            end
            
        elseif strcmp(changeMetric, 'seasonal-monthly-max')
            % calculate the seasonal maximum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, y-basePeriodYears(1)+1, month) = nanmax(squeeze(baseDaily(:, :, 1, month, :)), [], 3);
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-min')
            % calculate the seasonal minimum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, y-basePeriodYears(1)+1, month) = nanmin(squeeze(baseDaily(:, :, 1, month, :)), [], 3);
            end
            
        elseif strcmp(changeMetric, 'seasonal-monthly-mean-max') 
            % calculate the seasonal mean daily maximum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, y-basePeriodYears(1)+1, month) = nanmean(squeeze(baseDaily(:, :, 1, month, :)), 3);
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-mean-min') 
            % calculate the seasonal mean daily minimum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, y-basePeriodYears(1)+1, month) = nanmean(squeeze(baseDaily(:, :, 1, month, :)), 3);
            end
            
        elseif strcmp(changeMetric, 'warm-season-tx-anom') || strcmp(changeMetric, 'warm-season-tx') ...
               || strcmp(changeMetric, 'surrounding-season-tx') || strcmp(changeMetric, 'no-warm-season-tx')
            % calculate the seasonal mean daily minimum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, y-basePeriodYears(1)+1, month) = nanmean(squeeze(baseDaily(:, :, 1, month, :)), 3);
            end
                
        elseif strcmp(changeMetric, 'ann-max')

            % store annual max temperature at each gridbox for this year
            baseData(:, :, y-basePeriodYears(1)+1) = nanmax(squeeze(baseDaily), [], 3);
            
        elseif strcmp(changeMetric, 'ann-min')

            % store annual min temperature at each gridbox for this year
            baseData(:, :, y-basePeriodYears(1)+1) = nanmin(squeeze(baseDaily), [], 3);

        elseif strcmp(changeMetric, 'daily-max') || strcmp(changeMetric, 'daily-min')

            % store mean daily max temperature at each gridbox for this year
            baseData(:, :, y-basePeriodYears(1)+1) = nanmean(squeeze(baseDaily), 3);

        end
        

        clear baseDaily baseDaily3d;
    end

    if strcmp(changeMetric, 'ann-max') || strcmp(changeMetric, 'daily-max') || ...
       strcmp(changeMetric, 'ann-min') || strcmp(changeMetric, 'daily-min')
            annExt = baseData;
            %save(['e:/data/projects/bowen/temp-chg-data/cmip5-' changeMetric '-' curModel '-historical-' num2str(basePeriodYears(1)) '-' num2str(basePeriodYears(end)) '.mat'], 'annExt');
        
   
            % if computing annual maximum or mean daily maximum, take the mean across all base period
            % years (baseData now 3D: (x, y, year))
            baseData = nanmean(baseData, 3);

%         if strcmp(changeMetric, 'ann-max')
%             txx = baseData;
%             save(['e:/data/projects/bowen/temp-chg-data/ann-max-historical.mat'], 'txx');
%             continue;
%         end
    elseif strcmp(changeMetric, 'seasonal-monthly-max') || strcmp(changeMetric, 'seasonal-monthly-mean-max') || ...
           strcmp(changeMetric, 'seasonal-monthly-min') || strcmp(changeMetric, 'seasonal-monthly-mean-min') || ...
           strcmp(changeMetric, 'warm-season-tx') || strcmp(changeMetric, 'warm-season-tx-anom') || ...
           strcmp(changeMetric, 'surrounding-season-tx') || strcmp(changeMetric, 'no-warm-season-tx')
        % if computing seasonal metrics, average over all the annual
        % maximum or mean daily maximum, take the mean across all years
        % (baseData now 3D: (x, y, year, month))
        baseData = squeeze(nanmean(baseData, 3));
    end

    % ------------ load future data -------------    

    ['loading future: ' futureDataset]

    curModel = models{m};

    futureData = [];
    chgData = [];

    ['loading future model ' curModel '...']

    for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
        ['year ' num2str(y) '...']

        futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'startYear', y, 'endYear', (y+yearStep)-1);
        futureDaily = futureDaily{3};

        % convert any kelvin values to C
        if nanmean(nanmean(nanmean(nanmean(nanmean(futureDaily))))) > 100
            futureDaily = futureDaily - 273.15;
        end

        % if we are not using a seasonal metric
        if ~strcmp(changeMetric, 'seasonal-monthly-max') && ~strcmp(changeMetric, 'seasonal-monthly-mean-max') && ...
           ~strcmp(changeMetric, 'seasonal-monthly-min') && ~strcmp(changeMetric, 'seasonal-monthly-mean-min') && ...
           ~strcmp(changeMetric, 'warm-season-tx') && ~strcmp(changeMetric, 'warm-season-tx-anom') ...
           && ~strcmp(changeMetric, 'surrounding-season-tx') && ~strcmp(changeMetric, 'no-warm-season-tx')
            % reshape to 3D (x, y, day)
            futureDaily = reshape(futureDaily, [size(futureDaily, 1), size(futureDaily, 2), ...
                                                     size(futureDaily, 3)*size(futureDaily, 4)*size(futureDaily, 5)]);
        end

        % set water grid cells to NaN
        % include loops for month and day (5D) in case we are using
        % seasonal change metric
        for i = 1:size(futureDaily, 3)
            for j = 1:size(futureDaily, 4)
                for k = 1:size(futureDaily, 5)
                    curGrid = futureDaily(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    futureDaily(:, :, i, j, k) = curGrid;
                end
            end
        end

        if strcmp(changeMetric, 'thresh') || strcmp(changeMetric, 'thresh-range')
            % loop over thresholds
            for t = 1:length(thresh)
                % latitude
                for xlat = 1:size(futureDaily, 1)
                    % longitude
                    for ylon = 1:size(futureDaily, 2)

                        if isnan(futureDaily(xlat, ylon, 1))
                            futureData(xlat, ylon, y-futurePeriodYears(1)+1, t) = NaN;
                            continue;
                        end

                        % compute percentile threshold for this grid cell
                        % and year
                        futureData(xlat, ylon, y-futurePeriodYears(1)+1, t) = prctile(squeeze(futureDaily(xlat, ylon, :)), thresh(t));
                    end
                end
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-max')
            % calculate the seasonal maximum for each month

            % loop over months
            for month = 1:size(futureDaily, 4)
                futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmax(squeeze(futureDaily(:, :, 1, month, :)), [], 3);
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-min')
            % calculate the seasonal minimum for each month

            % loop over months
            for month = 1:size(futureDaily, 4)
                futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmin(squeeze(futureDaily(:, :, 1, month, :)), [], 3);
            end

        elseif strcmp(changeMetric, 'seasonal-monthly-mean-max') 
            % calculate the seasonal mean daily maximum for each month

            % loop over months
            for month = 1:size(futureDaily, 4)
                futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmean(squeeze(futureDaily(:, :, 1, month, :)), 3);
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-mean-min') 
            % calculate the seasonal mean daily minimum for each month

            % loop over months
            for month = 1:size(futureDaily, 4)
                futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmean(squeeze(futureDaily(:, :, 1, month, :)), 3);
            end

        elseif strcmp(changeMetric, 'warm-season-tx-anom') || strcmp(changeMetric, 'warm-season-tx') ...
               || strcmp(changeMetric, 'surrounding-season-tx') || strcmp(changeMetric, 'no-warm-season-tx')
            % calculate the seasonal mean daily minimum for each month

            % loop over months
            for month = 1:size(futureDaily, 4)
                futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmean(squeeze(futureDaily(:, :, 1, month, :)), 3);
            end

        elseif strcmp(changeMetric, 'ann-max')

            % store annual max temperature at each gridbox for this year
            futureData(:, :, y-futurePeriodYears(1)+1) = nanmax(squeeze(futureDaily), [], 3);

        elseif strcmp(changeMetric, 'ann-min')

            % store annual max temperature at each gridbox for this year
            futureData(:, :, y-futurePeriodYears(1)+1) = nanmin(squeeze(futureDaily), [], 3);

        elseif strcmp(changeMetric, 'daily-max') || strcmp(changeMetric, 'daily-min')

            % store annual max temperature at each gridbox for this year
            futureData(:, :, y-futurePeriodYears(1)+1) = nanmean(squeeze(futureDaily), 3);

        end

        clear futureDaily futureDaily3d;
    end

    if strcmp(changeMetric, 'ann-max') || strcmp(changeMetric, 'daily-max') || ...
       strcmp(changeMetric, 'ann-min') || strcmp(changeMetric, 'daily-min')
        
        %annExt = futureData;
        %save(['e:/data/projects/bowen/temp-chg-data/cmip5-' changeMetric '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'annExt');
        
        % if computing annual maximum or mean daily maximum, take the mean across all
        % years (futureData now 3D: (x, y))
        futureData = nanmean(futureData, 3);

        % calculate change for the current base period model:
        chgData = futureData - baseData;

    elseif strcmp(changeMetric, 'seasonal-monthly-max') || strcmp(changeMetric, 'seasonal-monthly-mean-max') || ...
           strcmp(changeMetric, 'seasonal-monthly-min') || strcmp(changeMetric, 'seasonal-monthly-mean-min')
        % if computing seasonal metrics, average over all the annual
        % maximum or mean daily maximum, take the mean across all years
        % (futureData now 4D: (x, y, year, month))
        futureData = squeeze(nanmean(futureData, 3));

        % calculate change for the current base period model, average over base models:
        chgData = futureData - baseData;
    elseif strcmp(changeMetric, 'thresh') || strcmp(changeMetric, 'thresh-range')
        chgData = nanmean(futureData, 3) - nanmean(baseData, 3);
        
    elseif strcmp(changeMetric, 'warm-season-tx-anom')
        % take mean across all months & years
        baseAnnTx = squeeze(nanmean(baseData, 3));
        futureAnnTx = squeeze(nanmean(nanmean(futureData, 4), 3));

        % annual Tx change for this model
        annualTxChg = futureAnnTx - baseAnnTx;

        baseWarmSeasonTx = [];
        futureWarmSeasonTx = [];
        for xlat = 1:size(baseData, 1)
            for ylon = 1:size(baseData, 2)
                % average over hottest months for current model
                baseWarmSeasonTx(xlat, ylon) = squeeze(nanmean(baseData(xlat, ylon, seasons(hottestSeason(xlat, ylon, m), :)), 3));
                % average over all years & hottest months
                futureWarmSeasonTx(xlat, ylon) = squeeze(nanmean(nanmean(futureData(xlat, ylon, :, seasons(hottestSeason(xlat, ylon, m), :)), 4), 3));
            end
        end

        % change in warm season Tx minus annual Tx
        chgData = (futureWarmSeasonTx - baseWarmSeasonTx) - annualTxChg;
    elseif  strcmp(changeMetric, 'warm-season-tx')

        % take mean across all months & years
        baseAnnTx = squeeze(nanmean(baseData, 3));
        futureAnnTx = squeeze(nanmean(nanmean(futureData, 4), 3));

        baseWarmSeasonTx = [];
        futureWarmSeasonTx = [];
        for xlat = 1:size(baseData, 1)
            for ylon = 1:size(baseData, 2)
                
                curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
                curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));
                
                % exclude tropics
                if ~excludeTropics || (xlat <= 35 || xlat >= 55)
                    if ~isnan(hottestSeason(xlat, ylon, m))
%                         months = [hottestSeason(xlat, ylon, m)-1 hottestSeason(xlat, ylon, m) hottestSeason(xlat, ylon, m)+1];
%                         months(months == 0) = 12;
%                         months(months == 13) = 1;

                        % average over hottest months for current model
                        baseWarmSeasonTx(xlat, ylon) = squeeze(nanmean(baseData(xlat, ylon, curTxxMonthsHist), 3));
                        % average over all years & hottest months
                        futureWarmSeasonTx(xlat, ylon) = squeeze(nanmean(nanmean(futureData(xlat, ylon, :, curTxxMonthsFut), 4), 3));
                    else

                        % set to nans
                        baseWarmSeasonTx(xlat, ylon) = NaN;
                        futureWarmSeasonTx(xlat, ylon) = NaN;
                    end
                else
                    months = 1:12;
                    % average over hottest months for current model
                    baseWarmSeasonTx(xlat, ylon) = squeeze(nanmean(baseData(xlat, ylon, months), 3));
                    % average over all years & hottest months
                    futureWarmSeasonTx(xlat, ylon) = squeeze(nanmean(nanmean(futureData(xlat, ylon, :, months), 4), 3));
                end
            end
        end

        % change in warm season Tx 
        chgData = (futureWarmSeasonTx - baseWarmSeasonTx);

    elseif  strcmp(changeMetric, 'no-warm-season-tx')

        % take mean across all months & years
        baseAnnTx = squeeze(nanmean(baseData, 3));
        futureAnnTx = squeeze(nanmean(nanmean(futureData, 4), 3));

        baseWarmSeasonTx = [];
        futureWarmSeasonTx = [];
        for xlat = 1:size(baseData, 1)
            for ylon = 1:size(baseData, 2)
                
                if ~isnan(hottestSeason(xlat, ylon, m))
                    
                    
                    months = [hottestSeason(xlat, ylon, m)-1 hottestSeason(xlat, ylon, m) hottestSeason(xlat, ylon, m)+1];
                    months(months == 0) = 12;
                    months(months == 13) = 1;
                    noWarmMonths = 1:12;
                    noWarmMonths(intersect(noWarmMonths, months)) = [];

                    % average over hottest months for current model
                    baseWarmSeasonTx(xlat, ylon) = squeeze(nanmean(baseData(xlat, ylon, noWarmMonths), 3));
                    % average over all years & hottest months
                    futureWarmSeasonTx(xlat, ylon) = squeeze(nanmean(nanmean(futureData(xlat, ylon, :, noWarmMonths), 4), 3));
                else

                    % set to nans
                    baseWarmSeasonTx(xlat, ylon) = NaN;
                    futureWarmSeasonTx(xlat, ylon) = NaN;
                end
            end
        end

        % change in warm season Tx 
        chgData = (futureWarmSeasonTx - baseWarmSeasonTx);
        
    elseif  strcmp(changeMetric, 'surrounding-season-tx')

        % take mean across all months & years
        baseAnnTx = squeeze(nanmean(baseData, 3));
        futureAnnTx = squeeze(nanmean(nanmean(futureData, 4), 3));

        baseSeasonTx = [];
        futureSeasonTx = [];
        for xlat = 1:size(baseData, 1)
            for ylon = 1:size(baseData, 2)
                
                surSeasons = [hottestSeason(xlat, ylon, m)-1 hottestSeason(xlat, ylon, m)+1];
                surSeasons(surSeasons==0) = 4;
                surSeasons(surSeasons==5) = 1;
                
                % average over hottest months for current model
                baseSeasonTx(xlat, ylon) = squeeze(nanmean(baseData(xlat, ylon, [seasons(surSeasons(1), :) seasons(surSeasons(2), :)]), 3));
                % average over all years & hottest months
                futureSeasonTx(xlat, ylon) = squeeze(nanmean(nanmean(futureData(xlat, ylon, :, [seasons(surSeasons(1), :) seasons(surSeasons(2), :)]), 4), 3));
            end
        end

        % change in warm season Tx 
        chgData = (futureSeasonTx - baseSeasonTx);

    end

    
    if strcmp(changeMetric, 'thresh')
        curChg = chgData;
        for t = 1:size(chgData,4)
            chgData = squeeze(curChg(:,:,:,t));
            save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-' changeMetric '-' num2str(thresh(t)) '-' baseVar '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '-' hottestSeasonType '.mat'], 'chgData');
        end
    elseif excludeTropics
        save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-' changeMetric '-' baseVar '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '-exclude-tropics' '-' hottestSeasonType '.mat'], 'chgData');
    else
        save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-' changeMetric '-' baseVar '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgData');
    end


end
