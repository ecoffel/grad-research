aircraft = '777-300';
dataset = 'cmip5';
rcps = {'historical', 'rcp85'};

useSubplots = false;

% load modeled data
if ismember('historical', rcps)
    load(['wr-' aircraft '-' dataset '-historical.mat']);
    load(['tr-' aircraft '-' dataset '-historical.mat']);
    wrModelHistorical = weightRestriction;
    trModelHistorical = totalRestriction;
    
    historicalAirports = {};
    for a = 1:length(wrModelHistorical)
        historicalAirports{end+1} = wrModelHistorical{a}{1}{1};
    end
end

if ismember('rcp85', rcps)
    load(['wr-' aircraft '-' dataset '-rcp85.mat']);
    load(['tr-' aircraft '-' dataset '-rcp85.mat']);
    wrModelRcp85 = weightRestriction;
    trModelRcp85 = totalRestriction;
    
    rcp85Airports = {};
    for a = 1:length(wrModelRcp85)
        rcp85Airports{end+1} = wrModelRcp85{a}{1}{1};
    end
end

airports = {};
for a = 1:length(historicalAirports)
    if ismember(historicalAirports{a}, rcp85Airports)
        airports{end+1} = historicalAirports{a};
    end
end

% load observations
% load(['wr-' aircraft '-obs-.mat']);
% wrObs = weightRestriction;

% find which airports are in both the historical and future dataset

if useSubplots
    % for day change bar plot
    figBar = figure('Color', [1, 1, 1]);

    % box plot showing WR stats
    figBox = figure('Color', [1, 1, 1]);

    % for frequency plot showing days above a WR threshold
    figFreq = figure('Color', [1, 1, 1]);
end

if strcmp(aircraft, '777-300')
    figBoxYLim = [0 200];
    figFreqYLim = [-50 200];
    freqThresh = 60;
    
    figBarBins = 0:10:100;
    figBarXLim = [-5 105];
    figBarYLim = [-75 75];
elseif strcmp(aircraft, '737-800')
    figBoxYLim = [0 50];
    figFreqYLim = [-10 150];
    freqThresh = 10;
    
    figBarBins = 0:3:24;
    figBarXLim = [-5 25];
    figBarYLim = [-50 50];
elseif strcmp(aircraft, '787')
    figBoxYLim = [0 80];
    figFreqYLim = [-40 100];
    freqThresh = 40;
    
    figBarBins = 0:5:60;
    figBarXLim = [-5 65];
    figBarYLim = [-60 60];
end

