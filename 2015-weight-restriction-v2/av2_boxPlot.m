aircraft = '737-800';
dataset = 'cmip5';
rcps = {'historical', 'rcp85'};

% load modeled data
load(['wr-' aircraft '-' dataset '-historical.mat']);
load(['tr-' aircraft '-' dataset '-historical.mat']);
wrModelHistorical = weightRestriction;
trModelHistorical = totalRestriction;

load(['wr-' aircraft '-' dataset '-rcp85.mat']);
load(['tr-' aircraft '-' dataset '-rcp85.mat']);
wrModelRcp85 = weightRestriction;
trModelRcp85 = totalRestriction;

% load observations
load(['wr-' aircraft '-obs-.mat']);
wrObs = weightRestriction;

airports = {'PHX', 'LGA', 'DCA', 'DEN'};
aInds = 1:4;

% for day change bar plot
figBar = figure('Color', [1, 1, 1]);

% box plot showing WR stats
figBox = figure('Color', [1, 1, 1]);

% for frequency plot showing days above a WR threshold
figFreq = figure('Color', [1, 1, 1]);

for aInd = aInds
    data = [];

    boxPlotData = [];
    boxPlotGroup = [];

    % number of days per year above restriction threshold
    freq = [];
    freqThresh = 8;

    % combine all models for current airport
    for m = 1:length(wrModelHistorical{aInd})
        
        % take data for days with restriction > 0 for box plot
        boxData = wrModelHistorical{aInd}{m}(2, :);
        boxData = boxData(boxData > 0);
        
        boxPlotData = [boxPlotData boxData];
        boxPlotGroup = [boxPlotGroup ones(size(boxData))];

        % number of days in current model above freqThresh
        freq(1, m) = length(find(wrModelHistorical{aInd}{m}(2, :) > freqThresh)) / 20.0;

        data{1}{m} = wrModelHistorical{aInd}{m}(2, :)';
    end

    % divide future up into 20 year segments
    for i = 1:3

        C_tmp = [];
        G_tmp = [];
        data{1+i} = {};

        for m = 1:length(wrModelRcp85{aInd})
            % find number of days in this model's year ( there are 61 years total )
            numDays = length(wrModelRcp85{aInd}{m}(2, :)) / 61;

            % WR data for each period
            curData = wrModelRcp85{aInd}{m}(2, (numDays * (i*20-20) + 1) : (numDays * i*20));

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
    figure(figBox);
    subplot(2, 2, aInd);
    hold on;
    boxplot(boxPlotData, boxPlotGroup, 'Labels', {'1985-2005', '2020-2040', '2040-2060', '2060-2080'});
    title(airports{aInd}, 'FontSize', 30);
    ylim([0 30]);
    
    % 
    % fig = figure('Color', [1,1,1]);
    % box on;
    % % p = plot(freq, 'LineWidth', 2);
    % % ylabel(['Number of days above ' num2str(freqThresh) 'k restriction'], 'FontSize', 30);
    % % set(gca, 'FontSize', 30);
    % % set(gca, 'XTick', [1, 2, 3, 4]);
    % % set(gca, 'XTickLabel', {'1985-2004', '2020-2040', '2040-2060', '2060-2080'});
    % 
    figure(figFreq);
    subplot(2, 2, aInd);
    p1 = shadedErrorBar([1, 2, 3, 4], freq(:, 1)', std(freq, [], 2)', 'o', 1);
    set(p1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
    set(p1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
    set(p1.edge, 'Color', 'k');
    ylabel(['Number of days'], 'FontSize', 26);
    set(gca, 'FontSize', 26);
    set(gca, 'XTick', [1, 2, 3, 4]);
    set(gca, 'XTickLabel', {'1985-2004', '2020-2040', '2040-2060', '2060-2080'});
    title(airports{aInd}, 'FontSize', 30);
    ylim([0 100]);

    bins = [0 3 6 9 12 15 18 21 24];

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

    figure(figBar);
    subplot(2, 2, aInd);
    [b2, be2] = barwitherr(err2, bins, squeeze(nanmean(y2, 1)));
    hold on;
    title(airports{aInd}, 'FontSize', 30);
    xlabel('Payload restriction (1000s lbs)', 'FontSize', 30);
    ylabel('Change in days per year', 'FontSize', 30);
    set(gca, 'FontSize', 30);
    ylim([-40 40]);
    xlim([-2 26]);
    set(b2, 'FaceColor', [61/255.0, 155/255.0, 237/255.0], 'EdgeColor', 'k');
end




