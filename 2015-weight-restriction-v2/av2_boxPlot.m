aircraft = 'a380';
dataset = 'cmip5';
rcps = {'historical', 'rcp45', 'rcp85'};

useSubplots = true;

baseDir = '2015-weight-restriction-v2/wr-data/';

trData = {};
wrData = {};

% index of the hour to plot
selectedHour = 3;

% load modeled data
if ismember('historical', rcps)
    load([baseDir 'wr-' aircraft '-' dataset '-historical.mat']);
    %load([baseDir 'tr-' aircraft '-' dataset '-historical.mat']);
    wrModelHistorical = weightRestriction;
    %trModelHistorical = totalRestriction;
    
    %trData{end+1} = trModelHistorical;
    wrData{end+1} = wrModelHistorical;
    
    historicalAirports = {};
    for a = 1:length(wrModelHistorical)
        historicalAirports{end+1} = wrModelHistorical{a}{1}{1};
    end
end

if ismember('rcp45', rcps)
    load([baseDir 'wr-' aircraft '-' dataset '-rcp45.mat']);
    %load([baseDir 'tr-' aircraft '-' dataset '-rcp45.mat']);
    wrModelRcp45 = weightRestriction;
    %trModelRcp45 = totalRestriction;
    
    %trData{end+1} = trModelRcp45;
    wrData{end+1} = wrModelRcp45;
    
    rcp45Airports = {};
    for a = 1:length(wrModelRcp45)
        rcp45Airports{end+1} = wrModelRcp45{a}{1}{1};
    end
end

if ismember('rcp85', rcps)
    load([baseDir 'wr-' aircraft '-' dataset '-rcp85.mat']);
    %load([baseDir 'tr-' aircraft '-' dataset '-rcp85.mat']);
    wrModelRcp85 = weightRestriction;
    %trModelRcp85 = totalRestriction;
    
    %trData{end+1} = trModelRcp85;
    wrData{end+1} = wrModelRcp85;
    
    rcp85Airports = {};
    for a = 1:length(wrModelRcp85)
        rcp85Airports{end+1} = wrModelRcp85{a}{1}{1};
    end
end

airports = {};
for a = 1:length(historicalAirports)
    if ismember(historicalAirports{a}, rcp45Airports)
        airports{end+1} = historicalAirports{a};
    end
end

% load observations
% load(['wr-' aircraft '-obs-.mat']);
% wrObs = weightRestriction;

% find which airports are in both the historical and future dataset

if useSubplots
    % for day change bar plot
%     figBar = figure('Color', [1, 1, 1]);
% 
%     % box plot showing WR stats
%     figBox = figure('Color', [1, 1, 1]);
% 
%     % for frequency plot showing days above a WR threshold
%     figFreq = figure('Color', [1, 1, 1]);
end

if strcmp(aircraft, '777-300')
    noPlotThresh = 10;
    figBoxYLim = [0 200];
    figFreqYLim = [-10 250];
    
    figBarBins = 0:10:100;
    barXTick = 0:20:100;
    figBarXLim = [-5 105];
    figBarYLim = [-75 75];
elseif strcmp(aircraft, '737-800')
    noPlotThresh = 5;
    figBoxYLim = [0 50];
    figFreqYLim = [-10 100];
    
    figBarBins = 0:3:24;
    barXTick = 0:3:24;
    figBarXLim = [-5 25];
    figBarYLim = [-50 50];
elseif strcmp(aircraft, '787')
    noPlotThresh = 10;
    figBoxYLim = [0 80];
    figFreqYLim = [-10 150];
    
    figBarBins = 0:5:60;
    barXTick = 0:10:60;
    figBarXLim = [-5 65];
    figBarYLim = [-60 60];
elseif strcmp(aircraft, 'a320')
    noPlotThresh = 5;
    figBoxYLim = [0 20];
    figFreqYLim = [-10 100];
    
    figBarBins = 0:3:21;
    barXTick = 0:3:21;
    figBarXLim = [-5 25];
    figBarYLim = [-50 50];
elseif strcmp(aircraft, 'a380')
    noPlotThresh = 30;
    figBoxYLim = [0 300];
    figFreqYLim = [-10 150];
    
    figBarBins = 0:20:250;
    barXTick = 0:50:250;
    figBarXLim = [-15 255];
    figBarYLim = [-100 100];
    
end

