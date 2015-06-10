airportDb = loadAirportDb('airports.dat');

obsAirports = {'PHX', 'LGA', 'DCA', 'DEN'};

airportLats = [];
airportLons = [];

for a = 1:length(obsAirports)
    [code, airportLat, airportLon] = searchAirportDb(airportDb, 'DCA');
    airportLats(a) = airportLat;
    airportLons(a) = airportLon;
end

obsPeriods = {1981:2011, 1981:2011, 1981:2011, 1996:2011};
weightRestrictionTemp = {[38, 47, 53], [0 31, 33], [0 31 33], [0 30 37]};              % temp threshholds for restriction at weight level
weightRestrictionLevel = {[1, 10, 15], [1, 10, 15], [1, 10, 15], [1, 10, 15]};         % in thousands of pounds
tempDisplay = [1 2 3];
months = [6 7 8];

ensembleMean = 'pre';
varianceCorrection = false;

fileformat = 'pdf';
barchart = true;
histogram = true;
plotbiascorrection = true;

basePeriod = 1981:2005;
futurePeriod = 2021:2069;

obsDir = 'e:/data/flight/wx/output/daily/tasmax';

% must be arranged such that any future periods comes directly after the
% corresponding base period
if strcmp(ensembleMean, 'post')
    vars = {{'cmip5/output/bnu-esm/r1i1p1/historical', 'cmip5/output/bnu-esm/r1i1p1/rcp85'}, ...
            {'cmip5/output/canesm2/r1i1p1/historical', 'cmip5/output/canesm2/r1i1p1/rcp85'}, ...
            {'cmip5/output/ccsm4/r1i1p1/historical', 'cmip5/output/ccsm4/r1i1p1/rcp85'}, ...
            {'cmip5/output/cesm1-bgc/r1i1p1/historical', 'cmip5/output/cesm1-bgc/r1i1p1/rcp85'}, ...
            {'cmip5/output/cesm1-cam5/r1i1p1/historical', 'cmip5/output/cesm1-cam5/r1i1p1/rcp85'}, ...
            {'cmip5/output/cmcc-cm/r1i1p1/historical', 'cmip5/output/cmcc-cm/r1i1p1/rcp85'}, ...
            {'cmip5/output/cmcc-cms/r1i1p1/historical', 'cmip5/output/cmcc-cms/r1i1p1/rcp85'}, ...
            {'cmip5/output/cnrm-cm5/r1i1p1/historical', 'cmip5/output/cnrm-cm5/r1i1p1/rcp85'}, ...
            {'cmip5/output/gfdl-cm3/r1i1p1/historical', 'cmip5/output/gfdl-cm3/r1i1p1/rcp85'}, ...
            {'cmip5/output/gfdl-esm2g/r1i1p1/historical', 'cmip5/output/gfdl-esm2g/r1i1p1/rcp85'}, ...
            {'cmip5/output/gfdl-esm2m/r1i1p1/historical', 'cmip5/output/gfdl-esm2m/r1i1p1/rcp85'}, ...
            {'cmip5/output/hadgem2-es/r1i1p1/historical', 'cmip5/output/hadgem2-es/r1i1p1/rcp85'}, ...
            {'cmip5/output/ipsl-cm5a-mr/r1i1p1/historical', 'cmip5/output/ipsl-cm5a-mr/r1i1p1/rcp85'}, ...
            {'cmip5/output/miroc-esm/r1i1p1/historical', 'cmip5/output/miroc-esm/r1i1p1/rcp85'}, ...
            {'cmip5/output/mpi-esm-mr/r1i1p1/historical', 'cmip5/output/mpi-esm-mr/r1i1p1/rcp85'}, ...
            {'cmip5/output/mri-cgcm3/r1i1p1/historical', 'cmip5/output/mri-cgcm3/r1i1p1/rcp85'}, ...
            {'cmip5/output/noresm1-m/r1i1p1/historical', 'cmip5/output/noresm1-m/r1i1p1/rcp85'}};