for aInd = 1:length(airports)
    
    data = [];

    boxPlotData = [];
    boxPlotGroup = [];

    % number of days per year above restriction threshold
    freq = [];
    
    aIndHistorical = -1;
    for a = 1:length(wrModelHistorical)
        if strcmp(airports{aInd}, wrModelHistorical{a}{1}{1})
            aIndHistorical = a;
        end
    end
    
    aIndRcp85 = -1;
    for a = 1:length(wrModelRcp85)
        if strcmp(airports{aInd}, wrModelRcp85{a}{1}{1})
            aIndRcp85 = a;
        end
    end
    
    % combine all models for current airport
    for m = 1:length(wrModelHistorical{aIndHistorical})
        
        % take data for days with restriction > 0 for box plot
        boxData = wrModelHistorical{aIndHistorical}{m}{3}(2, :);
        boxData = boxData(boxData > 0);
        
        boxPlotData = [boxPlotData boxData];
        boxPlotGroup = [boxPlotGroup ones(size(boxData))];

        % number of days in current model above freqThresh
        freq(1, m) = length(find(wrModelHistorical{aIndHistorical}{m}{3}(2, :) > freqThresh)) / 20.0;

        data{1}{m} = wrModelHistorical{aIndHistorical}{m}{3}(2, :)';
    end

    % divide future up into 20 year segments
    for i = 1:3

        C_tmp = [];
        G_tmp = [];
        data{1+i} = {};

        for m = 1:length(wrModelRcp85{aIndRcp85})
            % find number of days in this model's year ( there are 61 years total )
            numDays = length(wrModelRcp85{aIndRcp85}{m}{3}(2, :)) / 61;

            % WR data for each period
            curData = wrModelRcp85{aIndRcp85}{m}{3}(2, (numDays * (i*20-20) + 1) : (numDays * i*20));

            % number of days in current model above freqThresh
            freq(1+i, m) = length(find(curData > freqThresh)) / 20.0;

            % add to grouped data matrix for boxplots
            boxData = curData(curData > 0);
            G_tmp = [G_tmp m .* ones(1, length(boxData))];
            C_tmp = [C_tmp boxData];

            % add to normal matrix for hist
            data{1+i}{m} = curData';
        end

        boxPlotGroup = [boxPlotGroup (i+1) .* ones(size(C_tmp))];
        boxPlotData = [boxPlotData C_tmp];

    %     figure;
    %     hold on;
    %     boxplot(C_tmp,G_tmp);
    %     ylim([0 25]);

    end

    % plot the mean boxplot for each 20 year period (across all models),
    % only showing data for days with a > 0 weight restriction
    
    
    if useSubplots
        figure(figBox);
        subplot(2, 2, aInd);
    else
        figure('Color', [1,1,1]);
    end
    hold on;
    b = boxplot(boxPlotData, boxPlotGroup, 'Labels', {'1985-2005', '2020-2040', '2040-2060', '2060-2080'});
    title(airports{aInd}, 'FontSize', 30);
    set(findobj(gca, 'Type', 'text'), 'FontSize', 20, 'VerticalAlignment', 'middle');
    set(gca, 'FontSize', 20);
    ylabel('Payload restriction (1000s lbs)', 'FontSize', 20);
    for ih = 1:length(b)
        set(b(ih,:), 'LineWidth', 2); % Set the line width of the Box outlines here
    end
    ylim(figBoxYLim);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wr-box-' aircraft '-' rcps{end} '-' airports{aInd} '.png'], '-m3');
    
    % 
    % fig = figure('Color', [1,1,1]);
    % box on;
    % % p = plot(freq, 'LineWidth', 2);
    % % ylabel(['Number of days above ' num2str(freqThresh) 'k restriction'], 'FontSize', 30);
    % % set(gca, 'FontSize', 30);
    % % set(gca, 'XTick', [1, 2, 3, 4]);
    % % set(gca, 'XTickLabel', {'1985-2004', '2020-2040', '2040-2060', '2060-2080'});
    % 
    if useSubplots
        figure(figFreq);
        subplot(2, 2, aInd);
    else
        figure('Color', [1,1,1]);
    end
    p1 = shadedErrorBar([1, 2, 3, 4], freq(:, 1)', std(freq, [], 2)', 'o', 1);
    set(p1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
    set(p1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
    set(p1.edge, 'Color', 'k');
    ylabel(['Number of days'], 'FontSize', 26);
    set(gca, 'FontSize', 26);
    set(gca, 'XTick', [1, 2, 3, 4]);
    set(gca, 'XTickLabel', {'1985-2004', '2020-2040', '2040-2060', '2060-2080'});
    title(airports{aInd}, 'FontSize', 30);
    ylim(figFreqYLim);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wr-freq-' aircraft '-' rcps{end} '-' airports{aInd} '.png'], '-m3');

    %bins = [0 3 6 9 12 15 18 21 24];
    bins = figBarBins;

    histData = [];

    for m = 1:length(data{1})
        h = hist(data{1}{m}, bins) ./ 20;
        histData(1, m, :) = h;

        % rcp85
        for i = 1:3
            h = hist(data{i+1}{m}, bins) ./ 20;
            histData(1+i, m, :) = h;
        end
    end

    % plot the change in the number of days in each weight restriction bin
    y2 = squeeze(histData(4, :, :)) - squeeze(histData(1, :, :));
    err2 = nanstd(y2, [], 1);

    if useSubplots
        figure(figBar);
        subplot(2, 2, aInd);
    else
        figure('Color', [1,1,1]);
    end
    [b2, be2] = barwitherr(err2, bins, squeeze(nanmean(y2, 1)));
    hold on;
    title(airports{aInd}, 'FontSize', 30);
    set(gca, 'FontSize', 20);
    xlabel('Payload restriction (1000s lbs)', 'FontSize', 30);
    ylabel('Change in days per year', 'FontSize', 30);
    ylim(figBarYLim);
    xlim(figBarXLim);
    set(b2, 'FaceColor', [61/255.0, 155/255.0, 237/255.0], 'EdgeColor', 'k');
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wr-bar-' aircraft '-' rcps{end} '-' airports{aInd} '.png'], '-m3');
    
    close all;
end

if useSubplots
    figure(figBar);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wr-bar-' rcps{end} '-' aircraft '.png'], '-m3');

    figure(figFreq);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wr-freq-' rcps{end} '-' aircraft '.png'], '-m3');

    figure(figBox);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['wr-box-' rcps{end} '-' aircraft '.png'], '-m3');
end
close all;



