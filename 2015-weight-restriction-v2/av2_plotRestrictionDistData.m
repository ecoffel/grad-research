
% hours to analyze
selectedHours = 1:24;

% take the mean over all hours or compute each separately
hourlyMean = true;

% are we using restriction data with months separtaed out
monthlyData = false;

restrictionDataBaseDir = '2015-weight-restriction-v2/restrictionData/restriction-data-old/'; 

% 3 = RCP 4.5
% 4 = RCP 8.5
rcpInd = 4;

% starting subplot index
subplotInd = 1;

acSurfs = av2_loadSurfaces();

aircraftList = {};

% percentage of flights with at least some restriction
prcRestPast = [];
% percentage of target TOW removed
meanTowRestPast = [];
% percentage of payload+fuel capacity restricted
prcPayloadFuelRestPast = [];

prcRestFuture = [];
meanTowRestFuture = [];
prcPayloadFuelRestFuture = [];

for curHour = selectedHours
    load([restrictionDataBaseDir 'restrictionData-tr-' num2str(curHour)]);

    % ac/airport combos
    % 737-800/LGA, airportInd = 3
    % 777-300/DXB, airportInd = 4

    for acInd = 1:length(restrictionData)
        
        weightBins = restrictionData{acInd}{1}{2};
        weightBinsInd = 6:length(weightBins);

        aircraft = restrictionData{acInd}{1}{1};
        
        % build list of all a/c
        if length(aircraftList) < length(restrictionData)
            aircraftList{end+1} = aircraft;
        end

        % find surface that corresponds to this a/c
        curSurf = -1;
        for s = 1:length(acSurfs)
            if strcmp(acSurfs{s}{1}{1}, aircraft)
                curSurf = acSurfs{s};
                break;
            end
        end

        % current a/c weights
        acOEW = curSurf{1}{2};
        acSearchMin = curSurf{1}{3};
        acMTOW = curSurf{1}{4};

        payloadAndFuel = acMTOW - acOEW;

        airportCount = 1;

        % airportInd starts at 1; index 1 is the RCP name in restrictionData
        for airportInd = 2:length(restrictionData{acInd}{2})
            airport = restrictionData{acInd}{2}{airportInd}{1};

            if monthlyData
                % divide by # days in month
                divCoef = 31;
                
                % calculate stats for the past (rcp = historical)
                % percentage of flights restricted
                prcRestPast(acInd, :, :, airportCount, curHour) = squeeze(nanmean(nanmean(restrictionData{acInd}{2}{airportInd}{2}{1}, 3), 2)) ...
                                           ./ squeeze(nanmean(nanmean(restrictionData{acInd}{2}{airportInd}{2}{3}, 3), 2)) .* 100;

                % percentage of TOW restricted
                meanTowRestPast(acInd, :, :, airportCount, curHour) = squeeze(nanmean(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 3), 2)) ...
                                    ./ squeeze(nanmean(nanmean(restrictionData{acInd}{2}{airportInd}{2}{4}, 3), 2)) .* 100;

                prcPayloadFuelRestPast(acInd, :, :, airportCount, curHour) = squeeze(nanmean(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 3), 2)) .* 0.83 ./ divCoef ...
                                    ./ payloadAndFuel .* 100;


                % stats for the future (rcp = rcpInd)
                % percentage of flights restricted
                prcRestFuture(acInd, :, :, airportCount, curHour) = squeeze(nanmean(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{1}, 3), 2)) ...
                                           ./ squeeze(nanmean(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{3}, 3), 2)) .* 100;

                % percentage of TOW restricted
                meanTowRestFuture(acInd, :, :, airportCount, curHour) = squeeze(nanmean(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 3), 2)) ...
                                    ./ squeeze(nanmean(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{4}, 3), 2)) .* 100;

                prcPayloadFuelRestFuture(acInd, :, :, airportCount, curHour) = squeeze(nanmean(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 3), 2)) .* 0.83 ./ divCoef ...
                                    ./ payloadAndFuel .* 100;
            
            else % ---------- not using monthly data ------------
                
                % divide by # days in year
                divCoef = 365;
                
                % calculate stats for the past (rcp = historical)
                % percentage of flights restricted
                prcRestPast(acInd, :, :, airportCount, curHour) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{1}, 2)) ...
                                           ./ squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{3}, 2)) .* 100;

                % percentage of TOW restricted
                meanTowRestPast(acInd, :, :, airportCount, curHour) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) ...
                                    ./ squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{4}, 2)) .* 100;

                prcPayloadFuelRestPast(acInd, :, :, airportCount, curHour) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) .* 0.83 ./ divCoef ...
                                    ./ payloadAndFuel .* 100;


                % stats for the future (rcp = rcpInd)
                % percentage of flights restricted
                prcRestFuture(acInd, :, :, airportCount, curHour) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{1}, 2)) ...
                                           ./ squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{3}, 2)) .* 100;

                % percentage of TOW restricted
                meanTowRestFuture(acInd, :, :, airportCount, curHour) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) ...
                                    ./ squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{4}, 2)) .* 100;

                prcPayloadFuelRestFuture(acInd, :, :, airportCount, curHour) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) .* 0.83 ./ divCoef ...
                                    ./ payloadAndFuel .* 100;
            end
            airportCount = airportCount + 1;
        end        
    end
end