for aInd = 1:length(airports)
    
    data = [];

    boxPlotData = [];
    boxPlotGroup = [];

    % number of days per year above restriction threshold
    freq = [];
    
    % get the historical data from the cell array
    wrModelHistorical = wrData{1};
    
    aIndHistorical = -1;
    for a = 1:length(wrModelHistorical)
        if strcmp(airports{aInd}, wrModelHistorical{a}{1}{1})
            aIndHistorical = a;
        end
    end
    
    % combine all models for current airport
    for m = 1:length(wrModelHistorical{aIndHistorical})
        
        % take data for days with restriction > 0 for box plot
        boxData = wrModelHistorical{aIndHistorical}{m}{3}(selectedHour, :);
        boxData = boxData(boxData > 0);
        
        if length(boxData) == 0
            boxData = 0;
        end
        
        boxPlotData = [boxPlotData boxData];
        boxPlotGroup = [boxPlotGroup ones(size(boxData))];

        % loop over all WR thresholds considered in the bar plot and record
        % their exceedance frequency
        for b = 1:length(figBarBins)
            freq(1, m, b) = length(find(wrModelHistorical{aIndHistorical}{m}{3}(selectedHour, :) > figBarBins(b))) / 20.0;
        end

        data{1}{m} = wrModelHistorical{aIndHistorical}{m}{3}(selectedHour, :)';
    end

    % loop over future datasets
    
    % divide future up into 20 year segments
    for i = 1:3

        C_tmp = [];
        G_tmp = [];
        data{1+i} = {};

        % initialize list for each model
        for m = 1:length(wrData{1}{1})
            data{1+i}{m} = [];
        end
        
        % loop over RCPs
        for r = 2:length(wrData)
        
            wrModelFuture = wrData{r};
            
            aIndFuture = -1;
            for a = 1:length(wrModelFuture)
                if strcmp(airports{aInd}, wrModelFuture{a}{1}{1})
                    aIndFuture = a;
                end
            end
            
            % loop over all models
            for m = 1:length(wrModelFuture{aIndFuture})
            
                % find number of days in this model's year ( there are 61 years total )
                numDays = length(wrModelFuture{aIndFuture}{m}{3}(selectedHour, :)) / 61;

                % WR data for each period
                curData = wrModelFuture{aIndFuture}{m}{3}(selectedHour, (numDays * (i*20-20) + 1) : (numDays * i*20));

                % number of days in current model above freqThresh
                if r > 2
                    % if we are on a second future scenario, average current
                    % freq with existing (for each WR threshold)
                    for b = 1:length(figBarBins)
                        freq(1+i, m, b) = nanmean([freq(1+i, m) length(find(curData > figBarBins(b))) / 20.0]);
                    end
                else
                    % if we are on first future scenario, just set freq
                    % (for each WR threshold)
                    for b = 1:length(figBarBins)
                        freq(1+i, m) = length(find(curData > figBarBins(b))) / 20.0;
                    end
                end

                % add to grouped data matrix for boxplots
                boxData = curData(curData > 0);
                G_tmp = [G_tmp m .* ones(1, length(boxData))];
                C_tmp = [C_tmp boxData];

                % add to normal matrix for hist
                data{1+i}{m} = [data{1+i}{m}; curData'];
            end
        end

        if length(C_tmp) == 0
            C_tmp = 0;
        end
        
        boxPlotGroup = [boxPlotGroup (i+1) .* ones(size(C_tmp))];
        boxPlotData = [boxPlotData C_tmp];

    end

    % if there is no data or no WR, don't plot
    if length(boxPlotData) == 0 || max(boxPlotData) < noPlotThresh
        continue;
    end
    
    % plot the mean boxplot for each 20 year period (across all models),
    % only showing data for days with a > 0 weight restriction
    
    if useSubplots
        curFig = figure('Color', [1, 1, 1]);
    end
    
    if useSubplots
        %figure(figBox);
        subplot(2, 3, 1);
        %subplot(2, 2, aInd);
    else
        figure('Color', [1,1,1]);
    end
    
    hold on;
    b = boxplot(boxPlotData, boxPlotGroup, 'Labels', {'1995', '2030', '2050', '2070'});
    %title(airports{aInd}, 'FontSize', 30);
    set(findobj(gca, 'Type', 'text'), 'FontSize', 20, 'VerticalAlignment', 'middle');
    set(gca, 'FontSize', 30);
    ylabel('Restriction (1000s lbs)', 'FontSize', 24);
    for ih = 1:length(b)
        set(b(ih,:), 'LineWidth', 2); % Set the line width of the Box outlines here
    end
    ylim(figBoxYLim);
    
    if ~useSubplots
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['wr-box-' aircraft '-' rcps{end} '-' airports{aInd} '.png'], '-m3');
    end
    
    if useSubplots
        %figure(figFreq);
        subplot(2, 3, 2);
        %subplot(2, 2, aInd);
    else
        figure('Color', [1,1,1]);
    end
    
    % find the threshold with the maximum frequency change, if there is
    % some frequency change at all
    if max(max(max(freq))) > 0
        freqDiff = squeeze(nanmean(freq, 2));
        freqDiff = freqDiff(end, :) - freqDiff(1, :);
        freqDiffInd = find(freqDiff == max(freqDiff));
    else
        freqDiffInd = 1;
    end
    
    % select the WR threshold with the maximum frequency change
    freq = freq(:, :, freqDiffInd);
    
    freqMean = nanmean(freq, 2)';
    
    % create the error matrix
    yErr = std(freq, [], 2)';
    % limit bottom frequency to zero
    yErr(2, :) = std(freq, [], 2)';
    for i = 1:size(yErr, 2)
        if freq(i) - yErr(2, i) < 0
            yErr(2, i) = freqMean(i);
        end
    end
    
    p1 = shadedErrorBar([1, 2, 3, 4], freqMean, yErr, 'o', 1);
    set(p1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
    set(p1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
    set(p1.edge, 'Color', 'k');
    ylabel(['Number of days'], 'FontSize', 24);
    set(gca, 'FontSize', 20);
    set(gca, 'XTick', [1, 2, 3, 4]);
    set(gca, 'XTickLabel', {'1995', '2030', '2050', '2070'});
    %title(airports{aInd}, 'FontSize', 30);
    ylim(figFreqYLim);
    
    % add text with the chosen freq threshold
    textY = figFreqYLim(end) - (figFreqYLim(end) - figFreqYLim(1))*0.1;
    text(1.2, textY, ['Threshold: ' num2str(figBarBins(freqDiffInd)) 'k lbs'], 'HorizontalAlignment', 'left', 'FontSize', 24);
    
    xlim([0.9 4]);
    
    if ~useSubplots
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['wr-freq-' aircraft '-' rcps{end} '-' airports{aInd} '.png'], '-m3');
    end

    %bins = [0 3 6 9 12 15 18 21 24];
    bins = figBarBins;

    histData = [];

    for m = 1:length(data{1})
        % historical data
        h = hist(data{1}{m}, bins) ./ 20;
        histData(1, m, :) = h;

        % future scenarios
        for i = 1:3
            % divide by the number of future scenarios * 20
            h = hist(data{i+1}{m}, bins) ./ (20*(length(wrData)-1));
            histData(1+i, m, :) = h;
        end
    end

    % plot the change in the number of days in each weight restriction bin
    y2 = squeeze(histData(4, :, :)) - squeeze(histData(1, :, :));
    err2 = nanstd(y2, [], 1);

    if useSubplots
        %figure(figBar);
        subplot(2, 3, 3);
        %subplot(2, 2, aInd);
    else
        figure('Color', [1,1,1]);
    end
    [b2, be2] = barwitherr(err2, bins, squeeze(nanmean(y2, 1)));
    hold on;
    %title(airports{aInd}, 'FontSize', 30);
    set(gca, 'FontSize', 20);
    xlabel('Restriction (1000s lbs)', 'FontSize', 24);
    ylabel('Change in days per year', 'FontSize', 24);
    ylim(figBarYLim);
    xlim(figBarXLim);
    set(b2, 'FaceColor', [61/255.0, 155/255.0, 237/255.0], 'EdgeColor', 'k');
    
    set(gca, 'XTick', barXTick);
    
    rcpStr = '';
    for r = 2:length(rcps)
        rcpStr = [rcpStr rcps{r} '-'];
    end
    
    if ~useSubplots
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['wr-bar-' aircraft '-' rcpStr '-' airports{aInd} '.png'], '-m1');
    end
    
    if useSubplots
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['wr-' aircraft '-' rcpStr '-' airports{aInd} '.png'], '-m1');
    end
    
    close all;
end




