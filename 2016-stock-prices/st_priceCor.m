fileDir = '2016-stock-prices\data';
fileNames = dir([fileDir, '\', '*.csv']);
fileNames = {fileNames.name};



for f = 1:length(fileNames)
    data = csvread([fileDir '\' fileNames{f}]);
    
end