elseif strcmp(ensembleMean, 'pre')
    vars = {{'cmip5/output/ensemble-mean/r1i1p1/historical', 'cmip5/output/ensemble-mean/r1i1p1/rcp85'}};
elseif strcmp(ensembleMean, 'rank')
    vars = {['cmip5/output/ensemble-mean/r1i1p1/historical/rank'], ...
            ['cmip5/output/ensemble-mean/r1i1p1/rcp85/rank']};
end
    
varPeriods = {basePeriod, futurePeriod};
plotColors = {{[0 0 1], [0 1 0]}, {[1 0 0], [1 0 1]}};

cutoffTemps = [];

yearStep = 1;
baseDir = 'e:/';

if ~exist('weightRestrictedDaysUncorr', 'var')
    weightRestrictedDaysUncorr = {};
    weightRestrictedDaysCorr = {};
    weightRestrictedDaysObs = [];

    yearlyTempUncorr = {};
    yearlyTempCorr = {};
    yearlyTempObs = [];

    for m = 1:length(vars)
        for v = 1:length(vars{m})
            curModel = vars{m}{v};

            if length(findstr(curModel, 'narccap')) ~= 0
                tempVar = 'tasmax';
                tempPlev = -1;

                if length(findstr(curModel, 'ensemble-mean')) == 0
                    isRegridded = true;
                else
                    isRegridded = false;
                end
            elseif length(findstr(curModel, 'narr')) ~= 0
                tempVar = 'tasmax';
                tempPlev = -1;

                isRegridded = false;
            elseif length(findstr(curModel, 'ncep')) ~= 0
                tempVar = 'tmax';
                tempPlev = -1;

                isRegridded = false;
            elseif length(findstr(curModel, 'cmip5')) ~= 0
                tempVar = 'tasmax';
                tempPlev = -1;

                if length(findstr(curModel, 'ensemble-mean')) == 0
                    isRegridded = true;
                else
                    isRegridded = false;
                end
            end

            dailyTempData = [];
            yearlyTempUncorr{m}{v} = [];

            ['loading ' curModel '...']
            for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
                ['year ' num2str(y)]

                if isRegridded
                    tempStr = [baseDir 'data/' curModel '/' tempVar '/regrid'];
                else
                    tempStr = [baseDir 'data/' curModel '/' tempVar];
                end

                if tempPlev ~= -1
                    dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', tempPlev);
                else
                    dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
                end

                if length(dailyTemp{1}) == 0
                    continue;
                end

                for a = 1:length(obsAirports)
                    [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, [airportLats(a) airportLats(a)], [airportLons(a) airportLons(a)]);

                    curDailyTempData = dailyTemp{3};

                    curDailyTempData = curDailyTempData(:,:,:,months,:);
                    curDailyTempData = squeeze(reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                               [length(latIndexRange), length(lonIndexRange), ...
                                                size(curDailyTempData, 3), size(curDailyTempData,4)*size(curDailyTempData,5)]))-273.15;

                    if y-varPeriods{v}(1)+1 > 1
                        if length(curDailyTempData) >= size(yearlyTempUncorr{m}{v}{a}, 2)
                            yearlyTempUncorr{m}{v}{a}(y-varPeriods{v}(1)+1, :) = [single(curDailyTempData(1:min(length(curDailyTempData), size(yearlyTempUncorr{m}{v}{a}, 2))))];
                        else
                            yearlyTempUncorr{m}{v}{a}(y-varPeriods{v}(1)+1, :) = [single(padarray(curDailyTempData, size(yearlyTempUncorr{m}{v}{a}, 2)-length(curDailyTempData), NaN, 'post'))];
                        end
                    else
                        yearlyTempUncorr{m}{v}{a}(y-varPeriods{v}(1)+1, :) = [single(curDailyTempData)];
                    end
                end

                clear dailyTemp curDailyTempData;
            end
        end
    end
end

obsStart = [];
obsEnd = [];
obsData = {};
obsPeriod = {};

