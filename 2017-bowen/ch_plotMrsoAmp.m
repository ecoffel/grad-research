load lat;
load lon;

% load TNn amplification map
load ampAgreement-rcp85-23-cmip5-ann-max-all-2060-2080
txxAmp = saveData.data{3};

% load snow change map
load mrso-chg-1
mrsoChgMap = saveData.data{3};

load mrso-bowen-corr-cmip5;
mrsoCorrMap = saveData.data{3};

% matched lists with change in tnn/snow at each grid cell
txxCor = [];
mrsoChg = [];
mrsoCorr = [];

for xlat = 1:90
    for ylon = 1:size(txxAmp, 2)
        if ~isnan(txxAmp(xlat, ylon)) && ~isnan(mrsoChgMap(xlat, ylon)) && mrsoChgMap(xlat, ylon) ~= 0 && txxAmp(xlat, ylon) ~= 0
            txxCor(end+1) = txxAmp(xlat, ylon);
            mrsoChg(end+1) = mrsoChgMap(xlat, ylon);
            mrsoCorr(end+1) = mrsoCorrMap(xlat, ylon);
        end
    end
end

% count nan tiles - all tiles with no historical snow
mrsoChg(isnan(mrsoChg)) = 0;

% these are the possible amp levels
tChg = -3:.5:3;
% the mean snow change corresponding to each amp level
meanMrsoChg = [];
meanMrsoCorr = [];
% and the std of snow change at each amp level
meanMrsoChgStd = [];
meanMrsoCorrStd = [];
% whether the snow change at each t level is significant at 95th percent
mrsoChgSig = [];
mrsoCorrSig = [];

% go over all levels and find the mean/std snow change for all grid cells
for t = 1:length(tChg)
    if t < length(tChg)
        ind = find(txxCor > tChg(t) & txxCor <= tChg(t+1));
    else
        ind = find(txxCor > tChg(t));
    end
    meanMrsoChg(end+1) = nanmedian(mrsoChg(ind));
    meanMrsoCorr(end+1) = nanmedian(mrsoCorr(ind));
    
    meanMrsoChgStd(end+1) = std(mrsoChg(ind));
    meanMrsoCorrStd(end+1) = std(mrsoCorr(ind));
    if length(ind) > 0
        mrsoChgSig(end+1) = length(find(sign(mrsoChg(ind)) == sign(meanMrsoChg(end)))) >= .75*numel(ind);
        mrsoCorrSig(end+1) = length(find(sign(mrsoCorr(ind)) == sign(meanMrsoCorr(end)))) >= .75*numel(ind);
        %snwSig(end+1) = kstest2(snwCor(ind), zeros(size(snwCor(ind))));
    else
        mrsoChgSig(end+1) = 0;
        mrsoCorrSig(end+1) = 0;
    end
end

% convert nan's into not sig (and we won't draw a marker)
mrsoChgSig(isnan(mrsoChgSig)) = 0;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;

msize = 15;

yyaxis left;
errorbar(tChg-0.05, meanMrsoChg, meanMrsoChgStd, 'o', 'MarkerSize', 15, 'LineWidth', 2, 'Color', [85/255.0, 158/255.0, 237/255.0]);
for t = 1:length(tChg)
    if mrsoChgSig(t)
        plot(tChg(t)-0.05, meanMrsoChg(t), 'o', 'MarkerSize', 15, 'MarkerFaceColor', [85/255.0, 158/255.0, 237/255.0], 'MarkerEdgeColor', [85/255.0, 158/255.0, 237/255.0]);
    end
end

ylabel('Soil moisture change (%)', 'FontSize', 36, 'Color', [.1 .1 .1]);
ylim([-5 5]);
set(gca, 'YTick', -5:5);

yyaxis right;
errorbar(tChg+0.05, meanMrsoCorr, meanMrsoCorrStd, 'o', 'MarkerSize', 15, 'LineWidth', 2, 'Color', [242, 106, 72]./255.0);
for t = 1:length(tChg)
    if mrsoCorrSig(t)
        plot(tChg(t)+0.05, meanMrsoCorr(t), 'o', 'MarkerSize', 15, 'MarkerFaceColor', [242, 106, 72]./255.0, 'MarkerEdgeColor', [242, 106, 72]./255.0);
    end
end

ylabel('Soil moisture - Bowen ratio correlation', 'FontSize', 36, 'Color', [.1 .1 .1]);
ylim([-1 0]);
%plot(-4:4, zeros(1,9), '--', 'Color', 'k', 'LineWidth', 2);

xlim([-.25 2.75]);
set(gca, 'XTick', 0:.5:2.5);
xlabel(['TXx amplification (' char(176) 'C)'], 'FontSize', 36, 'Color', [.1 .1 .1]);
set(gca, 'FontSize', 36);
set(gcf, 'Position', get(0,'Screensize'));
export_fig 'bowen-txx-amp.pdf';
%print(['snow-tnn-amp.eps'], '-depsc', '-r300');
close all;