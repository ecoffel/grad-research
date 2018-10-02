
regionBoundsEthiopia = [[5.5 14.8]; [31, 40]];

load E:\data\ssp-pop\ssp1\output\ssp1\ssp1_2010.mat;
[latIndsEthiopiaSSP, lonIndsEthiopiaSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

tas = loadMonthlyData('E:\data\cmip5\output\access1-0\mon\r1i1p1\historical\tas', 'tas', 'startYear', 1900, 'endYear', 2005);
pr = loadMonthlyData('E:\data\cmip5\output\access1-0\mon\r1i1p1\historical\pr', 'pr', 'startYear', 1900, 'endYear', 2005);
%mrros = loadMonthlyData('E:\data\cmip5\output\access1-0\mon\r1i1p1\historical\mrros', 'mrros', 'startYear', 1900, 'endYear', 2005);

%mrros85 = loadMonthlyData('E:\data\cmip5\output\access1-0\mon\r1i1p1\rcp85\mrros', 'mrros', 'startYear', 2006, 'endYear', 2099);
tasFut = loadMonthlyData('E:\data\cmip5\output\access1-0\mon\r1i1p1\rcp85\tas', 'tas', 'startYear', 2006, 'endYear', 2099);
prFut = loadMonthlyData('E:\data\cmip5\output\access1-0\mon\r1i1p1\rcp85\pr', 'pr', 'startYear', 2006, 'endYear', 2099);

[latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5] = latLonIndexRange({tas{1}, tas{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

t = nanmean(squeeze(nanmean(nanmean(tas{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)),2);
%m = nanmean(squeeze(nanmean(nanmean(mrros{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)),2);
p = nanmean(squeeze(nanmean(nanmean(pr{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);

tf = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
pf = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
%mf = nanmean(squeeze(nanmean(nanmean(mrros85{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);

bwfpLat = [];
bwfpLon = [];
bwfp = [];
bwfpEthiopia = [];
gwfp = [];
gwfpEthiopia = [];

sspEthiopiaLon = ssp1_2010{2}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
sspEthiopiaLat = ssp1_2010{1}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
sspEthiopia = ssp1_2010{3}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
for m = 1:12
    fprintf('loading bwfp/gwfp...\n');
    load(['E:\data\bgwfp\output\bwfp\bwfp_' num2str(m)]);
    eval(['bwfp(:, :, ' num2str(m) ') = bwfp_' num2str(m) '{3};']);
    
    load(['E:\data\bgwfp\output\gwfp\gwfp_' num2str(m)]);
    eval(['gwfp(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{3};']);
    
    if m == 1
        bwfpLat = bwfp_1{1};
        bwfpLon = bwfp_1{2};
        
        [latIndsEthiopiaBW, lonIndsEthiopiaBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
    end
    
    fprintf('loading bwfp/gwfp month %d...\n', m);
    tmp = regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);
    bwfpEthiopia(:, :, m) = tmp{3};
    tmp = regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), gwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);
    gwfpEthiopia(:, :, m) = tmp{3};
    
    eval(['clear bwfp_' num2str(m) ';']);
    eval(['clear gwfp_' num2str(m) ';']);
end

pcBwfp = squeeze(nansum(nansum(bwfpEthiopia,2),1) ./ nansum(nansum(sspEthiopia)));
pcGwfp = squeeze(nansum(nansum(gwfpEthiopia,2),1) ./ nansum(nansum(sspEthiopia)));

% convert to mm/monthregridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);
%bwfp = bwfp .* 3600 .* 24 .* 30;
%bwfpEthiopia = bwfpEthiopia .* 3600 .* 24 .* 30;

