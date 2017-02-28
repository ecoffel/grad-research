
%wxBaseDir = '2015-weight-restriction-v2/airport-wx/';

wxBaseDir = 'G:\data\flight\airport-wx\';

airports = {'IAH', 'DEN'};

% subplot dimensions
subplotRow = 2;
subplotCol = 2;

% mean daily max or annual max
annMax = true;

% for the file name, like 'MDW-DXB'
airportStr = '';

figure('Color', [1, 1, 1]);

ind = 1;
% loop over airports
for a = 1:length(airports)
    airport = airports{a};
    
    if length(airportStr) > 0
        airportStr = [airportStr '-' airport];
    else
        airportStr = airport;
    end
    
    % load wx data (and just crash out if it doesn't exist)
    load([wxBaseDir 'airport-wx-cmip5-historical-' airport '.mat']);
    wxDataHistorical = wxData;
    
    load([wxBaseDir 'airport-wx-cmip5-rcp45-' airport '.mat']);
    wxDataRcp45 = wxData;

    load([wxBaseDir 'airport-wx-cmip5-rcp85-' airport '.mat'])
    wxDataRcp85 = wxData;

    tasmaxRcp85 = [];
    tasmaxRcp45 = [];
    tasmaxHistorical = [];
    
    ['processing ' airport '...']
    
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
        
        % process future data
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
    
    annualMeanRcp85 = squeeze(nanmean(tasmaxRcp85, 3));
    annualMaxRcp85 = squeeze(nanmax(tasmaxRcp85, [], 3));
    annualMeanErrRcp85 = std(annualMeanRcp85, [], 1);
    annualMaxErrRcp85 = std(annualMaxRcp85, [], 1);
    
    annualMeanRcp45 = squeeze(nanmean(tasmaxRcp45, 3));
    annualMaxRcp45 = squeeze(nanmax(tasmaxRcp45, [], 3));
    annualMeanErrRcp45 = std(annualMeanRcp45, [], 1);
    annualMaxErrRcp45 = std(annualMaxRcp45, [], 1);
    
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
    
    fitRcp45 = fitlm(1:size(annualMaxRcp45, 2), nanmean(annualMaxRcp45, 1));
    fitRcp45Y = fitRcp45.Fitted;
    fitRcp45Slope = fitRcp45.Coefficients.Estimate(2);
    fitRcp45SE = fitRcp45.Coefficients.SE(2);
    
    fitRcp85 = fitlm(1:size(annualMaxRcp85, 2), nanmean(annualMaxRcp85, 1));
    fitRcp85Y = fitRcp85.Fitted;
    fitRcp85Slope = fitRcp85.Coefficients.Estimate(2);
    fitRcp85SE = fitRcp85.Coefficients.SE(2);
    
    % -------------------------- plot the temp change --------------------
    h = subplot(subplotRow, subplotCol, ind);
    hold on;
    box on;
    grid on;
    
    if annMax
        p1 = shadedErrorBar(1:size(annualMaxRcp85, 2), nanmean(annualMaxRcp85, 1), annualMaxErrRcp85, '-', 1);
        set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.edge, 'Color', 'k');

        p2 = shadedErrorBar(1:size(annualMaxRcp45, 2), nanmean(annualMaxRcp45, 1), annualMaxErrRcp45, '-', 1);
        set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.edge, 'Color', 'k');
        
        % plot the historical annual maximum
        plot(linspace(1, size(annualMaxRcp85, 2), 50), ones(50, 1) .* annualMaxHistorical, '--k', 'LineWidth', 2);
        
        % plot the rcp 45 and 8.5 trends
        plot(1:size(annualMaxRcp45, 2), fitRcp45Y, '--', 'Color', [90/255.0, 90/255.0, 90/255.0], 'LineWidth', 2);
        plot(1:size(annualMaxRcp85, 2), fitRcp85Y, '--', 'Color', [90/255.0, 90/255.0, 90/255.0], 'LineWidth', 2);
        
    else
        p1 = shadedErrorBar(1:size(annualMeanRcp85, 2), nanmean(annualMeanRcp85, 1), annualMeanErrRcp85, '-', 1);
        set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
        set(p1.edge, 'Color', 'k');

        p2 = shadedErrorBar(1:size(annualMeanRcp45, 2), nanmean(annualMeanRcp45, 1), annualMeanErrRcp45, '-', 1);
        set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
        set(p2.edge, 'Color', 'k');
    end
    
    set(h, 'XTick', [6 16 26 36 46 56]);
    set(h, 'XTickLabel', [2025 2035 2045 2055 2065 2075]);
    set(h, 'FontSize', 26);
    ylabel(['Temperature (' char(176) 'C)'], 'FontSize', 30);
    xlim([1 61]);
    title(airport, 'FontSize', 30);
    legend([p1.mainLine, p2.mainLine], ['RCP 8.5, ' num2str(roundn(fitRcp85Slope*10, -2)) char(176) 'C/decade'], ...
                                       ['RCP 4.5, ' num2str(roundn(fitRcp45Slope*10, -2)) char(176) 'C/decade'], ...
                                       'Location', 'northwest');
    
    ind = ind + 1;
    
    
    % -------------------------- plot the frequency change ---------------
    h = subplot(subplotRow, subplotCol, ind);
    hold on;
    box on;
    grid on;

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
    set(h, 'FontSize', 26);
    
    ylabel('Multiple', 'FontSize', 30);
    title(airport, 'FontSize', 30);
    legend([p1.mainLine, p2.mainLine], 'RCP 8.5', 'RCP 4.5', 'Location', 'northwest');
    
    ind = ind + 1;
end

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['temp-fig-' airportStr '.png'], '-m2');