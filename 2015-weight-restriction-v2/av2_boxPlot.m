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
aInd = 4;

data = [];

C_historical = [];
C_rcp85 = [];

G_rcp85 = [];

% number of days per year above restriction threshold
freq = [];
freqThresh = 10;

% combine all models for LGA
for m = 1:length(trModelHistorical{aInd})
    C_historical = [C_historical trModelHistorical{aInd}{m}(2, :)];
    
    % number of days in current model above freqThresh
    freq(1, m) = length(find(trModelHistorical{aInd}{m}(2, :) > freqThresh)) / 20.0;
    
    data{1}{m} = trModelHistorical{aInd}{m}(2, :)';
end

% divide future up into 20 year segments
for i = 1:3
    
    C_tmp = [];
    G_tmp = [];
    data{1+i} = {};
    
    for m = 1:length(trModelRcp85{aInd})
        % find number of days in this model's year ( there are 61 years total )
        numDays = length(trModelRcp85{aInd}{m}(2, :)) / 61;

        % WR data for each period
        curData = trModelRcp85{aInd}{m}(2, (numDays * (i*20-20) + 1) : (numDays * i*20));

        % number of days in current model above freqThresh
        freq(1+i, m) = length(find(curData > freqThresh)) / 20.0;
        
        %curData = curData(find(curData > freqThresh));
        
        % add to grouped data matrix for boxplots
        G_tmp = [G_tmp m .* ones(1, length(curData))];
        C_tmp = [C_tmp curData];
        
        % add to normal matrix for hist
        data{1+i}{m} = curData';
    end
    
    G_rcp85 = [G_rcp85 (i-1) .* ones(size(C_tmp))];
    C_rcp85 = [C_rcp85 C_tmp];
    
%     figure;
%     hold on;
%     boxplot(C_tmp,G_tmp);
%     ylim([0 25]);
    
end

% fig = figure('Color', [1,1,1]);
% hold on;
% boxplot(C_rcp85, G_rcp85);
% ylim([0 30]);
% 
% fig = figure('Color', [1,1,1]);
% box on;
% % p = plot(freq, 'LineWidth', 2);
% % ylabel(['Number of days above ' num2str(freqThresh) 'k restriction'], 'FontSize', 30);
% % set(gca, 'FontSize', 30);
% % set(gca, 'XTick', [1, 2, 3, 4]);
% % set(gca, 'XTickLabel', {'1985-2004', '2020-2040', '2040-2060', '2060-2080'});
% 
% p1 = shadedErrorBar([1, 2, 3, 4], freq(:, 1)', std(freq, [], 2)', 'o', 1);
% set(p1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
% set(p1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
% set(p1.edge, 'Color', 'k');
% ylabel(['Number of days above ' num2str(freqThresh) 'k restriction'], 'FontSize', 30);
% set(gca, 'FontSize', 30);
% set(gca, 'XTick', [1, 2, 3, 4]);
% set(gca, 'XTickLabel', {'1985-2004', '2020-2040', '2040-2060', '2060-2080'});

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

% y1 = squeeze(histData(4, :, :)) ./ squeeze(histData(1, :, :));
% err1 = nanstd(y1, [], 1);
% 
% figure('Color', [1, 1, 1]);
% hold on;
% barwitherr(err1, bins, squeeze(nanmean(y1, 1)));
% plot(-100:100, ones(size(-100:100)), 'k--');
% xlabel('Restriction (1000s lbs)', 'FontSize', 30);
% ylabel('Relative frequency change (multiple)', 'FontSize', 30);
% set(gca, 'FontSize', 30);
% ylim([0 40]);
% xlim([-2 26]);

y2 = squeeze(histData(4, :, :)) - squeeze(histData(1, :, :));
err2 = nanstd(y2, [], 1);

figure('Color', [1, 1, 1]);
b2 = barwitherr(err2, bins, squeeze(nanmean(y2, 1)));
hold on;
xlabel('Restriction (1000s lbs)', 'FontSize', 30);
ylabel('Days per year', 'FontSize', 30);
set(gca, 'FontSize', 30);
ylim([-40 40]);
xlim([-2 26]);





