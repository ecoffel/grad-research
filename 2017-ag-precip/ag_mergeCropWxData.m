
% load US corn yield
load 2017-ag-precip\ag-data\ag-corn-yield-us.mat
cornYield = cropData;

% load the census database of counties
countyDb = ab_loadCountyDb();

% loop over each state
for s = 1:length(cropData)
    ['processing ' cropData{s}{1} '...']
    
    % loop over counties for this state
    for c = 1:length(cropData{3})
        
    end
end