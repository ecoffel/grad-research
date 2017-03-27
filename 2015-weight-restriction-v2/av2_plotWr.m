aircraft = {'a380'};%, 'a320', '787', '777-300', 'a380'};
wrBaseDir = '2015-weight-restriction-v2/wr-data/';

surfs = av2_loadSurfaces();

% colors for the full runway range - for the 1 legend
plotColors = distinguishable_colors(length(6000:1000:15000));
fullRunwayRange = 6000:1000:15000;

tempRange = 25:55;
figure('Color', [1,1,1]);
for a = 1:length(aircraft)
    if strcmp(aircraft{a}, '737-800')
        runwayRange = 6000:1000:12000;
    elseif strcmp(aircraft{a}, 'a320')
        runwayRange = 6000:1000:12000;
    elseif strcmp(aircraft{a}, 'a380')
        runwayRange = 8000:1000:15000;
    elseif strcmp(aircraft{a}, '777-300')
        runwayRange = 8000:1000:15000;
    elseif strcmp(aircraft{a}, '787')
        runwayRange = 8000:1000:15000;
    end

    wr = [];

    for t = 1:length(tempRange)
        for r = 1:length(runwayRange)
            wr(t, r) = av2_calcWeightRestriction(tempRange(t), runwayRange(r), 0, aircraft{a}, surfs);
        end
    end

    subplot_tight(1,1, a, [0.14, 0.04]);
    hold on;
    grid on;
    box on;
    axis square;

    lines = [];
    legendStr = '';
    for r = 1:length(fullRunwayRange)
        ind = find(fullRunwayRange(r) == runwayRange);
        if length(ind) == 1
            lines(end+1) = plot(tempRange(:), wr(:, ind), 'LineWidth', 2, 'Color', plotColors(r, :));
        else
            %lines(end+1) = plot(NaN, NaN, 'LineWidth', 2, 'Color', plotColors(r, :));
        end

        if length(legendStr) > 0
            legendStr = [legendStr ',''' num2str(fullRunwayRange(r)) ' ft '''];
        else
            legendStr = ['''' num2str(fullRunwayRange(r)) ' ft'''];
        end
    end

    % only print 1 legend - for 737
    if a == 1
        eval(['legend(lines, ' legendStr ', ''Location'', ''eastoutside'');']);
    end
    
    xlabel(['Temperature (' char(176) 'C)'], 'FontSize', 24);
    ylabel('WR (1000s lbs)', 'FontSize', 24);
    set(gca, 'FontSize', 24);
    title(aircraft{a}, 'FontSize', 24);
end