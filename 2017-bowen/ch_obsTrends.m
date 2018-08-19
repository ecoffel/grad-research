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

wbTrendSig = zeros(size(lat));
wbTrendSig(wbTrendSig == 0) = NaN;

wbOnTxxTrend = zeros(size(lat));
wbOnTxxTrend(wbOnTxxTrend == 0) = NaN;

wbOnTxxTrendSig = zeros(size(lat));
wbOnTxxTrendSig(wbOnTxxTrendSig == 0) = NaN;

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            continue;
        end
        
        wb = squeeze(nanmax(nanmax(eraWb(xlat, ylon, :, :, :), [], 5), [], 4));
        wbOnTxx = [];
        
        for year = 1:size(eraWb, 3)
            yearWb = eraWb(xlat, ylon, :, :, :);
            yearWb = reshape(yearWb, [numel(yearWb),1]);
            wbOnTxx(year) = yearWb(txxDays(xlat, ylon, year));
        end
        
        if length(find(isnan(wb))) > 5
            continue;
        end
        
        f = fit((1:length(wb))', wb, 'poly1');
        wbTrend(xlat, ylon) = f.p1;
        wbTrendSig(xlat, ylon) = Mann_Kendall(wb, .05);
        
        f = fit((1:length(wbOnTxx))', wbOnTxx', 'poly1');
        wbOnTxxTrend(xlat, ylon) = f.p1;
        wbOnTxxTrendSig(xlat, ylon) = Mann_Kendall(wbOnTxx, .05);
    end
end