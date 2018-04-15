var = 'pr';

load(['E:\data\projects\bowen\derived-chg\' var 'ChgTxxMonths.mat']);
load(['E:\data\projects\bowen\derived-chg\' var 'Chg-absolute-all-txx.mat']);

load lat;
load lon;

load('2017-bowen/hottest-season-txx-rel-cmip5.mat');

varChg = eval([var 'Chg']);
varChgWarmMean = [];

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        months = squeeze(hottestSeason(xlat, ylon, :));
        months = [months-1 months months+1];
        months(months == 0) = 12;
        months(months == 13) = 1;
        
        months(isnan(months(:,1)),1) = mode(months(:,1));
        months(isnan(months(:,2)),2) = mode(months(:,2));
        months(isnan(months(:,3)),3) = mode(months(:,3));
        
        if length(find(isnan(months))) > 0
            fill = zeros([size(hottestSeason, 3), 1]);
            fill(fill==0) = NaN;
            varChgWarmMean(xlat, ylon, :) = fill;
        else
            varChgWarmMean(xlat, ylon, :) = nanmean(varChg(xlat, ylon, :, months), 4);
        end
    end
end

eval([var 'ChgWarmTxxAnom = ' var 'ChgTxxMonths - varChgWarmMean;']);
save(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmTxxAnom.mat'], [var 'ChgWarmTxxAnom']);