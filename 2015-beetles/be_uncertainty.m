baseDir = 'C:\git-ecoffel\grad-research\bt-output';
ensembles = 1:10;
kvals = {'mean'};
thresholds = [70 80 90 100];

lat = [];
lon = [];
rankings = [];

% confidence interval
ciThresh = 95;
CI = [];

cnt = 1;

for k = 1:length(kvals)
    curK = kvals{k};
    
    for e = ensembles
        for thresh = thresholds
            path = [baseDir '\bt-toe-bc-' curK '-r' num2str(e) 'i1p1-bt-' num2str(thresh) '-perc--11-cmip5-all-ext-2006-2050-cmip5-1985-2004-csiro-mk3-6-0.mat'];
            load(path);
            
            if length(lat) == 0
                lat = saveData.data{1};
                lon = saveData.data{2};
            end
            
            data = saveData.data{3};
            rankings(:, :, cnt) = data;
            cnt = cnt + 1;
            
            clear data saveData;
        end
    end
end

perc5 = round((100-ciThresh)/100.0 * size(rankings, 3));
perc95 = round(ciThresh/100.0 * size(rankings, 3));

% rank & pick 5th & 95th percentile
for xlat = 1:size(rankings, 1)
    for ylon = 1:size(rankings, 2)
        rankings(xlat, ylon, :) = sort(rankings(xlat, ylon, :));
        
        % lower
        CI(xlat, ylon, 1) = rankings(xlat, ylon, perc5);
        % higher
        CI(xlat, ylon, 2) = rankings(xlat, ylon, perc95);
    end
end

resultLow = {lat, lon, CI(:, :, 1)};
resultHigh = {lat, lon, CI(:, :, 2)};

saveData = struct('data', {resultLow}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [2006 2040], ...
                  'plotTitle', 'Time of emergence, 5% threshold', ...
                  'fileTitle', 'toe-ci-5p.pdf', ...
                  'plotXUnits', 'Year', ...
                  'blockWater', true);
              
plotFromDataFile(saveData);
              
saveData = struct('data', {resultHigh}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [2006 2040], ...
                  'plotTitle', 'Time of emergence, 95% threshold', ...
                  'fileTitle', 'toe-ci-95p.pdf', ...
                  'plotXUnits', 'Year', ...
                  'blockWater', true);
              
plotFromDataFile(saveData);


% plot std 
resultStd = {lat, lon, nanstd(rankings, [], 3)};
saveData = struct('data', {resultStd}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [0 15], ...
                  'plotTitle', 'Time of emergence, STD', ...
                  'fileTitle', 'toe-ci-std.pdf', ...
                  'plotXUnits', 'Years', ...
                  'blockWater', true);
              
plotFromDataFile(saveData);





