
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
rcp = 'historical';
timePeriod = [1981 2016];

plotTempPTrends = true;
plotHotDryTrends = false;

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
    gldasTemp = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1981, 'endYear', 2010);
    gldasTemp{3} = nanmean(gldasTemp{3} - 273.15, 4);
    
    gldasPr = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1981, 'endYear', 2010);
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

north = true;

regionBounds = [[2 32]; [25, 44]];
regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

latGldas = gldasTemp{1};
lonGldas = gldasTemp{2};
[latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

[latIndsChirps, lonIndsChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorthChirps, lonIndsNorthChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthChirps, lonIndsSouthChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsSouthChirpsRel = latIndsSouthChirps-latIndsChirps(1)+1;
latIndsNorthChirpsRel = latIndsNorthChirps-latIndsChirps(1)+1;
lonIndsSouthChirpsRel = lonIndsSouthChirps-lonIndsChirps(1)+1;
lonIndsNorthChirpsRel = lonIndsNorthChirps-lonIndsChirps(1)+1;

load lat;
load lon;

[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsSouthRel = latIndsSouth-latInds(1)+1;
latIndsNorthRel = latIndsNorth-latInds(1)+1;
lonIndsSouthRel = lonIndsSouth-lonInds(1)+1;
lonIndsNorthRel = lonIndsNorth-lonInds(1)+1;


if ~exist('cmip5Temp', 'var')
    cmip5Temp = [];
    for m = 1:length(models)
        fprintf('processing %s...\n', models{m});
        t = loadDailyData(['E:\data\cmip5\output\' models{m} '\r1i1p1\historical\tasmax\regrid\world'], 'startYear', 1981, 'endYear', 2005);
        %t2 = loadDailyData(['E:\data\cmip5\output\' models{m} '\r1i1p1\rcp85\tasmax\regrid\world'], 'startYear', 2006, 'endYear', 2016);
        t = dailyToMonthly(t);
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
        p = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\pr\regrid\world'], 'pr', 'startYear', 1981, 'endYear', 2005);
        %p2 = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\rcp85\pr\regrid\world'], 'pr', 'startYear', 2006, 'endYear', 2016);
        p{3} = p{3} .* 3600 .* 24;
        %p2{3} = p2{3} .* 3600 .* 24;
        p = nanmean(p{3}(latInds, lonInds, :, :), 4);
        %p2 = nanmean(p2{3}(latInds, lonInds, :, :), 4);

        cmip5Pr(:,:,:,m) = p;%cat(3, p, p2);
    end
end

if north
    curLatInds = latIndsNorth;
    curLonInds = lonIndsNorth;
    
    curLatIndsRel = latIndsNorthRel;
    curLonIndsRel = lonIndsNorthRel;
    
    curLatIndsChirpsRel = latIndsNorthChirpsRel;
    curLonIndsChirpsRel = lonIndsNorthChirpsRel;
    
    curLatIndsGldas = latIndsNorthGldas;
    curLonIndsGldas = lonIndsNorthGldas;
else
    curLatInds = latIndsSouth;
    curLonInds = lonIndsSouth;
    
    curLatIndsRel = latIndsSouthRel;
    curLonIndsRel = lonIndsSouthRel;
    
    curLatIndsChirpsRel = latIndsSouthChirpsRel;
    curLonIndsChirpsRel = lonIndsSouthChirpsRel;
    
    curLatIndsGldas = latIndsSouthGldas;
    curLonIndsGldas = lonIndsSouthGldas;
end

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

load('hottest-season-ncep.mat');
hottestSeasonNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSeasonSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));
       
tempTrends = [];
tempTrendsP = [];
tempTrendsCmip5 = [];
tempTrendsPCmip5 = [];
tempSE = [];
       
regionalTEra = squeeze(nanmean(nanmean(eraTemp{3}(curLatInds, curLonInds, :), 2), 1));
regionalTGldas = squeeze(nanmean(nanmean(gldasTemp{3}(curLatIndsGldas, curLonIndsGldas, :), 2), 1));
regionalTCpc = squeeze(nanmean(nanmean(cpc(curLatIndsRel, curLonIndsRel, :), 2), 1));
regionalTCmip5 = squeeze(nanmean(nanmean(cmip5Temp(curLatIndsRel, curLonIndsRel, :, :), 2), 1));

f = fitlm((1:length(regionalTEra))', regionalTEra, 'linear');
tempTrendsP(1) = f.Coefficients.pValue(2);
tempTrends(1) = f.Coefficients.Estimate(2);
tempSE(1) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalTGldas))', regionalTGldas, 'linear');
tempTrendsP(2) = f.Coefficients.pValue(2);
tempTrends(2) = f.Coefficients.Estimate(2);
tempSE(2) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalTCpc))', regionalTCpc, 'linear');
tempTrendsP(3) = f.Coefficients.pValue(2);
tempTrends(3) = f.Coefficients.Estimate(2);
tempSE(3) = f.Coefficients.SE(2);

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
regionalPCmip5 = squeeze(nanmean(nanmean(cmip5Pr(curLatIndsRel, curLonIndsRel, :, :), 2), 1));

f = fitlm((1:length(regionalPEra))', regionalPEra, 'linear');
prTrendsP(1) = f.Coefficients.pValue(2);
prTrends(1) = f.Coefficients.Estimate(2);
prSE(1) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPGldas))', regionalPGldas, 'linear');
prTrendsP(2) = f.Coefficients.pValue(2);
prTrends(2) = f.Coefficients.Estimate(2);
prSE(2) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPGpcp))', regionalPGpcp, 'linear');
prTrendsP(3) = f.Coefficients.pValue(2);
prTrends(3) = f.Coefficients.Estimate(2);
prSE(3) = f.Coefficients.SE(2);

