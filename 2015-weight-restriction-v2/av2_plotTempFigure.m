wxObsBaseDir = '2015-weight-restriction-v2/airport-wx/';
wxGcmBaseDir = 'e:\data\flight\airport-wx\';

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
    load([wxGcmBaseDir 'airport-wx-cmip5-historical-' airport '.mat']);
    wxDataHistorical = wxData;
    
    load([wxGcmBaseDir 'airport-wx-cmip5-rcp45-' airport '.mat']);
    wxDataRcp45 = wxData;

    load([wxGcmBaseDir 'airport-wx-cmip5-rcp85-' airport '.mat'])
    wxDataRcp85 = wxData;

    tasmaxRcp85 = [];
    tasmaxRcp45 = [];
    tasmaxHistorical = [];
    
    ['processing ' airport '...']
    
    % loop over models
    for m = 1:length(wxDataRcp85)
        
        % process historical data
        % years
        for y = 1:size(wxDataHistorical{m}{2}{2}, 1)
            % days
            for d = 1:size(wxDataHistorical{m}{2}{2}, 2)
                tasmaxHistorical(m, y, d) = nanmax(wxDataHistorical{m}{2}{2}(y, d, :));
            end
        end
        
        % process future data
        % loop over years
        for y = 1:size(wxDataRcp85{m}{2}{2}, 1)
            % loop over days
            for d = 1:size(wxDataRcp85{m}{2}{2}, 2)
                % max of 24 hour temps
                tasmaxRcp85(m, y, d) = nanmax(wxDataRcp85{m}{2}{2}(y, d, :));
                tasmaxRcp45(m, y, d) = nanmax(wxDataRcp45{m}{2}{2}(y, d, :));
            end
        end
    end
    
    % calculate historical mean annual max
    annualMaxHistorical = squeeze(nanmax(tasmaxHistorical, [], 3));
    annualMaxMeanHistorical = nanmean(nanmean(annualMaxHistorical));
    annualMaxErrHistorical = std(annualMaxHistorical, [], 1);
    
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
    recHistorical = [];

    % in the historical CMIP5...
    for m = 1:size(tasmaxHistorical, 1)
        for y = 1:size(tasmaxHistorical, 2)
            
            % initialize counter
            recHistorical(m, y) = 0;
            
            % loop days
            for d = 1:size(tasmaxHistorical, 3)
                
                % found a future exceedence of historical ann max
                if tasmaxHistorical(m, y, d) > annualMaxMeanHistorical
                    recHistorical(m, y) = recHistorical(m, y) + 1;
                end
            end
        end
    end
    
    % and in the future RCP 4.5 and 8.5 CMIP5...
    for m = 1:size(tasmaxRcp85, 1)
        for y = 1:size(tasmaxRcp85, 2)
            
            % initialize counter
            recRcp85(m, y) = 0;
            recRcp45(m, y) = 0;
            
            % loop days
            for d = 1:size(tasmaxRcp85, 3)
                
                % found a future exceedence of historical ann max
                if tasmaxRcp85(m, y, d) > annualMaxMeanHistorical
                    recRcp85(m, y) = recRcp85(m, y) + 1;
                end
                
                % found a future exceedence of historical ann max
                if tasmaxRcp45(m, y, d) > annualMaxMeanHistorical
                    recRcp45(m, y) = recRcp45(m, y) + 1;
                end
                
            end
        end
    end
    
    % averaged for each decade
    recRcp85Decadal = [];
    recRcp45Decadal = [];
    recHistoricalDecadal = [];
    
    % loop over each future decade for the historical CMIP5
    for m = 1:size(recHistorical, 1)
        cnt = 1;
        for i = 1:10:size(recHistorical, 2)-1
            recHistoricalDecadal(m, cnt) = nanmean(recHistorical(m, i:min(i+10, size(recHistorical,2))));
            cnt = cnt + 1;
        end
    end
    
    % loop over each future decade for the future CMIP5
    for m = 1:size(recRcp45, 1)
        cnt = 1;
        for i = 1:10:size(recRcp45, 2)-1
            recRcp45Decadal(m, cnt) = nanmean(recRcp45(m, i:i+10));
            recRcp85Decadal(m, cnt) = nanmean(recRcp85(m, i:i+10));
            cnt = cnt + 1;
        end
    end
    
    fitHistorical = fitlm(1:size(annualMaxHistorical, 2), nanmean(annualMaxHistorical, 1));
    fitHistoricalY = fitHistorical.Fitted;
    fitHistoricalSlope = fitHistorical.Coefficients.Estimate(2);
    fitHistoricalSE = fitHistorical.Coefficients.SE(2);
    
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

    xRange = 1:length(1985:2080);

    yDataRcp85 = zeros(size(xRange));
    yDataRcp85(yDataRcp85 == 0) = NaN;
    yDataRcp85(end-size(annualMaxRcp85, 2)+1:end) = squeeze(nanmean(annualMaxRcp85, 1));

    errDataRcp85 = zeros(size(xRange));
    errDataRcp85(yDataRcp85 == 0) = NaN;
    errDataRcp85(end-length(annualMaxErrRcp85)+1:end) = annualMaxErrRcp85;

    % plot rcp 8.5
    p1 = shadedErrorBar(xRange, yDataRcp85, errDataRcp85, '-', 1);
    set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
    set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
    set(p1.edge, 'Color', 'k');

    yDataRcp45 = zeros(size(xRange));
    yDataRcp45(yDataRcp45 == 0) = NaN;
    yDataRcp45(end-size(annualMaxRcp45, 2)+1:end) = squeeze(nanmean(annualMaxRcp45, 1));

    errDataRcp45 = zeros(size(xRange));
    errDataRcp45(yDataRcp45 == 0) = NaN;
    errDataRcp45(end-length(annualMaxErrRcp45)+1:end) = annualMaxErrRcp45;

    % plot rcp 4.5
    p2 = shadedErrorBar(xRange, yDataRcp45, errDataRcp45, '-', 1);
    set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
    set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
    set(p2.edge, 'Color', 'k');

    yDataHistorical = zeros(size(xRange));
    yDataHistorical(yDataHistorical == 0) = NaN;
    yDataHistorical(1:size(annualMaxHistorical, 2)) = squeeze(nanmean(annualMaxHistorical, 1));

    errDataHistorical = zeros(size(xRange));
    errDataHistorical(errDataHistorical == 0) = NaN;
    errDataHistorical(1:length(annualMaxErrHistorical)) = annualMaxErrHistorical;

    % plot historical
    p3 = shadedErrorBar(xRange, yDataHistorical, errDataHistorical, '-', 1);
    set(p3.mainLine,  'LineWidth', 2, 'Color', [121/255.0, 211/255.0, 80/255.0]);
    set(p3.patch, 'FaceColor', [121/255.0, 211/255.0, 80/255.0]);
    set(p3.edge, 'Color', 'k');

    % plot the historical annual maximum
    plot(xRange, ones(size(xRange)) .* annualMaxMeanHistorical, '--k', 'LineWidth', 2);

    % plot the rcp 45 and 8.5 trends
    firRcp45YData = zeros(size(xRange));
    firRcp45YData(firRcp45YData == 0) = NaN;
    firRcp45YData(end-length(fitRcp45Y)+1:end) = fitRcp45Y;
    
    firRcp85YData = zeros(size(xRange));
    firRcp85YData(firRcp85YData == 0) = NaN;
    firRcp85YData(end-length(fitRcp85Y)+1:end) = fitRcp85Y;
    
    plot(xRange, firRcp45YData, '--', 'Color', [90/255.0, 90/255.0, 90/255.0], 'LineWidth', 2);
    plot(xRange, firRcp85YData, '--', 'Color', [90/255.0, 90/255.0, 90/255.0], 'LineWidth', 2);

    set(h, 'XTick', [1 21 41 61 81 96]);
    set(h, 'XTickLabel', [1985 2005 2025 2045 2065 2080]);
    set(h, 'FontSize', 26);
    ylabel(['Temperature (' char(176) 'C)'], 'FontSize', 30);
    xlim([xRange(1) xRange(end)]);
    title(airport, 'FontSize', 30);
    legend([p1.mainLine, p2.mainLine, p3.mainLine], ...
                                       ['RCP 8.5, ' num2str(roundn(fitRcp85Slope*10, -2)) char(176) 'C/decade'], ...
                                       ['RCP 4.5, ' num2str(roundn(fitRcp45Slope*10, -2)) char(176) 'C/decade'], ...
                                       ['Historical'], ...
                                       'Location', 'northwest');
    
    ind = ind + 1;
    
    
    % -------------------------- plot the frequency change ---------------
    h = subplot(subplotRow, subplotCol, ind);
    hold on;
    box on;
    grid on;

    recXRange = 1:length(2025:10:2075);
    
    yDataRecRcp85 = zeros(size(recXRange));
    yDataRecRcp85(yDataRecRcp85 == 0) = NaN;
    yDataRecRcp85(end-size(recRcp85Decadal, 2)+1:end) = squeeze(nanmean(recRcp85Decadal, 1));

    errDataRecRcp85 = zeros(size(recXRange));
    errDataRecRcp85(errDataRecRcp85 == 0) = NaN;
    errDataRecRcp85(end-size(recRcp85Decadal, 2)+1:end) = squeeze(nanstd(recRcp85Decadal, [], 1));
    
    % plot frequency for RCP 8.5
    p1 = shadedErrorBar(recXRange, yDataRecRcp85, errDataRecRcp85, '-', 1);
    set(p1.mainLine,  'LineWidth', 2, 'Color', [237/255.0, 104/255.0, 104/255.0]);
    set(p1.patch, 'FaceColor', [237/255.0, 104/255.0, 104/255.0]);
    set(p1.edge, 'Color', 'k');

    yDataRecRcp45 = zeros(size(recXRange));
    yDataRecRcp45(yDataRecRcp45 == 0) = NaN;
    yDataRecRcp45(end-size(recRcp45Decadal, 2)+1:end) = squeeze(nanmean(recRcp45Decadal, 1));

    errDataRecRcp45 = zeros(size(recXRange));
    errDataRecRcp45(errDataRecRcp45 == 0) = NaN;
    errDataRecRcp45(end-size(recRcp45Decadal, 2)+1:end) = squeeze(nanstd(recRcp45Decadal, [], 1));
    
    % plot frequency for RCP 4.5
    p2 = shadedErrorBar(recXRange, yDataRecRcp45, errDataRecRcp45, '-', 1);
    set(p2.mainLine,  'LineWidth', 2, 'Color', [104/255.0, 186/255.0, 237/255.0]);
    set(p2.patch, 'FaceColor', [104/255.0, 186/255.0, 237/255.0]);
    set(p2.edge, 'Color', 'k');
   
    xlim([recXRange(1) recXRange(end)]);
    ylim([0 100]);
    
    set(h, 'XTick', recXRange);
    set(h, 'XTickLabel', 2025:10:2075);
    set(h, 'FontSize', 26);
    
    ylabel('Multiple', 'FontSize', 30);
    title(airport, 'FontSize', 30);
    legend([p1.mainLine, p2.mainLine], 'RCP 8.5', 'RCP 4.5', 'Location', 'northwest');
    
    ind = ind + 1;
end

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['temp-fig-' airportStr '.png'], '-m2');