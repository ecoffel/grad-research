% look at monthly mean temp/bowen fit or monthly mean max temperature &
% mean bowen
monthlyMean = true;

% plot curves for each model separately
plotEachModel = false;

% plot scatter plots for each month of bowen, temp
plotScatter = true;

% whether to predict the difference between the monthly warming and the the annual mean warming
%predictDifference = true;

% whether to predict temps based on historical CMIP5 bowen to test whether
% future response changes - this is JUST HISTORICAL
predictOnHistoricalCmip5 = false;

% whether to show the change in the bowen model when run over historical
% bowen vs future (true), or the difference between predicted temps when
% run over future bowens vs. historical simulated CMIP5 temps - this is
% LIKE ABOVE parameter but for CHANGE in the bowen model
showBowenModelChange = true;

% should we build the bowen/temp relationship using NCEP and then predict
% using CMIP5-based percentage change in bowen to modify NCEP bowen
trainOnNcep = false;

lags = 0;

lagStr = 'lag';
for l = lags
    lagStr = [lagStr '-' num2str(l)];
end

trainOnNcepStr = '';
if trainOnNcep
    trainOnNcepStr = 'train-ncep';
end

% type of model to fit to data
fitType = 'poly22';

rcpHistorical = 'historical';
rcpFuture = 'rcp85';

timePeriodHistorical = '1985-2004';
timePeriodFuture = '2060-2080';

monthlyMeanStr = 'monthlyMean';
if ~monthlyMean
    monthlyMeanStr = 'monthlyMax';
end

dataset = 'cmip5';

load lat;
load lon;

regionInd = 2;
months = 1:12;

baseDir = 'e:/data/bowen';

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'India', ...
                'West Africa', ...
                'Central Africa', ...
                'Tropics'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'india', ...
            'africa-west', ...
            'africa-cent', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
           [[25 35], [-103 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[8, 26], [67, 90]]; ...             % India
           [[7, 20], [-15 + 360, 15]]; ...          % west Africa
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics

switch regionAb{regionInd}
    
    %         {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3'};

    
    case 'us-cent'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
%         models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'hadgem2-cc', 'ipsl-cm5a-mr', 'miroc-esm'};
    case 'us-se'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'europe'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'med'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr'};
    case 'sa-n'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};
    case 'amazon'
        models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};
    case 'india'
        models = {'bnu-esm', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
                  'ipsl-cm5a-mr', 'miroc-esm'};
    case 'africa-west'
        models = {'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-esm2g', 'gfdl-esm2m'};
    case 'africa-central'
        models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
end
       
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

% historical model temp/bowen
meanTempHistoricalNCEP = [];
meanLFluxHistoricalNCEP = [];
meanSFluxHistoricalNCEP = [];

meanTempHistoricalCmip5 = [];
meanLFluxHistoricalCmip5 = [];
meanSFluxHistoricalCmip5 = [];

% future model temp/bowen
meanTempFuture = [];
meanLFluxFuture = [];
meanSFluxFuture = [];
% future predicted temp from modeled bowen (historical)
meanTempPredictedHistorical = [];
% and future bowen
meanTempPredictedFuture = [];
modelR2 = [];

% coefficient on the squared term to measure sensitivity
modelCoeff = [];
% is the squared coefficient significant
modelCoeffSig = [];

modelSig = [];

% NCEP-based model for each month
ncepModels = {};
% CMIP5 models for each month/model
cmip5Models = {};

for model = 1:length(models)

    % if we are loading NCEP and haven't done so already
