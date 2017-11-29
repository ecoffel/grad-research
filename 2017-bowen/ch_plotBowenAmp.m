load lat;
load lon;

% load TNn amplification map
load ampAgreement-rcp85-23-cmip5-ann-max-all-2060-2080
txxAmp = saveData.data{3};

% load snow change map
load bowen-chg-hottest-cmip5
bowenChgMap = saveData.data{3};

load tmax-bowen-corr-cmip5;
bowenCorrMap = saveData.data{3};

% matched lists with change in tnn/snow at each grid cell
txxCor = [];
bowenChg = [];
bowenCorr = [];

for xlat = 1:90
    for ylon = 1:size(txxAmp, 2)
        if ~isnan(txxAmp(xlat, ylon)) && ~isnan(bowenChgMap(xlat, ylon)) && bowenChgMap(xlat, ylon) ~= 0 && txxAmp(xlat, ylon) ~= 0
            txxCor(end+1) = txxAmp(xlat, ylon);
            bowenChg(end+1) = bowenChgMap(xlat, ylon);
            bowenCorr(end+1) = bowenCorrMap(xlat, ylon);
        end
    end
end

% count nan tiles - all tiles with no historical snow
bowenChg(isnan(bowenChg)) = 0;

% these are the possible amp levels
tChg = -3:.5:3;
% the mean snow change corresponding to each amp level
meanBowenChg = [];
meanBowenCorr = [];
% and the std of snow change at each amp level
meanBowenChgStd = [];
meanBowenCorrStd = [];
% whether the snow change at each t level is significant at 95th percent
bowenChgSig = [];
bowenCorrSig = [];

% go over all levels and find the mean/std snow change for all grid cells
for t = 1:length(tChg)
    if t < length(tChg)
        ind = find(txxCor > tChg(t) & txxCor <= tChg(t+1));
    else
        ind = find(txxCor > tChg(t));
    end
    meanBowenChg(end+1) = nanmedian(bowenChg(ind));
    meanBowenCorr(end+1) = nanmedian(bowenCorr(ind));
    
    meanBowenChgStd(end+1) = std(bowenChg(ind));
    meanBowenCorrStd(end+1) = std(bowenCorr(ind));
    if length(ind) > 0
        bowenChgSig(end+1) = length(find(sign(bowenChg(ind)) == sign(meanBowenChg(end)))) >= .75*numel(ind);
        bowenCorrSig(end+1) = length(find(sign(bowenCorr(ind)) == sign(meanBowenCorr(end)))) >= .75*numel(ind);
        %snwSig(end+1) = kstest2(snwCor(ind), zeros(size(snwCor(ind))));
    else
        bowenChgSig(end+1) = 0;
        bowenCorrSig(end+1) = 0;
    end
end

% convert nan's into not sig (and we won't draw a marker)
bowenChgSig(isnan(bowenChgSig)) = 0;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;

msize = 15;

yyaxis left;
errorbar(tChg-0.05, meanBowenChg, meanBowenChgStd, 'o', 'MarkerSize', 15, 'LineWidth', 2, 'Color', [85/255.0, 158/255.0, 237/255.0]);
for t = 1:length(tChg)
    if bowenChgSig(t)
        plot(tChg(t)-0.05, meanBowenChg(t), 'o', 'MarkerSize', 15, 'MarkerFaceColor', [85/255.0, 158/255.0, 237/255.0], 'MarkerEdgeColor', [85/255.0, 158/255.0, 237/255.0]);
    end
end

ylabel('Bowen ratio change (%)', 'FontSize', 36, 'Color', [.1 .1 .1]);
ylim([-50 75]);

yyaxis right;
errorbar(tChg+0.05, meanBowenCorr, meanBowenCorrStd, 'o', 'MarkerSize', 15, 'LineWidth', 2, 'Color', [242, 106, 72]./255.0);
for t = 1:length(tChg)
    if bowenCorrSig(t)
        plot(tChg(t)+0.05, meanBowenCorr(t), 'o', 'MarkerSize', 15, 'MarkerFaceColor', [242, 106, 72]./255.0, 'MarkerEdgeColor', [242, 106, 72]./255.0);
    end
end

ylabel('Bowen ratio - Tx correlation', 'FontSize', 36, 'Color', [.1 .1 .1]);
ylim([0 1]);
%plot(-4:4, zeros(1,9), '--', 'Color', 'k', 'LineWidth', 2);

xlim([-.25 2.75]);
set(gca, 'XTick', 0:.5:2.5);
xlabel(['TXx amplification (' char(176) 'C)'], 'FontSize', 36, 'Color', [.1 .1 .1]);
set(gca, 'FontSize', 36);
set(gcf, 'Position', get(0,'Screensize'));
export_fig 'bowen-txx-amp.pdf';
%print(['snow-tnn-amp.eps'], '-depsc', '-r300');
close all;