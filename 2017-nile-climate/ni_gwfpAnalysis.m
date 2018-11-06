

[regionInds, regions, regionNames] = ni_getRegions();
regionBoundsEthiopia = regions('nile-ethiopia');
regionBoundsBlue = regions('nile-blue');
regionBoundsWhite = regions('nile-white');

if ~exist('ssp1_2010')
    load E:\data\ssp-pop\ssp1\output\ssp1\ssp1_2010.mat;
    [latIndsEthiopiaSSP, lonIndsEthiopiaSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
    [latIndsBlueSSP, lonIndsBlueSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
    [latIndsWhiteSSP, lonIndsWhiteSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
end

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1961, 'endYear', 2014);
    udelp = {udelp{1}, udelp{2}, flipud(udelp{3})};
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1961, 'endYear', 2014);
    udelt = {udelt{1}, udelt{2}, flipud(udelt{3})};
    
    [latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({udelp{1},udelp{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
    [latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({udelp{1},udelp{2},[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
    [latIndsWhiteUdel, lonIndsWhiteUdel] = latLonIndexRange({udelp{1},udelp{2},[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
    
    udeltEthiopia = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, :), 4), 2), 1));
    udelpEthiopia = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, :), 4), 2), 1));
end

ihd = find(udeltEthiopia > prctile(udeltEthiopia, 74) & udelpEthiopia < prctile(udelpEthiopia, 34));
id = find(udeltEthiopia < prctile(udeltEthiopia, 74) & udelpEthiopia < prctile(udelpEthiopia, 34));
ih = find(udeltEthiopia > prctile(udeltEthiopia, 74) & udelpEthiopia > prctile(udelpEthiopia, 34));

% load and store ssp data
if ~exist('ssp')
    ssp = [];
    for s = 1:5
        fprintf('loading ssp %d...\n',s);
        decind = 1;
        for dec = 2010:10:2090
            load(['E:\data\ssp-pop\ssp' num2str(s) '\output\ssp' num2str(s) '\ssp' num2str(s) '_' num2str(dec) '.mat']);
            eval(['ssp(:,:,decind,s) = ssp' num2str(s) '_' num2str(dec) '{3};']);
            decind = decind+1;
        end
    end
end

earthradius = almanac('earth','radius','meters');

if ~exist('gwfpEthiopia')
    gwfp = [];
    gwfpEthiopia = [];
    gwfpBlue = [];
    gwfpWhite = [];

    sspEthiopiaLon = ssp1_2010{2}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
    sspEthiopiaLat = ssp1_2010{1}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
    sspEthiopia = ssp1_2010{3}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);

    for m = 1:12
        fprintf('loading gwfp month %d...\n', m);

        load(['E:\data\bgwfp\output\gwfp\gwfp_' num2str(m)]);
        eval(['gwfp(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{3};']);

        if m == 1
            gwfpLat = gwfp_1{1};
            gwfpLon = gwfp_1{2};

            [latIndsEthiopiaGW, lonIndsEthiopiaGW] = latLonIndexRange({gwfpLat,gwfpLon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
            [latIndsBlueGW, lonIndsBlueGW] = latLonIndexRange({gwfpLat,gwfpLon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
            [latIndsWhiteGW, lonIndsWhiteGW] = latLonIndexRange({gwfpLat,gwfpLon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
        end

        
        tmp = regridGriddata({gwfpLat(latIndsEthiopiaGW, lonIndsEthiopiaGW), gwfpLon(latIndsEthiopiaGW, lonIndsEthiopiaGW), gwfp(latIndsEthiopiaGW, lonIndsEthiopiaGW, m)}, ...
                             {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, ...
                             false);
        gwfpEthiopia(:, :, m) = tmp{3};
        
        % blue nile
        tmp = regridGriddata({gwfpLat(latIndsBlueGW, lonIndsBlueGW), gwfpLon(latIndsBlueGW, lonIndsBlueGW), gwfp(latIndsBlueGW, lonIndsBlueGW, m)}, ...
                             {ssp1_2010{1}(latIndsBlueSSP,lonIndsBlueSSP), ssp1_2010{2}(latIndsBlueSSP,lonIndsBlueSSP), ssp1_2010{3}(latIndsBlueSSP,lonIndsBlueSSP)}, ...
                             false);
        gwfpBlue(:, :, m) = tmp{3};

        tmp = regridGriddata({gwfpLat(latIndsWhiteGW, lonIndsWhiteGW), gwfpLon(latIndsWhiteGW, lonIndsWhiteGW), gwfp(latIndsWhiteGW, lonIndsWhiteGW, m)}, ...
                             {ssp1_2010{1}(latIndsWhiteSSP,lonIndsWhiteSSP), ssp1_2010{2}(latIndsWhiteSSP,lonIndsWhiteSSP), ssp1_2010{3}(latIndsWhiteSSP,lonIndsWhiteSSP)}, ...
                             false);
        gwfpWhite(:, :, m) = tmp{3};

        eval(['clear gwfp_' num2str(m) ';']);
        eval(['clear gwfp_' num2str(m) ';']);
    end
end

% compute area table for ethiopia
areaTableEthiopia = [];
udelLatTableEthiopia = [];
udelLonTableEthiopia = [];
latdiff = ssp1_2010{1}(2,1)-ssp1_2010{1}(1,1);
londiff = ssp1_2010{2}(1,2)-ssp1_2010{2}(1,1);
for xind = 1:length(latIndsEthiopiaSSP)
    xlat = latIndsEthiopiaSSP(xind);
    for yind = 1:length(lonIndsEthiopiaSSP)
        ylon = lonIndsEthiopiaSSP(yind);
        curArea = areaint([ssp1_2010{1}(xlat, ylon) ssp1_2010{1}(xlat, ylon)+latdiff ssp1_2010{1}(xlat, ylon)+latdiff ssp1_2010{1}(xlat, ylon)], ...
                          [ssp1_2010{2}(xlat, ylon) ssp1_2010{2}(xlat, ylon) ssp1_2010{2}(xlat, ylon)+londiff ssp1_2010{2}(xlat, ylon)+londiff], earthradius);


        [curUdelLatInd, curUdelLonInd] = latLonIndex(udelp, [ssp1_2010{1}(xlat, ylon), ssp1_2010{2}(xlat, ylon)]);
        udelLatTableEthiopia(xind, yind) = curUdelLatInd;
        udelLonTableEthiopia(xind, yind) = curUdelLonInd;

        areaTableEthiopia(xind, yind) = curArea;
    end
end


% compute gw supply for ethiopia
% ------------------------------------------
s = 3;
gwSupplyHistTotal = zeros(length(1961:2014), 1);
gwSupplyPcHistEthiopia = zeros(length(1961:2014), 1);
gwSupplySpatialHistEthiopia = [];
for year = 1:size(udelp{3}, 3)
    for xind = 1:length(latIndsEthiopiaSSP)
        xlat = latIndsEthiopiaSSP(xind);
        for yind = 1:length(lonIndsEthiopiaSSP)
            ylon = lonIndsEthiopiaSSP(yind);

            gwSupplySpatialHistEthiopia(xind, yind, year) = areaTableEthiopia(xind, yind) * nansum(squeeze(udelp{3}(udelLatTableEthiopia(xind, yind), udelLonTableEthiopia(xind, yind), year, :))) * 1e-3;
            
            ittr = (areaTableEthiopia(xind, yind) * nansum(squeeze(udelp{3}(udelLatTableEthiopia(xind, yind), udelLonTableEthiopia(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, 1, s)) * ...
                                         (ssp(xlat, ylon, 1, s) / nansum(nansum(ssp(latIndsEthiopiaSSP, lonIndsEthiopiaSSP, 1, s))));

            % could be nan if div by 0 pop
            if ~isnan(ittr)
                gwSupplyPcHistEthiopia(year) = gwSupplyPcHistEthiopia(year) + ittr;
            end

            % not pc
            ittrTotal = areaTableEthiopia(xind, yind) * nansum(squeeze(udelp{3}(udelLatTableEthiopia(xind, yind), udelLonTableEthiopia(xind, yind), year, :))) * 1e-3 * ...
                                         (ssp(xlat, ylon, 1, s) / (nansum(nansum(ssp(latIndsEthiopiaSSP, lonIndsEthiopiaSSP, 1, s))) + nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));


            if ~isnan(ittrTotal)
                gwSupplyHistTotal(year) = gwSupplyHistTotal(year) + ittrTotal;
            end
        end
    end
end


pcGwfpEthiopia = 0;
gwfpEthiopiaSpatial = [];
% bwfp and ssp are on same grid now
latBwfpEthiopia = ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP);
lonBwfpEthiopia = ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP);

% calc historical per capita bw footprint -------------------
fprintf('calculating historical per capita gwfootprint...\n');
s = 3;
for xlat = 1:size(gwfpEthiopia, 1)
    latdiff = latBwfpEthiopia(2,1)-latBwfpEthiopia(1,1);
    londiff = lonBwfpEthiopia(1,2)-lonBwfpEthiopia(1,1);
    for ylon = 1:size(gwfpEthiopia, 2)
        curArea = areaTableEthiopia(xlat, ylon);

        gwfpEthiopiaSpatial(xlat, ylon) = curArea * nansum(squeeze(gwfpEthiopia(xlat, ylon, :))) * 1e-3;
        
        ittrEthiopia = curArea * nansum(squeeze(gwfpEthiopia(xlat, ylon, :))) * 1e-3 * ...
                                   (ssp(latIndsEthiopiaSSP(xlat), lonIndsEthiopiaSSP(ylon), 1, s) / nansum(nansum(squeeze(ssp(latIndsEthiopiaSSP, lonIndsEthiopiaSSP, 1, s)))));

        if ~isnan(ittrEthiopia)
            pcGwfpEthiopia = pcGwfpEthiopia + ittrEthiopia;
        end

    end
end

unmetGwDemand = [];
for year = 1:length(udelpEthiopia)
    unmetGwDemand(year) = length(find(gwSupplySpatialHistEthiopia(:, :, year) < gwfpEthiopiaSpatial)) / numel(gwfpEthiopiaSpatial);
end


colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1]);

b = boxplot((gwSupplyHistTotal(indBad)-nanmean(gwSupplyHistTotal))./nanmean(gwSupplyHistTotal).*100, 'width', .6, 'positions', [1]);

set(b, {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

b = boxplot((unmetGwDemand(indBad)-nanmean(unmetGwDemand))./nanmean(unmetGwDemand).*100, 'width', .6, 'positions', [2]);

set(b, {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([0 3], [0 0], 'k', 'linewidth', 2);

xlim([0 3]);
ylim([-15 15]);
set(gca, 'fontsize', 36);
set(gca, 'xtick', [1 2], 'xticklabels', {'', ''});
ylabel('% Difference from normal');
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-supply-demand-bad.eps;
close all;




figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1]);

b = boxplot((gwSupplyHistTotal(indGood)-nanmean(gwSupplyHistTotal))./nanmean(gwSupplyHistTotal).*100, 'width', .6, 'positions', [1]);

set(b, {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

b = boxplot((unmetGwDemand(indGood)-nanmean(unmetGwDemand))./nanmean(unmetGwDemand).*100, 'width', .6, 'positions', [2]);

set(b, {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([0 3], [0 0], 'k', 'linewidth', 2);

xlim([0 3]);
ylim([-15 15]);
set(gca, 'fontsize', 36);
set(gca, 'xtick', [1 2], 'xticklabels', {'', ''});
ylabel('% Difference from normal');
set(gcf, 'Position', get(0,'Screensize'));
export_fig gw-supply-demand-good.eps;
close all;
