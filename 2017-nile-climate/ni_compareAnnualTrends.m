
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
rcp = 'historical';
timePeriod = [1981 2016];

plotTempPTrends = false;
plotHotDryTrends = true;

if ~exist('eraTemp', 'var')
    fprintf('loading ERA...\n');
    eraTemp = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    eraTemp{3} = eraTemp{3} - 273.15;
    eraTemp = dailyToMonthly(eraTemp);
    eraTemp{3} = nanmean(eraTemp{3}, 4);
    
    eraPr = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    eraPr{3} = eraPr{3} .* 1000;
    eraPr = dailyToMonthly(eraPr);
    eraPr{3} = nanmean(eraPr{3}, 4);
    
end

if ~exist('gldasTemp', 'var')
    fprintf('loading GLDAS...\n');
    gldasTemp = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1960, 'endYear', 2010);
    gldasTemp{3} = nanmean(gldasTemp{3} - 273.15, 4);
    
    gldasPr = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1960, 'endYear', 2010);
    gldasPr{3} = gldasPr{3} .* 3600 .* 24;
    gldasPr{3} = nanmean(gldasPr{3}, 4);
end

if ~exist('gpcp', 'var')
    fprintf('loading GPCP...\n');
    gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\regrid\world\1979-2017', 'precip', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    gpcp{3} = nanmean(gpcp{3},4);
end

if ~exist('chirps', 'var')
    fprintf('loading CHIRPS...\n');
    chirps = [];
    load lat-chirps;
    load lon-chirps;
    
    % load pre-processed chirps with nile region selected
    for year = timePeriod(1):1:timePeriod(end)
        fprintf('chirps year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-' num2str(year) '.mat']);
        chirpsPr{3} = chirpsPr{3};
        
        if length(chirps) == 0
            latChirps = chirpsPr{1};
            lonChirps = chirpsPr{2};
            
            chirps = chirpsPr{3};
        else
            chirps = cat(4, chirps, chirpsPr{3});
        end
        
        clear chirpsPr;
    end
    % flip to (x, y, year, month)
    chirps = permute(chirps, [1 2 4 3]);
    chirps = nanmean(chirps, 4);
end

if ~exist('cpc', 'var')   
    cpc = [];
    for year = timePeriod(1):1:timePeriod(end)
        fprintf('cpc year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\temp-monthly-cpc-' num2str(year) '.mat']);
        cpcTemp{3} = cpcTemp{3};

        if length(cpc) == 0
            cpc = cpcTemp{3};
        else
            cpc = cat(4, cpc, cpcTemp{3});
        end

        clear cpcTemp;
    end
    cpc = permute(cpc, [1 2 4 3]);
    cpc = nanmean(cpc, 4);
end

if ~exist('udelt')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2014);
    udelp = {udelp{1}, udelp{2}, flipud(udelp{3})};
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2014);
    udelt = {udelt{1}, udelt{2}, flipud(udelt{3})};
end

blue = false;

[regionInds, regions, regionNames] = ni_getRegions();
regionBounds = regions('nile');
regionBoundsBlue = regions('nile-blue');
regionBoundsWhite = regions('nile-white');

