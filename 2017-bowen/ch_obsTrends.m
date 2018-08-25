load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

if ~exist('eraWb')
    load C:\git-ecoffel\grad-research\2017-bowen\txx-timing\txx-days-era-1981-2016.mat;
    eraWb = loadDailyData('E:\data\era-interim\output\wb-davies-jones-full\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraWb = eraWb{3};
end

wbTrend = zeros(size(lat));
wbTrend(wbTrend == 0) = NaN;
wbOnTxxTrend = zeros(size(lat));
wbOnTxxTrend(wbOnTxxTrend == 0) = NaN;

wbTrendSig = ones(size(lat));
wbOnTxxTrendSig = ones(size(lat));

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            continue;
        end
        
        wb = squeeze(nanmax(nanmax(eraWb(xlat, ylon, :, :, :), [], 5), [], 4));
        wbOnTxx = [];
        
        for year = 1:size(eraWb, 3)
            yearWb = squeeze(eraWb(xlat, ylon, :, :, :));
            yearWb = reshape(permute(yearWb, [3 2 1]), [numel(yearWb),1]);
            wbOnTxx(year) = yearWb(txxDays(xlat, ylon, year));
        end
        
        if length(find(isnan(wb))) > 5
            continue;
        else
            wb(isnan(wb)) = [];
        end
        
        if length(find(isnan(wbOnTxx))) > 5
            continue;
        else
            wbOnTxx(isnan(wbOnTxx)) = [];
        end
        
        f = fit((1:length(wb))', wb, 'poly1');
        wbTrend(xlat, ylon) = f.p1;
        wbTrendSig(xlat, ylon) = Mann_Kendall(wb, .05);
        
        f = fit((1:length(wbOnTxx))', wbOnTxx', 'poly1');
        wbOnTxxTrend(xlat, ylon) = f.p1;
        wbOnTxxTrendSig(xlat, ylon) = Mann_Kendall(wbOnTxx, .05);
    end
end

wbTrend = wbTrend .* 10;
wbOnTxxTrend = wbOnTxxTrend .* 10;

result = {lat, lon, wbTrend};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', ['T_W trend on T_W day'], ...
                  'fileTitle', ['wb-trend-on-wb'], ...
                  'plotXUnits', [char(176) 'C/decade'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'statData', ~wbTrendSig);
plotFromDataFile(saveData);

result = {lat, lon, wbOnTxxTrend};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', ['T_W trend on TXx day'], ...
                  'fileTitle', ['wb-trend-on-txx'], ...
                  'plotXUnits', [char(176) 'C/decade'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'statData', ~wbOnTxxTrendSig);
plotFromDataFile(saveData);
