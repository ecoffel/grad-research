timePeriod = [1960 2010];
numYears = (timePeriod(end)-timePeriod(1)+1);

% if ~exist('et', 'var')
%     fprintf('loading et...\n');
%     et = loadMonthlyData('E:\data\gldas-noah-v2\output\Evap_tavg', 'Evap_tavg', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
% end

if ~exist('p', 'var')
    fprintf('loading p...\n');
    p = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
end

% if ~exist('t', 'var')
%     fprintf('loading t...\n');
%     t = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
% end


lat = p{1};
lon = p{2};

regionBoundsNorth = [[13 32]; [29, 34]];
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

%tdata = t{3} - 273.15;
pdata = p{3} .* 3600 .* 24;
%etdata = et{3} .* 3600 .* 24;

figure('Color', [1,1,1]);
for season = 1:size(seasons, 1)
    regionTotalP = squeeze(nanmean(nanmean(nanmean(pdata(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    
    subplot(2,2,season);
    hold on;
    axis square;
    grid on;
    box on;
    plot(regionTotalP, 'LineWidth', 2);
    if Mann_Kendall(regionTotalP, 0.05)
        f = fit((1:length(regionTotalP))', regionTotalP, 'poly1');
        plot(1:length(regionTotalP), f(1:length(regionTotalP)), '--');
    end
    title(['Season ' num2str(season)]);
    ylim([0 6]);
    xlim([0 52]);
    ylabel('mm/day');
    xlabel('year');
end
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-chg-gldas-south.eps;
close all;

figure('Color', [1,1,1]);
for season = 1:size(seasons, 1)
    regionTotalP = squeeze(nanmean(nanmean(nanmean(pdata(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    
    subplot(2,2,season);
    hold on;
    axis square;
    grid on;
    box on;
    plot(regionTotalP, 'LineWidth', 2);
    if Mann_Kendall(regionTotalP, 0.05)
        f = fit((1:length(regionTotalP))', regionTotalP, 'poly1');
        plot(1:length(regionTotalP), f(1:length(regionTotalP)), '--');
    end
    title(['Season ' num2str(season)]);
    ylim([0 6]);
    xlim([0 52]);
    ylabel('mm/day');
    xlabel('year');
end
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-chg-gldas-north.eps;
close all;


if plotMap

    
    tdata = permute(squeeze(t{3}(latInds, lonInds, :, :)), [4, 3, 1, 2]) - 273.15;
    pdata = permute(squeeze(p{3}(latInds, lonInds, :, :)), [4, 3, 1, 2]) .* 3600 .* 24;
    etdata = permute(squeeze(et{3}(latInds, lonInds, :, :)), [4, 3, 1, 2]) .* 3600 .* 24;

    
    ttrendMap = [];
    ttrendSig = [];
    petrendMap = [];
    petrendSig = [];
    ptrendMap = [];
    ptrendSig = [];

    i = 1;
    total = size(tdata, 3)*size(tdata, 4);
    for xlat = 1:size(tdata, 3)
        for ylon = 1:size(tdata, 4)
            for season = 1:size(seasons, 1)
                curt = squeeze(nanmean(tdata(seasons(season,:), :, xlat, ylon), 1));
                curp = squeeze(nanmean(pdata(seasons(season,:), :, xlat, ylon), 1));
                curet = squeeze(nanmean(etdata(seasons(season,:), :, xlat, ylon), 1));

                curt = reshape(curt, [numel(curt), 1]);
                curp = reshape(curp, [numel(curp), 1]);
                curet = reshape(curet, [numel(curet), 1]);

                curpe = curp - curet;

                % convert to percent change
                curp = curp ./ nanmean(curp) .* 100;
                curpe = curpe ./ nanmean(curpe) .* 100;

                nn = find(~isnan(curt) & ~isnan(curp) & ~isnan(curpe));

                curt = curt(nn);
                curp = curp(nn);
                curpe = curpe(nn);

                if length(curt) < 10 || length(curp) < 10 || length(curpe) < 10
                    ttrendMap(xlat, ylon, season) = NaN;
                    ptrendMap(xlat, ylon, season) = NaN;
                    petrendMap(xlat, ylon, season) = NaN;
                    continue;
                end

                ttrendSig(xlat, ylon, season) = Mann_Kendall(curt, 0.05);
                ptrendSig(xlat, ylon, season) = Mann_Kendall(curp, 0.05);
                petrendSig(xlat, ylon, season) = Mann_Kendall(curpe, 0.05);

                if ttrendSig(xlat, ylon, season)
                    ft = fit((1:length(curt))', curt, 'poly1');
                    ttrendMap(xlat, ylon, season) = ft.p1;
                else
                    ttrendMap(xlat, ylon, season) = NaN;
                end

                if ptrendSig(xlat, ylon, season)
                    fp = fit((1:length(curp))', curp, 'poly1');
                    ptrendMap(xlat, ylon, season) = fp.p1;
                else
                    ptrendMap(xlat, ylon, season) = NaN;
                end

                if petrendSig(xlat, ylon, season)
                    fpe = fit((1:length(curpe))', curpe, 'poly1');
                    petrendMap(xlat, ylon, season) = fpe.p1;
                else
                    petrendMap(xlat, ylon, season) = NaN;
                end 
            end

            if mod(i,100) == 0
                fprintf('%d / %d\n', i, total);
            end

            i = i+1;
        end
    end

    % trend per decade
    ttrendMap = ttrendMap .* 10;
    ptrendMap = ptrendMap .* 10;
    petrendMap = petrendMap .* 10;

    for season = 1:size(seasons, 1)
    %     result = {lat, lon, ttrendMap(:, :, season)};
    %     saveData = struct('data', {result}, ...
    %                       'plotRegion', 'nile', ...
    %                       'plotRange', [-1 1], ...
    %                       'cbXTicks', -1:.5:1, ...
    %                       'plotTitle', ['T trend'], ...
    %                       'fileTitle', ['gldas-t-trend-' num2str(season) '.png'], ...
    %                       'plotXUnits', ['C'], ...
    %                       'blockWater', true, ...
    %                       'colormap', brewermap([],'*RdBu'), ...
    %                       'plotCountries', true);
    %     plotFromDataFile(saveData);

        result = {lat, lon, ptrendMap(:, :, season)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-20 20], ...
                          'cbXTicks', -20:10:20, ...
                          'plotTitle', ['P trend'], ...
                          'fileTitle', ['gldas-p-trend-' num2str(season) '.png'], ...
                          'plotXUnits', ['%/dec'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'RdBu'), ...
                          'plotCountries', true);
        plotFromDataFile(saveData);

        result = {lat, lon, petrendMap(:, :, season)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-20 20], ...
                          'cbXTicks', -20:10:20, ...
                          'plotTitle', ['PE trend'], ...
                          'fileTitle', ['gldas-pe-trend-' num2str(season) '.png'], ...
                          'plotXUnits', ['%/dec'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'RdBu'), ...
                          'plotCountries', true);
        plotFromDataFile(saveData);

    end
end