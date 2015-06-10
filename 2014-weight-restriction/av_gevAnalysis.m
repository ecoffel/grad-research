basePeriod = 1981:2005;
futurePeriod = 2051:2069;
isRegridded = true;

models = {'bnu-esm', 'canesm2', 'ccsm4', 'cesm1-bgc', ...
          'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-es', ...
          'ipsl-cm5a-mr', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', ...
          'noresm1-m'};

modelBaseDir = 'e:/data/cmip5/output';
modelEnsemble = 'r1i1p1';
      
modelVars = {'tasmax', ...
             'tasmax', 'tasmax', ...
             'tasmax', 'tasmax', ...
             'tasmax'};
       
modelPeriods = {basePeriod, ...
                2021:2029, 2030:2039, ...
                2040:2049, 2050:2059, ...
                2060:2069};

modelRcp = {'historical', ...
            'rcp85', 'rcp85', ...
            'rcp85', 'rcp85', ...
            'rcp85'};
            
obsDir = 'e:/data/flight/wx/output/daily/tasmax';
obsAirports = {'PHX', 'LGA', 'DCA', 'DEN'};
obsPeriods = {1981:2011, 1981:2011, 1981:2011, 1996:2011};

weightRestrictionTemp = {[38, 47, 53], [0 31, 33], [0 31 33], [0 30 37]};              % temp threshholds for restriction at weight level
weightRestrictionLevel = {[1, 10, 15], [1, 10, 15], [1, 10, 15], [1, 10, 15]};         % in thousands of pounds

modelLineStyles = {[102/255 178/255 255/255], ...
                   [255/255 153/255 153/255], [255/255 102/255 102/255], ...
                   [255/255 51/255 51/255], [255/255 0 0], ...
                   [204/255 0 0]};
               
modelLegends = '''1981-2005'', ''2021-2029'', ''2030-2039'', ''2040-2049'', ''2050-2059'', ''2060-2069''';

months = [5 6 7 8 9];
findMax = true;
biascorrect = true;
modelRegrid = true;

airportDb = loadAirportDb('airports.dat');
tempLatRange = {};
tempLonRange = {};

extremeDist = {};

obsStart = [];
obsEnd = [];
obsData = {};

% now load the obs at the end
for a = 1:length(obsAirports)
    
    [code, airportLat, airportLon] = searchAirportDb(airportDb, obsAirports{a});
    tempLatRange{a} = [airportLat airportLat];
    tempLonRange{a} = [airportLon airportLon];
    
    obsStart(a) = obsPeriods{a}(1);
    obsEnd(a) = obsPeriods{a}(end);
    obsData{a} = loadDailyData(obsDir, 'yearStart', obsStart, 'yearEnd', obsEnd, 'obs', 'daily', 'obsAirport', obsAirports{a});
    obsData{a} = obsData{a}(:, months, :);
    obsData{a} = reshape(obsData{a}, [size(obsData{a}, 1)*size(obsData{a}, 2)*size(obsData{a}, 3), 1]);    
end

dailyDataUncorr = {};
dailyDataCorr = {};

