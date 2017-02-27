load restrictionData;

% restrictionData{aircraft}{rcp}{airport}{data-item}

% acInd = 5;
%airportInd = 10;

for acInd = 1:length(restrictionData)
    weightBins = restrictionData{acInd}{1}{2};
    weightBinsInd = 6:length(weightBins);

    aircraft = restrictionData{acInd}{1}{1};

    airportCount = 1;
    for airportInd = 2:length(restrictionData{acInd}{2})
        airport = restrictionData{acInd}{2}{airportInd}{1};

        percentFlightsRestricted(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{3}, 2)) .* 100;

        meanTowRestricted(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{4}, 2)) .* 100;

        airportCount = airportCount + 1;
    end

    percentFlightsRestricted = nanmean(percentFlightsRestricted, 3);
    meanTowRestricted = nanmean(meanTowRestricted, 3);

    figure('Color', [1,1,1]);
    hold on;
    box on;
    [hAx, hLine1, hLine2] = plotyy(weightBins(weightBinsInd), percentFlightsRestricted(:, weightBinsInd), weightBins(weightBinsInd), meanTowRestricted(:, weightBinsInd));

    set(hLine1, 'LineStyle', 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'auto', 'LineWidth', 2);
    set(hLine2, 'LineStyle', 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'auto', 'LineWidth', 2);

    axis(hAx(1), 'square');
    axis(hAx(2), 'square');

    xlabel(hAx(1), 'TOW (1000s lbs)', 'FontSize', 24);
    set(hAx(2), 'XTick', []);

    ylabel(hAx(1), 'Percent flights restricted', 'FontSize', 24);
    ylabel(hAx(2), 'Percent TOW restricted', 'FontSize', 24);
    title(['All airports - ' aircraft], 'FontSize', 30);

    grid(hAx(1), 'on');
    set(hAx(1), 'FontSize', 24);
    set(hAx(2), 'FontSize', 24);
    xlim(hAx(1), [weightBins(weightBinsInd(1))-10, weightBins(end)+10]);
    xlim(hAx(2), [weightBins(weightBinsInd(1))-10, weightBins(end)+10]);

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wrDist-allAirports-' aircraft '.png'], '-m2');
    close all;
end