% now load the obs at the end
for a = 1:length(obsAirports)
    obsStart(a) = obsPeriods{a}(1);
    obsEnd(a) = obsPeriods{a}(end);
    obsData{a} = loadDailyData(obsDir, 'yearStart', obsStart(a), 'yearEnd', obsEnd(a), 'obs', 'daily', 'obsAirport', obsAirports{a});
    obsData{a} = obsData{a}(:, months, :);
    obsData{a} = reshape(obsData{a}, [size(obsData{a}, 1), size(obsData{a}, 2)*size(obsData{a}, 3)]);
    obsPeriod{a} = obsPeriods{a};
end

% calculate corrected temperature values
percentileCorrections = {};
percentileBuckets = {};
modelPercentileTemps = {};
obsPercentileTemps = {};

yearlyTempUncorrLinear = {};
yearlyTempCorrLinear = {};
obsDataLinear = {};

for m = 1:length(vars)
    for v = 1:length(vars{m})
        for a = 1:length(obsAirports)
            if length(varPeriods{v}) == length(basePeriod)
                if varPeriods{v} == basePeriod
                    numModelYears = size(yearlyTempUncorr{m}{v}{a}, 1);

                    yearlyTempUncorrLinear{m}{a} = reshape(yearlyTempUncorr{m}{v}{a}(1:min(size(obsData{a},1), numModelYears), :), [min(size(obsData{a},1), numModelYears)*size(yearlyTempUncorr{m}{v}{a}, 2), 1]);
                    
                    if length(obsDataLinear) < a
                        obsDataLinear{a} = reshape(obsData{a}(1:min(size(obsData{a},1), numModelYears),:), [min(size(obsData{a},1), numModelYears)*size(obsData{a},2), 1]);
                    end
                    
                    if ~varianceCorrection
                        [percentileCorrections{m}{a}, percentileBuckets{m}{a}, modelPercentileTemps{m}{a}, obsPercentileTemps{m}{a}] = meanCorrectionCurve(yearlyTempUncorrLinear{m}{a}, obsDataLinear{a}, 5);
                    end
                end
            end

            if varianceCorrection
                for y = 1:size(yearlyTempUncorr{m}{v}{a}, 1)
                    yearlyTempCorr{m}{v}{a}(y, :) = squeeze(meanVarBiasCorrect(yearlyTempUncorrLinear{m}{a}, obsDataLinear{a}, yearlyTempUncorr{m}{v}{a}(y, :)));
                end
            else
                for y = 1:size(yearlyTempUncorr{m}{v}{a}, 1)
                    for d = 1:size(yearlyTempUncorr{m}{v}{a}, 2)
                        corrIndex = find(yearlyTempUncorr{m}{v}{a}(y,d) >= modelPercentileTemps{m}{a}, 1, 'last');
                        if length(corrIndex) == 0
                            corrIndex = 1;
                        end
                        if ~isnan(yearlyTempUncorr{m}{v}{a}(y,d))
                            yearlyTempCorr{m}{v}{a}(y,d) = yearlyTempUncorr{m}{v}{a}(y,d) - percentileCorrections{m}{a}(corrIndex);
                        else
                            yearlyTempCorr{m}{v}{a}(y,d) = NaN;
                        end
                    end
                end
            end
            
            if histogram
                yearlyTempCorrLinear{m}{a} = reshape(yearlyTempCorr{m}{1}{a}, [size(yearlyTempCorr{m}{1}{a}, 1) * size(yearlyTempCorr{m}{1}{a},2), 1]);
            end
        end
    end
end

if plotbiascorrection
    meanCorrection = {};
    
    for a = 1:length(obsAirports)
        meanCorrection{a} = [];
        for m = 1:length(vars)
            if m > 1
                meanCorrection{a} = meanCorrection{a} + percentileCorrections{m}{a};
            else
                meanCorrection{a} = percentileCorrections{m}{a};
            end
        end
        meanCorrection{a} = meanCorrection{a} ./ length(vars);
        
        figure('Color', [1,1,1]);
        hold on;
        plot(percentileBuckets{1}{a}(2:end), meanCorrection{a}, 'k', 'LineWidth', 2);
        title([obsAirports{a} ' bias-correction'], 'FontSize', 30);
        xlabel('temperature percentile', 'FontSize', 28);
        ylabel('degrees C', 'FontSize', 28);
        xticks = get(gca, 'XTickLabel');
        yticks = get(gca, 'YTickLabel');
        set(gca, 'XTickLabel', xticks, 'FontSize', 18);
        set(gca, 'YTickLabel', yticks, 'FontSize', 18);
        set(gcf, 'Position', get(0,'Screensize'));
        eval(['export_fig cmip5-' obsAirports{a} '-bias-correction.' fileformat ';']);
        close all;
    end
