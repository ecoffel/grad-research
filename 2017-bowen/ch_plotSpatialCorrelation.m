txxWarmAnom = true;

useWb = false;
var = 'ef';

bootstrap = false;
daily = true;

if txxWarmAnom
    if strcmp(var, 'ef')
        if useWb
        yrange = [-1 5];
        yticks = -1:1:5;    
        else
        yrange = [-21 5];
        yticks = -20:5:5;
        end
        unit = 'unit EF';
    elseif strcmp(var, 'pr')
        yrange = [-4 1];
        yticks = -4:1:1;
        unit = 'mm/day';
    elseif strcmp(var, 'huss')
        if useWb
        yrange = [300 900];
        yticks = 300:100:900;
        else
            yrange = [-800 1000];
        yticks = -800:200:1000;
        end
        unit = 'kg/kg';
    end
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
              'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
%     models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%               'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
%               'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%               'miroc5', 'mri-cgcm3', 'noresm1-m'};

amp = [];
driverRaw = [];
if daily
    if useWb
        load(['E:\data\projects\bowen\derived-chg\' var 'WbAmp-16.mat']);
        amp = wbAmp;    

        load(['E:\data\projects\bowen\derived-chg\' var 'ChgDailyWarmWbAnom.mat']);
        driverRaw = eval([var 'ChgDailyWarmWbAnom']);
    else
        for m = 1:length(models)
            load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efTxxAmp-movingWarm-' models{m} '.mat']);
            load(['E:\data\projects\bowen\derived-chg\txx-amp\txxAmp-' models{m} '.mat']);

            amp(:, :, m) = txxAmp;
            driverRaw(:, :, m) = efTxxAmp;
        end
        
        driverRaw(abs(driverRaw)>.5) = NaN;
    end
end

% load(['E:\data\projects\bowen\derived-chg\wbTxxChg.mat']);
% amp = wbTxxChg;    
% 
% load(['E:\data\projects\bowen\derived-chg\tasmaxWbChg.mat']);
% driverRaw = eval(['tasmaxWbChg']);

rind = 1;
efind = 1;
dslopes = [];
dslopesP = [];

for region = [1]% 2 4 7 10]
    [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));
    
    allDriver = [];
    allADriver = [];
    allEGroup = [];
    
    for m = 1:length(models)
        
       load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
        
        a = squeeze(amp(:,:,m));
        a(waterGrid) = NaN;
        a = a(latInds,lonInds);
        if region == 1
            a(1:15,:) = NaN;
            a(75:90,:) = NaN;
        end
        a = reshape(a, [numel(a),1]);
        
        driver = squeeze(driverRaw(:,:,m));
        driver(waterGrid) = NaN;
        driver = driver(latInds,lonInds);
        if region == 1
            driver(1:15,:) = NaN;
            driver(75:90,:) = NaN;
        end
        driver = reshape(driver, [numel(driver),1]);
        
        % remove large ef vals
%         if ~useWb
%             driver(abs(driver)>.5) = NaN;
%         end
        
        efGroup(waterGrid) = NaN;
        efGroup = efGroup(latInds,lonInds);
        if region == 1
            efGroup(1:15,:) = NaN;
            efGroup(75:90,:) = NaN;
        end
        efGroup =  reshape(efGroup, [numel(efGroup),1]);

        nn = find(isnan(a) | isnan(driver));

        driver(nn) = [];
        aDriver = a;
        aDriver(nn) = [];
        efGroup(nn) = [];
        
        allDriver = [allDriver; driver];
        allADriver = [allADriver; aDriver];
        allEGroup = [allEGroup; efGroup];
        
        for e = 1:5
            
            % all ef vals
            if e == 5
                nn = 1:length(driver);
            else
                % others
                nn = find(efGroup == e);
            end
            
            curDriver = driver(nn);
            curADriver = aDriver(nn);
            
            if bootstrap
                if length(curDriver)>2
                    X = [ones(size(curADriver)), curDriver];
                    b = regress(curADriver,X);
                    afit = X*b;
                    resid = curADriver-afit;        
                    slopes = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
                    dslopes(rind, e,m) = nanmean(slopes(:,2));
                else
                    dslopes(rind, e,m) = NaN;
                end
            else
                f = fitlm(curDriver, curADriver, 'linear');
                dslopes(rind, e, m) = f.Coefficients.Estimate(2);
                dslopesP(rind, e, m) = f.Coefficients.pValue(2); 
                
                if e == 1
                   x = 5; 
                end
            end
        end
        
        %if region == 1
        %    data = {driver, slopes};
            %save(['E:\data\projects\bowen\derived-chg\slopes\slopes-' var '-' models{m} '-1.mat'], 'data');
        %end

    end

    rind = rind+1;
    
    colors = [[1 0 0 .01];
              [0 1 0 .01];
              [0 0 1 .01];
              [.5 .5 0 .01]];
    
%     for e = 2
%         
%         figure('Color',[1,1,1]);
%         hold on;
%         box on;
%         axis square;
%         grid on;
% 
%         X = [ones(size(allDriver(allEGroup == e))), allDriver(allEGroup == e)];
%         b = regress(allADriver(allEGroup == e),X);
%         afit = X*b;
%         resid = allADriver(allEGroup == e)-afit;        
%         slopes = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
%         y1 = slopes(:,1)+min(allDriver(allEGroup == e))*slopes(:,2);
%         y2 = slopes(:,1)+max(allDriver(allEGroup == e))*slopes(:,2);
% 
%         p1 = plot(allDriver(allEGroup == e), allADriver(allEGroup == e), '.');
%         set(p1, 'Color', colors(e,:));
%         p = plot([min(allDriver(allEGroup == e)) max(allDriver(allEGroup == e))], [y1 y2], 'r');
%         set(p,'Color',colors(e,:));
% 
%     end

    
end

dslopes = squeeze(dslopes);
dslopesP = squeeze(dslopesP);

[f,gof] = fit((1:4)', nanmedian(dslopes(1:4,:),2), 'poly3');
fx = 1:.1:4;
fy = f(fx);

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
%b = boxplot(dslopes','positions',1:5);

for e = 1:size(dslopes,1)
    for m = 1:size(dslopes,2)
        if dslopesP(e, m) <= 0.05 && dslopes(e, m) < 0
            b = plot(e, dslopes(e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [160, 116, 46]./255.0);
        elseif dslopesP(e, m) <= 0.05 && dslopes(e, m) > 0
            b = plot(e, dslopes(e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [68, 166, 226]./255.0);
        else
            b = plot(e, dslopes(e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2);
        end
    end
    
    b = plot([e-.2 e+.2], [nanmean(dslopes(e,:),2) nanmean(dslopes(e,:),2)], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
    b = plot([e-.2 e+.2], [nanmedian(dslopes(e,:),2) nanmedian(dslopes(e,:),2)], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);
end

plot([0 6], [0 0], '--k');
plot(fx, fy, '--k', 'LineWidth', 2, 'Color', [.5 .5 .5]);
ylim(yrange);
set(gca, 'YTick', yticks);
xlim([.5 5.5]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'Arid', 'Semi-arid', 'Temperate', 'Tropical', 'All'});
xtickangle(45);
ylabel([char(176) 'C / ' unit]);
%set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
%lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
%set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
if txxWarmAnom
    if daily
        if useWb
            export_fig(['wb-amp-spatial-' var '-daily-groups-movingwarm.eps']);
        else
            export_fig(['txx-amp-spatial-' var '-daily-groups-movingwarm.eps']);
        end
    end
end
close all;
