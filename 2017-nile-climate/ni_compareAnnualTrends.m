
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'ccsm4', ...
              'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fio-esm', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'giss-e2-h', 'giss-e2-h-cc', 'giss-e2-r', 'giss-e2-r-cc', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-lr', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
rcp = 'historical';
timePeriod = [1981 2016];

plotTempPTrends = true;
plotHotDryTrends = true;

if ~exist('eraTemp', 'var')
    fprintf('loading ERA...\n');
    eraTemp = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraTemp{3} = eraTemp{3} - 273.15;
    eraTemp = dailyToMonthly(eraTemp);
    eraTemp{3} = nanmean(eraTemp{3}, 4);
    
    eraPr = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraPr{3} = eraPr{3} .* 1000;
    eraPr = dailyToMonthly(eraPr);
    eraPr{3} = nanmean(eraPr{3}, 4);
    
end

if ~exist('gldasTemp', 'var')
    fprintf('loading GLDAS...\n');
    gldasTemp = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1961, 'endYear', 2010);
    gldasTemp{3} = nanmean(gldasTemp{3} - 273.15, 4);
    
    gldasPr = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1961, 'endYear', 2010);
    gldasPr{3} = gldasPr{3} .* 3600 .* 24;
    gldasPr{3} = nanmean(gldasPr{3}, 4);
end

if ~exist('gpcp', 'var')
    fprintf('loading GPCP...\n');
    gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\regrid\world\1979-2017', 'precip', 'startYear', 1981, 'endYear', 2016);
    gpcp{3} = nanmean(gpcp{3},4);
end

if ~exist('chirps', 'var')
    fprintf('loading CHIRPS...\n');
    chirps = [];
    load lat-chirps;
    load lon-chirps;
    
    % load pre-processed chirps with nile region selected
    for year = 1981:1:2016
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
    cpc = loadMonthlyData('E:\data\cpc-temp-monthly\output\air\monthly', 'air', 'startYear', 1961, 'endYear', 2016);
    
%     cpc = [];
%     for year = timePeriod(1):1:timePeriod(end)
%         fprintf('cpc year %d...\n', year);
%         load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\temp-monthly-cpc-' num2str(year) '.mat']);
%         cpcTemp{3} = cpcTemp{3};
% 
%         if length(cpc) == 0
%             cpc = cpcTemp{3};
%         else
%             cpc = cat(4, cpc, cpcTemp{3});
%         end
% 
%         clear cpcTemp;
%     end
%     cpc = permute(cpc, [1 2 4 3]);
%     cpc = nanmean(cpc, 4);
end

if ~exist('beTemp')
    beTemp = loadMonthlyData('E:\data\BerkeleyEarth\output\temperature\monthly', 'temperature', 'startYear', 1901, 'endYear', 2017);
end

if ~exist('hadcrutTemp')
    hadcrutTemp = loadMonthlyData('E:\data\HadCRUT4\output\temperature_anomaly\monthly', 'temperature_anomaly', 'startYear', 1901, 'endYear', 2017);
end

if ~exist('udelt')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2014);
    udelp = {udelp{1}, udelp{2}, flipud(udelp{3})};
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2014);
    udelt = {udelt{1}, udelt{2}, flipud(udelt{3})};
end

blue = true;

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

