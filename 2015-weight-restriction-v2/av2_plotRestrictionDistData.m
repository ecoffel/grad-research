load('2015-weight-restriction-v2/restrictionData/restrictionData-tr-12');
%load('restrictionData-tr');

% restrictionData{aircraft}{rcp}{airport}{data-item}

% is this a limited number of hours, or the whole day?
% if restrictionData-tr-12, numHours = 1
% if restrictionData-tr, numHours = 24
numHours = 1;

rcpInd = 4;
subplotInd = 1;
acSurfs = av2_loadSurfaces();

for acInd = 1:length(restrictionData)
    % percentage of flights with at least some restriction
    prcRestPast = [];
    % percentage of target TOW removed
    meanTowRestPast = [];
    % percentage of payload+fuel capacity restricted
    prcPayloadFuelRestPast = [];
    
    prcRestFuture = [];
    meanTowRestFuture = [];
    prcPayloadFuelRestFuture = [];
    
    weightBins = restrictionData{acInd}{1}{2};
    weightBinsInd = 6:length(weightBins);

    aircraft = restrictionData{acInd}{1}{1};
    
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
    for airportInd = 4%:length(restrictionData{acInd}{2})
        airport = restrictionData{acInd}{2}{airportInd}{1};
        
        % calculate stats for the past (rcp = historical)
        % percentage of flights restricted
        prcRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{3}, 2)) .* 100;

        % percentage of TOW restricted
        meanTowRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{4}, 2)) .* 100;
                        
        prcPayloadFuelRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) ./ 365 ./ ...
                            numHours ./ payloadAndFuel .* 100;
                       
        
        % stats for the future (rcp = rcpInd)
        % percentage of flights restricted
        prcRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{3}, 2)) .* 100;

        % percentage of TOW restricted
        meanTowRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{4}, 2)) .* 100;

        prcPayloadFuelRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) ./ 365 ./ ...
                            numHours ./ payloadAndFuel .* 100;
                        
        airportCount = airportCount + 1;
    end

    % take mean across airports
    prcRestPast = nanmean(prcRestPast, 3);
    meanTowRestPast = nanmean(meanTowRestPast, 3);
    prcRestFuture = nanmean(prcRestFuture, 3);
    meanTowRestFuture = nanmean(meanTowRestFuture, 3);
    prcPayloadFuelRestPast = nanmean(prcPayloadFuelRestPast, 3);
    prcPayloadFuelRestFuture = nanmean(prcPayloadFuelRestFuture, 3);
    
    % add the multi-model means to the end of the matrix... we'll make
    % these dots black and bold
    prcRestPast(end+1, :) = squeeze(nanmean(prcRestPast, 1));
    meanTowRestPast(end+1, :) = squeeze(nanmean(meanTowRestPast, 1));
    prcRestFuture(end+1, :) = squeeze(nanmean(prcRestFuture, 1));
    meanTowRestFuture(end+1, :) = squeeze(nanmean(meanTowRestFuture, 1));
    prcPayloadFuelRestPast(end+1, :) = squeeze(nanmean(prcPayloadFuelRestPast, 1));
    prcPayloadFuelRestFuture(end+1, :) = squeeze(nanmean(prcPayloadFuelRestFuture, 1));
    
    % plot left panel -----------------------------------------------------
    
    figure('Color', [1,1,1]);
    subplot(1, 2, 1);
    hold on;
    box on;
    axis square;
    
    p1 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcRestPast(end, weightBinsInd)), squeeze(range(prcRestPast(1:end-1, weightBinsInd), 1))/2.0, 'o', 1);
    set(p1.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0/255.0, 135/255.0, 255/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [66/255.0, 176/255.0, 244/255.0]);
    set(p1.edge, 'Color', 'k');
    
    p2 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcRestFuture(end, weightBinsInd)), squeeze(range(prcRestFuture(1:end-1, weightBinsInd), 1))/2.0, 'o', 1);
    set(p2.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 33/255.0, 33/255.0], 'LineWidth', 3);
    set(p2.patch, 'FaceColor', [249/255.0, 94/255.0, 94/255.0]);
    set(p2.edge, 'Color', 'k');
    
    xlabel('TOW (1000s lbs)', 'FontSize', 24);
    ylabel('Percent flights restricted', 'FontSize', 24);

    legend([p1.mainLine, p2.mainLine], 'Historical', 'RCP 8.5');
    
    grid(gca, 'on');
    set(gca, 'FontSize', 24);
    xlim([weightBins(weightBinsInd(1))-10, weightBins(end)+10]);
    ylim([-1 70]);
    %ylim([-1 max(max(prcRestFuture)) + 1]);
    
    % plot right panel ----------------------------------------------------
    
    subplot(1, 2, 2);
    hold on;
    box on;
    axis square;
    
    p1 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcPayloadFuelRestPast(end, weightBinsInd)), squeeze(range(prcPayloadFuelRestPast(1:end-1, weightBinsInd), 1))/2.0, 'o', 1);
    set(p1.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0/255.0, 135/255.0, 255/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [66/255.0, 176/255.0, 244/255.0]);
    set(p1.edge, 'Color', 'k');
    
    p2 = shadedErrorBar(weightBins(weightBinsInd), squeeze(prcPayloadFuelRestFuture(end, weightBinsInd)), squeeze(range(prcPayloadFuelRestFuture(1:end-1, weightBinsInd), 1))/2.0, 'o', 1);
    set(p2.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 33/255.0, 33/255.0], 'LineWidth', 3);
    set(p2.patch, 'FaceColor', [249/255.0, 94/255.0, 94/255.0]);
    set(p2.edge, 'Color', 'k');
    
    xlabel('TOW (1000s lbs)', 'FontSize', 24);
    ylabel('Percent TOW restricted', 'FontSize', 24);
    
    legend([p1.mainLine, p2.mainLine], 'Historical', 'RCP 8.5');

    grid(gca, 'on');
    set(gca, 'FontSize', 24);
    xlim([weightBins(weightBinsInd(1))-5, weightBins(end)+5]);
    ylim([-0.1 12]);
    %ylim([-0.1 max(max(prcPayloadFuelRestFuture)) + 0.1]);
    
    t = suptitle(['All airports - ' aircraft]);
    set(t, 'FontSize', 40);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wrDist-allAirports-' aircraft '.png'], '-m2');
    close all;
end