
load lat;
load lon;


[regionInds, regions, regionNames] = ni_getRegions();
regionBounds = regions('nile');
regionBoundsBlue = regions('nile-blue');
regionBoundsWhite = regions('nile-white');



models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'ccsm4', ...
              'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fio-esm', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'giss-e2-h', 'giss-e2-h-cc', 'giss-e2-r', 'giss-e2-r-cc', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-lr', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

timePeriod = [1981 2016];
          

if ~exist('era', 'var')
    fprintf('loading ERA...\n');
    eraMx = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    eraMx{3} = eraMx{3} - 273.15;
    
    
    eraMn = loadDailyData('E:\data\era-interim\output\mn2t\regrid\world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    eraMn{3} = eraMn{3} - 273.15;
    
    era = {eraMx{1}, eraMx{2}, (eraMx{3}+eraMn{3})./2};
    era = dailyToMonthly(era);
    
    eraPr = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    eraPr{3} = eraPr{3} .* 1000;
    eraPr = dailyToMonthly(eraPr);
end

if ~exist('gpcp', 'var')
    fprintf('loading GPCP...\n');
    gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\regrid\world\1979-2017', 'precip', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
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
end

if ~exist('gldas', 'var')
    fprintf('loading GLDAS...\n');
    gldas = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', timePeriod(1), 'endYear', 2010);
    gldas{3} = gldas{3} - 273.15;

    gldasPr = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', timePeriod(1), 'endYear', 2010);
    gldasPr{3} = gldasPr{3} .* 3600 .* 24;
end

if ~exist('cpc', 'var')   
   
    
    cpc = loadMonthlyData('E:\data\cpc-temp-monthly\output\air\monthly', 'air', 'startYear', 1981, 'endYear', 2016);
    cpc{3} = cpc{3}-273.15;

end


latCpc = cpc{1};
lonCpc = cpc{2};
[latIndsBlueCpc, lonIndsBlueCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteCpc, lonIndsWhiteCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

latGldas = gldas{1};
lonGldas = gldas{2};
[latIndsBlueGldas, lonIndsBlueGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteGldas, lonIndsWhiteGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

% latUdel = udelt{1};
% lonUdel = udelt{2};
% [latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({latUdel,lonUdel,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
% [latIndsWhiteUdel, lonIndsWhiteUdel] = latLonIndexRange({latUdel,lonUdel,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
% 
% latBe = beTemp{1};
% lonBe = beTemp{2};
% [latIndsBlueBe, lonIndsBlueBe] = latLonIndexRange({latBe,lonBe,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
% [latIndsWhiteBe, lonIndsWhiteBe] = latLonIndexRange({latBe,lonBe,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
% 
% latHadcrut = hadcrutTemp{1};
% lonHadcrut = hadcrutTemp{2};
% [latIndsBlueHadcrut, lonIndsBlueHadcrut] = latLonIndexRange({latHadcrut,lonHadcrut,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
% [latIndsWhiteHadcrut, lonIndsWhiteHadcrut] = latLonIndexRange({latHadcrut,lonHadcrut,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

[latIndsChirps, lonIndsChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsBlueChirps, lonIndsBlueChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteChirps, lonIndsWhiteChirps] = latLonIndexRange({latChirps,lonChirps,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
latIndsWhiteChirpsRel = latIndsWhiteChirps-latIndsChirps(1)+1;
latIndsBlueChirpsRel = latIndsBlueChirps-latIndsChirps(1)+1;
lonIndsWhiteChirpsRel = lonIndsWhiteChirps-lonIndsChirps(1)+1;
lonIndsBlueChirpsRel = lonIndsBlueChirps-lonIndsChirps(1)+1;

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
        t = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\tas\regrid\world'], 'tas', 'startYear', 1981, 'endYear', 2005);
        if nanmean(nanmean(nanmean(nanmean(t{3})))) > 100
            t{3} = t{3} - 273.15;
        end

        cmip5Temp(:,:,:,:,m) = t{3};%cat(3, t, t2);
    end
    
    cmip5Pr = [];
    for m = 1:length(models)
        fprintf('processing %s...\n', models{m});
        p = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\historical\pr\regrid\world'], 'pr', 'startYear', 1981, 'endYear', 2005);
        p{3} = p{3} .* 3600 .* 24;

        cmip5Pr(:,:,:,:,m) = p{3};%cat(3, p, p2);
    end
end


seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

blue = true;
       

if blue
    curLatInds = latIndsBlue;
    curLonInds = lonIndsBlue;
    
    curLatIndsRel = latIndsBlueRel;
    curLonIndsRel = lonIndsBlueRel;
    
    curLatIndsChirpsRel = latIndsBlueChirpsRel;
    curLonIndsChirpsRel = lonIndsBlueChirpsRel;
%     
    curLatIndsGldas = latIndsBlueGldas;
    curLonIndsGldas = lonIndsBlueGldas;
    
    curLatIndsCpc = latIndsBlueCpc;
    curLonIndsCpc = lonIndsBlueCpc;
    
%     curLatIndsUdel = latIndsBlueUdel;
%     curLonIndsUdel = lonIndsBlueUdel;
    
%     curLatIndsHadcrut = latIndsBlueHadcrut;
%     curLonIndsHadcrut = lonIndsBlueHadcrut;
%     
%     curLatIndsBe = latIndsBlueBe;
%     curLonIndsBe = lonIndsBlueBe;
else
    curLatInds = latIndsWhite;
    curLonInds = lonIndsWhite;
    
    curLatIndsRel = latIndsWhiteRel;
    curLonIndsRel = lonIndsWhiteRel;
    
    curLatIndsCpc = latIndsWhiteCpc;
    curLonIndsCpc = lonIndsWhiteCpc;
    
    curLatIndsChirpsRel = latIndsWhiteChirpsRel;
    curLonIndsChirpsRel = lonIndsWhiteChirpsRel;
    
    curLatIndsGldas = latIndsWhiteGldas;
    curLonIndsGldas = lonIndsWhiteGldas;
    
%     curLatIndsUdel = latIndsWhiteUdel;
%     curLonIndsUdel = lonIndsWhiteUdel;
    
%     curLatIndsHadcrut = latIndsWhiteHadcrut;
%     curLonIndsHadcrut = lonIndsWhiteHadcrut;
%     
%     curLatIndsBe = latIndsWhiteBe;
%     curLonIndsBe = lonIndsWhiteBe;
end


colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;



fig = figure('Color', [1,1,1]);
set(fig,'defaultAxesColorOrder',[colorHd; colorW]);
hold on;
axis square;

box on;
grid on;
    
for season = 1:size(seasons, 1)
    
    yyaxis left;
    regionalTEra = squeeze(nanmean(nanmean(nanmean(nanmean(era{3}(curLatInds, curLonInds, :, seasons(season,:)), 4), 2), 1), 3));
    regionalTCpc = squeeze(nanmean(nanmean(nanmean(nanmean(cpc{3}(curLatIndsCpc, curLonIndsCpc, :, seasons(season,:)), 4), 2), 1), 3));
    regionalTGldas = squeeze(nanmean(nanmean(nanmean(nanmean(gldas{3}(curLatIndsGldas, curLonIndsGldas, :, seasons(season,:)), 4), 2), 1), 3));
    regionalTCmip5 = squeeze(nanmean(nanmean(nanmean(nanmean(cmip5Temp(curLatInds, curLonInds, :, seasons(season,:), :), 4), 3), 2), 1));

    b = boxplot(regionalTCmip5, 'positions', [season-.12], 'width', .2);
    set(b, {'LineWidth', 'Color'}, {2, colorHd})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [.3 .3 .3], 'LineWidth', 2); 
    
    p1 = plot(season-.12, regionalTGldas, '*', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    p2 = plot(season-.12, regionalTEra, 'x', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    p3 = plot(season-.12, regionalTCpc, 'd', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    
    
    
    yyaxis right;
    regionalPGpcp = squeeze(nanmean(nanmean(nanmean(nanmean(gpcp{3}(curLatInds, curLonInds, :, seasons(season,:)), 3), 4), 2), 1));
    regionalPChirps = squeeze(nanmean(nanmean(nanmean(nanmean(chirps(curLatIndsChirpsRel, curLonIndsChirpsRel, :, seasons(season,:)), 3), 4), 2), 1));
    regionalPEra = squeeze(nanmean(nanmean(nanmean(nanmean(eraPr{3}(curLatInds, curLonInds, :, seasons(season,:)), 4), 2), 1), 3));
    regionalPCmip5 = squeeze(nanmean(nanmean(nanmean(nanmean(cmip5Pr(curLatInds, curLonInds, :, seasons(season,:), :), 4), 3), 2), 1));

    b = boxplot(regionalPCmip5, 'positions', [season+.12], 'width', .2);
    set(b, {'LineWidth', 'Color'}, {2, colorW})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [.3 .3 .3], 'LineWidth', 2); 
        
    p4 = plot(season+.12, regionalPEra, 'x', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    p5 = plot(season+.12, regionalPGpcp, '+', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    p6 = plot(season+.12, regionalPChirps, 's', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    
end

xlim([0 5]);
yyaxis left;
ylim([15 35]);
ylabel(['Temperature (' char(176) 'C)']);
yyaxis right;
ylim([0 9]);
ylabel(['Precipitation (mm/day)']);
leg = legend([p1, p2, p3, p5, p6], ' GLDAS', ' ERA-Interim', ' CPC', ' GPCP', ' CHIRPS', 'location', 'northwest', 'NumColumns', 2);
set(leg, 'fontsize', 30);
legend boxoff;
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

set(gca, 'FontSize', 40);
set(gcf, 'Position', get(0,'Screensize'));
export_fig temp-pr-verification-blue.eps
close all




fig = figure('Color', [1,1,1]);
hold on;
axis square;

box on;
grid on;
    
for season = 1:size(seasons, 1)
    
    regionalTEra = squeeze(nanmean(nanmean(nanmean(era{3}(curLatInds, curLonInds, :, seasons(season,:)), 4), 2), 1));
    regionalTCpc = squeeze(nanmean(nanmean(nanmean(cpc{3}(curLatIndsCpc, curLonIndsCpc, :, seasons(season,:)), 4), 2), 1));
    regionalTGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(curLatIndsGldas, curLonIndsGldas, :, seasons(season,:)), 4), 2), 1));
    regionalTCmip5 = squeeze(nanmean(nanmean(nanmean(cmip5Temp(curLatInds, curLonInds, :, seasons(season,:), :), 4), 2), 1));

    regionalPGpcp = squeeze(nanmean(nanmean(nanmean(gpcp{3}(curLatInds, curLonInds, :, seasons(season,:)), 4), 2), 1));
    regionalPEra = squeeze(nanmean(nanmean(nanmean(eraPr{3}(curLatInds, curLonInds, :, seasons(season,:)), 4), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldasPr{3}(curLatIndsGldas, curLonIndsGldas, :, seasons(season,:)), 4), 2), 1));
    regionalPCmip5 = squeeze(nanmean(nanmean(nanmean(cmip5Pr(curLatInds, curLonInds, :, seasons(season,:), :), 4), 2), 1));

    cmip5Corr = [];
    for m = 1:length(models)
        cmip5Corr(m) = corr(detrend(regionalTCmip5(:,m)-mean(regionalTCmip5(:,m))), detrend(regionalPCmip5(:,m)-mean(regionalPCmip5(:,m))));
    end
    
    b = boxplot(cmip5Corr, 'positions', [season], 'width', .2);
    set(b, {'LineWidth', 'Color'}, {2, colorHd})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [.3 .3 .3], 'LineWidth', 2); 
        
    p2 = plot(season, nancorr(detrend(regionalTEra-nanmean(regionalTEra)), detrend(regionalPEra-nanmean(regionalPEra))), 'x', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    p3 = plot(season, nancorr(detrend(regionalTGldas-mean(regionalTGldas)), detrend(regionalPGldas-mean(regionalPGldas))), '+', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    p4 = plot(season, nancorr(detrend(regionalTCpc-mean(regionalTCpc)), detrend(regionalPGpcp-mean(regionalPGpcp))), 's', 'Color', 'k','MarkerSize', 15, 'LineWidth', 2);
    
end

xlim([0 5]);
ylim([-1 1]);
plot([0 5], [0 0], '--k', 'linewidth', 2);
ylabel(['T-P Correlation']);
leg = legend([p2, p3, p4], ' ERA-Interim', ' GLDAS', ' CPC-GPCP', 'location', 'northeast');
set(leg, 'fontsize', 30);
legend boxoff;
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

set(gca, 'FontSize', 40);
set(gcf, 'Position', get(0,'Screensize'));
export_fig t-p-corr-verification-blue.eps
close all

