txxWarmAnom = true;
warmSeasonAnom = false;
excludeWinter = false;

var = 'ef';

if txxWarmAnom
    load E:\data\projects\bowen\derived-chg\efTxxAmp.mat;
    amp = txxAmp;
    if strcmp(var, 'TCHfss')
        load(['E:\data\projects\bowen\derived-chg\' var '.mat']);
        driverRaw = eval([var]);
    else
        load(['E:\data\projects\bowen\derived-chg\' var 'ChgDailyWarmTxxAnom.mat']);
        driverRaw = eval([var 'ChgDailyWarmTxxAnom']);
    end
    
    
    if strcmp(var, 'ef')
        yrange = [-25 10];
        yticks = -25:5:10;
        unit = 'unit EF';
        driverRaw(abs(driverRaw)>1) = NaN;
    elseif strcmp(var, 'pr')
        yrange = [-4 1];
        yticks = -4:1:1;
        unit = 'mm/day';
        driverRaw = driverRaw .* 3600 .* 24;
    elseif strcmp(var, 'netRad')
        yrange = [-.2 .2];
        yticks = -.2:.1:.2;
        unit = 'W/m^2';
    elseif strcmp(var, 'clt')
        yrange = [-.2 .2];
        yticks = -.2:.1:.2;
        unit = 'Fraction';
    elseif strcmp(var, 'hfss')
        yrange = [-.2 .2];
        yticks = -.2:.1:.2;
        unit = 'W/m^2';
    elseif strcmp(var, 'hfls')
        yrange = [-.1 .1];
        yticks = -.1:.05:.1;
        unit = 'W/m^2';
    elseif strcmp(var, 'TCHfss')
        yrange = [-1 1];
        yticks = -1:.5:1;
        unit = 'W/m^2';
    end
elseif warmSeasonAnom
    load e:/data/projects/bowen/derived-chg/txChg.mat;
    load e:/data/projects/bowen/derived-chg/txChgWarm.mat;
    amp = txChgWarm - txChg;
    
    if excludeWinter
        load E:\data\projects\bowen\derived-chg\hfssChgWarmAnom-nowint.mat;
        load E:\data\projects\bowen\derived-chg\prChgWarmAnom-nowint.mat;
        load E:\data\projects\bowen\derived-chg\efChgWarmAnom-nowint.mat;
    else
        load E:\data\projects\bowen\derived-chg\hfssChgWarmAnom.mat;
        load E:\data\projects\bowen\derived-chg\prChgWarmAnom.mat;
        load E:\data\projects\bowen\derived-chg\efChgWarmAnom.mat;
    end
    hfssRaw = hfssChgWarmAnom;
    prRaw = prChgWarmAnom;
    efRaw = efChgWarmAnom;
end

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china
       
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rind = 1;
dslopes = [];

for region = [1 2 4 7 10]
    [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

    for m = 1:size(amp,3)
        a = squeeze(amp(:,:,m));
        a(waterGrid) = NaN;
        a = a(latInds,lonInds);
        a = reshape(a, [numel(a),1]);

        driver = squeeze(driverRaw(:,:,m));
        driver(waterGrid) = NaN;
        driver = driver(latInds,lonInds);
        if region == 1
            driver(1:15,:) = NaN;
            driver(75:90,:) = NaN;
        end
        driver = reshape(driver, [numel(driver),1]);

        nn = find(isnan(a) | isnan(driver));

        driver(nn) = [];
        aDriver = a;
        aDriver(nn) = [];
        

        if length(driver)>2
            X = [ones(size(aDriver)), driver];
            b = regress(aDriver,X);
            afit = X*b;
            resid = aDriver-afit;        
            slopes = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
            dslopes(rind,m) = nanmean(slopes(:,2));
        else
            dslopes(rind,m) = NaN;
        end
        
        if region == 1
            data = {driver, slopes};
            %save(['E:\data\projects\bowen\derived-chg\slopes\slopes-' var '-' models{m} '-1.mat'], 'data');
        end
%         y1 = slopes(:,1)+min(driver)*slopes(:,2);
%         y2 = slopes(:,1)+max(driver)*slopes(:,2);
%         
%         figure('Color',[1,1,1]);
%         hold on;
%         box on;
%         axis square;
%         grid on;
%         p = plot([min(driver) max(driver)], [y1 y2], 'r');
%         set(p,'Color',[1 0 0 .01]);
%         ylim([-2 5]);
%         xlim([-10 10]);

    end

    rind = rind+1;
    
    
end

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
b = boxplot(dslopes','positions',1:5);
plot([0 6], [0 0], '--k');
ylim(yrange);
set(gca, 'YTick', yticks);
xlim([0 6]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'World', 'U.S.', 'Europe', 'Amazon', 'China'});xtickangle(45);
ylabel([char(176) 'C / ' unit]);
set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
if txxWarmAnom
    export_fig(['txx-amp-spatial-' var '-daily.eps']);
elseif warmSeasonAnom
    export_fig(['warm-anom-spatial-' var '.eps']);
end
close all;
