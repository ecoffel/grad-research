load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2010.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2060.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2070.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2060.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2070.mat
load E:\data\projects\bowen\derived-chg\txxAmp.mat

expHist = [];
exp5 = [];
exp3 = [];

histPop = ssp3_2010{3};
futurePop3 = (ssp3_2060{3}+ssp3_2070{3}) ./ 2;
futurePop5 = (ssp5_2060{3}+ssp5_2070{3}) ./ 2;

thresh = 1:.5:2.5;

for m = 1:size(amp, 3)
    for t = 1:length(thresh)
        expHist(m,t) = sum(sum(histPop(amp(:,:,m)>thresh(t))));
        exp5(m,t) = sum(sum(futurePop5(amp(:,:,m)>thresh(t))));
        exp3(m,t) = sum(sum(futurePop3(amp(:,:,m)>thresh(t))));
    end
end

figure('Color',[1,1,1]);
hold on;
axis square;
grid on;
box on;

b = boxplot([expHist(:,1) exp3(:,1) exp5(:,1) ...
         expHist(:,3) exp3(:,3) exp5(:,3) ...
         expHist(:,4) exp3(:,4) exp5(:,4)], 'positions', [.8 1 1.2 ...
                                                          1.8 2 2.2 ...
                                                          2.8 3 3.2], 'colors', 'gbrgbrgbr');

for bind = 1:size(b, 2)
    if ismember(bind, [1 4 7])
        set(b(:,bind), {'LineWidth', 'Color'}, {2, [101, 183, 34] ./ 255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    elseif ismember(bind, [2 5 8])
        set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    else
        set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    end
end                                                      
xlim([0 4]);
ylim([-.1e9, 3.6e9])
set(gca, 'XTick', [1 2 3], 'XTickLabels', {['1' char(176) 'C'], ['2' char(176) 'C'], ['2.5' char(176) 'C']});
set(gca, 'YTick', [0:.5:3.5].*1e9, 'YTickLabels', 0:.5:3.5);
ylabel('Population exposure (Billions)');
xlabel('TXx amplification');
set(gca, 'FontSize', 40);