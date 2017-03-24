%baseDirGcm = 'E:/data/flight/airport-wx/';
baseDirGcm = 'e:/data/flight/airport-wx/';
baseDirAsos = '2015-weight-restriction-v2/airport-wx/processed/';

airports = {'ATL', 'DCA', 'DEN', 'IAH', 'JFK', 'LAX', 'LGA', 'MIA', 'ORD', 'PHX', 'BKK', 'CDG', 'DXB', 'HKG', 'MAD', 'LHR', 'PEK', 'SHA', 'TLV'};

subplotRows = 5;
subplotCols = 4;

% difference between model and obs at each temp percentile
errors = {};

% load bias corrected models or not?
bc = true;

plotAirportTemps = false;
plotBias = true;

rcp = 'historical';

if plotAirportTemps
    figure('Color', [1,1,1]);
    hold on;
    axis off;
end

for a = 1:length(airports)
    airport = airports{a};
    
    errors{a} = {airport, {}};
    
    % load CMIP5 temps
    if bc
        load([baseDirGcm 'airport-wx-cmip5-' rcp '-bc-' airport '.mat']);
    else
        load([baseDirGcm 'airport-wx-cmip5-' rcp '-' airport '.mat']);
    end
    tempsGcm = wxData;
    
    % load observed temps
    load([baseDirAsos 'airport-wx-obs-' airport '.mat']);
    tempsObs = obsData;
    
    % find start and end year in obs data - GCMs from 1985 - 2004
    obsYearStartInd = max(1985 - tempsObs{2} + 1, 1);
    obsYearEndInd = min(max(2004 - tempsObs{2} + 1, 1), size(tempsObs{5}, 1));
    
    % select range of years that corresponds to GCMs
    obsMax = tempsObs{5}(obsYearStartInd:obsYearEndInd, :, :);
    obsMin = tempsObs{6}(obsYearStartInd:obsYearEndInd, :, :);
    
    % reshape into year x day
    obsMax = reshape(obsMax, [size(obsMax, 1), size(obsMax, 2)*size(obsMax, 3)]);
    obsMin = reshape(obsMin, [size(obsMin, 1), size(obsMin, 2)*size(obsMin, 3)]);
    
    gcmMax = [];
    gcmMin = [];
    
    % loop over models
    for m = 1:length(tempsGcm)
        errors{a}{2}{m} = {tempsGcm{m}{1}, [], []};
        gcmMax(:, :, m) = nanmax(tempsGcm{m}{2}{2}(:, 1:372, :), [], 3);
        gcmMin(:, :, m) = nanmin(tempsGcm{m}{2}{2}(:, 1:372, :), [], 3);
    end
    
    % temperature distributions for model & observations
    obsDistMax = [];
    obsDistMin = [];
    gcmDistMax = [];
    gcmDistMin = [];
    
    % percentiles to calculate
    prcThresh = 0:10:100;
    
    for p = 1:length(prcThresh)
        obsDistMax(p) = prctile(reshape(obsMax, [size(obsMax, 1)*size(obsMax, 2), 1]), prcThresh(p));
        obsDistMin(p) = prctile(reshape(obsMin, [size(obsMin, 1)*size(obsMin, 2), 1]), prcThresh(p));
        
        % loop over all models
        for m = 1:size(gcmMax, 3)
            % calculate percentile cutoffs for current GCM
            gcmDistMax(p, m) = prctile(reshape(gcmMax(:, :, m), [size(gcmMax(:, :, m), 1)*size(gcmMax(:, :, m), 2), 1]), prcThresh(p));
            gcmDistMin(p, m) = prctile(reshape(gcmMin(:, :, m), [size(gcmMin(:, :, m), 1)*size(gcmMin(:, :, m), 2), 1]), prcThresh(p));
            
            % find difference in cutoffs between GCM and obs
            errors{a}{2}{m}{2}(p) = gcmDistMax(p, m) - obsDistMax(p);
            errors{a}{2}{m}{3}(p) = gcmDistMin(p, m) - obsDistMin(p);
        end
    end
    
    if plotAirportTemps
        subplot_tight(subplotRows, subplotCols, a, [0.1 0.01]);
        hold on;
        axis square;
        box on;
        grid on;
        plot(gcmDistMax, 'Color', [90/255.0, 90/255.0, 90/255.0]);
        plot(obsDistMax,'k','LineWidth',4);
        %xlabel('Percentile', 'FontSize', 24);
        ylabel([char(176) 'C'], 'FontSize', 20);
        ylim([-50 50]);
        set(gca, 'FontSize', 20);
        set(gca, 'XTick', 1:11)
        set(gca, 'XTickLabel', {'Min', '', '', '', '', '', '', '', '', '', 'Max'});
        xlim([-1 12]);

        title(airport,'FontSize',24);
    end
end

if bc
    save('gcm-bias-bc.mat', 'errors');
else
    save('gcm-bias.mat', 'errors');
end

% calculate MSE across models for each airport
biasMax = [];
biasMin = [];
for a = 1:length(errors)
    for m = 1:length(errors{a}{2})
        biasMax(a, m, :) = errors{a}{2}{m}{2};
        biasMin(a, m, :) = errors{a}{2}{m}{3};
    end
end

biasMax = squeeze(nanmean(biasMax, 2));
biasMin = squeeze(nanmean(biasMin, 2));

if plotBias
    figure('Color', [1,1,1]);
    subplot(1, 2, 1);
    hold on;
    box on;
    grid on;
    axis square;
    plot(1:size(biasMax, 2), biasMax', 'Color', [90/255.0, 90/255.0, 90/255.0], 'LineWidth', 1);
    plot(1:size(biasMax, 2), nanmean(biasMax, 1), 'Color', 'k', 'LineWidth', 4);
    plot(1:size(biasMax, 2), zeros(size(biasMax, 2), 1), '--k', 'LineWidth', 2);
    xlabel('Percentile', 'FontSize', 24);
    ylabel(['Bias (' char(176) 'C)'], 'FontSize', 24);
    title('Daily maximum', 'FontSize', 30);
    set(gca, 'FontSize', 24);
    xlim([0 12]);
    ylim([-15 11]);
    set(gca, 'XTick', [1 6 11]);
    set(gca, 'XTickLabel', {'Min', '50th', 'Max'});
    
    subplot(1, 2, 2);
    hold on;
    box on;
    grid on;
    axis square;
    plot(1:size(biasMin, 2), biasMin', 'Color', [90/255.0, 90/255.0, 90/255.0], 'LineWidth', 1);
    plot(1:size(biasMin, 2), nanmean(biasMin, 1), 'Color', 'k', 'LineWidth', 4);
    plot(1:size(biasMin, 2), zeros(size(biasMin, 2), 1), '--k', 'LineWidth', 2);
    xlabel('Percentile', 'FontSize', 24);
    ylabel(['Bias (' char(176) 'C)'], 'FontSize', 24);
    title('Daily minimum', 'FontSize', 30);
    set(gca, 'FontSize', 24);
    xlim([0 12]);
    ylim([-15 11]);
    set(gca, 'XTick', [1 6 11]);
    set(gca, 'XTickLabel', {'Min', '50th', 'Max'});
end