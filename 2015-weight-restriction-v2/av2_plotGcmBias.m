baseDirGcm = 'E:/data/flight/airport-wx/';
baseDirAsos = '2015-weight-restriction-v2/airport-wx/processed/';

airports = {'DCA', 'DEN', 'IAH', 'JFK', 'LAX', 'LGA', 'MIA', 'ORD'};

figure('Color', [1,1,1]);
hold on;

for a = 1:length(airports)
    airport = airports{a};
    
    % load CMIP5 temps
    load([baseDirGcm 'airport-wx-cmip5-historical-' airport '.mat']);
    tempsGcm = wxData;
    
    % load observed temps
    load([baseDirAsos 'airport-wx-obs-' airport '.mat']);
    tempsObs = asosData;
    
    % find start and end year in obs data - GCMs from 1985 - 2004
    obsYearStartInd = max(1985 - tempsObs{2} + 1, 1);
    obsYearEndInd = max(2004 - tempsObs{2} + 1, 1);
    
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
        gcmMax(:, :, m) = nanmax(tempsGcm{m}{2}(:, 1:372, :), [], 3);
        gcmMin(:, :, m) = nanmin(tempsGcm{m}{2}(:, 1:372, :), [], 3);
    end
    
    % temperature distributions for model & observations
    obsDist = [];
    gcmDist = [];
    
    % percentiles to calculate
    prcThresh = 0:10:100;
    
    for p = 1:length(prcThresh)
        obsDist(p) = prctile(reshape(obsMax, [size(obsMax, 1)*size(obsMax, 2), 1]), prcThresh(p));
        
        for m = 1:size(gcmMax, 3)
            gcmDist(p, m) = prctile(reshape(gcmMax(:, :, m), [size(gcmMax(:, :, m), 1)*size(gcmMax(:, :, m), 2), 1]), prcThresh(p));
        end
    end
    
    subplot(3, 3, a);
    hold on;
    axis square;
    box on;
    grid on;
    plot(gcmDist);
    plot(obsDist,'k','LineWidth',4);
    xlim([-1 12]);
    title(airport,'FontSize',24);
end