timePeriod = [1980 2016];
numYears = (timePeriod(end)-timePeriod(1)+1);

if ~exist('tmaxNcepBase','var')
    tmaxNcepBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    tmaxEraBase = loadDailyData('e:/data/era-interim/output/mx2t/world/regrid', 'yearStart', timePeriod(1)+1, 'yearEnd', timePeriod(end)+1);
    
    % load pe data
    load('2017-nile-climate/data/pe/chgData-era-interim-PE-monthly-mean-historical.mat');
    eraPE = PE;
    load('2017-nile-climate/data/pe/chgData-era-interim-P-monthly-mean-historical.mat');
    eraP = P;
    load('2017-nile-climate/data/pe/chgData-era-interim-E-monthly-mean-historical.mat');
    eraE = E;
    load('2017-nile-climate/data/pe/chgData-era-interim-T-monthly-mean-historical.mat');
    eraT = T;
    
    load('2017-nile-climate/data/pe/chgData-ncep-reanalysis-PE-monthly-mean-historical.mat');
    ncepPE = PE;
    load('2017-nile-climate/data/pe/chgData-ncep-reanalysis-P-monthly-mean-historical.mat');
    ncepP = P;
    load('2017-nile-climate/data/pe/chgData-ncep-reanalysis-E-monthly-mean-historical.mat');
    ncepE = E;
    load('2017-nile-climate/data/pe/chgData-ncep-reanalysis-T-monthly-mean-historical.mat');
    ncepT = T;
end

coordPairs = csvread('ni-region.txt');

tmaxNcep = tmaxNcepBase{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :);
tmaxNcep = tmaxNcep-273.15;

tmaxEra = tmaxEraBase{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :);
tmaxEra = tmaxEra-273.15;

eraPE = eraPE(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);
eraE = eraE(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);
eraP = eraP(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);
eraT = eraT(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);

eraT(:,:,37,12) = NaN;

ncepPE = ncepPE(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);
ncepP = ncepP(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);
ncepE = ncepE(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);
ncepT = ncepT(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :);

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

lat = lat(latInds, lonInds);
lon = lon(latInds, lonInds);

% number of days in a year (each month is 31 days)
numDays = 372;

drawMaps = false;

% temperature: 
threshPrc = 95;
% duration (days)
threshDur = 5;

heatProbNcep = [];
heatProbEra = [];
heatPENcep = [];
heatPEEra = [];

% for all months, calculate the chance of there being a heatwave matching
% defined characteristics...
for month = 1:12
    % loop over all gridcells
    for xlat = 1:size(tmaxNcep, 1)
        for ylon = 1:size(tmaxNcep, 2)
            
            threshTempNcep = prctile(reshape(tmaxNcep(xlat,ylon,:,month,:), [numel(tmaxNcep(xlat,ylon,:,month,:)),1]), threshPrc);
            threshTempEra = prctile(reshape(tmaxEra(xlat,ylon,:,month,:), [numel(tmaxEra(xlat,ylon,:,month,:)),1]), threshPrc);
            
            for year = 1:size(tmaxNcep,3)
                % convert to 1D for current gridcell
                dNcep = reshape(tmaxNcep(xlat, ylon, year, month, :), [numel(tmaxNcep(xlat, ylon, year, month, :)), 1]);
                dEra = reshape(tmaxEra(xlat, ylon, year, month, :), [numel(tmaxEra(xlat, ylon, year, month, :)), 1]);

                % find all days above threshold temperature
                indTempNcep = find(dNcep > threshTempNcep);
                indTempEra = find(dEra > threshTempEra);

                % for how ever many days long wave we're looking for, take
                % difference of temp threshold indices - so if 1, that means
                % consequitive hot days
                % look for sub-arrays that contain X number of sequential ones
                x = (diff(indTempNcep))'==1;
                f = find([false, x] ~= [x, false]);
                indDurNcep = length(find(f(2:2:end)-f(1:2:end-1) >= threshDur));
                
                x = (diff(indTempEra))'==1;
                f = find([false, x] ~= [x, false]);
                indDurEra = length(find(f(2:2:end)-f(1:2:end-1) >= threshDur));

                % average number of events per year
                heatProbNcep(xlat, ylon, year, month) = indDurNcep;
                heatProbEra(xlat, ylon, year, month) = indDurEra;
            end
        end
    end
end

