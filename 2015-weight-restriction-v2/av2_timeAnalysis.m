aircraft = '787';
dataset = 'cmip5';
rcps = {'historical', 'rcp85'};

% load modeled data
load(['wr-' aircraft '-' dataset '-historical.mat']);
load(['tr-' aircraft '-' dataset '-historical.mat']);
wrModelHistorical = weightRestriction;
trModelHistorical = totalRestriction;

% load(['wr-' aircraft '-' dataset '-rcp85.mat']);
% load(['tr-' aircraft '-' dataset '-rcp85.mat']);
% wrModelRcp85 = weightRestriction;
% trModelRcp85 = totalRestriction;
% 
% % load observations
% load(['wr-' aircraft '-obs-.mat']);
% wrObs = weightRestriction;

airports = {'DXB'};
aInd = 1;

dataHours = [];

% loop over models
for m = 1:length(wrModelHistorical{aInd})
    % loop over days
    for d = 1:size(wrModelHistorical{aInd}{m}{3}, 2)
        
        % data for current day
        curDay = wrModelHistorical{aInd}{m}{3}(:, d);
        
        % if there is WR at hottest point (tasmax)
        if curDay(2) > 0
            dataHours(m, d, :) = curDay;
        end
    end
end

% average over days with weight restriction for each model
dataHoursMean = squeeze(nanmean(dataHours, 2));