latGldas = gldasTemp{1};
lonGldas = gldasTemp{2};
[latIndsBlueGldas, lonIndsBlueGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteGldas, lonIndsWhiteGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

latUdel = udelt{1};
lonUdel = udelt{2};
[latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({latUdel,lonUdel,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteUdel, lonIndsWhiteUdel] = latLonIndexRange({latUdel,lonUdel,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

[latIndsChirps, lonIndsChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsBlueChirps, lonIndsBlueChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteChirps, lonIndsWhiteChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
latIndsWhiteChirpsRel = latIndsWhiteChirps-latIndsChirps(1)+1;
latIndsBlueChirpsRel = latIndsBlueChirps-latIndsChirps(1)+1;
lonIndsWhiteChirpsRel = lonIndsWhiteChirps-lonIndsChirps(1)+1;
lonIndsBlueChirpsRel = lonIndsBlueChirps-lonIndsChirps(1)+1;

load lat;
load lon;

[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsBlue, lonIndsBlue] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhite, lonIndsWhite] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
latIndsWhiteRel = latIndsWhite-latInds(1)+1;
latIndsBlueRel = latIndsBlue-latInds(1)+1;
lonIndsWhiteRel = lonIndsWhite-lonInds(1)+1;
lonIndsBlueRel = lonIndsBlue-lonInds(1)+1;


if ~exist('cmip5Temp', 'var')
    cmip5Temp = [];
    for m = 1:length(models)
        fprintf('processing %s...\n', models{m});
        t = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\tas\regrid\world'], 'tas', 'startYear', 1901, 'endYear', 2005);
        %t2 = loadDailyData(['E:\data\cmip5\output\' models{m} '\r1i1p1\rcp85\tasmax\regrid\world'], 'startYear', 2006, 'endYear', 2016);
        %t = dailyToMonthly(t);
        %t2 = dailyToMonthly(t2);
        if nanmean(nanmean(nanmean(nanmean(t{3})))) > 100
            t{3} = t{3} - 273.15;
        end
    %     if nanmean(nanmean(nanmean(nanmean(t2{3})))) > 100
    %         t2{3} = t2{3} - 273.15;
    %     end
        t = nanmean(t{3}(latInds, lonInds, :, :), 4);
    %     t2 = nanmean(t2{3}(latInds, lonInds, :, :), 4);

        cmip5Temp(:,:,:,m) = t;%cat(3, t, t2);
    end
end

if ~exist('cmip5Pr', 'var')
    cmip5Pr = [];
    for m = 1:length(models)
        fprintf('processing %s...\n', models{m});
        p = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\pr\regrid\world'], 'pr', 'startYear', 1901, 'endYear', 2005);
        %p2 = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\rcp85\pr\regrid\world'], 'pr', 'startYear', 2006, 'endYear', 2016);
        p{3} = p{3} .* 3600 .* 24;
        %p2{3} = p2{3} .* 3600 .* 24;
        p = nanmean(p{3}(latInds, lonInds, :, :), 4);
        %p2 = nanmean(p2{3}(latInds, lonInds, :, :), 4);

        cmip5Pr(:,:,:,m) = p;%cat(3, p, p2);
    end
end

if blue
    curLatInds = latIndsBlue;
    curLonInds = lonIndsBlue;
    
    curLatIndsRel = latIndsBlueRel;
    curLonIndsRel = lonIndsBlueRel;
    
    curLatIndsChirpsRel = latIndsBlueChirpsRel;
    curLonIndsChirpsRel = lonIndsBlueChirpsRel;
    
    curLatIndsGldas = latIndsBlueGldas;
    curLonIndsGldas = lonIndsBlueGldas;
    
    curLatIndsUdel = latIndsBlueUdel;
    curLonIndsUdel = lonIndsBlueUdel;
else
    curLatInds = latIndsWhite;
    curLonInds = lonIndsWhite;
    
    curLatIndsRel = latIndsWhiteRel;
    curLonIndsRel = lonIndsWhiteRel;
    
    curLatIndsChirpsRel = latIndsWhiteChirpsRel;
    curLonIndsChirpsRel = lonIndsWhiteChirpsRel;
    
    curLatIndsGldas = latIndsWhiteGldas;
    curLonIndsGldas = lonIndsWhiteGldas;
    
    curLatIndsUdel = latIndsWhiteUdel;
    curLonIndsUdel = lonIndsWhiteUdel;
end

curLatInds = [latIndsBlue latIndsWhite];
curLonInds = [lonIndsBlue lonIndsWhite];

curLatIndsRel = [latIndsBlueRel latIndsWhiteRel];
curLonIndsRel = [lonIndsBlueRel lonIndsWhiteRel];

curLatIndsChirpsRel = [latIndsBlueChirpsRel latIndsWhiteChirpsRel];
curLonIndsChirpsRel = [lonIndsBlueChirpsRel lonIndsWhiteChirpsRel];

curLatIndsGldas = [latIndsBlueGldas latIndsWhiteGldas];
curLonIndsGldas = [lonIndsBlueGldas lonIndsWhiteGldas];

curLatIndsUdel = [latIndsBlueUdel latIndsWhiteUdel];
curLonIndsUdel = [lonIndsBlueUdel lonIndsWhiteUdel];

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

tempTrends = [];
tempTrendsP = [];
tempTrendsCmip5 = [];
tempTrendsPCmip5 = [];
tempSE = [];
       
regionalTEra = squeeze(nanmean(nanmean(eraTemp{3}(curLatInds, curLonInds, :), 2), 1));
regionalTGldas = squeeze(nanmean(nanmean(gldasTemp{3}(curLatIndsGldas, curLonIndsGldas, :), 2), 1));
regionalTCpc = squeeze(nanmean(nanmean(cpc(curLatIndsRel, curLonIndsRel, :), 2), 1));
regionalTUdel = squeeze(nanmean(nanmean(udelt{3}(curLatIndsUdel, curLonIndsUdel, :), 2), 1));
regionalTCmip5 = squeeze(nanmean(nanmean(cmip5Temp(curLatIndsRel, curLonIndsRel, :, :), 2), 1));

f = fitlm((1:length(regionalTEra))', regionalTEra, 'linear');
tempTrendsP(1) = f.Coefficients.pValue(2);
tempTrends(1) = f.Coefficients.Estimate(2);
tempSE(1) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalTGldas))', regionalTGldas, 'linear');
tempTrendsP(2) = f.Coefficients.pValue(2);
tempTrends(2) = f.Coefficients.Estimate(2);
tempSE(2) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalTUdel))', regionalTUdel, 'linear');
tempTrendsP(3) = f.Coefficients.pValue(2);
tempTrends(3) = f.Coefficients.Estimate(2);
tempSE(3) = f.Coefficients.SE(2);


f = fitlm((1:length(regionalTCpc))', regionalTCpc, 'linear');
tempTrendsP(4) = f.Coefficients.pValue(2);
tempTrends(4) = f.Coefficients.Estimate(2);
tempSE(4) = f.Coefficients.SE(2);


for m = 1:size(regionalTCmip5, 2)
    t = regionalTCmip5(:,m)';
    f = fitlm((1:length(t))', t, 'linear');
    tempTrendsPCmip5(m) = f.Coefficients.pValue(2);
    tempTrendsCmip5(m) = f.Coefficients.Estimate(2);
end

% /year -> /decade
tempTrendsCmip5 = tempTrendsCmip5 .* 10;
tempTrends = tempTrends .* 10;
tempSE = tempSE .* 10;

prTrendsCmip5 = [];
prTrendsPCmip5 = [];
prTrends = [];
prTrendsP = [];
prSE = [];
       
regionalPEra = squeeze(nanmean(nanmean(eraPr{3}(curLatInds, curLonInds, :), 2), 1));
regionalPGldas = squeeze(nanmean(nanmean(gldasPr{3}(curLatIndsGldas, curLonIndsGldas, :), 2), 1));
regionalPGpcp = squeeze(nanmean(nanmean(gpcp{3}(curLatInds, curLonInds, :), 2), 1));
regionalPChirps = squeeze(nanmean(nanmean(chirps(curLatIndsChirpsRel, curLonIndsChirpsRel, :), 2), 1));
regionalPUdel = squeeze(nanmean(nanmean(udelp{3}(curLatIndsUdel, curLonIndsUdel, :), 2), 1));
regionalPCmip5 = squeeze(nanmean(nanmean(cmip5Pr(curLatIndsRel, curLonIndsRel, :, :), 2), 1));

f = fitlm((1:length(regionalPEra))', regionalPEra, 'linear');
prTrendsP(1) = f.Coefficients.pValue(2);
prTrends(1) = f.Coefficients.Estimate(2);
prSE(1) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPGldas))', regionalPGldas, 'linear');
prTrendsP(2) = f.Coefficients.pValue(2);
prTrends(2) = f.Coefficients.Estimate(2);
prSE(2) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPUdel))', regionalPUdel, 'linear');
prTrendsP(3) = f.Coefficients.pValue(2);
prTrends(3) = f.Coefficients.Estimate(2);
prSE(3) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPGpcp))', regionalPGpcp, 'linear');
prTrendsP(4) = f.Coefficients.pValue(2);
prTrends(4) = f.Coefficients.Estimate(2);
prSE(4) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPChirps))', regionalPChirps, 'linear');
prTrendsP(5) = f.Coefficients.pValue(2);
prTrends(5) = f.Coefficients.Estimate(2);
prSE(5) = f.Coefficients.SE(2);



