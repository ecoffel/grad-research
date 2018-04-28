load E:\data\projects\bowen\derived-chg\txxAmp.mat;
load E:\data\projects\bowen\derived-chg\hfssChgWarmTxxAnom.mat;
load E:\data\projects\bowen\derived-chg\prChgWarmTxxAnom.mat;
load E:\data\projects\bowen\derived-chg\efChgWarmTxxAnom.mat;
hfss = hfssChgWarmTxxAnom;
pr = prChgWarmTxxAnom;
ef = efChgWarmTxxAnom;

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


rind = 1;
prslopes = [];
shslopes = [];
efslopes = [];

for region = [1 2 4 7 10]
    [latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));


    for m = 1:size(amp,3)
        %subplot(5,5,m);
        %hold on;

        a = squeeze(amp(:,:,m));
        a(waterGrid) = NaN;
        a = a(latInds,lonInds);
        a = reshape(a, [numel(a),1]);

        sh = squeeze(hfssChgWarmTxxAnom(:,:,m));
        sh(waterGrid) = NaN;
        sh = sh(latInds,lonInds);
        sh = reshape(sh, [numel(sh),1]);

        nn = find(isnan(a) | isnan(sh));

        sh(nn) = [];
        aSh = a;
        aSh(nn) = [];

        pr = squeeze(prChgWarmTxxAnom(:,:,m)) .* 3600 .* 24;
        pr(waterGrid) = NaN;
        pr = pr(latInds,lonInds);
        pr = reshape(pr, [numel(pr),1]);

        nn = find(isnan(a) | isnan(pr));

        pr(nn) = [];
        aPr = a;
        aPr(nn) = [];
        
        
        ef = squeeze(efChgWarmTxxAnom(:,:,m));
        ef(waterGrid) = NaN;
        ef = ef(latInds,lonInds);
        ef = reshape(ef, [numel(ef),1]);

        nn = find(isnan(a) | isnan(ef));

        ef(nn) = [];
        aEf = a;
        aEf(nn) = [];

        X = [ones(size(aSh)), sh];
        b = regress(aSh,X);
        afit = X*b;
        resid = aSh-afit;        
        slopes = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
        shslopes(rind,m) = nanmean(slopes(:,2));
        
        
        X = [ones(size(aPr)), pr];
        b = regress(aPr,X);
        afit = X*b;
        resid = aPr-afit;        
        slopes = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
        prslopes(rind,m) = nanmean(slopes(:,2));
        
        
        X = [ones(size(aEf)), ef];
        b = regress(aEf,X);
        afit = X*b;
        resid = aEf-afit;        
        slopes = bootstrp(1000, @(bootr)regress(afit+bootr,X),resid);
        efslopes(rind,m) = nanmean(slopes(:,2));
    %     
    %     y1 = bslopes(:,1)+min(x)*bslopes(:,2);
    %     y2 = bslopes(:,1)+max(x)*bslopes(:,2);
    %     
    %     figure('Color',[1,1,1]);
    %     hold on;
    %     box on;
    %     axis square;
    %     grid on;
    %     p = plot([min(x) max(x)], [y1 y2], 'r');
    %     set(p,'Color',[1 0 0 .01]);
    %     ylim([-2 5]);
    %     xlim([-10 10]);

%         [f,gof,out] = fit(sh, aSh, 'poly1');
%         shslopes(rind,m) = f.p1;
% 
%         [f,gof,out] = fit(pr, aPr, 'poly1');
%         prslopes(rind,m) = f.p1;
        %p = plot([min(x) max(x)], [f(min(x)) f(max(x))], 'k', 'LineWidth', 1);

    end

    rind = rind+1;
    
    
end

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
b = boxplot(shslopes','positions',1:5);
plot([0 6], [0 0], '--k');
ylim([-.25 .25]);
xlim([0 6]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'World', 'U.S.', 'Europe', 'Amazon', 'China'});xtickangle(45);
ylabel([char(176) 'C / W/m^2']);
set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig txx-amp-spatial-sh.eps;
close all;

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
b = boxplot(prslopes','positions',1:5);
plot([0 6], [0 0], '--k');
ylim([-2.5 2]);
xlim([0 6]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'World', 'U.S.', 'Europe', 'Amazon', 'China'});xtickangle(45);
ylabel([char(176) 'C / mm/day']);
set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig txx-amp-spatial-pr.eps;
close all;


figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
b = boxplot(efslopes','positions',1:5);
plot([0 6], [0 0], '--k');
ylim([-20 12]);
xlim([0 6]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'World', 'U.S.', 'Europe', 'Amazon', 'China'});
ylabel([char(176) 'C / unit EF']);
set(gca, 'YTick', -20:5:10);
xtickangle(45);
set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig txx-amp-spatial-ef.eps;
close all;


figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
xlim([-12 12]);
set(gca, 'XTick', -12:3:12);
ylim([-2 3]);
ylabel(['99th % Tx amplification (' char(176) 'C)']);
xlabel('PR amplification (mm/day)');
set(gca, 'FontSize', 40);