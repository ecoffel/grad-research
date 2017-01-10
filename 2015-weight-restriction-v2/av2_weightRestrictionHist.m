aircraft = '737-800';
dataset = 'cmip5';
rcp = 'historical';

load(['wr-' aircraft '-' dataset '-' rcp '.mat']);
load(['tr-' aircraft '-' dataset '-' rcp '.mat']);

airports = {'PHX', 'LGA', 'DCA', 'DEN'};

% stats on weight reduction on days with restriction
resMean = [];
resMedian = [];
resMax = [];

% fraction of days with restriction 
resNum = [];

for a = 1:length(weightRestriction)
    
    for m = 1:length(weightRestriction{a})
    
        airportData = weightRestriction{a}{m};
        
        for h = 1:size(airportData, 1)

            ind = find(squeeze(airportData(h, :)) > min(squeeze(airportData(h, :))));
            resNum(a, m, h) = length(ind) / size(airportData, 2); 
            resMean(a, m, h) = nanmean(squeeze(airportData(h, ind)));
            resMedian(a, m, h) = nanmedian(squeeze(airportData(h, ind)));

            if length(ind) > 0
                resMax(a, m, h) = max(squeeze(airportData(h, ind)));
            else
                resMax(a, m, h) = NaN;
            end

        end
        
    end
end