% each cmip5 model
for m = 1:length(models)
    dailyDataUncorr{m} = {};
    dailyDataCorr{m} = {};
    extremeDist{m} = {};
    
    ['loading ' models{m}]
    % each decade
    for d = 1:length(modelPeriods)
        model = models{m};
        var = modelVars{d};
        
        dailyDataUncorr{m}{d} = {};
        dailyDataCorr{m}{d} = {};
        
        % load ensemble mean temperatures
        for y = modelPeriods{d}(1):1:modelPeriods{d}(end)
            ['year ' num2str(y) '...']
            if modelRegrid
                curDaily = loadDailyData([modelBaseDir '/' model '/' modelEnsemble '/' modelRcp{d} '/' var '/regrid'], 'yearStart', y, 'yearEnd', y);
            else
                curDaily = loadDailyData([modelBaseDir '/' model '/' modelEnsemble '/' modelRcp{d} '/' var], 'yearStart', y, 'yearEnd', y);
            end

            % get the coords of the lat/lon target
            for a = 1:length(obsAirports)
                if length(dailyDataUncorr{m}{d}) < a
                    dailyDataUncorr{m}{d}{a} = [];
                end
                
                [latIndexRange, lonIndexRange] = latLonIndexRange(curDaily, tempLatRange{a}, tempLonRange{a});
                dailyDataUncorr{m}{d}{a} = [dailyDataUncorr{m}{d}{a}; reshape(curDaily{3}(latIndexRange, lonIndexRange,:,months,:), [size(curDaily{3},3)*length(months)*size(curDaily{3},5), 1])-273.15];
            end
            
            clear curDaily;
        end

        if length(modelPeriods{d}) == length(basePeriod)
            if modelPeriods{d} == basePeriod
                percentileCorrections = {};
                percentileBuckets = {};
                modelPercentileTemps = {};
                obsPercentileTemps = {};
                
                for a = 1:length(obsAirports)
                    [percentileCorrections{a}, percentileBuckets{a}, modelPercentileTemps{a}, obsPercentileTemps{a}] = meanCorrectionCurve(dailyDataUncorr{m}{d}{a}, obsData{a}, 5);
                end
            end
        end

        for a = 1:length(obsAirports)
            for day = 1:length(dailyDataUncorr{m}{d}{a})
                corrIndex = find(dailyDataUncorr{m}{d}{a}(day) >= modelPercentileTemps{a}, 1, 'last');
                if length(corrIndex) == 0
                    corrIndex = 1;
                end
                if ~isnan(dailyDataUncorr{m}{d}{a}(day))
                    dailyDataCorr{m}{d}{a}(day) = dailyDataUncorr{m}{d}{a}(day) - percentileCorrections{a}(corrIndex);
                else
                    dailyDataCorr{m}{d}{a}(day) = NaN;
                end
            end

            dailyDataCorr{m}{d}{a}(isnan(dailyDataCorr{m}{d}{a})) = [];
            [paramhat, parmci] = gevfit(dailyDataCorr{m}{d}{a}, 0.05);
            extremeDist{m}{d}{a} = {paramhat, parmci};
        end
        
    end
end

paramhat = [];
paramci = [];

for m = 1:length(models)
    for d = 1:length(modelPeriods)
        for a = 1:length(obsAirports)
            paramhat(:, a, d, m) = extremeDist{m}{d}{a}{1};
            paramci(:, :, a, d, m) = extremeDist{m}{d}{a}{2};
        end
    end
end

paramhat = squeeze(nanmean(paramhat, 4));
paramci = squeeze(nanmean(paramci, 5));

for a = 1:length(obsAirports)
    legHandles = [];
    figure('Color', [1 1 1]);
    hold on;
    for d = 1:length(modelPeriods)
        x = linspace(0, 50, 100);
        yCenter = gevpdf(x, paramhat(1, a, d), paramhat(2, a, d), paramhat(3, a, d));
        yMinus = gevpdf(x, paramci(1,1,d), paramci(1,2,d), paramci(1,3,d));
        yPlus = gevpdf(x, paramci(2,1,a,d), paramci(2,2,a,d), paramci(2,3,a,d));

        pCenter = plot(x, yCenter, 'Color', modelLineStyles{mod(d-1,length(modelLineStyles))+1}, 'LineWidth', 2);
        %pMinus = plot(x, yMinus, ':', 'Color', modelLineStyles{mod(e-1,length(modelLineStyles))+1}, 'LineWidth', 2);
        %pPlus = plot(x, yPlus, ':', 'Color', modelLineStyles{mod(e-1,length(modelLineStyles))+1}, 'LineWidth', 2);

        legHandles = [legHandles pCenter];
    end

    tempCutoffs = weightRestrictionTemp{a};
    yLimits = ylim;

    if tempCutoffs(1) > 0
        p1 = plot([tempCutoffs(1) tempCutoffs(1)], [yLimits(1) yLimits(end)], 'k--', 'LineWidth', 2);
        legHandles = [legHandles p1];
        modelLegends = [modelLegends ',''1k lbs'''];
    end
    p2 = plot([tempCutoffs(2) tempCutoffs(2)], [yLimits(1) yLimits(end)], 'k:', 'LineWidth', 2);
    p3 = plot([tempCutoffs(3) tempCutoffs(3)], [yLimits(1) yLimits(end)], 'k-.', 'LineWidth', 2);

    legHandles = [legHandles p2 p3];
    modelLegends = [modelLegends ',''10k lbs'', ''15k lbs'''];

    set(gcf, 'Position', get(0,'Screensize'));
    if length(modelLegends) > 0
        leg = eval(['legend(legHandles(:), {', modelLegends, '}, ''Location'', ''Best'');']);
        set(leg,'FontSize',16);
        set(leg, 'Location', 'NorthWest');
    end
    xlabel('degrees C', 'FontSize', 20);
    ylabel('occurrence', 'FontSize', 20);
    xlim([0 60]);
    title(obsAirports{a}, 'FontSize', 30);
    eval(['export_fig gevAnalysis-cmip5-future-mjjas-' obsAirports{a} '.pdf;']);
    close all;
end










