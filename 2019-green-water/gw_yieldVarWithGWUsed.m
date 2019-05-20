load('2019-green-water/pct-gw-used-maize.mat');
pctGWSupplyUsed(pctGWSupplyUsed == 0) = NaN;

load('gwfpPctUsed.mat');


load('2019-green-water/iizumiMaize');
load('2019-green-water/iizumiSoybean');
load('2019-green-water/iizumiRice');
load('2019-green-water/iizumiWheat');

load('2019-green-water/gpcpData-regrid.mat');

lat = iizumiMaize{1};
lon = iizumiMaize{2};

iizumiMaize{3} = iizumiMaize{3}(:, :, 2:end);
iizumiSoybean{3} = iizumiSoybean{3}(:, :, 2:end);
iizumiRice{3} = iizumiRice{3}(:, :, 2:end);
iizumiWheat{3} = iizumiWheat{3}(:, :, 2:end);

yieldNorm = [];

% gpcpSelData = [];
% monthInds = [];
% pcGw = [];
% 
% for xlat = 1:size(lat, 1)
%     for ylon = 1:size(lat, 2)
%         
%         pctTmp = squeeze(nanmean(pctGWSupplyUsed(xlat, ylon, 1995-1981+1:2004-1981+1, :), 3));
%         
%         if length(find(isnan(pctTmp))) > 0
%             monthInds(xlat, ylon, 1:3) = NaN;
%             gpcpSelData(xlat, ylon, 1:30) = NaN;
%             pcGw(xlat, ylon) = NaN;
%             continue;
%         end
%         
%         ind = find(pctTmp == nanmax(pctTmp));
%         monthInds(xlat, ylon, :) = [ind-1 ind ind+1];
%         
%         monthInds(monthInds == 0) = 12;
%         monthInds(monthInds == 13) = 1;
%         
%         gw = squeeze(nanmean(nanmean(pctGWSupplyUsed(xlat, ylon, 1995-1981+1:2004-1981+1, monthInds(xlat, ylon, :)), 4), 3));
%         gpcpSelData(xlat, ylon, :) = nanmean(gpcpRegridData(xlat, ylon, :, monthInds(xlat, ylon, :)), 4);
%         pcGw(xlat, ylon) = gw;
%     end
% end

yieldPrCorr = [];

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        
        maize = detrend(squeeze(iizumiMaize{3}(xlat, ylon, :)))+nanmean(squeeze(iizumiMaize{3}(xlat, ylon, :)));
        soybean = detrend(squeeze(iizumiSoybean{3}(xlat, ylon, :)));
        rice = detrend(squeeze(iizumiRice{3}(xlat, ylon, :)));
        wheat = detrend(squeeze(iizumiWheat{3}(xlat, ylon, :)));
        
        if (length(find(isnan(maize))) > 0 || isnan(gwfpPct{3}(xlat, ylon)))
            yieldNorm(xlat, ylon, 1:30) = NaN;
            yieldPrCorr(xlat, ylon) = NaN;
            continue;
        end
        
        yieldNorm(xlat, ylon, :) = maize;%nanmean([maize, soybean, rice, wheat], 2);
        
        if nanmean(squeeze(yieldNorm(xlat, ylon, :))) > 0
            yieldPrCorr(xlat, ylon) = nanstd(squeeze(yieldNorm(xlat, ylon, :)))/nanmean(squeeze(yieldNorm(xlat, ylon, :)));
        else
            yieldPrCorr(xlat, ylon) = NaN;
        end
        
%         x = squeeze(gpcpSelData(xlat, ylon, :));
%         y = squeeze(yieldNorm(xlat, ylon, :));
%         if length(x) == length(y)
%             yieldPrCorr(xlat, ylon) = corr(x, y);
%             
% %             mdl = fitlm(x, y);
% % 
% %             if mdl.Coefficients.pValue(2) < .1
% %                 yieldPrCorr(xlat, ylon) = mdl.Coefficients.Estimate(2);
% %             else
% %                 yieldPrCorr(xlat, ylon) = NaN;
% %             end
%         else
%             yieldPrCorr(xlat, ylon) = NaN;
%         end
    end
end

x = reshape(gwfpPct{3}, [numel(gwfpPct{3}), 1]);
y = reshape(yieldPrCorr, [numel(yieldPrCorr), 1]);

nn = find(~isnan(x) & ~isnan(y) & x > 0 & x <= 1 & ~isinf(x) & ~isinf(y));
x=x(nn);
y=y(nn);

