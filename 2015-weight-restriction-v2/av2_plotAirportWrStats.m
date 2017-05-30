
% hours to analyze (time of Tx)
selectedHour = 12;

% show bar graph or box plot
showBarPlot = true;

if showBarPlot
    % for bar graph
    selectedAirports = {'LGA', 'DXB', 'PHX', 'LAX'};
    airportList = {};
    aircraftList = {};
end

restrictionDataBaseDir = '2015-weight-restriction-v2/restrictionData/restriction-data-old/'; 

% 3 = RCP 4.5
% 4 = RCP 8.5
rcpInd = 4;

acSurfs = av2_loadSurfaces();

load([restrictionDataBaseDir 'restrictionData-tr-' num2str(selectedHour)]);

% if true, show the percentage of flights restricted at each airport
% if false, show the percentage payload+fuel weight removed
showPrcRestricted = true;

% ac/airport combos
% 737-800/LGA, airportInd = 3
% 777-300/DXB, airportInd = 4

if showBarPlot
    % percentage of MTOW flights restricted at each airport for each
    % aircraft type
    percentRestricted = [];
end

for acInd = 1:length(restrictionData)
    % percentage of flights with at least some restriction
    prcRestPast = [];
    % percentage of target TOW removed
    meanTowRestPast = [];
    % percentage of payload+fuel capacity restricted
    prcPayloadFuelRestPast = [];

    % all airport names for current aircraft
    airportLabels = {};
    
    prcRestFuture = [];
    meanTowRestFuture = [];
    prcPayloadFuelRestFuture = [];

    weightBins = restrictionData{acInd}{1}{2};
    weightBinsInd = 6:length(weightBins);

    aircraft = restrictionData{acInd}{1}{1};
    
    if showBarPlot
        % store names of aircraft to use in bar legend
        aircraftList{acInd} = aircraft;
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
        
        % skip all non-selected airports
        if showBarPlot && ~ismember(airport, selectedAirports)
            continue;
        end
        
        
        
        % save list of airports in correct order for bar plot
        if showBarPlot
            airportList{end+1} = airport;
        end
        
        % add current airport to list
        airportLabels{end+1} = airport;

        % calculate stats for the past (rcp = historical)
        % percentage of flights restricted
        prcRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{3}, 2)) .* 100;

        % percentage of TOW restricted
        meanTowRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{4}, 2)) .* 100;

        prcPayloadFuelRestPast(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{2}{airportInd}{2}{2}, 2)) .* 0.83 ./ 365 ./ ...
                            payloadAndFuel .* 100;


        % stats for the future (rcp = rcpInd)
        % percentage of flights restricted
        prcRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{1}, 2)) ./ ...
                                   squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{3}, 2)) .* 100;
                               
        if showBarPlot
            barApInd = -1;
            for ap = 1:length(selectedAirports)
                if strcmp(airport, selectedAirports{ap})
                    barApInd = ap;
                end
            end
            
            % dimensions: (gcm, TOW, airport, aircraft)
            percentRestricted(:, barApInd, acInd) = prcRestFuture(:, end, airportCount);
        end

        % percentage of TOW restricted
        meanTowRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) ./ ...
                            squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{4}, 2)) .* 100;

        prcPayloadFuelRestFuture(:, :, airportCount) = squeeze(nanmean(restrictionData{acInd}{rcpInd}{airportInd}{2}{2}, 2)) .* 0.83 ./ 365 ./ ...
                            payloadAndFuel .* 100;

        airportCount = airportCount + 1;
    end

    % plot a box plot for each aircraft type
    if ~showBarPlot
        if showPrcRestricted
            boxData = squeeze(prcRestFuture(:, 10, :));
            boxGroups = 1:size(prcRestFuture, 3);
        else
            boxData = squeeze(prcPayloadFuelRestFuture(:, 10, :));
            boxGroups = 1:size(prcPayloadFuelRestFuture, 3);
        end

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;

        b = boxplot(boxData, boxGroups, 'Labels', airportLabels);
        set(findobj(gca, 'Type', 'text'), 'FontSize', 14, 'VerticalAlignment', 'middle');
        set(gca, 'FontSize', 24);
        if prcPayloadFuelRestFuture
            ylabel('% flights restricted', 'FontSize', 24);
        else
            ylabel('% payload & fuel', 'FontSize', 24);
        end
        for ih = 1:size(b, 1)
            set(b(ih,:), 'LineWidth', 2); % Set the line width of the Box outlines here
        end

        ylim([0 22]);
        title(aircraft);
        %set(gcf, 'Position', get(0,'Screensize'));
        %export_fig(['wrDist-allAirports-' aircraft '-' num2str(curHour) '.png'], '-m2');
        %close all;
    end
end

if showBarPlot
    
    barData = [];
    barErrUpper = [];
    barErrLower = [];
    
    % loop over airports
    for i = 1:size(percentRestricted, 2)
        acData = [];
        acErrUpper = [];
        acErrLower = [];
        % loop over aircraft and get GCM-mean percent restricted at MTOW
        for a = 1:size(percentRestricted, 3)
            acData(a) = squeeze(nanmean(percentRestricted(:, i, a), 1));
            acErrUpper(a) =  min(100-acData(a), squeeze(nanstd(percentRestricted(:, i, a), [], 1)));
            acErrLower(a) =  min(acData(a), squeeze(nanstd(percentRestricted(:, i, a), [], 1)));
        end
        barData(i, :) = acData;
        barErrUpper(i, :) = acErrUpper;
        barErrLower(i, :) = acErrLower;
    end
    
    colors = [215 25 28;
              253 174 97;
              255 255 191;
              171 221 164;
              43 131 186] ./ 255.0;
    
    errorbar_groups(barData', barErrLower', barErrUpper', 'bar_width', 0.6, 'bar_colors', colors);
    
    fig = gcf;
    set(fig, 'Color', [1,1,1]);
    box on;
    axis square;
    grid on;
    
    legendStr = 'legend(';
    for a = 1:length(aircraftList)
        legendStr = [legendStr '''' upper(aircraftList{a}) ''','];
    end
    legendStr = legendStr(1:end-1);
    legendStr = [legendStr ');'];
    eval(legendStr);
    
    set(gca, 'FontSize', 24);
    set(gca, 'XTickLabel', selectedAirports);
    ylim([0 105]);
    ylabel('Percentage of flights with restriction', 'FontSize', 24);
    
end
