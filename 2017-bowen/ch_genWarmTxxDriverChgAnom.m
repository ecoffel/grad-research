txxWarmAnom = true;
warmSeasonAnom = false;

percentChg = false;
excludeWinter = false;

var = 'netRad';

if percentChg
    load(['E:\data\projects\bowen\derived-chg\' var 'ChgTxxMonths-percent.mat']);
    load(['E:\data\projects\bowen\derived-chg\' var 'Chg-all-txx.mat']);
else
    load(['E:\data\projects\bowen\derived-chg\' var 'ChgTxxMonths-absolute.mat']);
    load(['E:\data\projects\bowen\derived-chg\' var 'Chg-absolute-all-txx.mat']);
end

load lat;
load lon;

load('2017-bowen/hottest-season-txx-rel-cmip5.mat');

varChg = eval([var 'Chg']);
varChgWarmMean = [];
varChgAnnMean = [];


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
            varChgAnnMean(xlat, ylon, :) = fill;
        else
            for model = 1:size(months,1)
                varChgWarmMean(xlat, ylon, :) = nanmean(varChg(xlat, ylon, :, months(model,:)), 4);

                if excludeWinter && xlat > 60
                    %exclude nh winter
                    varChgAnnMean(xlat, ylon, :) = nanmean(varChg(xlat, ylon, :, [4:11]), 4);
                elseif excludeWinter && xlat < 30
                    %exclude sh winter
                    varChgAnnMean(xlat, ylon, :) = nanmean(varChg(xlat, ylon, :, [1:5 10:12]), 4);
                else
                    varChgAnnMean(xlat, ylon, :) = nanmean(varChg(xlat, ylon, :, :), 4);
                end
            end
        end
    end
end

prcStr = '';
if percentChg
    prcStr = '-percent';
end

winterStr = '';
if excludeWinter
    winterStr = '-nowint';
end

if txxWarmAnom
    eval([var 'ChgWarmTxxAnom = ' var 'ChgTxxMonths - varChgWarmMean;']);
    save(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmTxxAnom' prcStr winterStr '.mat'], [var 'ChgWarmTxxAnom']);
else
    eval([var 'ChgWarmAnom = varChgWarmMean - varChgAnnMean;']);
    save(['E:\data\projects\bowen\derived-chg\' var 'ChgWarmAnom' prcStr winterStr '.mat'], [var 'ChgWarmAnom']);
end