end

% calculate weight restricted days for observations
weightRestrictedDaysObs = {};
for a = 1:length(obsAirports)
    for w = 1:length(weightRestrictionTemp{a})
        for y = 1:size(obsData{a}, 1)
            curNumDays = length(find(reshape(permute(obsData{a}(y, :, :), [1 3 2]), [size(obsData{a}, 2)*size(obsData{a}, 3), 1]) ...
                                     >= weightRestrictionTemp{a}(w)));
            weightRestrictedDaysObs{a}(w, y) = curNumDays;
        end
    end
end

% calculate weight restricted days for uncorrected and corrected model data
for m = 1:length(vars)
    for v = 1:length(vars{m})
        for a = 1:length(obsAirports)
            for w = 1:length(weightRestrictionTemp{a})
                for y = 1:size(yearlyTempUncorr{m}{v}{a}, 1)
                    weightRestrictedDaysUncorr{m}{v}{a}(w, y) = length(find(yearlyTempUncorr{m}{v}{a}(y,:) >= weightRestrictionTemp{a}(w))); 
                end

                for y = 1:size(yearlyTempCorr{m}{v}{a},1)
                    weightRestrictedDaysCorr{m}{v}{a}(w, y) = length(find(yearlyTempCorr{m}{v}{a}(y,:) >= weightRestrictionTemp{a}(w)));
                end
            end
        end
    end
end

