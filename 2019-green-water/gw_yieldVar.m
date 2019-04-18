load('2019-green-water/iizumiMaize');
load('2019-green-water/gwfpData.mat');
load('2019-green-water/gpcpData-regrid.mat');

load('2019-green-water/pct-gw-used.mat');
pctGWSupplyUsed(pctGWSupplyUsed == 0) = NaN;

lat = iizumiMaize{1};
lon = iizumiMaize{2};

% midwest
latBounds = [33, 52];
lonBounds = [-110, -85]+360;

[latInds, lonInds] = latLonIndexRange({lat, lon, []}, latBounds, lonBounds);

gwfp = pctGWSupplyUsed(latInds, lonInds);
% hiMask = logical(nanmean(nanmean(pctGWSupplyUsed(latInds, lonInds, 1995-1981+1:2004-1981+1, [6:8]), 4), 3) > .5);
% loMask = logical(nanmean(nanmean(pctGWSupplyUsed(latInds, lonInds, 1995-1981+1:2004-1981+1, [6:8]), 4), 3) < .1);

yieldMaize = iizumiMaize{3}(latInds, lonInds, 2:end);
gpcpRegridData = gpcpRegridData(latInds, lonInds, :, :);

gpcpPr = [];

yieldPrRel = [];

for xlat = 1:size(yieldMaize, 1)
    for ylon = 1:size(yieldMaize, 2)
        y = detrend(normalize(squeeze(yieldMaize(xlat, ylon, :))));
        yieldMaize(xlat, ylon, :) = detrend(normalize(y));
        
        p = squeeze(normalize(squeeze(nanmean(gpcpRegridData(xlat, ylon, :, [6:8]), 4))));
        gpcpPr(xlat, ylon, :) = p;
        
        
        if length(find(isnan(p))) > 0 || length(find(isnan(y))) > 0
            yieldPrRel(xlat, ylon) = NaN;
        else
            mdl = fitlm(p, y);

            yieldPrRel(xlat, ylon) = mdl.Coefficients.Estimate(2);
        end
    end
end

xLo = reshape(gwfp, [numel(gwfp), 1]);
yLo = reshape(yieldPrRel, [numel(yieldPrRel), 1]);

xHi = reshape(prHi, [numel(prHi), 1]);
yHi = reshape(yieldHi, [numel(yieldHi), 1]);