%     if trainOnNcep && model == 1
%         ['loading NCEP...']
%         load([baseDir '/monthly-flux-temp/monthlyFluxTemp-historical-ncep-reanalysis--' timePeriodHistorical '.mat']);
%         bowenTempNcep = monthlyBowenTemp;
%         clear monthlyBowenTemp;    
%     end
    
    % load historical CMIP5
    ['loading historical ' models{model} '...']
    load([baseDir '/monthly-flux-temp/monthlyFluxTemp-' dataset '-' rcpHistorical '-' models{model} '-' timePeriodHistorical '.mat']);
    fluxTempCmip5 = monthlyFluxTemp;
    clear monthlyFluxTemp;    
    
    ['loading future ' models{model} '...']

    % load historical bowen data for comparison
    load([baseDir '/monthly-flux-temp/monthlyFluxTemp-' dataset '-' rcpFuture '-' models{model} '-' timePeriodFuture '.mat']);
    fluxTempFuture = monthlyFluxTemp;
    clear monthlyFluxTemp;

    cmip5Models{model} = {};
    
    for month = months
        ['month = ' num2str(month) '...']
        tempCmip5 = [];
        lFluxCmip5 = {};
        sFluxCmip5 = {};
        tempNcep = [];
        lFluxNcep = {};
        sFluxNcep = {};
        
        tempFuture = [];
        lFluxFuture = {};
        sFluxFuture = {};
        
        for l = 1:length(lags)
            lag = lags(l);
           
            lFluxNcep{l} = [];
            sFluxNcep{l} = [];
            lFluxCmip5{l} = [];
            sFluxCmip5{l} = [];
            lFluxFuture{l} = [];
            sFluxFuture{l} = [];
            
            % look at temps in current month
            tempMonth = month;
            % look at bowens in lagged month
            fluxMonth = month - lag;
            % limit bowen month and roll over (0 -> dec, -1 -> nov, etc)
            if fluxMonth <= 0
                fluxMonth = 12 + fluxMonth;
            end

            for xlat = 1:length(curLat)
                for ylon = 1:length(curLon)

                    % get all temp/bowen daily points for current region
                    % into one list (combines gridboxes & years for current model)
                    if monthlyMean

                        % --------- historical -------------

                            % lists of temps for current month for all
                            % years (cmip5)
                            curMonthTempsCmip5 = fluxTempCmip5{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                            curMonthSFluxesCmip5 = fluxTempCmip5{2}{fluxMonth}{curLat(xlat)}{curLon(ylon)};
                            curMonthLFluxesCmip5 = fluxTempCmip5{3}{fluxMonth}{curLat(xlat)}{curLon(ylon)};
                            
%                             ind = find(abs(curMonthSFluxesCmip5) <= 10);
%                             curMonthTempsCmip5 = curMonthTempsCmip5(ind);
%                             curMonthSFluxesCmip5 = curMonthSFluxesCmip5(ind);
                            
                            % only process NCEP once, on first model
                            if trainOnNcep && model == 1
                                curMonthTempsNcep = fluxTempNcep{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                                curMonthSFluxesNcep = fluxTempNcep{2}{fluxMonth}{curLat(xlat)}{curLon(ylon)};
                                curMonthLFluxesNcep = fluxTempNcep{3}{fluxMonth}{curLat(xlat)}{curLon(ylon)};
                            end

                            % start at year 2 to allow for lags
                            for year = 2:length(curMonthTempsCmip5)

                                tempYear = year;
                                fluxYear = year;
                                % if bowen month is *after* temp month, go to
                                % previous year
                                if tempMonth - fluxMonth < 0
                                    fluxYear = fluxYear - 1;
                                end

                                % this condition will slightly change the mean
                                % temperature and bowen for lagged plots
                                if fluxYear > 0
                                    nextTempCmip5 = curMonthTempsCmip5(tempYear);
                                    nextSFluxCmip5 = curMonthSFluxesCmip5(fluxYear);
                                    nextLFluxCmip5 = curMonthLFluxesCmip5(fluxYear);
                                    
                                    if trainOnNcep && model == 1
                                        nextTempNcep = curMonthTempsNcep(tempYear);
                                        nextSFluxNcep = curMonthSFluxesNcep(fluxYear);
                                        nextLFluxNcep = curMonthLFluxesNcep(fluxYear);
                                    end

                                    if ~isnan(nextTempCmip5) && ~isnan(nextSFluxCmip5) && ~isnan(nextLFluxCmip5)
                                        
                                        % only take one temp - the current,
                                        % lag 0
                                        if l == 1
                                            tempCmip5 = [tempCmip5; nextTempCmip5];
                                        end
                                        
                                        lFluxCmip5{l} = [lFluxCmip5{l}; nextLFluxCmip5];
                                        sFluxCmip5{l} = [sFluxCmip5{l}; nextSFluxCmip5];
                                    end
                                    
                                    % if we are on the first model and have
                                    % non-nan NCEP values, process them
                                    if trainOnNcep && model == 1 && ~isnan(nextTempNcep) && ~isnan(nextLFluxNcep) && ~isnan(nextSFluxNcep)
                                        % only take one temp - the current,
                                        % lag 0
                                        if l == 1
                                            tempNcep = [tempNcep; nextTempNcep];
                                        end
                                        
                                        lFluxNcep{l} = [lFluxNcep{l}; nextLFluxNcep];
                                        sFluxNcep{l} = [sFluxNcep{l}; nextSFluxNcep];
                                    end
                                end
                            end

                        % --------- future -------------

                        % lists of temps for current month for all years
                        curMonthTemps = fluxTempFuture{1}{tempMonth}{curLat(xlat)}{curLon(ylon)};
                        curMonthSFlux = fluxTempFuture{2}{fluxMonth}{curLat(xlat)}{curLon(ylon)};
                        curMonthLFlux = fluxTempFuture{3}{fluxMonth}{curLat(xlat)}{curLon(ylon)};

%                         ind = find(abs(curMonthSFlux) <= 10);
%                         curMonthTemps = curMonthTemps(ind);
%                         curMonthSFlux = curMonthSFlux(ind);
                        
                        % start at year 2 to allow for lags
                        for year = 2:length(curMonthTemps)

                            tempYear = year;
                            fluxYear = year;
                            % if bowen month is *after* temp month, go to
                            % previous year
                            if tempMonth - fluxMonth < 0
                                fluxYear = fluxYear - 1;
                            end

                            % this condition will slightly change the mean
                            % temperature and bowen for lagged plots
                            if fluxYear > 0
                                nextTempFuture = curMonthTemps(tempYear);
                                nextSFluxFuture = curMonthSFlux(fluxYear);
                                nextLFluxFuture = curMonthLFlux(fluxYear);

                                if ~isnan(nextTempFuture) && ~isnan(nextSFluxFuture) && ~isnan(nextLFluxFuture)
                                    % only take lag 0 temp
                                    if l == 1
                                        tempFuture = [tempFuture; nextTempFuture];
                                    end
                                    
                                    lFluxFuture{l} = [lFluxFuture{l}; nextLFluxFuture];
                                    sFluxFuture{l} = [sFluxFuture{l}; nextSFluxFuture];
                                end
                            end
                        end
                    end
                end
            end
            
        end

        % if using NCEP, only build models once (on first iteration)
        if trainOnNcep && model == 1
            curHistoricalTemp = tempNcep;
            curHistoricalLFlux = lFluxNcep;
            curHistoricalSFlux = sFluxNcep;
        elseif trainOnNcep && model > 1
            curHistoricalTemp = [];
            curHistoricalLFlux = [];
            curHistoricalSFlux = [];
        else
            curHistoricalTemp = tempCmip5;
            curHistoricalLFlux = lFluxCmip5;
            curHistoricalSFlux = sFluxCmip5;
        end
        
        % if we have prediction data (either NCEP for first time or current
        % CMIP5 model)
        if length(curHistoricalLFlux) > 0 && length(curHistoricalSFlux) > 0
            
            % create cell array of all bowen lags and the temp variable as
            % the last column
            tbl = table();
            for v = 1:length(curHistoricalLFlux)
                if v > 1 && length(curHistoricalLFlux{v}) < size(tbl, 1)
                    fill = zeros(size(tbl, 1) - length(curHistoricalLFlux{v}), 1);
                    fill(fill == 0) = NaN;
                    if length(fill) > 0
                        curHistoricalLFlux{v} = [curHistoricalLFlux{v}; fill];
                    end
                elseif v > 1 && length(curHistoricalLFlux{v}) > size(tbl, 1)
                    curHistoricalLFlux{v} = curHistoricalLFlux{v}(1:size(tbl, 1));
                end
                eval(['tbl.' 'lflux_lag' num2str(lags(v)) ' = curHistoricalLFlux{' num2str(v) '};']);
            end
            
            for v = 1:length(curHistoricalSFlux)
                if v > 1 && length(curHistoricalSFlux{v}) < size(tbl, 1)
                    fill = zeros(size(tbl, 1) - length(curHistoricalSFlux{v}), 1);
                    fill(fill == 0) = NaN;
                    if length(fill) > 0
                        curHistoricalSFlux{v} = [curHistoricalSFlux{v}; fill];
                    end
                elseif v > 1 && length(curHistoricalSFlux{v}) > size(tbl, 1)
                    curHistoricalSFlux{v} = curHistoricalSFlux{v}(1:size(tbl, 1));
                end
                eval(['tbl.' 'sflux_lag' num2str(lags(v)) ' = curHistoricalSFlux{' num2str(v) '};']);
            end
            
            tbl.temp = curHistoricalTemp;
            
            if plotScatter
                figure('Color', [1,1,1]);
                hold on;
                scatter(tbl.temp, tbl.sflux_lag0);
                title('S FLUX');
                
                figure('Color', [1,1,1]);
                hold on;
                scatter(tbl.temp, tbl.lflux_lag0);
                title('L FLUX');
            end
            
            % convert cell into table
            modelBT = fitlm(tbl, fitType);

            % if using NCEP, need to save this month's model to use on
            % future CMIP5 data
            if trainOnNcep
                ncepModels{tempMonth} = modelBT;
            else
                cmip5Models{model}{tempMonth} = modelBT;
            end

            % get the model pValue out of the anova structure
            a = anova(modelBT, 'summary');
            modelSig(model, tempMonth) = a(2, 5).pValue < 0.05;

            % save r2 value of model
            modelR2(model, tempMonth) = modelBT.Rsquared.Ordinary;
            
            % save coefficient on squared term
            if length(lags) == 1
                modelCoeff(model, tempMonth) = modelBT.Coefficients.Estimate(end);
                modelCoeffSig(model, tempMonth) = modelBT.Coefficients.pValue(end) <= 0.05 && ...
                                                  modelBT.Coefficients.pValue(end) > 0;
            end
        end
        
        % mean of historical temp
        if trainOnNcep && model == 1
            meanTempHistoricalNCEP(model, month) = nanmean(tempNcep);
        end
        meanTempHistoricalCmip5(model, month) = nanmean(tempCmip5);

        % mean historical model bowen for all lags
        for l = 1:length(lags)
            if trainOnNcep && model == 1
                meanLFluxHistoricalNCEP(month, l) = nanmean(lFluxNcep{l});
                meanSFluxHistoricalNCEP(month, l) = nanmean(sFluxNcep{l});
            end
            meanLFluxHistoricalCmip5(model, month, l) = nanmean(lFluxCmip5{l});
            meanSFluxHistoricalCmip5(model, month, l) = nanmean(sFluxCmip5{l});
        end

        % mean of future temp (CMIP5)
        meanTempFuture(model, month) = nanmean(tempFuture);
        
        % mean future model bowen for each lag
        for l = 1:length(lags)
            meanLFluxFuture(model, month, l) = nanmean(lFluxFuture{l});
            meanSFluxFuture(model, month, l) = nanmean(sFluxFuture{l});
        end

        clear tempNcep tempCmip5 tempFuture lFluxNcep sFluxNcep lFluxCmip5 sFluxCmip5 lFluxFuture sFluxFuture;
    end
    
    clear fluxTempNcep fluxTempCmip5 fluxTempFuture;
end

% predict future temps based on model trained on historical data,
% using future model bowen values as input
if trainOnNcep
    % trained using saved NCEP model for this month

    % now use CMIP5 mean percent bowen change to amplify bowens for
    % this region
    lFluxChgCmip5 = [];
    sFluxChgCmip5 = [];
    for model = 1:size(meanLFluxFuture, 1)
        lFluxChgCmip5(model, :) = (meanLFluxFuture(model, :) - meanLFluxHistoricalCmip5(model, :)) ./ meanLFluxHistoricalCmip5(model, :) + 1;
        sFluxChgCmip5(model, :) = (meanSFluxFuture(model, :) - meanSFluxHistoricalCmip5(model, :)) ./ meanSFluxHistoricalCmip5(model, :) + 1;
    end
    
    % multiply historical NCEP bowen by 
    meanLFluxFutureNCEP = repmat(meanLFluxHistoricalNCEP', size(lFluxChgCmip5, 1), 1) .* lFluxChgCmip5;
    meanSFluxFutureNCEP = repmat(meanSFluxHistoricalNCEP', size(sFluxChgCmip5, 1), 1) .* sFluxChgCmip5;
    
    for month = 1:12
        meanTempPredictedHistorical(month) = predict(ncepModels{month}, [meanLFluxHistoricalNCEP(month), meanSFluxHistoricalNCEP(month)]);
        % predict future based on modified NCEP bowens (for each CMIP5
        % model)
        for model = 1:size(meanLFluxFutureNCEP, 1)
            meanTempPredictedFuture(model, month) = predict(ncepModels{month}, [meanLFluxFutureNCEP(model, month), meanSFluxFutureNCEP(model, month)]);
        end
    end
else
    % train using current CMIP5-based model
    % historical CMIP5 bowens
    for month = 1:12
        for model = 1:size(meanLFluxHistoricalCmip5, 1)
            meanTempPredictedHistorical(model, month) = predict(cmip5Models{model}{month}, [squeeze(meanLFluxHistoricalCmip5(model, month, :))', squeeze(meanSFluxHistoricalCmip5(model, month, :))']);
            % and future CMIP5 bowen
            meanTempPredictedFuture(model, month) = predict(cmip5Models{model}{month}, [squeeze(meanLFluxFuture(model, month, :))', squeeze(meanSFluxFuture(model, month, :))']);
        end
    end
end

% test for significance of bowen change at 95%
%[h, p, ci, stats] = ttest(meanTempFuture(model, month), meanTempPredicted(model, month), 0.05);

if trainOnNcep
    meanTempPredictedHistorical = repmat(meanTempPredictedHistorical, [size(meanTempFuture, 1), 1]);
    meanTempHistoricalNCEP = repmat(meanTempHistoricalNCEP, [size(meanTempFuture, 1), 1]);
end

% CMIP5 warming
warming = squeeze(meanTempFuture - meanTempHistoricalCmip5);
annMeanWarming = squeeze(nanmean(meanTempFuture - meanTempHistoricalCmip5, 2));

% make prediction based on historical CMIP5 bowens
if predictOnHistoricalCmip5
    warmingPredicted = meanTempPredictedHistorical - meanTempHistoricalNCEP;
    annMeanWarmingPredicted = nanmean(meanTempPredictedHistorical - meanTempHistoricalNCEP, 2);
else
    if showBowenModelChange
        % use historical bowens & future bowens and show the difference
        % between the two
        warmingPredicted = meanTempPredictedFuture - meanTempPredictedHistorical;
        annMeanWarmingPredicted = nanmean(meanTempPredictedFuture - meanTempPredictedHistorical, 2);
    else
        % normal - use future bowens and CMIP5 historical temps
        warmingPredicted = meanTempPredictedFuture - meanTempHistoricalCmip5;
        annMeanWarmingPredicted = nanmean(meanTempPredictedFuture - meanTempHistoricalCmip5, 2);
    end
end

diff = warming;
predictedDiff = warmingPredicted;

for m = 1:12
    diff(:,m) = diff(:, m) - annMeanWarming;
    predictedDiff(:,m) = predictedDiff(:,m) - annMeanWarmingPredicted;
end

% error in seasonal anomalies
diffErr = nanstd(diff, [], 1);
predictedDiffErr = nanstd(predictedDiff, [], 1);

f = figure('Color', [1,1,1]);
hold on;
axis square;
box on;
grid on;

p1 = shadedErrorBar(1:12, nanmean(diff, 1)', diffErr', 'k', 1);
set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p1.edge, 'Color', 'w');

p2 = shadedErrorBar(1:12, nanmean(predictedDiff, 1), predictedDiffErr, 'k', 1);
set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);
set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p2.edge, 'Color', 'w');
    
%plot(nanmean(diff,1),'b');
%plot(nanmean(predictedDiff,1),'r')
plot(1:12, zeros(12,1), '--', 'LineWidth', 3, 'Color', [0.4 0.4 0.4]);
xlim([1 12]);
set(gca, 'XTick', 1:12);
ylim([-3 3]);
xlabel('Month', 'FontSize', 24);
ylabel(['Warming anomaly ' char(176) 'C'], 'FontSize', 24);
set(gca, 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
legend([p1.mainLine, p2.mainLine], 'CMIP5', 'Flux model');%, 'location', 'best');
if predictOnHistoricalCmip5
    export_fig(['fluxModelPrediction-' regionAb{regionInd} '-historical-test' '-' lagStr '-' trainOnNcepStr '.png']);
else
    if showBowenModelChange
        export_fig(['fluxModelPrediction-' regionAb{regionInd} '-bowen-model-change' '-' lagStr '-' trainOnNcepStr '.png']);
    else
        export_fig(['fluxModelPrediction-' regionAb{regionInd} '-' lagStr '-' trainOnNcepStr '.png']);
    end
end
close all;

if ~predictOnHistoricalCmip5
    fig = figure('Color',[1,1,1]);
    subplot(1,2,1);
    hold on;
    box on;
    grid on;
    axis square;

    if trainOnNcep
        % historical temps (NCEP)
        p1 = plot(1:12, nanmean(meanTempHistoricalNCEP, 1), 'LineWidth', 3, 'Color', [25/255.0, 158/255.0, 56/255.0]);
    end

    % historical temps (predicted based on NCEP)
    p2 = plot(1:12, nanmean(meanTempPredictedHistorical, 1), 'LineWidth', 3, 'Color', [85/255.0, 158/255.0, 237/255.0]);
    
    % future temps (modeled)
    p3 = plot(1:12, nanmean(meanTempFuture, 1), 'LineWidth', 3, 'Color', [239/255.0, 71/255.0, 85/255.0]);

    % future temps (predicted)
    p4 = plot(1:12, nanmean(meanTempPredictedFuture, 1), 'LineWidth', 3, 'Color', 'k');

    if trainOnNcep
        leg = legend([p1, p2, p3, p4], 'NCEP historical', 'NCEP predicted historical', 'CMIP5 future', 'Predicted future');
    else
        leg = legend([p2, p3, p4], 'CMIP5 predicted historical', 'CMIP5 future', 'Predicted future');
    end
    set(leg, 'FontSize', 20, 'location', 'south');
    xlabel('Month', 'FontSize', 24);
    ylabel(['Temperature ' char(176) 'C'], 'FontSize', 24);
    ylim([-10 40]);
    xlim([0.5 12.5]);
    set(gca, 'FontSize', 24);

    % right hand plot -------------------
    subplot(1,2,2);     
    grid on;

    [ax, p1, p2] = plotyy(1:12, nanmean(modelR2, 1), 1:12, ones(1, 12) .* 100);
    hold(ax(1));
    hold(ax(2));
    
    set(p1, 'Color', [0.3 0.3 0.3], 'LineWidth', 3);
    set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);

    box(ax(1), 'on');
    axis(ax(1), 'square');
    axis(ax(2), 'square');

    set(ax(1), 'XTick', 1:12);
    set(ax(2), 'XTick', 1:12);
    set(ax(1), 'XLim', [.5 12.5]);
    set(ax(2), 'XLim', [.5 12.5]);
    set(ax(1), 'YLim', [0 1], 'YTick', [0 0.25 0.5 0.75 1]);
    set(ax(2), 'YLim', [-10 1], 'YTick', -10:2:0);
    set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
    set(ax(1), 'YColor', 'k', 'FontSize', 24);

    for model = 1:size(modelR2, 1)
        plot(ax(1), 1:12, modelR2(model, :), 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    end
    %plot(1:12, nanmean(modelR2, 1), 'Color', [0.3 0.3 0.3], 'LineWidth', 4);
    %ylim([0 1]);

    for month = 1:size(modelR2, 2)
        % plot significance markers on R2 plot
        p5 = plot(ax(1), month, nanmean(modelR2(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [0.5 0.5 0.5], 'MarkerEdgeColor', 'k');
        
        % if training on ncep, then only need the ncep model to be
        % significant
        if trainOnNcep
            sigCutoff = 0;
        else
            % otherwise, want 2/3 of CMIP5 models to be sig
            sigCutoff = 0.66*length(models);
        end
        
        if length(find(modelSig(:, month))) > sigCutoff
            set(p5, 'LineWidth', 3, 'MarkerFaceColor', [0.5 0.5 0.5]);
        else
            set(p5, 'LineWidth', 3);
        end
        
        % plot significance markers on coeff plot plot
        p6 = plot(ax(2), month, nanmean(modelCoeff(:, month), 1), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if length(find(modelCoeffSig(:, month))) > sigCutoff
            set(p6, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p6, 'LineWidth', 3);
        end
    end

    %xlim([0.5 12.5]);
    set(gca, 'FontSize', 24);
    xlabel('Month', 'FontSize', 24);
    ylabel(ax(1), 'R2', 'FontSize', 24);
    ylabel(ax(2), 'Coefficient', 'FontSize', 24);

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['r2PredictionFlux-' regionAb{regionInd} '-' dataset '-BT-' monthlyMeanStr '-' lagStr '-' trainOnNcepStr '.png']);
    close all;
end



