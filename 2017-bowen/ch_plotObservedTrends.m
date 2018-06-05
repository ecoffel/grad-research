temp = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2016);
ef = loadDailyData('E:\data\era-interim\output\EF\regrid\world', 'startYear', 1981, 'endYear', 2016);

temp{3} = temp{3} - 273.15;
ef{3}(ef{3} < 0 | ef{3} > 1) = NaN;

load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

txxslopes = [];
txxslopesP = [];
efslopes = [];
efslopesP = [];

for xlat = 1:size(lat,1)
    for ylon = 1:size(lat,2)
        if waterGrid(xlat, ylon)
            txxslopes(xlat, ylon) = NaN;
            efslopes(xlat, ylon) = NaN;
            
            txxslopesP(xlat, ylon) = 0;
            efslopesP(xlat, ylon) = 0;
            
            continue;
        end
        
        curtxx = [];
        curef = [];
        
        for y = 1:size(temp{3}, 3)
            t = temp{3}(xlat, ylon, y, :, :);
            t = reshape(t, [numel(t), 1]);
            i = find(t == nanmax(t));

            e = ef{3}(xlat, ylon, :, :, :);
            e = reshape(e, [numel(e), 1]);
            
            curtxx(y) = t(i);
            curef(y) = e(i);
        end
        
        
        f = fitlm((1:length(curtxx))', curtxx', 'linear');
        txxslopes(xlat, ylon) = f.Coefficients.Estimate(2);
        txxslopesP(xlat, ylon) = f.Coefficients.pValue(2); 
        
        nn = find(~isnan(curef));
        curef = curef(nn);
        f = fitlm((1:length(curef))', curef', 'linear');
        efslopes(xlat, ylon) = f.Coefficients.Estimate(2);
        efslopesP(xlat, ylon) = f.Coefficients.pValue(2); 
    end
end

efslopes = efslopes .* 10;
txxslopes = txxslopes .* 10;

efslopesP = efslopesP < .05;
txxslopesP = txxslopesP < .05;

txxslopesP(1:15,:) = 0;
txxslopesP(75:90,:) = 0;
txxslopesP = ~txxslopesP;

result = {lat, lon, txxslopes};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-1 1], ...
                  'cbXTicks', -1:.5:1, ...
                  'plotTitle', ['TXx slopes'], ...
                  'fileTitle', ['txx-slopes-era.eps'], ...
                  'plotXUnits', [char(176) 'C / decade'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'statData', txxslopesP, ...
                  'stippleInterval', 5);
plotFromDataFile(saveData);


efslopesP = ~efslopesP;
efslopesP(1:15,:) = 0;
efslopesP(75:90,:) = 0;


result = {lat, lon, efslopes};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.1 .1], ...
                  'cbXTicks', -.1:.05:.1, ...
                  'plotTitle', ['EF trends'], ...
                  'fileTitle', ['ef-slopes-era.eps'], ...
                  'plotXUnits', ['unit EF / decade'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'BrBG'), ...
                  'statData', efslopesP, ...
                  'stippleInterval', 5);
plotFromDataFile(saveData);