for xlat = 1:length(latInds)
    for ylon = 1:length(lonInds)
        if length(find(coordPairs(:,1) == latInds(xlat) & coordPairs(:,2) == lonInds(ylon))) == 0
            heatProbNcep(xlat, ylon, :, :) = NaN;
            heatProbEra(xlat, ylon, :, :) = NaN;
            eraPE(xlat, ylon, :, :) = NaN;
            eraP(xlat, ylon, :, :) = NaN;
            eraE(xlat, ylon, :, :) = NaN;
            eraT(xlat, ylon, :, :) = NaN;
            
            ncepPE(xlat, ylon, :, :) = NaN;
            ncepE(xlat, ylon, :, :) = NaN;
            ncepP(xlat, ylon, :, :) = NaN;
            ncepT(xlat, ylon, :, :) = NaN;
        end
    end
end

eraPTrend = [];
eraPTrendSig = [];
ncepPTrend = [];
ncepPTrendSig = [];
figure('Color',[1,1,1]);
hold on;
for m = 1:12
    for xlat = 1:size(eraP,1)
        for ylon = 1:size(eraP,2)
            d = squeeze(eraP(xlat, ylon, :, m));
            nn = find(~isnan(d));
            d = d(nn);
            if length(d) < 30
                continue;
            end
            f = fit((1:length(d))', d, 'poly1');
            eraPTrend(xlat, ylon, m) = f.p1;
            eraPTrendSig(xlat, ylon, m) = Mann_Kendall(d, 0.05);
            
            d = squeeze(ncepT(xlat, ylon, :, m));
            f = fit((1:length(d))', d, 'poly1');
            ncepPTrend(xlat, ylon, m) = f.p1;
            ncepPTrendSig(xlat, ylon, m) = Mann_Kendall(d, 0.05);
        end
    end
    
    
    mtrendEra = squeeze(nanmean(nanmean(eraPE(:,:,:,m),2),1));
    mtrendNcep = squeeze(nanmean(nanmean(ncepPE(:,:,:,m),2),1));
    subplot(4,3,m);
    hold on;
    box on;
    grid on;
    p1=plot(mtrendEra,'r', 'LineWidth', 2);
    p2=plot(mtrendNcep,'b', 'LineWidth', 2);
    if Mann_Kendall(mtrendEra, 0.05)
        f = fit((1:length(mtrendEra))',mtrendEra,'poly1');
        plot(1:length(mtrendEra),f(1:length(mtrendEra)),'r--');
    end
    if Mann_Kendall(mtrendNcep, 0.05)
        f = fit((1:length(mtrendNcep))',mtrendNcep,'poly1');
        plot(1:length(mtrendNcep),f(1:length(mtrendNcep)),'b--');
    end
    title(['Month ' num2str(m)]);
    if m == 1
        legend([p1,p2],{'ERA', 'NCEP'});
    end
end
suptitle('P-E');
set(gcf, 'Position', get(0,'Screensize'));
export_fig nile-pe.png -m2;
close all;

eraPTrend = [];
eraPTrendSig = [];
ncepPTrend = [];
ncepPTrendSig = [];
figure('Color',[1,1,1]);
hold on;
for m = 1:12
    for xlat = 1:size(eraP,1)
        for ylon = 1:size(eraP,2)
            d = squeeze(eraP(xlat, ylon, :, m));
            nn = find(~isnan(d));
            d = d(nn);
            if length(d) < 30
                continue;
            end
            f = fit((1:length(d))', d, 'poly1');
            eraPTrend(xlat, ylon, m) = f.p1;
            eraPTrendSig(xlat, ylon, m) = Mann_Kendall(d, 0.05);
            
            d = squeeze(ncepP(xlat, ylon, :, m));
            f = fit((1:length(d))', d, 'poly1');
            ncepPTrend(xlat, ylon, m) = f.p1;
            ncepPTrendSig(xlat, ylon, m) = Mann_Kendall(d, 0.05);
        end
    end
    
    mtrendEra = squeeze(nanmean(nanmean(eraP(:,:,:,m),2),1));
    mtrendNcep = squeeze(nanmean(nanmean(ncepP(:,:,:,m),2),1));
    subplot(4,3,m);
    hold on;
    box on;
    grid on;
    p1=plot(mtrendEra,'r', 'LineWidth', 2);
    p2=plot(mtrendNcep,'b', 'LineWidth', 2);
    if Mann_Kendall(mtrendEra, 0.05)
        f = fit((1:length(mtrendEra))',mtrendEra,'poly1');
        plot(1:length(mtrendEra),f(1:length(mtrendEra)),'r--');
    end
    if Mann_Kendall(mtrendNcep, 0.05)
        f = fit((1:length(mtrendNcep))',mtrendNcep,'poly1');
        plot(1:length(mtrendNcep),f(1:length(mtrendNcep)),'b--');
    end
    title(['Month ' num2str(m)]);
    if m == 1
        legend([p1,p2],{'ERA', 'NCEP'});
    end
end
suptitle('P');
set(gcf, 'Position', get(0,'Screensize'));
export_fig nile-p.png -m2;
close all;

eraTTrend = [];
eraTTrendSig = [];
ncepTTrend = [];
ncepTTrendSig = [];
figure('Color',[1,1,1]);
hold on;
for m = 1:12
    
    for xlat = 1:size(eraT,1)
        for ylon = 1:size(eraT,2)
            d = squeeze(eraT(xlat, ylon, :, m));
            nn = find(~isnan(d));
            d = d(nn);
            if length(d) < 30
                continue;
            end
            f = fit((1:length(d))', d, 'poly1');
            eraTTrend(xlat, ylon, m) = f.p1;
            eraTTrendSig(xlat, ylon, m) = Mann_Kendall(d, 0.05);
            
            d = squeeze(ncepT(xlat, ylon, :, m));
            f = fit((1:length(d))', d, 'poly1');
            ncepTTrend(xlat, ylon, m) = f.p1;
            ncepTTrendSig(xlat, ylon, m) = Mann_Kendall(d, 0.05);
        end
    end
    
    mtrendEra = squeeze(nanmean(nanmean(eraT(:,:,:,m),2),1));
    mtrendNcep = squeeze(nanmean(nanmean(ncepT(:,:,:,m),2),1));
    subplot(4,3,m);
    hold on;
    box on;
    grid on;
    p1=plot(mtrendEra,'r', 'LineWidth', 2);
    p2=plot(mtrendNcep,'b', 'LineWidth', 2);
    if Mann_Kendall(mtrendEra, 0.05)
        f = fit((1:length(mtrendEra))',mtrendEra,'poly1');
        plot(1:length(mtrendEra),f(1:length(mtrendEra)),'r--');
    end
    if Mann_Kendall(mtrendNcep, 0.05)
        f = fit((1:length(mtrendNcep))',mtrendNcep,'poly1');
        plot(1:length(mtrendNcep),f(1:length(mtrendNcep)),'b--');
    end
    title(['Month ' num2str(m)]);
    if m == 1
        legend([p1,p2],{'ERA', 'NCEP'});
    end
end
suptitle('T');
set(gcf, 'Position', get(0,'Screensize'));
export_fig nile-t.png -m2;
close all;


for month = 1:12
    result = {lat, lon, eraPTrend(:,:,month)};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-.1 .1], ...
                      'cbXTicks', [-.1 -.05 0 0.05 .1], ...
                      'plotTitle', ['ERA pr trend (month ' num2str(month) ')'], ...
                      'fileTitle', ['era-pr-trend-' num2str(month) '.png'], ...
                      'plotXUnits', ['mm/day'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'RdBu'), ...
                      'statData', eraPTrendSig(:,:,month),...
                      'plotCountries', true);
    plotFromDataFile(saveData);
end

for month = 1:12
    result = {lat, lon, ncepPTrend(:,:,month)};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-.1 .1], ...
                      'cbXTicks', [-.1 -.05 0 0.05 .1], ...
                      'plotTitle', ['NCEP pr trend (month ' num2str(month) ')'], ...
                      'fileTitle', ['ncep-pr-trend-' num2str(month) '.png'], ...
                      'plotXUnits', ['mm/day'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'RdBu'), ...
                      'statData', ncepPTrendSig(:,:,month),...
                      'plotCountries', true);
    plotFromDataFile(saveData);
end


heatProbEraArea = reshape(permute(squeeze(nansum(nansum(heatProbEra,2),1)),[2,1]), [numel(nansum(nansum(heatProbEra,2),1)),1]);
heatProbEraTime = reshape(nansum(nansum(heatProbEra,4),3), [numel(nansum(nansum(heatProbEra,4),3)),1]);
eraPEArea = reshape(permute(squeeze(nanmean(nanmean(eraPE,2),1)), [2,1]), [numel(nanmean(nanmean(eraPE,2),1)),1]);
eraPETime = reshape(nanmean(nanmean(eraPE,4),3), [numel(nanmean(nanmean(eraPE,4),3)),1]);

indArea = find(heatProbEraArea ~= 0 & ~isnan(eraPEArea));
indTime = find(heatProbEraTime ~= 0 & ~isnan(eraPETime));

figure; hold on; scatter(heatProbEraArea(indArea), eraPEArea(indArea));
figure; hold on; scatter(heatProbEraTime(indTime), eraPETime(indTime));


% number of heat waves per year averaged across all regional grid cells
% figure('Color',[1,1,1]);
% hold on;
% axis square;
% grid on;
% box on;



