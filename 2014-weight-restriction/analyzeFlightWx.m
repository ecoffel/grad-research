% repeat this analysis for winter

airport = 'PHX';
departureWindow = [17 17];
departureMonths = [6 7 8];
filterWx = true;
regression = false;

if ~exist('flightWx')
    flightWx = {};
    for y = 2003:2008
        load(['aviation-weather/data/flightWx', num2str(y), '.mat']);
        eval(['curFlightWx = flightWx', num2str(y), ';']);
        eval(['clear flightWx', num2str(y), ';']);
        
        if filterWx
            
            filteredFlights = cellfun(@(x) (strcmp(x{1}{3}, airport) & ...                     % departure airport = PHX 
                                                 x{2}{7} >= 9 & ...                      % visibility > 9 miles
                                                 x{2}{5} >= 0 & x{2}{5} < 10 & ...      % wind speed < 10 knots
                                                 x{2}{6} <= 15 & ...                    % wind gust < 15 knots
                                                 x{2}{3} >= -10 & x{2}{3} <= 60 & ...   % -10 < temp < 60 degrees C
                                                 x{1}{5} >= -5 & x{1}{5} < 600), ...    % -5 < delay < 600 minutes
                                                 curFlightWx, 'UniformOutput', false);
        else
            filteredFlights = cellfun(@(x) (strcmp(x{1}{3}, airport) & x{2}{3} <= 60 & x{1}{5} >= -5), ...
                                                 curFlightWx, 'UniformOutput', false);
        end
        
        % find entries that are empty in the filter and replace with zeros
        empty = find(cellfun(@isempty, filteredFlights));
        filteredFlights(empty) = {0};
        filteredFlights = find([filteredFlights{:}]);
        curFlightWx = curFlightWx(filteredFlights);
        
        % find flights that are in the correct months
        depTimesCell = cellfun(@(x) datevec(x{1}{6}), curFlightWx, 'UniformOutput', false);
        depMonths = cell2mat(cellfun(@(x) x(2), depTimesCell, 'UniformOutput', false));
        depMonthsInd = find(ismember(depMonths, departureMonths));
        curFlightWx = curFlightWx(depMonthsInd);
        
        flightWx = {flightWx{:} curFlightWx{:}};
        clear curFlightWx depTimesCell filteredFlights;
    end
end

