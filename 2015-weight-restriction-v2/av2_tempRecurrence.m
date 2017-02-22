airportWxBaseDir = '2015-weight-restriction-v2/airport-wx/';

% mean daily max or annual max
annMax = true;

airports = {'PHX', 'DEN', 'MDW', 'DXB'};

figure('Color', [1, 1, 1]);

ind = 1;
% loop over airports
for a = 1:length(airports)
    
    if ~exist('wxDataHistorical')
        load([airportWxBaseDir 'airport-wx-cmip5-historical-' airports{a} '.mat']);
        wxDataHistorical = wxData;
    end

    if ~exist('wxDataRcp85')
        load([airportWxBaseDir, 'airport-wx-cmip5-rcp85-' airports{a} '.mat']);
        wxDataRcp85 = wxData;
    end

    if ~exist('wxDataRcp45')
        load([airportWxBaseDir, 'airport-wx-cmip5-rcp45-' airports{a} '.mat']);
        wxDataRcp45 = wxData;
    end

    tasmaxHistorical = [];
    tasmaxRcp85 = [];
    tasmaxRcp45 = [];
    
    ['processing ' airports{a} '...']
    
    % loop over models
    for m = 1:length(wxDataRcp85)
        
        % process historical data
        % years
        for y = 1:size(wxDataHistorical{m}{2}, 1)
            % days
            for d = 1:size(wxDataHistorical{m}{2}, 2)
                tasmaxHistorical(m, y, d) = nanmax(wxDataHistorical{m}{2}(y, d, :));
            end
        end
        
        % loop over years
        for y = 1:size(wxDataRcp85{m}{2}, 1)
            % loop over days
            for d = 1:size(wxDataRcp85{m}{2}, 2)
                % max of 24 hour temps
                tasmaxRcp85(m, y, d) = nanmax(wxDataRcp85{m}{2}(y, d, :));
                tasmaxRcp45(m, y, d) = nanmax(wxDataRcp45{m}{2}(y, d, :));
            end
        end
    end
    
    % calculate historical mean annual max
    annualMaxHistorical = squeeze(nanmax(tasmaxHistorical, [], 3));
    annualMaxHistorical = nanmean(nanmean(annualMaxHistorical));
    
    annualMaxRcp85 = squeeze(nanmax(tasmaxRcp85, [], 3));
    annualMaxRcp45 = squeeze(nanmax(tasmaxRcp45, [], 3));
    
    % calculate number of days above historical annual max
    recRcp85 = [];
    recRcp45 = [];

    for m = 1:size(tasmaxRcp85, 1)
        for y = 1:size(tasmaxRcp85, 2)
            
            % initialize counter
            recRcp85(m, y) = 0;
            recRcp45(m, y) = 0;
            
            % loop days
            for d = 1:size(tasmaxRcp85, 3)
                
                % found a future exceedence of historical ann max
                if tasmaxRcp85(m, y, d) > annualMaxHistorical
                    recRcp85(m, y) = recRcp85(m, y) + 1;
                end
                
                % found a future exceedence of historical ann max
                if tasmaxRcp45(m, y, d) > annualMaxHistorical
                    recRcp45(m, y) = recRcp45(m, y) + 1;
                end
                
            end
        end
    end
    
    
    % averaged for each decade
    recRcp85Decadal = [];
    recRcp45Decadal = [];
    
    % loop over each future decade
    for m = 1:size(recRcp45, 1)
        cnt = 1;
        for i = 1:10:size(recRcp45, 2)-1
            recRcp45Decadal(m, cnt) = nanmean(recRcp45(m, i:i+10));
            recRcp85Decadal(m, cnt) = nanmean(recRcp85(m, i:i+10));
            cnt = cnt + 1;
        end
    end
    
    h = subplot(2, 2, ind);
    hold on;

    p1 = shadedErrorBar(1:size(recRcp85Decadal, 2), nanmean(recRcp85Decadal, 1), nanstd(recRcp85Decadal, [], 1), '-', 1);
    set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
    set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
    set(p1.edge, 'Color', 'k');

    p2 = shadedErrorBar(1:size(recRcp45Decadal, 2), nanmean(recRcp45Decadal, 1), nanstd(recRcp45Decadal, [], 1), '-', 1);
    set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
    set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
    set(p2.edge, 'Color', 'k');
    
    xlim([1 6]);
    ylim([0 100]);
    
    set(h, 'XTick', [1 2 3 4 5 6]);
    set(h, 'XTickLabel', [2025 2035 2045 2055 2065 2075]);
    set(h, 'FontSize', 30);
    
    ylabel('Multiple', 'FontSize', 30);
    title(airports{a}, 'FontSize', 30);
    legend([p1.mainLine, p2.mainLine], 'RCP 8.5', 'RCP 4.5');
    
    ind = ind + 1;
end