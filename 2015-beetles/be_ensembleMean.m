baseDir = 'C:\git-ecoffel\grad-research';
ensembles = 1:10;
kvals = {'mean'};
thresholds = [90];

lat = [];
lon = [];

meanTOE = [];
cnt = 1;

for k = 1:length(kvals)
    curK = kvals{k};
    
    for e = ensembles
        for thresh = thresholds
            path = [baseDir '\bt-toe-bc-' curK '-r' num2str(e) 'i1p1-bt-' num2str(thresh) '-perc--11-cmip5-all-ext-2006-2050-cmip5-1985-2004.mat'];
            load(path);
            
            if length(lat) == 0
                lat = saveData.data{1};
                lon = saveData.data{2};
            end
            
            data = saveData.data{3};
            meanTOE(:, :, cnt) = data;
            cnt = cnt + 1;
            
            clear data saveData;
        end
    end
end

meanTOE = nanmean(meanTOE, 3);
result = {lat, lon, meanTOE};

saveData = struct('data', {result}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [2006 2040], ...
                  'plotTitle', 'Time of emergence, CSIRO 10-ensemble mean', ...
                  'fileTitle', 'toe-ens-mean-csiro.pdf', ...
                  'plotXUnits', 'Year', ...
                  'blockWater', true);
              
plotFromDataFile(saveData);
              





