load restrictionData-tr;

% restrictionData{aircraft}{rcp}{airport}{data-item}

rcpInd = 4;

subplotInd = 1;

for acInd = 1:length(restrictionData)
    prcRestPast = [];
    meanTowRestPast = [];
    
    prcRestFuture = [];
    meanTowRestFuture = [];
    
    weightBins = restrictionData{acInd}{1}{2};
    weightBinsInd = 6:length(weightBins);

    aircraft = restrictionData{acInd}{1}{1};
    
    airportCount = 1;
    for airportInd = 2:length(restrictionData{acInd}{2})
        airport = restrictionData{acInd}{2}{airportInd}{1};

        % calculate stats for the past (rcp = historical)
        prcRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{3}, 2)) .* 100;

        meanTowRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{4}, 2)) .* 100;
                        
        
        % stats for the future (rcp = rcpInd)
        prcRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{3}, 2)) .* 100;

        meanTowRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{4}, 2)) .* 100;

        airportCount = airportCount + 1;
    end

    % take mean across airports
    prcRestPast = nanmean(prcRestPast, 3);
    meanTowRestPast = nanmean(meanTowRestPast, 3);
    prcRestFuture = nanmean(prcRestFuture, 3);
    meanTowRestFuture = nanmean(meanTowRestFuture, 3);
    
    % add the multi-model means to the end of the matrix... we'll make
    % these dots black and bold
    prcRestPast(end+1, :) = squeeze(nanmean(prcRestPast, 1));
    meanTowRestPast(end+1, :) = squeeze(nanmean(meanTowRestPast, 1));
    prcRestFuture(end+1, :) = squeeze(nanmean(prcRestFuture, 1));
    meanTowRestFuture(end+1, :) = squeeze(nanmean(meanTowRestFuture, 1));
    
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
    ylim([-1 max(max(prcRestFuture)) + 1]);
    
    % plot right panel ----------------------------------------------------
    
    subplot(1, 2, 2);
    hold on;
    box on;
    axis square;
    
    p1 = shadedErrorBar(weightBins(weightBinsInd), squeeze(meanTowRestPast(end, weightBinsInd)), squeeze(range(meanTowRestPast(1:end-1, weightBinsInd), 1))/2.0, 'o', 1);
    set(p1.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0/255.0, 135/255.0, 255/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [66/255.0, 176/255.0, 244/255.0]);
    set(p1.edge, 'Color', 'k');
    
    p2 = shadedErrorBar(weightBins(weightBinsInd), squeeze(meanTowRestFuture(end, weightBinsInd)), squeeze(range(meanTowRestFuture(1:end-1, weightBinsInd), 1))/2.0, 'o', 1);
    set(p2.mainLine,  'MarkerSize', 12, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 33/255.0, 33/255.0], 'LineWidth', 3);
    set(p2.patch, 'FaceColor', [249/255.0, 94/255.0, 94/255.0]);
    set(p2.edge, 'Color', 'k');
    
    xlabel('TOW (1000s lbs)', 'FontSize', 24);
    ylabel('Percent TOW restricted', 'FontSize', 24);
    
    legend([p1.mainLine, p2.mainLine], 'Historical', 'RCP 8.5');

    grid(gca, 'on');
    set(gca, 'FontSize', 24);
    xlim([weightBins(weightBinsInd(1))-5, weightBins(end)+5]);
    ylim([-0.1 max(max(meanTowRestFuture)) + 0.1]);
    
    t = suptitle(['All airports - ' aircraft]);
    set(t, 'FontSize', 40);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wrDist-allAirports-' aircraft '.png'], '-m2');
    close all;
end