l = 0;
if barchart
    yDataPast = {};
    yDataFuture = {};
    
    yDataPastMean = {};
    yDataFutureMean = {};
    
    errorPast = {};
    errorFuture = {};
    
    for a = 1:length(obsAirports)
        for t = 1:length(tempDisplay)
            plotTitle = [obsAirports{a}, ', ' num2str(weightRestrictionLevel{a}(tempDisplay(t))) 'k lbs'];
            fileTitle = ['weightRestrictionDays-', obsAirports{a}, '-', num2str(weightRestrictionLevel{a}(tempDisplay(t))), '.' fileformat];

            figure('Color', [1,1,1]);
            hold on;

            yDataPast{a} = [];
            yDataFuture{a} = [];

            for m = 1:length(vars)
                yDataPast{a}(m,:) = squeeze(weightRestrictedDaysCorr{m}{1}{a}(tempDisplay(t),:))';
                yDataFuture{a}(m,:) = squeeze(weightRestrictedDaysCorr{m}{2}{a}(tempDisplay(t), :))';
            end

            errorPast{a} = [];
            errorFuture{a} = [];

            for y = 1:size(yDataPast{a},2)
                errorPast{a}(y) = std(yDataPast{a}(:,y));
            end
            for y = 1:size(yDataFuture{a},2)
                errorFuture{a}(y) = std(yDataFuture{a}(:,y));
            end

            % take ensemble mean
            yDataPastMean{a} = nanmean(yDataPast{a}, 1);
            yDataFutureMean{a} = nanmean(yDataFuture{a}, 1);

            modelXAxis = basePeriod(1):10:futurePeriod(end);
            modelYAxis = tsmovavg([yDataPastMean{a}, yDataFutureMean{a}], 's', 10);
            errors = tsmovavg([errorPast{a}, errorFuture{a}], 's', 10);
            binCenters = (round2(modelXAxis, 10, 'floor')+round2(modelXAxis, 10, 'ceil')) ./ 2;

            if mod(length(modelYAxis), 0) == 0
                modelYAxis = modelYAxis(10:10:end);
            else
                modelYAxis = [modelYAxis(10:10:end), modelYAxis(end)];
            end

            if mod(length(errors), 0) == 0
                errors = errors(10:10:end);
            else
                errors = [errors(10:10:end), errors(end)];
            end

            binCentersPast = [];
            binCentersFuture = [];

            % plot historical and future model
            b1 = bar(modelXAxis(find(modelXAxis <= basePeriod(end))), modelYAxis(1:length(basePeriod(1:10:end))), 'histc');
            e1 = errorbar(binCenters(find(modelXAxis <= basePeriod(end))), modelYAxis(1:length(basePeriod(1:10:end))), errors(1:length(basePeriod(1:10:end))), '.');
            set(b1, 'FaceColor', 'b');
            set(e1, 'LineWidth', 2);
            set(e1, 'Color', [.5 .5 .5]);

            b2 = bar(modelXAxis(find(modelXAxis >= futurePeriod(1))), modelYAxis(length(basePeriod(1:10:end))+1:end), 'histc');
            e2 = errorbar(binCenters(find(modelXAxis >= futurePeriod(1))), modelYAxis(length(basePeriod(1:10:end))+1:end), errors(length(basePeriod(1:10:end))+1:end), '.');
            set(b2, 'FaceColor', 'r');
            set(e2, 'LineWidth', 2);
            set(e2, 'Color', [.5 .5 .5]);

            % plot obs data
            o = plot(obsPeriod{a}, weightRestrictedDaysObs{a}(tempDisplay(t), :), 'k', 'LineWidth', 2);

            % fit and plot trend on obs
            p = polyfit(obsPeriod{a}, weightRestrictedDaysObs{a}(tempDisplay(t), :), 1);
            p = plot(obsPeriod{a}, polyval(p, obsPeriod{a}), 'r');

            % plot middle years on bar (do at end to keep out of legend)
            bar(modelXAxis(find(modelXAxis > basePeriod(end) & modelXAxis < futurePeriod(1))), zeros(floor((futurePeriod(1)-basePeriod(end))/10), 1)', 'histc');

            %l = legend([b1, b2, o, p], 'CMIP5 ensemble mean historical', 'CMIP5 ensemble mean rcp85', 'observed', 'observed trend');
            title(plotTitle, 'FontSize', 30);
            xlabel('year', 'FontSize', 24);
            ylabel('weight restricted days', 'FontSize', 24);
            ylim([0, size(yearlyTempUncorr{1}{v}{a}, 2)]);
            %set(l, 'FontSize', 7);
            %set(l, 'Location', 'best');

            eval(['export_fig ' fileTitle ';']);
            close all;
        end
        
        if histogram        
            histBins = linspace(0,50,20);
            tempUncorrHistMean = [];
            tempCorrHistMean = [];
            tempObsHist = hist(obsDataLinear{a}, histBins);

            for m = 1:length(vars)
                if length(tempUncorrHistMean) == 0
                    tempUncorrHistMean = hist(yearlyTempUncorrLinear{m}{a}, histBins);
                else
                    tempUncorrHistMean = tempUncorrHistMean + hist(yearlyTempUncorrLinear{m}{a}, histBins);
                end
                
                if length(tempCorrHistMean) == 0
                    tempCorrHistMean = hist(yearlyTempCorrLinear{m}{a}, histBins);
                else
                    tempCorrHistMean = tempCorrHistMean + hist(yearlyTempCorrLinear{m}{a}, histBins);
                end
            end
            
            tempUncorrHistMean = tempUncorrHistMean ./ length(vars);
            tempCorrHistMean = tempCorrHistMean ./ length(vars);

            yLimits = [0 1200];
            yTickStep = 200;
            
            figure('Color', [1,1,1]);
            hold on;
            bar(histBins, tempUncorrHistMean, 'histc');
            xlabel('degrees C', 'FontSize', 28);
            ylabel('occurances', 'FontSize', 28);
            xlim([0 50]);
            ylim(yLimits);
            title('Uncorrected CMIP5', 'FontSize', 30);
            set(get(gca,'child'), 'FaceColor', [51/255 153/255 255/255], 'EdgeColor', 'k');
            xticks = get(gca, 'XTickLabel');
            yticks = get(gca, 'YTickLabel');
            set(gca, 'XTickLabel', xticks, 'FontSize', 20);
            set(gca, 'YTickLabel', yticks, 'FontSize', 20);
            set(gca,'YTick',[yLimits(1):yTickStep:yLimits(end)]);
            set(gcf, 'Position', get(0,'Screensize'));
            eval(['export_fig cmip5-' obsAirports{a} '-uncorr-past-hist.' fileformat ';']);
            close all;

            figure('Color', [1,1,1]);
            hold on;
            bar(histBins, tempCorrHistMean, 'histc');
            xlabel('degrees C', 'FontSize', 28);
            ylabel('occurances', 'FontSize', 28);
            xlim([0 50]);
            ylim(yLimits);
            title('Corrected CMIP5', 'FontSize', 30);
            set(get(gca,'child'),'FaceColor', [51/255 153/255 255/255],'EdgeColor','k');
            xticks = get(gca, 'XTickLabel');
            yticks = get(gca, 'YTickLabel');
            set(gca, 'XTickLabel', xticks, 'FontSize', 20);
            set(gca, 'YTickLabel', yticks, 'FontSize', 20);
            set(gca,'YTick',[yLimits(1):yTickStep:yLimits(end)]);
            set(gcf, 'Position', get(0,'Screensize'));
            eval(['export_fig cmip5-' obsAirports{a} '-corr-past-hist.' fileformat ';']);
            close all;

            figure('Color', [1,1,1]);
            hold on;
            bar(histBins, tempObsHist, 'histc');
            xlabel('degrees C', 'FontSize', 28);
            ylabel('occurances', 'FontSize', 28);
            xlim([0 50]);
            ylim(yLimits);
            title('Observations', 'FontSize', 30);
            set(get(gca,'child'),'FaceColor','g','EdgeColor','k');
            set(gcf, 'Position', get(0,'Screensize'));
            xticks = get(gca, 'XTickLabel');
            yticks = get(gca, 'YTickLabel');
            set(gca, 'XTickLabel', xticks, 'FontSize', 20);
            set(gca, 'YTickLabel', yticks, 'FontSize', 20);
            set(gca,'YTick', [yLimits(1):yTickStep:yLimits(end)]);
            eval(['export_fig obs-' obsAirports{a} '-past-hist.' fileformat ';']);
            close all; 
        end
    end
else
    figure('Color', [1, 1, 1]);
    hold on;
    legendText = '';
    for v = 1:length(vars)
        %for w = 1:length(weightRestrictionTemp{find(strcmp(obsAirports, code))})
            p = plot(varPeriods{v}, squeeze(weightRestrictedDaysUncorr(v, tempDisplay, 1:19)), 'LineWidth', 2);
            set(p, 'Color', plotColors{v}{tempDisplay});
            p = plot(varPeriods{v}, squeeze(weightRestrictedDaysCorr(v, tempDisplay, 1:19)), '--', 'LineWidth', 2);
            set(p, 'Color', plotColors{v}{tempDisplay});

            legendText = [legendText, '''', vars{v}, ' cutoff, uncorrected'','];
            legendText = [legendText, '''', vars{v}, ' cutoff, corrected'','];
        %end
    end
    plot(obsPeriod, weightRestrictedDaysObs(tempDisplay, :), 'k', 'LineWidth', 2);
    %legendText = [legendText, '''ground obs'''];
    %l = eval(['legend(' legendText ');']);

    title(plotTitle, 'FontSize', 30);
    xlabel('year', 'FontSize', 24);
    ylabel('weight restricted days', 'FontSize', 24);
    ylim([0, size(yearlyTempUncorr, 3)]);
    set(gcf, 'Position', get(0,'Screensize'));
    %set(l, 'FontSize', 7);
    %set(l, 'Location', 'best');

    eval(['export_fig ' fileTitle ';']);
    close all;
end

