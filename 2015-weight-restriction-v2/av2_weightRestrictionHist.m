load wr-cmip5-historical-rcp85;

airportData = weightRestriction{2};

% mean weight reduction on days with restriction
resMean = [];

% fraction of days with restriction 
resNum = [];

for h = 1:size(airportData, 1)
    
    ind = find(squeeze(airportData(h, :)) > 0);
    resNum(h) = length(ind) / size(airportData, 2); 
    resMean(h) = nanmean(squeeze(airportData(h, ind)));
    
end

