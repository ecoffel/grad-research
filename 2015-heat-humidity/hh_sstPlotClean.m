% remove the line from the middle of the SST maps by averaging

load tosTempExtremes-wb-west-africa-day-mean-future-top-max-cmip5-100

data = saveData.data{3};

% average bar at longitude 360
col = [data(:, 179)];
data(:, 180) = col;

saveData.data{3} = data;
plotFromDataFile(saveData);