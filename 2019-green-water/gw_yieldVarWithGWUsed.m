load('2019-green-water/pct-gw-used-maize.mat');
pctGWSupplyUsed(pctGWSupplyUsed == 0) = NaN;

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

gpcpSelData = [];
monthInds = [];
pcGw = [];

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        
        pctTmp = squeeze(nanmean(pctGWSupplyUsed(xlat, ylon, 1995-1981+1:2004-1981+1, :), 3));
        
        if length(find(isnan(pctTmp))) > 0
            monthInds(xlat, ylon, 1:3) = NaN;
            gpcpSelData(xlat, ylon, 1:30) = NaN;
            pcGw(xlat, ylon) = NaN;
            continue;
        end
        
        ind = find(pctTmp == nanmax(pctTmp));
        monthInds(xlat, ylon, :) = [ind-1 ind ind+1];
        
        monthInds(monthInds == 0) = 12;
        monthInds(monthInds == 13) = 1;
        
        gw = squeeze(nanmean(nanmean(pctGWSupplyUsed(xlat, ylon, 1995-1981+1:2004-1981+1, monthInds(xlat, ylon, :)), 4), 3));
        gpcpSelData(xlat, ylon, :) = nanmean(gpcpRegridData(xlat, ylon, :, monthInds(xlat, ylon, :)), 4);
        pcGw(xlat, ylon) = gw;
    end
end

yieldPrCorr = [];

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        
        maize = normalize(detrend(squeeze(iizumiMaize{3}(xlat, ylon, :))));
        soybean = normalize(detrend(squeeze(iizumiSoybean{3}(xlat, ylon, :))));
        rice = normalize(detrend(squeeze(iizumiRice{3}(xlat, ylon, :))));
        wheat = normalize(detrend(squeeze(iizumiWheat{3}(xlat, ylon, :))));
        
        if (isnan(maize(1)) && isnan(soybean(1)) && isnan(rice(1)) && isnan(wheat(1))) || isnan(pcGw(xlat, ylon))
            yieldNorm(xlat, ylon, 1:30) = NaN;
            yieldPrCorr(xlat, ylon) = NaN;
            continue;
        end
        
        yieldNorm(xlat, ylon, :) = maize;%nanmean([maize, soybean, rice, wheat], 2);
        
        x = squeeze(gpcpSelData(xlat, ylon, :));
        y = squeeze(yieldNorm(xlat, ylon, :));
        if length(x) == length(y)
            mdl = fitlm(x, y);

            if mdl.Coefficients.pValue(2) < .1
                yieldPrCorr(xlat, ylon) = mdl.Coefficients.Estimate(2);
            else
                yieldPrCorr(xlat, ylon) = NaN;
            end
        else
            yieldPrCorr(xlat, ylon) = NaN;
        end
    end
end


x = reshape(pcGw, [numel(pcGw), 1]);
y = reshape(yieldPrCorr, [numel(yieldPrCorr), 1]);

x(x>2 | x<0) = NaN;