if regression
    
    coeffs = {[], [], [], []};
    lens = [];
    for d = 8:22
        % find flights within departure window
        depTimesCell = cellfun(@(x) datevec(x{1}{6}), flightWx, 'UniformOutput', false);
        depTimes = cell2mat(cellfun(@(x) x(4), depTimesCell, 'UniformOutput', false));
        depTimeInd = find(depTimes == d);
        filteredFlightData = flightWx(depTimeInd);
        
        % find non-empty indices
        notEmptyIndex = find(cellfun(@(x) ~isempty(x), filteredFlightData));
        filteredFlightData = filteredFlightData(notEmptyIndex);
        
        depTimes = cellfun(@(x) datevec(x{1}{6}), filteredFlightData, 'UniformOutput', false);
        depTimes = cell2mat(cellfun(@(x) x(4), depTimes, 'UniformOutput', false));
        
        % make sure the arrays are all the same length by deleting any
        % empty entries
        notDelayEmpty = find(cellfun(@(x) ~isempty(x{1}{5}), filteredFlightData));
        notVisEmpty = find(cellfun(@(x) ~isempty(x{2}{7}), filteredFlightData));
        notWindSpdEmpty = find(cellfun(@(x) ~isempty(x{2}{5}), filteredFlightData));
        notWindGustEmpty = find(cellfun(@(x) ~isempty(x{2}{6}), filteredFlightData));
        notTempEmpty = find(cellfun(@(x) ~isempty(x{2}{3}), filteredFlightData));
        
        filteredFlightData = filteredFlightData(intersect(intersect(notDelayEmpty, notVisEmpty), intersect(notWindSpdEmpty, notWindGustEmpty)));
        
        delays = cell2mat(cellfun(@(x) x{1}{5}, filteredFlightData, 'UniformOutput', false));
        vis = cell2mat(cellfun(@(x) x{2}{7}, filteredFlightData, 'UniformOutput', false));
        windSpd = cell2mat(cellfun(@(x) x{2}{5}, filteredFlightData, 'UniformOutput', false));
        windGust = cell2mat(cellfun(@(x) x{2}{6}, filteredFlightData, 'UniformOutput', false));
        temps = cell2mat(cellfun(@(x) x{2}{3}, filteredFlightData, 'UniformOutput', false));
        
        % count flights in this departure window
        lens(end+1) = length(filteredFlightData);
        
        X = [temps', vis', windSpd', windGust'];
        c = regress(delays', X);
        coeffs{1}(end+1) = c(1);
        coeffs{2}(end+1) = c(2);
        coeffs{3}(end+1) = c(3);
        coeffs{4}(end+1) = c(4);
        
        clear filteredFlightData depTimes delays vis windSpd windGust temps;
    end

    figure('Color', [1,1,1]);
    hold on;
    plot(8:22, coeffs{1}, 'k', 'LineWidth', 2);
    plot(8:22, coeffs{2}, 'b');
    plot(8:22, coeffs{3}, 'r');
    plot(8:22, coeffs{4}, 'g');
    l = legend('temp', 'vis', 'wind speed', 'wind gust');
    xlabel('hour', 'FontSize', 18);
    ylabel('coeff', 'FontSize', 18);
    title('DEN summer delay factors', 'FontSize', 18);
    set(gcf, 'Position', get(0,'Screensize'));
    set(l, 'FontSize', 18, 'Location', 'best');
    myaa('publish');
    exportfig('analyzeFlightWx-summer-regression-coeff-den.png', 'Width', 16);
    close all;

else
    
% find flights within departure window
    depTimesCell = cellfun(@(x) datevec(x{1}{6}), flightWx, 'UniformOutput', false);
    depTimes = cell2mat(cellfun(@(x) x(4), depTimesCell, 'UniformOutput', false));
    depTimeInd = find(depTimes >= departureWindow(1) & depTimes <= departureWindow(2));
    filteredFlightData = flightWx(depTimeInd);

    emptyIndex = find(cellfun(@(x) isempty(x{2}{3}), filteredFlightData));
    for e = emptyIndex
        filteredFlightData{e}{2}{3} = 0;
    end

    delays = cell2mat(cellfun(@(x) x{1}{5}, filteredFlightData, 'UniformOutput', false));
    temps = cell2mat(cellfun(@(x) x{2}{3}, filteredFlightData, 'UniformOutput', false));

    [h, bp] = hist(temps, min(temps):1:max(temps));

    ind = {};
    for i = 1:length(bp)
        ind{i} = find(temps == bp(i));
    end

    bpdelay = [];
    for i = 1:length(ind)
        if length(find(delays(ind{i}) > 15)) > 10
            bpdelay(i) = length(find(delays(ind{i}) > 15))/length(delays(ind{i}));
        else
            bpdelay(i) = NaN;
        end
    end

    indNonNan = find(~isnan(bpdelay));
    bp = bp(indNonNan);
    bpdelay = bpdelay(indNonNan);

    p = polyfit(bp, bpdelay, 1);
    py = polyval(p, bp);

    figure('Color', [1 1 1]);
    hold on;
    plot(bp, bpdelay, 'k', 'LineWidth', 2);
    plot(bp, py, '-r');
    title('PHX: summer percentage of flights delayed between 5-5pm', 'FontSize', 16);
    xlabel('temp (deg C)', 'FontSize', 18);
    ylabel('percentage delayed', 'FontSize', 18);
    l = legend('percentage delayed', 'regression');

    set(gcf, 'Position', get(0,'Screensize'));
    set(l, 'FontSize', 18, 'Location', 'best');
    myaa('publish');
    exportfig('analyzeFlightWx-summer-nowx-phx-test.png', 'Width', 16);
    close all;
end