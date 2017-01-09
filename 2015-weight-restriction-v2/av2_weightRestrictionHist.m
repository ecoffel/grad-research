aircraft = '777-200';
dataset = 'obs';
rcp = '';

load(['wr-' aircraft '-' dataset '-' rcp '.mat']);
load(['tr-' aircraft '-' dataset '-' rcp '.mat']);

airports = {'PHX', 'DEN'};

% stats on weight reduction on days with restriction
resMean = [];
resMedian = [];
resMax = [];

% fraction of days with restriction 
resNum = [];

for a = 1:length(airports)
    airportData = weightRestriction{a};

    for h = 1:size(airportData, 1)

        ind = find(squeeze(airportData(h, :)) > min(squeeze(airportData(h, :))));
        resNum(a, h) = length(ind) / size(airportData, 2); 
        resMean(a, h) = nanmean(squeeze(airportData(h, ind)));
        resMedian(a, h) = nanmedian(squeeze(airportData(h, ind)));
        
        if length(ind) > 0
            resMax(a, h) = max(squeeze(airportData(h, ind)));
        else
            resMax(a, h) = NaN;
        end
        
    end
end