latCpc = cpc{1};
lonCpc = cpc{2};
[latIndsBlueCpc, lonIndsBlueCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteCpc, lonIndsWhiteCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

latBe = beTemp{1};
lonBe = beTemp{2};
[latIndsBlueBe, lonIndsBlueBe] = latLonIndexRange({latBe,lonBe,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteBe, lonIndsWhiteBe] = latLonIndexRange({latBe,lonBe,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

latHadcrut = hadcrutTemp{1};
lonHadcrut = hadcrutTemp{2};
[latIndsBlueHadcrut, lonIndsBlueHadcrut] = latLonIndexRange({latHadcrut,lonHadcrut,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteHadcrut, lonIndsWhiteHadcrut] = latLonIndexRange({latHadcrut,lonHadcrut,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

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
        t = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\tas\regrid\world'], 'tas', 'startYear', 1981, 'endYear', 2004);
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
        p = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\pr\regrid\world'], 'pr', 'startYear', 1981, 'endYear', 2004);
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
    
    curLatIndsHadcrut = latIndsBlueHadcrut;
    curLonIndsHadcrut = lonIndsBlueHadcrut;
    
    curLatIndsBe = latIndsBlueBe;
    curLonIndsBe = lonIndsBlueBe;
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
    
    curLatIndsHadcrut = latIndsWhiteHadcrut;
    curLonIndsHadcrut = lonIndsWhiteHadcrut;
    
    curLatIndsBe = latIndsWhiteBe;
    curLonIndsBe = lonIndsWhiteBe;
end

curLatInds = [latIndsBlue latIndsWhite];
curLonInds = [lonIndsBlue lonIndsWhite];

curLatIndsRel = [latIndsBlueRel latIndsWhiteRel];
curLonIndsRel = [lonIndsBlueRel lonIndsWhiteRel];

curLatIndsChirpsRel = [latIndsBlueChirpsRel latIndsWhiteChirpsRel];
curLonIndsChirpsRel = [lonIndsBlueChirpsRel lonIndsWhiteChirpsRel];

curLatIndsGldas = [latIndsBlueGldas latIndsWhiteGldas];
curLonIndsGldas = [lonIndsBlueGldas lonIndsWhiteGldas];

curLatIndsCpc = [lonIndsBlueCpc lonIndsWhiteCpc];
curLonIndsCpc = [lonIndsBlueCpc lonIndsWhiteCpc];

curLatIndsUdel = [latIndsBlueUdel latIndsWhiteUdel];
curLonIndsUdel = [lonIndsBlueUdel lonIndsWhiteUdel];

curLatIndsHadcrut = [latIndsBlueHadcrut latIndsWhiteHadcrut];
curLonIndsHadcrut = [lonIndsBlueHadcrut lonIndsWhiteHadcrut];

curLatIndsBe = [latIndsBlueBe latIndsWhiteBe];
curLonIndsBe = [lonIndsBlueBe lonIndsWhiteBe];

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
       
regionalTEra = squeeze(nanmean(nanmean(nanmean(eraTemp{3}(curLatInds, curLonInds, :, :), 2), 1), 4));
regionalTGldas = squeeze(nanmean(nanmean(nanmean(gldasTemp{3}(curLatIndsGldas, curLonIndsGldas, :, :), 2), 1), 4));
regionalTCpc = squeeze(nanmean(nanmean(nanmean(cpc{3}(curLatIndsCpc, curLonIndsCpc, :, :), 2), 1), 4));
regionalTUdel = squeeze(nanmean(nanmean(nanmean(udelt{3}(curLatIndsUdel, curLonIndsUdel, :, :), 2), 1), 4));
regionalTHadcrut = squeeze(nanmean(nanmean(nanmean(hadcrutTemp{3}(curLatIndsHadcrut, curLonIndsHadcrut, :, :), 2), 1), 4));
regionalTBe = squeeze(nanmean(nanmean(nanmean(beTemp{3}(curLatIndsBe, curLonIndsBe, :, :), 2), 1), 4));
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

f = fitlm((1:length(regionalTHadcrut))', regionalTHadcrut, 'linear');
tempTrendsP(4) = f.Coefficients.pValue(2);
tempTrends(4) = f.Coefficients.Estimate(2);
tempSE(4) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalTBe))', regionalTBe, 'linear');
tempTrendsP(5) = f.Coefficients.pValue(2);
tempTrends(5) = f.Coefficients.Estimate(2);
tempSE(5) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalTCpc))', regionalTCpc, 'linear');
tempTrendsP(6) = f.Coefficients.pValue(2);
tempTrends(6) = f.Coefficients.Estimate(2);
tempSE(6) = f.Coefficients.SE(2);


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
       
regionalPEra = squeeze(nanmean(nanmean(nanmean(eraPr{3}(curLatInds, curLonInds, :, :), 2), 1), 4));
regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldasPr{3}(curLatIndsGldas, curLonIndsGldas, :, :), 2), 1), 4));
regionalPGpcp = squeeze(nanmean(nanmean(nanmean(gpcp{3}(curLatInds, curLonInds, :, :), 2), 1), 4));
regionalPChirps = squeeze(nanmean(nanmean(nanmean(chirps(curLatIndsChirpsRel, curLonIndsChirpsRel, :, :), 2), 1), 4));
regionalPUdel = squeeze(nanmean(nanmean(nanmean(udelp{3}(curLatIndsUdel, curLonIndsUdel, :, :), 2), 1), 4));
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

