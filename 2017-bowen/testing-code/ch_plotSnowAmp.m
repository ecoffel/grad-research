load lat;
load lon;

% load TNn amplification map
load ampAgreement-rcp85-23-cmip5-ann-min-all-2060-2080
tnnAmp = saveData.data{3};

% load snow change map
load snw-chg-1
snwChg = saveData.data{3};

% matched lists with change in tnn/snow at each grid cell
tnnCor = [];
snwCor = [];

% look only at NH
for xlat = 45:90
    for ylon = 1:size(tnnAmp, 2)
        if ~isnan(tnnAmp(xlat, ylon)) && ~isnan(snwChg(xlat, ylon)) && snwChg(xlat, ylon) ~= 0 && tnnAmp(xlat, ylon) ~= 0
            tnnCor(end+1) = tnnAmp(xlat, ylon);
            snwCor(end+1) = snwChg(xlat, ylon);
        end
    end
end

% count nan tiles - all tiles with no historical snow
snwCor(isnan(snwCor)) = 0;

% these are the possible amp levels
tChg = -6:1:6;
% the mean snow change corresponding to each amp level
meanSnwCor = [];
% and the std of snow change at each amp level
meanSnwStd = [];
% whether the snow change at each t level is significant at 95th percent
snwSig = [];

% go over all levels and find the mean/std snow change for all grid cells
for t = 1:length(tChg)
    if t < length(tChg)
        ind = find(tnnCor > tChg(t) & tnnCor <= tChg(t+1));
    else
        ind = find(tnnCor > tChg(t));
    end
    meanSnwCor(end+1) = nanmedian(snwCor(ind));
    meanSnwStd(end+1) = std(snwCor(ind));
    if length(ind) > 0
        snwSig(end+1) = length(find(sign(snwCor(ind)) == sign(meanSnwCor(end)))) >= .75*numel(ind);
        %snwSig(end+1) = kstest2(snwCor(ind), zeros(size(snwCor(ind))));
    else
        snwSig(end+1) = 0;
    end
end

% convert nan's into not sig (and we won't draw a marker)
snwSig(isnan(snwSig)) = 0;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;

msize = 15;

errorbar(tChg, meanSnwCor, meanSnwStd, 'o', 'MarkerSize', 15, 'LineWidth', 2, 'Color', [85/255.0, 158/255.0, 237/255.0]);
for t = 1:length(tChg)
    if snwSig(t)
        plot(tChg(t), meanSnwCor(t), 'o', 'MarkerSize', 15, 'MarkerFaceColor', [85/255.0, 158/255.0, 237/255.0], 'MarkerEdgeColor', [85/255.0, 158/255.0, 237/255.0]);
    end
end

%plot(-4:4, zeros(1,9), '--', 'Color', 'k', 'LineWidth', 2);

ylim([-100 50]);
xlim([-.25 6.25]);
set(gca, 'XTick', -2:6);
xlabel(['TNn amplification (' char(176) 'C)'], 'FontSize', 36, 'Color', [.1 .1 .1]);
ylabel('% Snow mass change', 'FontSize', 36, 'Color', [.1 .1 .1]);
set(gca, 'FontSize', 36);
set(gcf, 'Position', get(0,'Screensize'));
export_fig 'snow-tnn-amp.pdf';
%print(['snow-tnn-amp.eps'], '-depsc', '-r300');
close all;