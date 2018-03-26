load lat;
load lon;

% load TNn amplification map
load e:\data\projects\bowen\derived-chg\txxAmp.mat
ampVar = amp;

% load snow change map
load e:\data\projects\bowen\derived-chg\efChg-absolute.mat
derVar = efChg;

% matched lists with change in tnn/snow at each grid cell
gridTxx = [];
gridDer = [];

for model = 1:size(ampVar, 3)
    ind = 1;
    for xlat = 1:90
        for ylon = 1:size(ampVar, 2)
            if ~isnan(ampVar(xlat, ylon)) && ~isnan(derVar(xlat, ylon, model)) && derVar(xlat, ylon, model) ~= 0 && ampVar(xlat, ylon, model) ~= 0
                gridTxx(model, ind) = ampVar(xlat, ylon);
                gridDer(model, ind) = derVar(xlat, ylon);
            else
                gridTxx(model, ind) = NaN;
                gridDer(model, ind) = NaN;
            end
            ind = ind+1;
        end
    end
end

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
        ind = find(gridTxx > tChg(t) & gridTxx <= tChg(t+1));
    else
        ind = find(gridTxx > tChg(t));
    end
    meanMrsoChg(end+1) = nanmedian(derVar(ind));
    meanMrsoCorr(end+1) = nanmedian(mrsoCorr(ind));
    
    meanMrsoChgStd(end+1) = std(derVar(ind));
    meanMrsoCorrStd(end+1) = std(mrsoCorr(ind));
    if length(ind) > 0
        mrsoChgSig(end+1) = length(find(sign(derVar(ind)) == sign(meanMrsoChg(end)))) >= .75*numel(ind);
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