colors = distinguishable_colors(9) .* .75;% get(fig, 'defaultaxescolororder');
legItems = [];
if plotTempPTrends
    
    fig = figure('Color',[1,1,1]);
    
    hold on;
    box on;
    axis square;
    set(gca, 'YGrid', 'on');

    yyaxis left;
    displace = [-.35 -.25 -.15 -.05 .05 .15];
    for d = 1:length(tempTrendsP)
        e = errorbar(1+displace(d), tempTrends(d), tempSE(d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(1+displace(d), tempTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);

        legItems(end+1) = p;
        set(legItems(end), 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));

        if tempTrendsP(d) < .05
            plot(1+displace(d), tempTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :), 'LineWidth', 2);
        else
            plot(1+displace(d), tempTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', 'w', 'Color', colors(d, :), 'LineWidth', 2);
        end
    end

    b = boxplot(tempTrendsCmip5', 'positions', [1.25], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    ylabel([char(176) 'C/decade']);
    ylim([-1 1]);
    xlim([.5 2.5]);

    % skip color 4 (for cpc) so that 2 unique pr datasets have their own
    % colors
    colors(4,:)=colors(7,:);
    colors(5,:)=colors(8,:);

    yyaxis right;
    displace = [-.25 -.15 -.05 .05 .15];
    for d = 1:length(prTrends)
            e = errorbar(2+displace(d), prTrends(d), prSE(d), 'Color', colors(d,:), 'LineWidth', 2);
            p = plot(2+displace(d), prTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
            if d >= 4
                legItems(end+1) = p;
                set(legItems(end), 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
            end
            if prTrendsP(d) < .05
                plot(2+displace(d), prTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :), 'LineWidth', 2);
            else
                plot(2+displace(d), prTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', 'w', 'Color', colors(d, :), 'LineWidth', 2);
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
tprc = 83;
pprc = 25;


prcTEra = prctile(regionalTEra, tprc);
prcPEra = prctile(regionalPEra, pprc);

prcTGldas = prctile(regionalTGldas, tprc);
prcPGldas = prctile(regionalPGldas, pprc);

prcTCpc = prctile(regionalTCpc, tprc);
prcPGpcp = prctile(regionalPGpcp, pprc);

prcTUdel = prctile(regionalTUdel, tprc);
prcPUdel = prctile(regionalPUdel, pprc);

prcTHadcrut = prctile(regionalTHadcrut, tprc);
prcTBe = prctile(regionalTBe, tprc);

prcTCmip5 = prctile(regionalTCmip5, tprc, 1);
prcPCmip5 = prctile(regionalPCmip5, pprc, 1);

% 1981 - 2016 time period
hotDryEra = regionalTEra > prcTEra & regionalPEra < prcPEra;
hotDryCpcGpcp = regionalTCpc(21:end) > prcTCpc & regionalPGpcp < prcPGpcp;

% 1981 - 2010
hotDryGldas = regionalTGldas > prcTGldas & regionalPGldas < prcPGldas;

% 1981 - 2014
hotDryUdel = regionalTUdel > prcTUdel & regionalPUdel < prcPUdel;

hotDryCmip5 = [];
for model = 1:size(cmip5Temp, 4)
    hotDryCmip5(:, model) = regionalTCmip5(:, model) > prcTCmip5(model) & regionalPCmip5(:, model) < prcPCmip5(model);
end

% tSuper = [regionalTEra(1:2010-1981+1), regionalTGldas(1981-1960+1:end), regionalTUdel(1981-1901+1:2010-1901+1), ...
%           regionalTCpc(1:2010-1981+1), regionalTHadcrut(1981-1901+1:2010-1901+1), regionalTBe(1981-1901+1:2010-1901+1)];
% tSuperPrc = [prctile(regionalTEra(1:2005-1981+1), tprc), prctile(regionalTGldas(1981-1960+1:2005-1981+1), tprc), prctile(regionalTUdel(1981-1901+1:2005-1901+1), tprc), ...
%           prctile(regionalTCpc(1:2005-1981+1), tprc), prctile(regionalTHadcrut(1981-1901+1:2005-1901+1), tprc), prctile(regionalTBe(1981-1901+1:2005-1901+1), tprc)];
% 
% pSuper = [regionalPEra(1:2010-1981+1) regionalPGldas(1981-1960+1:end), regionalPUdel(1981-1901+1:2010-1901+1), ...
%           regionalPGpcp(1:2010-1981+1), regionalPChirps(1:2010-1981+1)];
% pSuperPrc = [prctile(regionalPEra(1:2005-1981+1), pprc) prctile(regionalPGldas(1981-1960+1:2005-1960+1), pprc), prctile(regionalPUdel(1981-1901+1:2005-1901+1), pprc), ...
%           prctile(regionalPGpcp(1:2005-1981+1), pprc), prctile(regionalPChirps(1:2005-1981+1), pprc)];
% superEnsemble = {tSuper, tSuperPrc, pSuper, pSuperPrc};
% save('nile-super-ensemble-blue.mat', 'superEnsemble');

superEndYr = 2016;
superStartYr = 1981;

tSuper = [regionalTCpc(superStartYr-1961+1:superEndYr-1961+1), regionalTHadcrut(superStartYr-1901+1:superEndYr-1901+1), regionalTBe(superStartYr-1901+1:superEndYr-1901+1)];
tSuperPrc = [prctile(regionalTCpc(1:superEndYr-1981+1), tprc), prctile(regionalTHadcrut(superStartYr-1901+1:superEndYr-1901+1), tprc), prctile(regionalTBe(superStartYr-1901+1:superEndYr-1901+1), tprc)];

pSuper = [regionalPGpcp(1:superEndYr-1981+1), regionalPChirps(1:superEndYr-1981+1)];
pSuperPrc = [prctile(regionalPGpcp(1:superEndYr-1981+1), pprc), prctile(regionalPChirps(1:superEndYr-1981+1), pprc)];
superEnsemble = {tSuper, tSuperPrc, pSuper, pSuperPrc};

hdTrendsSuper = [];
hdTrendsSuperP = [];
hdTrendsSuperSE = [];
for t = 1:size(tSuper, 2)
    for p = 1:size(pSuper, 2)
        curHd = tSuper(:, t) > tSuperPrc(t) & pSuper(:, p) < pSuperPrc(p);
        f = fitlm((1:length(curHd))', curHd', 'linear');
        hdTrendsSuperP(t, p) = f.Coefficients.pValue(2);
        hdTrendsSuper(t, p) = f.Coefficients.Estimate(2);
        hdTrendsSuperSE(t, p) = f.Coefficients.SE(2);
    end
end

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
hdTrendsSuper = hdTrendsSuper .* 10;
hdTrendsSuperSE = hdTrendsSuperSE .* 10;

if plotHotDryTrends
    colors = distinguishable_colors(9) .* .75;% get(fig, 'defaultaxescolororder');
    
    fig2 = figure('Color',[1,1,1]);
    hold on;
    box on;
    pbaspect([1 2 1]);
    set(gca, 'YGrid', 'on');

    colors(4,:) = colors(9,:);
    
    displace = [-.25 -.13 -.01];
    for d = 1:length(hdTrends)
        e = errorbar(1+displace(d), hdTrends(d), hdTrendsSE(d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(1+displace(d), hdTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', colors(d, :));

        if hdTrendsP(d) < .05
            plot(1+displace(d), hdTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :), 'LineWidth', 2);
        else
            plot(1+displace(d), hdTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', [1 1 1], 'Color', colors(d, :), 'LineWidth', 2);
        end
    end

    plot([1.15 1.15], [-2 2], '-k');
    
    b = boxplot(reshape(hdTrendsSuper, [numel(hdTrendsSuper), 1]), 'positions', [1.34], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [0 0 0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    
    b = boxplot(hdTrendsCmip5', 'positions', [1.48], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    plot([0 2], [0 0], '--k');

    ylabel(['# Years per decade']);
    ylim([-.2 .3]);
    xlim([.55 1.75]);
    set(gca, 'FontSize', 36);
    set(gca, 'XTick', [1.15], 'XTickLabels', {'Hot & dry years'});
    set(gca, 'YTick', -.2:.1:.3);
    %legend(legItems, {'ERA-Interim', 'GLDAS', 'UDel', 'HadCRUT4', 'BerkeleyEarth', 'CPC', 'GPCP', 'CHIRPS-2'}, 'numColumns', 5);

    set(gcf, 'Position', get(0,'Screensize'));
    export_fig('annual-hot-dry-trends-total.eps');
    close all;
end