% take mean across airports
prcRestPast = squeeze(nanmean(prcRestPast, 4));
meanTowRestPast = squeeze(nanmean(meanTowRestPast, 4));
prcRestFuture = squeeze(nanmean(prcRestFuture, 4));
meanTowRestFuture = squeeze(nanmean(meanTowRestFuture, 4));
prcPayloadFuelRestPast = squeeze(nanmean(prcPayloadFuelRestPast, 4));
prcPayloadFuelRestFuture = squeeze(nanmean(prcPayloadFuelRestFuture, 4));

% add the multi-model means to the end of the matrix... we'll make
% these dots black and bold
prcRestPast(:, end+1, :, :) = squeeze(nanmean(prcRestPast, 2));
meanTowRestPast(:, end+1, :, :) = squeeze(nanmean(meanTowRestPast, 2));
prcRestFuture(:, end+1, :, :) = squeeze(nanmean(prcRestFuture, 2));
meanTowRestFuture(:, end+1, :, :) = squeeze(nanmean(meanTowRestFuture, 2));
prcPayloadFuelRestPast(:, end+1, :, :) = squeeze(nanmean(prcPayloadFuelRestPast, 2));
prcPayloadFuelRestFuture(:, end+1, :, :) = squeeze(nanmean(prcPayloadFuelRestFuture, 2));

% if taking hourly mean, average over last dimension (curHour)
if hourlyMean
    prcRestPast = squeeze(nanmean(prcRestPast, 4));
    meanTowRestPast = squeeze(nanmean(meanTowRestPast, 4));
    prcRestFuture = squeeze(nanmean(prcRestFuture, 4));
    meanTowRestFuture = squeeze(nanmean(meanTowRestFuture, 4));
    prcPayloadFuelRestPast = squeeze(nanmean(prcPayloadFuelRestPast, 4));
    prcPayloadFuelRestFuture = squeeze(nanmean(prcPayloadFuelRestFuture, 4));
end


for acInd = 1:size(prcRestPast, 1)
    for curHour = 1:size(prcRestPast, 4)
        % plot left panel -----------------------------------------------------
        figure('Color', [1,1,1]);
        subplot(1, 2, 1);
        hold on;
        box on;
        axis square;

        p1 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcRestPast(acInd, end, weightBinsInd, curHour)), squeeze(range(prcRestPast(acInd, 1:end-1, weightBinsInd, curHour), 2))/2.0, 'o', 1);
        set(p1.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0/255.0, 135/255.0, 255/255.0], 'LineWidth', 3);
        set(p1.patch, 'FaceColor', [66/255.0, 176/255.0, 244/255.0]);
        set(p1.edge, 'Color', 'k');

        p2 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcRestFuture(acInd, end, weightBinsInd, curHour)), squeeze(range(prcRestFuture(acInd, 1:end-1, weightBinsInd, curHour), 2))/2.0, 'o', 1);
        set(p2.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 33/255.0, 33/255.0], 'LineWidth', 3);
        set(p2.patch, 'FaceColor', [249/255.0, 94/255.0, 94/255.0]);
        set(p2.edge, 'Color', 'k');

        xlabel('TOW (1000s lbs)', 'FontSize', 24);
        ylabel('Percent flights restricted', 'FontSize', 24);

        legend([p1.mainLine, p2.mainLine], 'Historical', 'RCP 8.5');

        grid(gca, 'on');
        set(gca, 'FontSize', 24);
        xlim([weightBins(weightBinsInd(1))-10, weightBins(end)+10]);
        if hourlyMean
            ylim([-1 30]);
        else
            ylim([-1 50]);
        end
        %ylim([-1 max(max(prcRestFuture)) + 1]);

        % plot right panel ----------------------------------------------------
        subplot(1, 2, 2);
        hold on;
        box on;
        axis square;

        p1 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcPayloadFuelRestPast(acInd, end, weightBinsInd, curHour)), squeeze(range(prcPayloadFuelRestPast(acInd, 1:end-1, weightBinsInd, curHour), 2))/2.0, 'o', 1);
        set(p1.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0/255.0, 135/255.0, 255/255.0], 'LineWidth', 3);
        set(p1.patch, 'FaceColor', [66/255.0, 176/255.0, 244/255.0]);
        set(p1.edge, 'Color', 'k');

        p2 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcPayloadFuelRestFuture(acInd, end, weightBinsInd, curHour)), squeeze(range(prcPayloadFuelRestFuture(acInd, 1:end-1, weightBinsInd, curHour), 2))/2.0, 'o', 1);
        set(p2.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 33/255.0, 33/255.0], 'LineWidth', 3);
        set(p2.patch, 'FaceColor', [249/255.0, 94/255.0, 94/255.0]);
        set(p2.edge, 'Color', 'k');

        xlabel('TOW (1000s lbs)', 'FontSize', 24);
        ylabel('Percent fuel + payload capacity', 'FontSize', 24);

        legend([p1.mainLine, p2.mainLine], 'Historical', 'RCP 8.5');

        grid(gca, 'on');
        set(gca, 'FontSize', 24);
        xlim([weightBins(weightBinsInd(1))-5, weightBins(end)+5]);
        if hourlyMean
            ylim([-0.1 3]);
        else
            ylim([-0.1 6]);
        end
        %ylim([-0.1 max(max(prcPayloadFuelRestFuture)) + 0.1]);

        t = suptitle(['All airports - ' aircraftList{acInd}]);
        set(t, 'FontSize', 40);

        set(gcf, 'Position', get(0,'Screensize'));
        if hourlyMean
            export_fig(['wrDist-allAirports-' aircraftList{acInd} '-hourMean.png'], '-m2');
        else
            export_fig(['wrDist-allAirports-' aircraftList{acInd} '-' num2str(curHour) '.png'], '-m2');
        end
        close all;
    end
end