f = fitlm((1:length(regionalPChirps))', regionalPChirps, 'linear');
prTrendsP(4) = f.Coefficients.pValue(2);
prTrends(4) = f.Coefficients.Estimate(2);
prSE(4) = f.Coefficients.SE(2);

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
    temp = colors(1,:);
    colors(1,:) = colors(2,:);
    colors(2,:) = temp;
    set(fig, 'defaultaxescolororder', colors);
    
    legItems = [];
    hold on;
    box on;
    axis square;
    grid on;

    yyaxis left;
    displace = [-.15 -.05 .05];
    for d = 1:length(tempTrendsP)
        e = errorbar(1+displace(d), tempTrends(d), tempSE(d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(1+displace(d), tempTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);

        legItems(end+1) = p;

        if tempTrendsP(d) < .05
            plot(1+displace(d), tempTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end

    b = boxplot(tempTrendsCmip5', 'positions', [1.15], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    ylabel([char(176) 'C/decade']);
    ylim([-1 1]);
    xlim([.5 2.5]);

    colors(3,:)=colors(4,:);
    colors(4,:)=colors(5,:);

    yyaxis right;
    displace = [-.2 -.1 0 .1];
    for d = 1:length(prTrends)
            e = errorbar(2+displace(d), prTrends(d), prSE(d), 'Color', colors(d,:), 'LineWidth', 2);
            p = plot(2+displace(d), prTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
            if d >= 3
                legItems(end+1) = p;
            end
            if prTrendsP(d) < .05
                plot(2+displace(d), prTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
            end
    end

    b = boxplot(prTrendsCmip5', 'positions', [2.2], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    ylabel('mm/day/decade');
    plot([0 3], [0 0], 'k--');
    plot([1.5 1.5], [-10 10], 'k');
    ylim([-.3 .3]);

    xlim([.5 2.5]);
    set(gca, 'FontSize', 40);
    set(gca, 'XTick', [1 2], 'XTickLabels', {'Temperature', 'Precipitation'});
    set(gca, 'YTick', -.3:.1:.3);
    legend(legItems, {'ERA-Interim', 'GLDAS', 'CPC', 'GPCP', 'CHIRPS-2'}, 'location', 'northeast');
    set(gcf, 'Position', get(0,'Screensize'));
    if north
        export_fig('annual-temp-pr-trends-north.eps');
    else
        export_fig('annual-temp-pr-trends-south.eps');
    end
    close all;
end



% hot/dry trends ----------------------------------------------------------

prcTEra = prctile(eraTemp{3}(curLatInds, curLonInds, :), 90, 3);
prcPEra = prctile(eraPr{3}(curLatInds, curLonInds, :), 10, 3);

prcTGldas = prctile(gldasTemp{3}(curLatIndsGldas, curLonIndsGldas, :), 90, 3);
prcPGldas = prctile(gldasPr{3}(curLatIndsGldas, curLonIndsGldas, :), 10, 3);

prcTCpc = prctile(cpc(curLatIndsRel, curLonIndsRel, :), 90, 3);
prcPGpcp = prctile(gpcp{3}(curLatIndsRel, curLonIndsRel, :), 10, 3);

prcTCmip5 = squeeze(prctile(cmip5Temp(curLatIndsRel, curLonIndsRel, :, :), 90, 3));
prcPCmip5 = squeeze(prctile(cmip5Pr(curLatIndsRel, curLonIndsRel, :, :), 10, 3));

% 1981 - 2016 time period
for year = 1:(timePeriod(end)-timePeriod(1)+1)
    hotDryEra(year) = numel(find(eraTemp{3}(curLatInds, curLonInds, year) > prcTEra & eraPr{3}(curLatInds, curLonInds, year) < prcPEra));
    hotDryCpcGpcp(year) = numel(find(cpc(curLatIndsRel, curLonIndsRel, year) > prcTCpc & gpcp{3}(curLatIndsRel, curLonIndsRel, year) < prcPGpcp));
end

% 1981 - 2010
for year = 1:size(gldasTemp{3}, 3)
    hotDryGldas(year) = numel(find(gldasTemp{3}(curLatIndsGldas, curLonIndsGldas, year) > prcTGldas & gldasPr{3}(curLatIndsGldas, curLonIndsGldas, year) < prcPGldas));
end

for model = 1:size(cmip5Temp, 4)
    for year = 1:size(cmip5Temp, 3)
        hotDryCmip5(year, model) = numel(find(cmip5Temp(curLatIndsRel, curLonIndsRel, year, model) > prcTCmip5(:, :, model) & cmip5Pr(curLatIndsRel, curLonIndsRel, year, model) < prcPCmip5(:, :, model)));
    end
end

hotDryEra = normr(hotDryEra);
hotDryCpcGpcp = normr(hotDryCpcGpcp);
hotDryGldas = normr(hotDryGldas);
hotDryCmip5 = normc(hotDryCmip5);

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

f = fitlm((1:length(hotDryCpcGpcp))', hotDryCpcGpcp', 'linear');
hdTrendsP(3) = f.Coefficients.pValue(2);
hdTrends(3) = f.Coefficients.Estimate(2);
hdTrendsSE(3) = f.Coefficients.SE(2);

for model = 1:size(cmip5Temp, 4)
    f = fitlm((1:size(hotDryCmip5, 1))', hotDryCmip5(:, model), 'linear');
    hdTrendsCmip5P(model) = f.Coefficients.pValue(2);
    hdTrendsCmip5(model) = f.Coefficients.Estimate(2);
    hdSECmip5(model) = f.Coefficients.SE(2);
end


if plotHotDryTrends

    figure('Color',[1,1,1]);
    colors = get(gca, 'colororder');
    legItems = [];
    hold on;
    box on;
    axis square;
    grid on;

    displace = [-.15 -.05 .05];
    for d = 1:length(hdTrends)
        e = errorbar(1+displace(d), hdTrends(d), hdTrendsSE(d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(1+displace(d), hdTrends(d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);

        legItems(end+1) = p;

        if hdTrendsP(d) < .05
            plot(1+displace(d), hdTrends(d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end

    b = boxplot(hdTrendsCmip5', 'positions', [1.15], 'widths', [.1]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    plot([0 2], [0 0], '--k');

    ylabel(['Normalized trend']);
    ylim([-.015 .015]);
    xlim([.5 1.5]);
    set(gca, 'FontSize', 40);
    set(gca, 'XTick', [1], 'XTickLabels', {'Hot & dry years'});
    set(gca, 'YTick', -.015:.005:.015);
    legend(legItems, {'ERA-Interim', 'GLDAS', 'CPC-GPCP'}, 'location', 'southwest');
    set(gcf, 'Position', get(0,'Screensize'));
    if north
        export_fig('annual-hot-dry-trends-north.eps');
    else
        export_fig('annual-hot-dry-trends-south.eps');
    end
    close all;
end