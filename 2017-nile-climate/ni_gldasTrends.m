timePeriod = [1960 2010];
numYears = (timePeriod(end)-timePeriod(1)+1);

fprintf('loading et...\n');
et = loadMonthlyData('E:\data\gldas-noah-v2\output\Evap_tavg', 'Evap_tavg', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));

fprintf('loading p...\n');
p = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));

fprintf('loading t...\n');
t = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({et{1}, et{2}, []}, regionBounds(1,:), regionBounds(2,:));

lat = et{1}(latInds, lonInds);
lon = et{2}(latInds, lonInds);

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
total = numel(tdata(1,1,:,:));
for xlat = 1:size(tdata, 3)
    for ylon = 1:size(tdata, 4)
        curt = reshape(squeeze(tdata(:, :, xlat, ylon)), [numel(squeeze(tdata(:, :, xlat, ylon))), 1]);
        curp = reshape(squeeze(pdata(:, :, xlat, ylon)), [numel(squeeze(pdata(:, :, xlat, ylon))), 1]);
        curet = reshape(squeeze(etdata(:, :, xlat, ylon)), [numel(squeeze(etdata(:, :, xlat, ylon))), 1]);
        
        curpe = curp - curet;
        
        nn = find(~isnan(curt) & ~isnan(curp) & ~isnan(curpe));
        
        curt = curt(nn);
        curp = curp(nn);
        curpe = curpe(nn);
        
        if length(curt) < 300 || length(curp) < 300 || length(curpe) < 300
            ttrendMap(xlat, ylon) = NaN;
            ptrendMap(xlat, ylon) = NaN;
            petrendMap(xlat, ylon) = NaN;
            continue;
        end
        
        ft = fit((1:length(curt))', curt, 'poly1');
        fp = fit((1:length(curp))', curp, 'poly1');
        fpe = fit((1:length(curpe))', curpe, 'poly1');
        
        ttrendMap(xlat, ylon) = ft.p1;
        ptrendMap(xlat, ylon) = fp.p1;
        petrendMap(xlat, ylon) = fpe.p1;
        
        ttrendSig(xlat, ylon) = Mann_Kendall(curt, 0.05);
        ptrendSig(xlat, ylon) = Mann_Kendall(curp, 0.05);
        petrendSig(xlat, ylon) = Mann_Kendall(curpe, 0.05);
        
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

result = {lat, lon, ttrendMap};
saveData = struct('data', {result}, ...
                  'plotRegion', 'nile', ...
                  'plotRange', [-.05 .05], ...
                  'cbXTicks', -.05:.025:.05, ...
                  'plotTitle', ['T trend'], ...
                  'fileTitle', ['gldas-t-trend.png'], ...
                  'plotXUnits', ['C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'plotCountries', true);
plotFromDataFile(saveData);

result = {lat, lon, ptrendMap};
saveData = struct('data', {result}, ...
                  'plotRegion', 'nile', ...
                  'plotRange', [-.025 .025], ...
                  'cbXTicks', -.025:.025:.025, ...
                  'plotTitle', ['P trend'], ...
                  'fileTitle', ['gldas-p-trend.png'], ...
                  'plotXUnits', ['mm/day/dec'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'RdBu'), ...
                  'statData', ptrendSig,...
                  'plotCountries', true);
plotFromDataFile(saveData);

result = {lat, lon, petrendMap};
saveData = struct('data', {result}, ...
                  'plotRegion', 'nile', ...
                  'plotRange', [-.002 .002], ...
                  'cbXTicks', [-.002 .002], ...
                  'plotTitle', ['PE trend'], ...
                  'fileTitle', ['gldas-pe-trend.png'], ...
                  'plotXUnits', ['mm/day/dec'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'RdBu'), ...
                  'statData', petrendSig,...
                  'plotCountries', true);
plotFromDataFile(saveData);

tdata = squeeze(nanmean(nanmean(tdata, 4), 3));
pdata = squeeze(nanmean(nanmean(pdata, 4), 3));
etdata = squeeze(nanmean(nanmean(etdata, 4), 3));

figure('Color', [1,1,1]);
for month = 1:12
    curT = squeeze(tdata(month, :));
    curP = squeeze(pdata(month, :));
    cureET = squeeze(etdata(month, :));
    
    subplot(3,4,month);
    hold on;
    axis square
    grid on;
    box on;
    
    yyaxis left;
    plot(curT);
    if Mann_Kendall(curT, 0.05)
        f = fit((1:length(curT))', curT', 'poly1');
        plot(1:length(curT), f(1:length(curT)), '--');
    end
    
    ylabel([char(176) 'C']);
    
    yyaxis right;
    plot(curP);
    if Mann_Kendall(curT, 0.05)
        f = fit((1:length(curP))', curP', 'poly1');
        plot(1:length(curP), f(1:length(curP)), '--');
    end
    
    ylabel('mm/day');
    xlabel('Year');
    title(['Month ' num2str(month)]);
end
suptitle('P and T');


figure('Color', [1,1,1]);
for month = 1:12
    pe = squeeze(pdata(month, :) - etdata(month, :));
    
    subplot(3,4,month);
    hold on;
    axis square
    grid on;
    box on;
    
    plot(pe);
    if Mann_Kendall(pe, 0.05)
        f = fit((1:length(pe))', pe', 'poly1');
        plot(1:length(pe), f(1:length(pe)), '--');
    end
    
    ylabel('mm/day');
    xlabel('Year');
    title(['Month ' num2str(month)]);
end
suptitle('P - E');
