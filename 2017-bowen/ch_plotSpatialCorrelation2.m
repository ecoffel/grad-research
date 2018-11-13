txxWarmAnom = true;

useWb = false;
var = 'huss';

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

showbar = false;

for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxChg-' models{m}]);
    txxChgOnTxx(:, :, m) = txxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/wbTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    wbOnTxx(:,:,m) = wbTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    hussOnTxx(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    efOnTxx(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChg-' models{m}]);
    wbChgOnWb(:, :, m) = wbChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    txxOnWb(:,:,m) = tasmaxTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    hussOnWb(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    efOnWb(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txChgWarm-' models{m}]);
    txChgWarmSeason(:, :, m) = txChgWarm;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efWarmChg-movingWarm-' models{m}]);
    efChgWarmSeason(:, :, m) = efWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\hussWarmChg-movingWarm-' models{m}]);
    hussChgWarmSeason(:, :, m) = hussWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChgWarm-' models{m}]);
    wbChgWarmSeason(:, :, m) = wbChgWarm;
end

efOnTxx(abs(efOnTxx)>.5) = NaN;
efOnWb(abs(efOnWb)>.5) = NaN;
efChgWarmSeason(abs(efChgWarmSeason)>.5) = NaN;

colorWarm = [160, 116, 46]./255.0;
colorHuss = [28, 165, 51]./255.0;
colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]; ...               % china
           [[-24 -8], [14 40]]; ...                      % south africa
           [[-45 -25], [-65 -49]+360]];

region = 1;
[latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

if showbar 

    for m = 1:length(models)

        load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);

        efGroup(waterGrid) = NaN;
        efGroup(1:15,:) = NaN;
        efGroup(75:90,:) = NaN;
        efGroup =  reshape(efGroup, [numel(efGroup),1]);

        cureftxx = efOnTxx(:, :, m);
        cureftxx(waterGrid) = NaN;
        cureftxx(1:15,:) = NaN;
        cureftxx(75:90,:) = NaN;
        cureftxx =  reshape(cureftxx, [numel(cureftxx),1]);
        eftxx(:,m) = cureftxx;

        curefwb = efOnWb(:, :, m);
        curefwb(waterGrid) = NaN;
        curefwb(1:15,:) = NaN;
        curefwb(75:90,:) = NaN;
        curefwb =  reshape(curefwb, [numel(curefwb),1]);
        efwb(:,m) = curefwb;

        curefwarm = efChgWarmSeason(:, :, m);
        curefwarm(waterGrid) = NaN;
        curefwarm(1:15,:) = NaN;
        curefwarm(75:90,:) = NaN;
        curefwarm =  reshape(curefwarm, [numel(curefwarm),1]);
        efwarm(:,m) = curefwarm;

        curhusstxx = hussOnTxx(:, :, m);
        curhusstxx(waterGrid) = NaN;
        curhusstxx(1:15,:) = NaN;
        curhusstxx(75:90,:) = NaN;
        curhusstxx =  reshape(curhusstxx, [numel(curhusstxx),1]);
        husstxx(:,m) = curhusstxx;

        curhusswb = hussOnWb(:, :, m);
        curhusswb(waterGrid) = NaN;
        curhusswb(1:15,:) = NaN;
        curhusswb(75:90,:) = NaN;
        curhusswb =  reshape(curhusswb, [numel(curhusswb),1]);
        husswb(:,m) = curhusswb;

        curhusswarm = hussChgWarmSeason(:, :, m);
        curhusswarm(waterGrid) = NaN;
        curhusswarm(1:15,:) = NaN;
        curhusswarm(75:90,:) = NaN;
        curhusswarm =  reshape(curhusswarm, [numel(curhusswarm),1]);
        husswarm(:,m) = curhusswarm;

        curwbtxx = wbOnTxx(:, :, m);
        curwbtxx(waterGrid) = NaN;
        curwbtxx(1:15,:) = NaN;
        curwbtxx(75:90,:) = NaN;
        curwbtxx =  reshape(curwbtxx, [numel(curwbtxx),1]);
        wbtxx(:,m) = curwbtxx;

        curwbwb = wbChgOnWb(:, :, m);
        curwbwb(waterGrid) = NaN;
        curwbwb(1:15,:) = NaN;
        curwbwb(75:90,:) = NaN;
        curwbwb =  reshape(curwbwb, [numel(curwbwb),1]);
        wbwb(:,m) = curwbwb;

        curwbwarm = wbChgWarmSeason(:, :, m);
        curwbwarm(waterGrid) = NaN;
        curwbwarm(1:15,:) = NaN;
        curwbwarm(75:90,:) = NaN;
        curwbwarm =  reshape(curwbwarm, [numel(curwbwarm),1]);
        wbwarm(:,m) = curwbwarm;

        curtxxtxx = txxChgOnTxx(:, :, m);
        curtxxtxx(waterGrid) = NaN;
        curtxxtxx(1:15,:) = NaN;
        curtxxtxx(75:90,:) = NaN;
        curtxxtxx =  reshape(curtxxtxx, [numel(curtxxtxx),1]);
        txxtxx(:,m) = curtxxtxx;

        curtxxwb = txxOnWb(:, :, m);
        curtxxwb(waterGrid) = NaN;
        curtxxwb(1:15,:) = NaN;
        curtxxwb(75:90,:) = NaN;
        curtxxwb =  reshape(curtxxwb, [numel(curtxxwb),1]);
        txxwb(:,m) = curtxxwb;

        curtxxwarm = txChgWarmSeason(:, :, m);
        curtxxwarm(waterGrid) = NaN;
        curtxxwarm(1:15,:) = NaN;
        curtxxwarm(75:90,:) = NaN;
        curtxxwarm =  reshape(curtxxwarm, [numel(curtxxwarm),1]);
        txxwarm(:,m) = curtxxwarm;
    end

    names = {'Arid', 'Semi-arid', 'Temperate', 'Tropical', 'All'};

    load twchgTPer_warming_warm;
    twchgTPer_warming_warm = twchgTPer_warming;
    load twchgTPer_warming_txx;
    twchgTPer_warming_txx = twchgTPer_warming;
    load twchgTPer_warming_tw;
    twchgTPer_warming_wb = twchgTPer_warming;

    for e = 5

        % all ef vals
        if e == 5
            nn = find(~isnan(efGroup));
        else
            % others
            nn = find(efGroup == e);
        end

        cureftxx = (squeeze(eftxx(nn,:)));
        curefwb = (squeeze(efwb(nn,:)));
        curefwarm = (squeeze(efwarm(nn,:)));
        curhusstxx = (squeeze(husstxx(nn,:)));
        curhusswb = (squeeze(husswb(nn,:)));
        curhusswarm = (squeeze(husswarm(nn,:)));
        curwbtxx = (squeeze(wbtxx(nn,:)));
        curwbwb = (squeeze(wbwb(nn,:)));
        curwbwarm = (squeeze(wbwarm(nn,:)));
        curtxxtxx = (squeeze(txxtxx(nn,:)));
        curtxxwb = (squeeze(txxwb(nn,:)));
        curtxxwarm = (squeeze(txxwarm(nn,:)));


        prcWbPosWb = [];
        prcWbNegWb = [];
        prcWbPosTx = [];
        prcWbNegTx = [];
        curtxwarmPos = [];
        curtxwarmNeg = [];
        for m = 1:size(curwbwb, 2)

            curtwp = twchgTPer_warming_warm(:,:,m);
            curtwp(waterGrid) = NaN;
            curtwp(1:15,:) = NaN;
            curtwp(75:90,:) = NaN;
            curtwp = reshape(curtwp, [numel(curtwp),1]);

            %indWbPosWarm = find(curwbwarm(:,m)-nanmean(curwbwarm(:,m),1) > 0);
            %indWbNegWarm = find(curwbwarm(:,m)-nanmean(curwbwarm(:,m),1) < 0);

            indWbPosWarm = find(curtwp(nn) > .50);
            indWbNegWarm = find(curtwp(nn) <= .50);

            curtxwarmPos(m) = nanmean(curtxxwarm(indWbPosWarm, m));
            curtxwarmNeg(m) = nanmean(curtxxwarm(indWbNegWarm, m));

            curefwarmPos(m) = nanmean(curefwarm(indWbPosWarm, m));
            curefwarmNeg(m) = nanmean(curefwarm(indWbNegWarm, m));

            curhusswarmPos(m) = nanmean(curhusswarm(indWbPosWarm, m));
            curhusswarmNeg(m) = nanmean(curhusswarm(indWbNegWarm, m));

    %         indWbPosWb = find(curwbwb(:,m)-nanmean(curwbwarm(:,m),1) > 0);
    %         indWbNegWb = find(curwbwb(:,m)-nanmean(curwbwarm(:,m),1) < 0);

            curtwp = twchgTPer_warming_wb(:,:,m);
            curtwp(waterGrid) = NaN;
            curtwp(1:15,:) = NaN;
            curtwp(75:90,:) = NaN;
            curtwp = reshape(curtwp, [numel(curtwp),1]);

            indWbPosWb = find(curtwp(nn) > .50);
            indWbNegWb = find(curtwp(nn) <= .50);

            prcWbPosWb(m) = length(indWbPosWb)/length(nn)*100;
            prcWbNegWb(m) = length(indWbNegWb)/length(nn)*100;

            curtxwbPos(m) = nanmean(curtxxwb(indWbPosWb, m));
            curtxwbNeg(m) = nanmean(curtxxwb(indWbNegWb, m));

            curefwbPos(m) = nanmean(curefwb(indWbPosWb, m));
            curefwbNeg(m) = nanmean(curefwb(indWbNegWb, m));

            curhusswbPos(m) = nanmean(curhusswb(indWbPosWb, m));
            curhusswbNeg(m) = nanmean(curhusswb(indWbNegWb, m));

            %indWbPosTxx = find(curwbtxx(:,m)-nanmean(curwbwarm(:,m),1) > 0);
            %indWbNegTxx = find(curwbtxx(:,m)-nanmean(curwbwarm(:,m),1) < 0);

            curtwp = twchgTPer_warming_txx(:,:,m);
            curtwp(waterGrid) = NaN;
            curtwp(1:15,:) = NaN;
            curtwp(75:90,:) = NaN;
            curtwp = reshape(curtwp, [numel(curtwp),1]);

            indWbPosTxx = find(curtwp(nn) > .50);
            indWbNegTxx = find(curtwp(nn) <= .50);

            prcWbPosTx(m) = length(indWbPosTxx)/length(nn)*100;
            prcWbNegTx(m) = length(indWbNegTxx)/length(nn)*100;

            curtxtxxPos(m) = nanmean(curtxxtxx(indWbPosTxx, m));
            curtxtxxNeg(m) = nanmean(curtxxtxx(indWbNegTxx, m));

            cureftxxPos(m) = nanmean(cureftxx(indWbPosTxx, m));
            cureftxxNeg(m) = nanmean(cureftxx(indWbNegTxx, m));

            curhusstxxPos(m) = nanmean(curhusstxx(indWbPosTxx, m));
            curhusstxxNeg(m) = nanmean(curhusstxx(indWbNegTxx, m));
        end


        fig = figure('Color', [1,1,1]);
        set(fig,'defaultAxesColorOrder',[colorTxx; colorHuss]);
        hold on;
        box on;
        grid on;

        pbaspect([1 2 1]);
        yyaxis left;
        b = bar([1 5], [nanmedian(curtxwbPos) nanmedian(curtxwbNeg)], .25, 'k');
        set(b, 'facecolor', colorTxx, 'linewidth', 2);
        er = errorbar(1, nanmedian(curtxwbPos), nanmedian(curtxwbPos)-min(curtxwbPos), max(curtxwbPos)-nanmedian(curtxwbPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(5, nanmedian(curtxwbNeg), nanmedian(curtxwbNeg)-min(curtxwbNeg), max(curtxwbNeg)-nanmedian(curtxwbNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        ylim([0 13]);
        ylabel(['Tx change (' char(176) 'C)']);

    %     b = bar([2 6], [nanmedian(curefwbPos) nanmedian(curefwbNeg)], .25, 'k');
    %     set(b, 'facecolor', colorWarm, 'linewidth', 2);
    %     er = errorbar(2, nanmedian(curefwbPos), nanmedian(curefwbPos)-min(curefwbPos), max(curefwbPos)-nanmedian(curefwbPos));
    %     set(er, 'color', 'k', 'linewidth', 2);
    %     er = errorbar(6, nanmedian(curefwbNeg), nanmedian(curefwbNeg)-min(curefwbNeg), max(curefwbNeg)-nanmedian(curefwbNeg));
    %     set(er, 'color', 'k', 'linewidth', 2);

        yyaxis right;
        b = bar([2 6], [nanmedian(curhusswbPos) nanmedian(curhusswbNeg)], .25, 'k');
        set(b, 'facecolor', colorHuss, 'linewidth', 2);
        er = errorbar(2, nanmedian(curhusswbPos), nanmedian(curhusswbPos)-min(curhusswbPos), max(curhusswbPos)-nanmedian(curhusswbPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(6, nanmedian(curhusswbNeg), nanmedian(curhusswbNeg)-min(curhusswbNeg), max(curhusswbNeg)-nanmedian(curhusswbNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        ylabel('Specific humidity change (g/kg)');
        set(gca, 'XTick', [1.5 5.5], 'XTickLabels', {'T-dominated', 'H-dominated'});
        xtickangle(45);
        xlim([0 7]);
        ylim([0 .005]);
        set(gca, 'YTick', 0:.001:.005, 'YTickLabels', 0:5);
        %title('Max T_W day');
        set(gca, 'YTick', 0:.001:.005);
        set(gca, 'fontsize', 36);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['bar-prc-wb-' num2str(e) '.eps']);
        close all;

        fig = figure('Color', [1,1,1]);
        set(fig,'defaultAxesColorOrder',[colorTxx; colorHuss]);
        hold on;
        box on;
        grid on;

        pbaspect([1 2 1]);
        yyaxis left;
        b = bar([1 5], [nanmedian(curtxtxxPos) nanmedian(curtxtxxNeg)], .25, 'k');
        set(b, 'facecolor', colorTxx, 'linewidth', 2);
        er = errorbar(1, nanmedian(curtxtxxPos), nanmedian(curtxtxxPos)-min(curtxtxxPos), max(curtxtxxPos)-nanmedian(curtxtxxPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(5, nanmedian(curtxtxxNeg), nanmedian(curtxtxxNeg)-min(curtxtxxNeg), max(curtxtxxNeg)-nanmedian(curtxtxxNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        ylim([0 13]);
        ylabel(['Tx change (' char(176) 'C)']);

    %     b = bar([2 6], [nanmedian(curefwbPos) nanmedian(curefwbNeg)], .25, 'k');
    %     set(b, 'facecolor', colorWarm, 'linewidth', 2);
    %     er = errorbar(2, nanmedian(curefwbPos), nanmedian(curefwbPos)-min(curefwbPos), max(curefwbPos)-nanmedian(curefwbPos));
    %     set(er, 'color', 'k', 'linewidth', 2);
    %     er = errorbar(6, nanmedian(curefwbNeg), nanmedian(curefwbNeg)-min(curefwbNeg), max(curefwbNeg)-nanmedian(curefwbNeg));
    %     set(er, 'color', 'k', 'linewidth', 2);

        yyaxis right;
        b = bar([2 6], [nanmedian(curhusstxxPos) nanmedian(curhusstxxNeg)], .25, 'k');
        set(b, 'facecolor', colorHuss, 'linewidth', 2);
        er = errorbar(2, nanmedian(curhusstxxPos), nanmedian(curhusstxxPos)-min(curhusstxxPos), max(curhusstxxPos)-nanmedian(curhusstxxPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(6, nanmedian(curhusstxxNeg), nanmedian(curhusstxxNeg)-min(curhusstxxNeg), max(curhusstxxNeg)-nanmedian(curhusstxxNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        ylabel('Specific humidity change (g/kg)');
        set(gca, 'XTick', [1.5 5.5], 'XTickLabels', {'T-dominated', 'H-dominated'});
        xtickangle(45);
        xlim([0 7]);
        ylim([0 .005]);
        set(gca, 'YTick', 0:.001:.005, 'YTickLabels', 0:5);
        %title('Max T_W day');
        set(gca, 'YTick', 0:.001:.005);
        set(gca, 'fontsize', 36);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['bar-prc-txx-' num2str(e) '.eps']);
        close all;


















        fig = figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;

        ns = 20;
        b = bar([1 ns+1], [nanmedian(curtxwarmPos) nanmedian(curtxwarmNeg)], .05, 'k');
        set(b, 'facecolor', colorTxx, 'linewidth', 2);
        er = errorbar(1, nanmedian(curtxwarmPos), nanmedian(curtxwarmPos)-min(curtxwarmPos), max(curtxwarmPos)-nanmedian(curtxwarmPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+1, nanmedian(curtxwarmNeg), nanmedian(curtxwarmNeg)-min(curtxwarmNeg), max(curtxwarmNeg)-nanmedian(curtxwarmNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([6 ns+6], [nanmedian(curtxwbPos) nanmedian(curtxwbNeg)], .05, 'k');
        set(b, 'facecolor', colorTxx, 'linewidth', 2);
        er = errorbar(6, nanmedian(curtxwbPos), nanmedian(curtxwbPos)-min(curtxwbPos), max(curtxwbPos)-nanmedian(curtxwbPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+6, nanmedian(curtxwbNeg), nanmedian(curtxwbNeg)-min(curtxwbNeg), max(curtxwbNeg)-nanmedian(curtxwbNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([11 ns+11], [nanmedian(curtxtxxPos) nanmedian(curtxtxxNeg)], .05, 'k');
        set(b, 'facecolor', colorTxx, 'linewidth', 2);
        er = errorbar(11, nanmedian(curtxtxxPos), nanmedian(curtxtxxPos)-min(curtxtxxPos), max(curtxtxxPos)-nanmedian(curtxtxxPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+11, nanmedian(curtxtxxNeg), nanmedian(curtxtxxNeg)-min(curtxtxxNeg), max(curtxtxxNeg)-nanmedian(curtxtxxNeg));
        set(er, 'color', 'k', 'linewidth', 2);


        b = bar([2 ns+2], [nanmedian(curefwarmPos) nanmedian(curefwarmNeg)], .05, 'k');
        set(b, 'facecolor', colorWarm, 'linewidth', 2);
        er = errorbar(2, nanmedian(curefwarmPos), nanmedian(curefwarmPos)-min(curefwarmPos), max(curefwarmPos)-nanmedian(curefwarmPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+2, nanmedian(curefwarmNeg), nanmedian(curefwarmNeg)-min(curefwarmNeg), max(curefwarmNeg)-nanmedian(curefwarmNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([7 ns+7], [nanmedian(curefwbPos) nanmedian(curefwbNeg)], .05, 'k');
        set(b, 'facecolor', colorWarm, 'linewidth', 2);
        er = errorbar(7, nanmedian(curefwbPos), nanmedian(curefwbPos)-min(curefwbPos), max(curefwbPos)-nanmedian(curefwbPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+7, nanmedian(curefwbNeg), nanmedian(curefwbNeg)-min(curefwbNeg), max(curefwbNeg)-nanmedian(curefwbNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([12 ns+12], [nanmedian(cureftxxPos) nanmedian(cureftxxNeg)], .05, 'k');
        set(b, 'facecolor', colorWarm, 'linewidth', 2);
        er = errorbar(12, nanmedian(cureftxxPos), nanmedian(cureftxxPos)-min(cureftxxPos), max(cureftxxPos)-nanmedian(cureftxxPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+12, nanmedian(cureftxxNeg), nanmedian(cureftxxNeg)-min(cureftxxNeg), max(cureftxxNeg)-nanmedian(cureftxxNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([3 ns+3], [nanmedian(curhusswarmPos) nanmedian(curhusswarmNeg)], .05, 'k');
        set(b, 'facecolor', colorHuss, 'linewidth', 2);
        er = errorbar(3, nanmedian(curhusswarmPos), nanmedian(curhusswarmPos)-min(curhusswarmPos), max(curhusswarmPos)-nanmedian(curhusswarmPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+3, nanmedian(curhusswarmNeg), nanmedian(curhusswarmNeg)-min(curhusswarmNeg), max(curhusswarmNeg)-nanmedian(curhusswarmNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([8 ns+8], [nanmedian(curhusswbPos) nanmedian(curhusswbNeg)], .05, 'k');
        set(b, 'facecolor', colorHuss, 'linewidth', 2);
        er = errorbar(8, nanmedian(curhusswbPos), nanmedian(curhusswbPos)-min(curhusswbPos), max(curhusswbPos)-nanmedian(curhusswbPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+8, nanmedian(curhusswbNeg), nanmedian(curhusswbNeg)-min(curhusswbNeg), max(curhusswbNeg)-nanmedian(curhusswbNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        b = bar([13 ns+13], [nanmedian(curhusstxxPos) nanmedian(curhusstxxNeg)], .05, 'k');
        set(b, 'facecolor', colorHuss, 'linewidth', 2);
        er = errorbar(13, nanmedian(curhusstxxPos), nanmedian(curhusstxxPos)-min(curhusstxxPos), max(curhusstxxPos)-nanmedian(curhusstxxPos));
        set(er, 'color', 'k', 'linewidth', 2);
        er = errorbar(ns+13, nanmedian(curhusstxxNeg), nanmedian(curhusstxxNeg)-min(curhusstxxNeg), max(curhusstxxNeg)-nanmedian(curhusstxxNeg));
        set(er, 'color', 'k', 'linewidth', 2);

        %     er = errorbar(1, nanmedian(curtxxtxx), nanmedian(curtxxtxx)-min(curtxxtxx), max(curtxxtxx)-nanmedian(curtxxtxx));
    %     set(er, 'color', 'k', 'linewidth', 2);
    %     er = errorbar(5, nanmedian(curtxxwarm), nanmedian(curtxxwarm)-min(curtxxwarm), max(curtxxwarm)-nanmedian(curtxxwarm));
    %     set(er, 'color', 'k', 'linewidth', 2);
    %     er = errorbar(9, nanmedian(curtxxwb), nanmedian(curtxxwb)-min(curtxxwb), max(curtxxwb)-nanmedian(curtxxwb));
    %     set(er, 'color', 'k', 'linewidth', 2);

        ylabel('Normalized change');
        set(gca, 'XTick', [7 7+ns], 'XTickLabels', {'T_W+', 'T_W-'});
    %     ylim([0 7e-3]);
    %     set(gca, 'YTick', 1e-3 .* [0:7], 'YTickLabels', 0:7);
    %     xtickangle(45);
        xlim([-2 36]);
        set(gca, 'fontsize', 36);
        title(names{e}, 'fontsize', 36);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['ef-wb-txx-rel-chg-bar-' num2str(e) '.eps']);
        close all;

    end
end
    

amp = hussChgWarmSeason .* 1000;
driverRaw = txChgWarmSeason;
% amp = wbOnTxx;
% driverRaw = efOnTxx;

amp2 = [];%txChgWarmSeason;
driverRaw2 = [];%efChgWarmSeason;

unit = 'unit EF';

rind = 1;
efind = 1;
dslopes = [];
dslopesP = [];

dchg = [];

for m = 1:length(models)

   load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
    %efGroup = twGroup;
    
    a = squeeze(amp(:,:,m));
    a(waterGrid) = NaN;
    a(1:15,:) = NaN;
    a(75:90,:) = NaN;
    a = reshape(a, [numel(a),1]);

    driver = squeeze(driverRaw(:,:,m));
    driver(waterGrid) = NaN;
    driver(1:15,:) = NaN;
    driver(75:90,:) = NaN;
    driver = reshape(driver, [numel(driver),1]);
    
    if length(amp2) > 0
        a2 = squeeze(amp2(:,:,m));
        a2(waterGrid) = NaN;
        a2(1:15,:) = NaN;
        a2(75:90,:) = NaN;
        a2 = reshape(a2, [numel(a2),1]);

        driver2 = squeeze(driverRaw2(:,:,m));
        driver2(waterGrid) = NaN;
        driver2(1:15,:) = NaN;
        driver2(75:90,:) = NaN;
        driver2 = reshape(driver2, [numel(driver2),1]);
    end

    efGroup(waterGrid) = NaN;
    efGroup(1:15,:) = NaN;
    efGroup(75:90,:) = NaN;
    efGroup =  reshape(efGroup, [numel(efGroup),1]);

    if length(amp2) > 0
        nn = find(isnan(a) | isnan(driver) | isnan(a2) | isnan(driver2));
        driver2(nn) = [];
        aDriver2 = a2;
        aDriver2(nn) = [];
    else
        nn = find(isnan(a) | isnan(driver));
    end

    driver(nn) = [];
    aDriver = a;
    aDriver(nn) = [];

    efGroup(nn) = [];

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
        
        dchg(1, e, m) = nanmean(curADriver);

        f = fitlm(curDriver, curADriver, 'linear');
        dslopes(1, e, m) = f.Coefficients.Estimate(2);
        dslopesP(1, e, m) = f.Coefficients.pValue(2); 
        
        if length(amp2) > 0
            curDriver = driver2(nn);
            curADriver = aDriver2(nn);

            dchg(2, e, m) = nanmean(curADriver);

            f = fitlm(curDriver, curADriver, 'linear');
            dslopes(2, e, m) = f.Coefficients.Estimate(2);
            dslopesP(2, e, m) = f.Coefficients.pValue(2); 
        end

    end

end

% txxslopes=squeeze(dslopes(1,5,:));
% txxp=squeeze(dslopesP(1,5,:));
% if length(amp2) > 0
%     wbslopes=squeeze(dslopes(2,5,:))
%     wbp=squeeze(dslopesP(2,5,:));
% end
% 
% figure('Color',[1,1,1]);
% hold on; 
% axis square;
% box on;
% grid on;
% for m = 1:length(txxslopes)
%     t = text(txxslopes(m), wbslopes(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
%     t.FontSize = 26;
% end
% set(gca, 'XDir', 'reverse')
% xlim([-15 3])
% ylim([-3 15])
% set(gca, 'XTick', [-15 -10 -5 0 3]);
% xlabel(['TXx ' char(176) 'C / unit EF']);
% ylabel(['T_{W} ' char(176) 'C / unit EF']);
% set(gca, 'YTick', [-3 0 5 10 15]);
% plot([3 -15], [-3 15], '--k')
% set(gca, 'FontSize', 36);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig(['ef-txx-wb-slope-scatter.eps']);
% close all;


% dslopes = squeeze(dslopes);
% dslopesP = squeeze(dslopesP);
st = squeeze(dslopes);
[f,gof] = fit((1:4)', nanmedian(st(1:4,:),2), 'poly3');
fx = 1:.1:4;
fy = f(fx);

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
%b = boxplot(dslopes','positions',1:5);

%colorTxx = [160, 116, 46]./255.0;
%colorWb = [68, 166, 226]./255.0;


b = boxplot(squeeze(dslopes)');
for bind = 1:size(b, 2)
    set(b(:,bind), {'LineWidth', 'Color'}, {2, colorWb})
    lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
end

% for e = 1:size(dslopes,2)
%     for m = 1:size(dslopes,3)
%         
%         displacement = 0;
%         if length(amp2) > 0
%             displacement = -.1;
%         end
%         
%         if dslopesP(1, e, m) <= 0.05 && dslopes(1, e, m) < 0
%             b = plot(e+displacement, dslopes(1, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorWb);
%         elseif dslopesP(1, e, m) <= 0.05 && dslopes(1, e, m) > 0
%             b = plot(e+displacement, dslopes(1, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorWb);
%         else
%             b = plot(e+displacement, dslopes(1, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2);
%         end
%         
%         if length(amp2) > 0
%             if dslopesP(2, e, m) <= 0.05 && dslopes(2, e, m) < 0
%                 b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorTxx);
%             elseif dslopesP(2, e, m) <= 0.05 && dslopes(2, e, m) > 0
%                 b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorTxx);
%             else
%                 b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2);
%             end
%         end
%     end
%     
%     if length(amp2) > 0
%         b = plot([e-.2 e], [squeeze(nanmean(dslopes(1, e,:),3)) squeeze(nanmean(dslopes(1, e,:),3))], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
%         b = plot([e-.2 e], [squeeze(nanmedian(dslopes(1, e,:),3)) squeeze(nanmedian(dslopes(1, e,:),3))], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);
% 
%         b = plot([e e+.2], [squeeze(nanmean(dslopes(2, e,:),3)) squeeze(nanmean(dslopes(2, e,:),3))], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
%         b = plot([e e+.2], [squeeze(nanmedian(dslopes(2, e,:),3)) squeeze(nanmedian(dslopes(2, e,:),3))], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);
%     else
%         b = plot([e-.2 e+.2], [squeeze(nanmean(dslopes(1, e,:),3)) squeeze(nanmean(dslopes(1, e,:),3))], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
%         b = plot([e-.2 e+.2], [squeeze(nanmedian(dslopes(1, e,:),3)) squeeze(nanmedian(dslopes(1, e,:),3))], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);
%     end
% end

plot([0 6], [0 0], '--k', 'linewidth', 2);
%plot(fx, fy, '--k', 'LineWidth', 2, 'Color', [.5 .5 .5]);
%ylim(yrange);
%set(gca, 'YTick', yticks);
xlim([.5 5.5]);
%ylim([-.5 1]);
set(gca, 'FontSize', 36);
set(gca, 'XTick', 1:5, 'XTickLabel', {'Arid', 'Semi-arid', 'Temperate', 'Tropical', 'All'});
%set(gca, 'XTick', 1:5, 'XTickLabel', {'10', '30', '50', '70', '90'});
set(gca, 'YTick', -.5:.1:1);
xtickangle(45);
%xlabel('Climate zone');
ylabel(['g/kg per ' char(176) 'C Tx']);
%set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
%lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
%set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['spatial-huss-per-tx-chg-efgroup.eps']);
close all;
