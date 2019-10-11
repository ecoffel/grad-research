
startYear = 1981;
endYear = 2018;

load waterGrid;
waterGrid = logical(waterGrid);

load lat;
load lon;
lonRot = lon;
lonRot(lonRot > 180) = lonRot(lonRot > 180) - 360;

if ~exist('tempEra')
    fprintf('loading era temps...\n');
    tempEra = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempEra{3}))))) > 100
        tempEra{3} = tempEra{3} - 273.15;
    end
end
tempEraData = squeeze(nanmean(nanmean(tempEra{3}, 5), 3));

if ~exist('prEra')
    fprintf('loading era pr...\n');
    prEra = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', startYear, 'endYear', endYear);
end
prEraData = squeeze(nanmean(nansum(prEra{3}, 5), 3));

for m = 1:12
    tmp = prEraData(:, :, m);
    tmp(waterGrid) = NaN;
    prEraData(:, :, m) = tmp;
    
    tmp = tempEraData(:, :, m);
    tmp(waterGrid) = NaN;
    tempEraData(:, :, m) = tmp;
end

pp = reshape(nansum(prEraData, 3), [numel(nansum(prEraData, 3)),1]);
pp(pp == 0) = NaN;
pr10 = prctile(pp, 10);
% 1 = tropical, 2 = dry, 3 = temperate, 4 = continental, 5 = polar/alpine
classifications = zeros(size(lat));
for ylon = 1:size(lon, 2)

    
    fprintf(['processing ylon = ' num2str(ylon) '...\n']);
    
    ylonTSeries = [];
    ylonPSeries = [];
    
    for xlat = 1:size(lat, 1)
        if waterGrid(xlat, ylon)
            classifications(xlat, ylon) = NaN;
%             continue
        end
        
        tempTimeSeries = reshape(permute(squeeze(tempEra{3}(xlat, ylon, :, :, :)), [3, 2, 1]), [numel(tempEra{3}(xlat, ylon, :, :, :)), 1]);
        prTimeSeries = reshape(permute(squeeze(prEra{3}(xlat, ylon, :, :, :)), [3, 2, 1]), [numel(prEra{3}(xlat, ylon, :, :, :)), 1]);
       
        
        if nanmin(tempEraData(xlat, ylon, :), [], 3) >= 18
            classifications(xlat, ylon) = 1;
        end
        
        if nansum(prEraData(xlat, ylon, :)) <= pr10
            classifications(xlat, ylon) = 2;
        end
        
        if nanmin(tempEraData(xlat, ylon, :), [], 3) < 18 && nanmin(tempEraData(xlat, ylon, :), [], 3) > -3
            classifications(xlat, ylon) = 3;
        end
        
        if nanmin(tempEraData(xlat, ylon, :), [], 3) < -3
            classifications(xlat, ylon) = 4;
        end
        
        if nanmax(tempEraData(xlat, ylon, :), [], 3) < 10
            classifications(xlat, ylon) = 5;
        end
        
        
        if length(ylonTSeries) == 0
            ylonTSeries  = tempTimeSeries;
            ylonPSeries = prTimeSeries;
        else
            ylonTSeries  = [ylonTSeries, tempTimeSeries];
            ylonPSeries = [ylonPSeries, prTimeSeries];
        end
        
        
%         dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-' num2str(la) '-' num2str(lo) '.txt'], tempTimeSeries);
%         dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-' num2str(la) '-' num2str(lo) '.txt'], prTimeSeries);
        
    end
    
    lo = 2*round(lonRot(xlat,ylon)/2);
    la = 2*round(lat(xlat,ylon)/2);
    
    dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-' num2str(lo) '.txt'], ylonTSeries);
    dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-' num2str(lo) '.txt'], ylonPSeries);
end
classifications(isnan(classifications)) = 0;
dlmwrite('2020-ag-land-climate/koppen-classifications.txt', classifications);
% 
% fprintf('loading cpc...\n');
% tempCpc = loadDailyData('E:\data\cpc-temp\output\tmax\regrid\world', 'startYear', startYear, 'endYear', endYear);
% if nanmean(nanmean(nanmean(nanmean(nanmean(tempCpc{3}))))) > 100
%     tempCpc{3} = tempCpc{3} - 273.15;
% end
% 
% fprintf('loading ncep...\n');
% tempNcep = loadDailyData('E:\data\ncep-reanalysis\output\tmax\regrid\world', 'startYear', startYear, 'endYear', endYear);
% if nanmean(nanmean(nanmean(nanmean(nanmean(tempNcep{3}))))) > 100
%     tempNcep{3} = tempNcep{3} - 273.15;
% end
%     


% csvwrite(['E:/data/ecoffel/data/projects/electricity/script-data/' plantData '-pp-tx.csv'], plantTxTimeSeries);

