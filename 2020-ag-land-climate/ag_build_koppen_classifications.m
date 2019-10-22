
startYear = 1981;
endYear = 2016;

load waterGrid;
waterGrid = logical(waterGrid);

computeAnom = false;
% how many grid cells around current cell to compute anomaly from
anomRange = 2;

% annual max temp and max daily precip
exportTmax = true;

anomStr = '';
if computeAnom
    anomStr = ['-anom-' num2str(anomRange)];
end

tDataset = 'era-interim';
tVar = 'mn2t';


load lat;
load lon;
lonRot = lon;
lonRot(lonRot > 180) = lonRot(lonRot > 180) - 360;

if ~exist('temp')
    fprintf(['loading ' tDataset ' ' tVar '...\n']);
    temp = loadDailyData(['E:/data/' tDataset '/output/' tVar '/regrid/world'], 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
        temp{3} = temp{3} - 273.15;
    end
end
tempData = temp{3};

% if ~exist('prEra')
%     fprintf('loading era pr...\n');
%     prEra = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', startYear, 'endYear', endYear);
% end
% prEraData = prEra{3};

% for y = 1:size(prEra{3}, 3)
%     for m = 1:size(prEra{3}, 4)
%         for d = 1:size(prEra{3}, 5)
%             tmp = prEraData(:, :, y, m, d);
%             tmp(waterGrid) = NaN;
%             prEraData(:, :, y, m, d) = tmp;
%         end
%     end
% end

for y = 1:size(temp{3}, 3)
    for m = 1:size(temp{3}, 4)
        for d = 1:size(temp{3}, 5)
            tmp = tempData(:, :, y, m, d);
            tmp(waterGrid) = NaN;
            tempData(:, :, y, m, d) = tmp;
        end
    end
end

% classifications = zeros(size(lat));
for ylon = 1:size(lon, 2)
    
    fprintf(['processing ylon = ' num2str(ylon) '...\n']);
    
    ylonTSeries = [];
%     ylonPSeries = [];
    
    dayNum = [NaN];
    
    for xlat = 1:size(lat, 1)
        
        if exportTmax
            tempTimeSeries = [];
            prTimeSeriesEra = [];
            
            i = 1;
            
            for y = 1:size(temp{3}, 3)
                tempTimeSeries(end+1,1) = nanmin(nanmin(tempData(xlat, ylon, y, :, :)));
%                 prTimeSeriesEra(end+1,1) = nanmax(nanmax(prEraData(xlat, ylon, y, :, :)));
                
                if xlat == 1
                    dayNum(end+1) = i;
                    i = i + 1;
                end
            end
            
            
            if computeAnom
                xMin = max(1, xlat-anomRange);
                xMax = min(size(lat, 1), xlat+anomRange);
                yMin = max(1, ylon-anomRange);
                yMax = min(size(lat, 2), ylon+anomRange);

                % compute anom
                tempTimeSeries = tempTimeSeries - nanmean(nanmean(nanmean(nanmax(nanmax(tempData(xMin:xMax, yMin:yMax, :, :, :), [], 5), [], 4))));
            end
        else
            tempTimeSeries = reshape(permute(squeeze(tempData(xlat, ylon, :, :, :)), [3, 2, 1]), [numel(tempData(xlat, ylon, :, :, :)), 1]);

            if computeAnom
                xMin = max(1, xlat-anomRange);
                xMax = min(size(lat, 1), xlat+anomRange);
                yMin = max(1, ylon-anomRange);
                yMax = min(size(lat, 2), ylon+anomRange);

                % compute anom
                tempTimeSeries = tempTimeSeries - nanmean(nanmean(nanmean(nanmean(nanmean(tempData(xMin:xMax, yMin:yMax, :, :, :))))));
            end
            
            if length(dayNum) == 1
                i = 2;
                for year = 1:size(temp{3}, 3)
                    dayCnt = 1;
                    for month = 1:size(temp{3}, 4)
                        for day = 1:size(temp{3}, 5)
                            if length(find(~isnan(temp{3}(xlat, ylon, year, month, day)))) > 0
                                dayNum(i) = dayCnt;
                                dayCnt = dayCnt + 1;
                            else
                                dayNum(i) = NaN;
                            end
                            i = i + 1;
                        end
                    end
                end
            end            
        end
        
%         prTimeSeries = reshape(permute(squeeze(prEraData(xlat, ylon, :, :, :)), [3, 2, 1]), [numel(prEraData(xlat, ylon, :, :, :)), 1]);
        
        tempTimeSeries = [lat(xlat, ylon); tempTimeSeries];
%         prTimeSeriesEra = [lat(xlat, ylon); prTimeSeriesEra];
        
        ylonTSeries  = [ylonTSeries, tempTimeSeries];
%         ylonPSeries  = [ylonPSeries, prTimeSeries];
                
    end
    
    ylonTSeries  = [dayNum', ylonTSeries];
%     ylonPSeries  = [dayNum', ylonPSeries];

    lo = 2*round(lonRot(xlat,ylon)/2);
    la = 2*round(lat(xlat,ylon)/2);
    
    if exportTmax
        dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/' tVar '-' tDataset '-' num2str(lo) anomStr '.txt'], ylonTSeries);
%         dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/pmax-era-' num2str(lo) anomStr '.txt'], ylonPSeries);
    else
        dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/' tVar '-' tDataset '-' num2str(lo) anomStr '.txt'], ylonTSeries);
%         dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-cpc-' num2str(lo) anomStr '.txt'], ylonTSeriesCpc);
    end
%     dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/t-mean-' num2str(lo) '.txt'], ylonTSeriesMean);
%     dlmwrite(['E:/data/ecoffel/data/projects/ag-land-climate/t-p-dist/p-' num2str(lo) '.txt'], ylonPSeries);
end
% classifications(isnan(classifications)) = 0;
% dlmwrite('2020-ag-land-climate/koppen-classifications.txt', classifications);