for m = 1:size(regionalPCmip5, 2)
    p = regionalPCmip5(:,m)';
    f = fitlm((1:length(p))', p, 'linear');
    prTrendsPCmip5(m) = f.Coefficients.pValue(2);
    prTrendsCmip5(m) = f.Coefficients.Estimate(2);
end


% /year -> /decade
prTrendsCmip5 = prTrendsCmip5 .* 10;
prTrends = prTrends .* 10;
prSE = prSE .* 10;



if plotTempPTrends
    
    fig = figure('Color',[1,1,1]);
    
    colors = get(fig, 'defaultaxescolororder');
    
    legItems = [];
    hold on;
    box on;
    axis square;
    grid on;

    yyaxis left;
    displace = [-.2 -.1 0 .1];
    for d = 1:length(tempTrendsP)
        e = errorbar(1+displace(d), tempTrends(d), tempSE(d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(1+displace(d), tempTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);

        legItems(end+1) = p;

        if tempTrendsP(d) < .05
            plot(1+displace(d), tempTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end

    b = boxplot(tempTrendsCmip5', 'positions', [1.2], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    ylabel([char(176) 'C/decade']);
    ylim([-1 1]);
    xlim([.5 2.5]);

    % skip color 4 (for cpc) so that 2 unique pr datasets have their own
    % colors
    colors(4,:)=colors(5,:);
    colors(5,:)=colors(6,:);

    yyaxis right;
    displace = [-.25 -.15 -.05 .05 .15];
    for d = 1:length(prTrends)
            e = errorbar(2+displace(d), prTrends(d), prSE(d), 'Color', colors(d,:), 'LineWidth', 2);
            p = plot(2+displace(d), prTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
            if d >= 4
                legItems(end+1) = p;
            end
            if prTrendsP(d) < .05
                plot(2+displace(d), prTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
            end
    end

    b = boxplot(prTrendsCmip5', 'positions', [2.25], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    ylabel('mm/day/decade');
    plot([0 3], [0 0], 'k--');
    plot([1.5 1.5], [-10 10], 'k');
    ylim([-.3 .3]);

    xlim([.5 2.5]);
    set(gca, 'FontSize', 36);
    set(gca, 'XTick', [1 2], 'XTickLabels', {'Temperature', 'Precipitation'});
    set(gca, 'YTick', -.3:.1:.3);
    legend(legItems, {'ERA-Interim', 'GLDAS', 'UDel', 'CPC', 'GPCP', 'CHIRPS-2'}, 'location', 'northeast');
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig('annual-temp-pr-trends-total.eps');
    close all;
%     if blue
%         export_fig('annual-temp-pr-trends-blue.eps');
%     else
%         export_fig('annual-temp-pr-trends-white.eps');
%     end
%     close all;
end



% hot/dry trends ----------------------------------------------------------
tprc = 74;
pprc = 34;


prcTEraBlue = prctile(eraTemp{3}(latIndsBlue, lonIndsBlue, :), tprc, 3);
prcPEraBlue = prctile(eraPr{3}(latIndsBlue, lonIndsBlue, :), pprc, 3);

prcTGldasBlue = prctile(gldasTemp{3}(latIndsBlueGldas, lonIndsBlueGldas, :), tprc, 3);
prcPGldasBlue = prctile(gldasPr{3}(latIndsBlueGldas, lonIndsBlueGldas, :), pprc, 3);

prcTCpcBlue = prctile(cpc(latIndsBlueRel, lonIndsBlueRel, :), tprc, 3);
prcPGpcpBlue = prctile(gpcp{3}(latIndsBlueRel, lonIndsBlueRel, :), pprc, 3);

prcTUdelBlue = prctile(udelt{3}(latIndsBlueUdel, lonIndsBlueUdel, :), tprc, 3);
prcPUdelBlue = prctile(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :), pprc, 3);

prcTCmip5Blue = squeeze(prctile(cmip5Temp(latIndsBlueRel, lonIndsBlueRel, :, :), tprc, 3));
prcPCmip5Blue = squeeze(prctile(cmip5Pr(latIndsBlueRel, lonIndsBlueRel, :, :), pprc, 3));

prcTEraWhite = prctile(eraTemp{3}(latIndsWhite, lonIndsWhite, :), tprc, 3);
prcPEraWhite = prctile(eraPr{3}(latIndsWhite, lonIndsWhite, :), pprc, 3);

prcTGldasWhite = prctile(gldasTemp{3}(latIndsWhiteGldas, lonIndsWhiteGldas, :), tprc, 3);
prcPGldasWhite = prctile(gldasPr{3}(latIndsWhiteGldas, lonIndsWhiteGldas, :), pprc, 3);

prcTCpcWhite = prctile(cpc(latIndsWhiteRel, lonIndsWhiteRel, :), tprc, 3);
prcPGpcpWhite = prctile(gpcp{3}(latIndsWhiteRel, lonIndsWhiteRel, :), pprc, 3);

prcTUdelWhite = prctile(udelt{3}(latIndsWhiteUdel, lonIndsWhiteUdel, :), tprc, 3);
prcPUdelWhite = prctile(udelp{3}(latIndsWhiteUdel, lonIndsWhiteUdel, :), pprc, 3);

prcTCmip5White = squeeze(prctile(cmip5Temp(latIndsWhiteRel, lonIndsWhiteRel, :, :), tprc, 3));
prcPCmip5White = squeeze(prctile(cmip5Pr(latIndsWhiteRel, lonIndsWhiteRel, :, :), pprc, 3));

% 1981 - 2016 time period
for year = 1:(timePeriod(end)-timePeriod(1)+1)
    hotDryEraBlue(year) = numel(find(eraTemp{3}(latIndsBlue, lonIndsBlue, year) > prcTEraBlue & eraPr{3}(latIndsBlue, lonIndsBlue, year) < prcPEraBlue));
    hotDryEraWhite(year) = numel(find(eraTemp{3}(latIndsWhite, lonIndsWhite, year) > prcTEraWhite & eraPr{3}(latIndsWhite, lonIndsWhite, year) < prcPEraWhite));
    
    hotDryCpcGpcpBlue(year) = numel(find(cpc(latIndsBlueRel, lonIndsBlueRel, year) > prcTCpcBlue & gpcp{3}(latIndsBlueRel, lonIndsBlueRel, year) < prcPGpcpBlue));
    hotDryCpcGpcpWhite(year) = numel(find(cpc(latIndsWhiteRel, lonIndsWhiteRel, year) > prcTCpcWhite & gpcp{3}(latIndsWhiteRel, lonIndsWhiteRel, year) < prcPGpcpWhite));
end

hotDryEra = (hotDryEraBlue + hotDryEraWhite) ./ (length(latIndsBlue)*length(lonIndsBlue) + length(latIndsWhite)*length(lonIndsWhite));
hotDryCpcGpcp = (hotDryCpcGpcpBlue + hotDryCpcGpcpWhite) ./ (length(latIndsBlueRel)*length(lonIndsBlueRel) + length(latIndsWhiteRel)*length(lonIndsWhiteRel));

% 1981 - 2010
for year = 1:size(gldasTemp{3}, 3)
    hotDryGldasBlue(year) = numel(find(gldasTemp{3}(latIndsBlueGldas, lonIndsBlueGldas, year) > prcTGldasBlue & gldasPr{3}(latIndsBlueGldas, lonIndsBlueGldas, year) < prcPGldasBlue));
    hotDryGldasWhite(year) = numel(find(gldasTemp{3}(latIndsWhiteGldas, lonIndsWhiteGldas, year) > prcTGldasWhite & gldasPr{3}(latIndsWhiteGldas, lonIndsWhiteGldas, year) < prcPGldasWhite));
end

hotDryGldas = (hotDryGldasBlue + hotDryGldasWhite) ./ (length(latIndsBlueGldas)*length(lonIndsBlueGldas) + length(latIndsWhiteGldas)*length(lonIndsWhiteGldas));

% 1981 - 2014
for year = 1:size(udelt{3}, 3)
    hotDryUdelBlue(year) = numel(find(udelt{3}(latIndsBlueUdel, lonIndsBlueUdel, year) > prcTUdelBlue & udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, year) < prcPUdelBlue));
    hotDryUdelWhite(year) = numel(find(udelt{3}(latIndsWhiteUdel, lonIndsWhiteUdel, year) > prcTUdelWhite & udelp{3}(latIndsWhiteUdel, lonIndsWhiteUdel, year) < prcPUdelWhite));
end

hotDryUdel = (hotDryUdelBlue + hotDryUdelWhite) ./ (length(latIndsBlueUdel)*length(lonIndsBlueUdel) + length(latIndsWhiteUdel)*length(lonIndsWhiteUdel));

for model = 1:size(cmip5Temp, 4)
    for year = 1:size(cmip5Temp, 3)
        hotDryCmip5Blue(year, model) = numel(find(cmip5Temp(latIndsBlueRel, lonIndsBlueRel, year, model) > prcTCmip5Blue(:, :, model) & cmip5Pr(latIndsBlueRel, lonIndsBlueRel, year, model) < prcPCmip5Blue(:, :, model)));
        hotDryCmip5White(year, model) = numel(find(cmip5Temp(latIndsWhiteRel, lonIndsWhiteRel, year, model) > prcTCmip5White(:, :, model) & cmip5Pr(latIndsWhiteRel, lonIndsWhiteRel, year, model) < prcPCmip5White(:, :, model)));
    end
end

hotDryCmip5 = (hotDryCmip5Blue + hotDryCmip5Blue) ./ (length(latIndsBlueRel)*length(lonIndsBlueRel) + length(latIndsWhiteRel)*length(lonIndsWhiteRel));

% covert to % land area per year
hotDryEra = hotDryEra .* 100;
hotDryCpcGpcp = hotDryCpcGpcp .* 100;
hotDryGldas = hotDryGldas .* 100;
hotDryUdel = hotDryUdel .* 100;
hotDryCmip5 = hotDryCmip5 .* 100;

% hotDryEra = normr(hotDryEra);
% hotDryCpcGpcp = normr(hotDryCpcGpcp);
% hotDryGldas = normr(hotDryGldas);
% hotDryUdel = normr(hotDryUdel);
% hotDryCmip5 = normc(hotDryCmip5);

hdTrendsP = [];
hdTrends = [];
hdTrendsSE = [];
hdTrendsCmip5P = [];
hdTrendsCmip5 = [];
hdTrendsCmip5SE = [];

f = fitlm((1:length(hotDryEra))', hotDryEra', 'linear');
hdTrendsP(1) = f.Coefficients.pValue(2);
hdTrends(1) = f.Coefficients.Estimate(2);
hdTrendsSE(1) = f.Coefficients.SE(2);

f = fitlm((1:length(hotDryGldas))', hotDryGldas', 'linear');
hdTrendsP(2) = f.Coefficients.pValue(2);
hdTrends(2) = f.Coefficients.Estimate(2);
hdTrendsSE(2) = f.Coefficients.SE(2);

f = fitlm((1:length(hotDryUdel))', hotDryUdel', 'linear');
hdTrendsP(3) = f.Coefficients.pValue(2);
hdTrends(3) = f.Coefficients.Estimate(2);
hdTrendsSE(3) = f.Coefficients.SE(2);

f = fitlm((1:length(hotDryCpcGpcp))', hotDryCpcGpcp', 'linear');
hdTrendsP(4) = f.Coefficients.pValue(2);
hdTrends(4) = f.Coefficients.Estimate(2);
hdTrendsSE(4) = f.Coefficients.SE(2);



for model = 1:size(cmip5Temp, 4)
    f = fitlm((1:size(hotDryCmip5, 1))', hotDryCmip5(:, model), 'linear');
    hdTrendsCmip5P(model) = f.Coefficients.pValue(2);
    hdTrendsCmip5(model) = f.Coefficients.Estimate(2);
    hdSECmip5(model) = f.Coefficients.SE(2);
end

% convert to per decade
hdTrends = hdTrends .* 10;
hdTrendsSE = hdTrendsSE .* 10;
hdTrendsCmip5 = hdTrendsCmip5 .* 10;
hdSECmip5 = hdSECmip5 .* 10;

if plotHotDryTrends

    figure('Color',[1,1,1]);
    colors = get(gca, 'colororder');
    legItems = [];
    hold on;
    box on;
    pbaspect([1 2 1]);
    grid on;

    displace = [-.2 -.1 0 .1];
    for d = 1:length(hdTrends)
        e = errorbar(1+displace(d), hdTrends(d), hdTrendsSE(d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(1+displace(d), hdTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);

        legItems(end+1) = p;

        if hdTrendsP(d) < .05
            plot(1+displace(d), hdTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end

    b = boxplot(hdTrendsCmip5', 'positions', [1.2], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    plot([0 2], [0 0], '--k');

    ylabel(['% Land area per decade']);
    ylim([-1 20]);
    xlim([.5 1.5]);
    set(gca, 'FontSize', 36);
    set(gca, 'XTick', [1], 'XTickLabels', {'Hot & dry years'});
    set(gca, 'YTick', -5:5:20);
    legend(legItems, {'ERA-Interim', 'GLDAS', 'UDel', 'CPC-GPCP'}, 'location', 'southwest');

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig('annual-hot-dry-trends-total.eps');
    close all;
end