load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2010.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2060.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2070.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2060.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2070.mat
load recurChg-99-movingWarm.mat;

amp = squeeze(nanmean(data{3},3))-squeeze(nanmean(data{2},3));

expHist = [];
exp5 = [];
exp3 = [];

histPop = ssp3_2010{3};
futurePop3 = (ssp3_2060{3}+ssp3_2070{3}) ./ 2;
futurePop5 = (ssp5_2060{3}+ssp5_2070{3}) ./ 2;

bins = -20:8:20;
binlabels = {};
bplotrows = [];
bplotpos = [];


for b = 1:length(bins)+3
    
    if b == 1
        binlabels{b} = ['< ' num2str(bins(b))];
    elseif b == length(bins)+1
        binlabels{b} = ['> ' num2str(bins(b-1))];
    elseif b < length(bins)+1
        binlabels{b} = [num2str(bins(b-1)) ' - ' num2str(bins(b))];
    end

    for m = 1:size(amp, 3)
        
        if b == 1
            % < first bin
            expHist(m,b) = nansum(nansum(histPop(amp(:,:,m)<bins(b))));
            exp5(m,b) = nansum(nansum(futurePop5(amp(:,:,m)<bins(b))));
            exp3(m,b) = nansum(nansum(futurePop3(amp(:,:,m)<bins(b))));
        elseif b == length(bins)+1
            % > last bin
            expHist(m,b) = nansum(nansum(histPop(amp(:,:,m)>bins(b-1))));
            exp5(m,b) = nansum(nansum(futurePop5(amp(:,:,m)>bins(b-1))));
            exp3(m,b) = nansum(nansum(futurePop3(amp(:,:,m)>bins(b-1))));
        elseif b == length(bins)+2
            % # with posdays
            expHist(m,b) = nansum(nansum(histPop(amp(:,:,m) > 0)));
            exp5(m,b) = nansum(nansum(futurePop5(amp(:,:,m) > 0)));
            exp3(m,b) = nansum(nansum(futurePop3(amp(:,:,m) > 0)));
        elseif b == length(bins)+3
            % # with neg days
            expHist(m,b) = -nansum(nansum(histPop(amp(:,:,m) < 0)));
            exp5(m,b) = -nansum(nansum(futurePop5(amp(:,:,m) < 0)));
            exp3(m,b) = -nansum(nansum(futurePop3(amp(:,:,m) < 0)));
        else
            % between bins
            expHist(m,b) = nansum(nansum(histPop(amp(:,:,m)>=bins(b-1) & amp(:,:,m)<bins(b))));
            exp5(m,b) = nansum(nansum(futurePop5(amp(:,:,m)>=bins(b-1) & amp(:,:,m)<bins(b))));
            exp3(m,b) = nansum(nansum(futurePop3(amp(:,:,m)>=bins(b-1) & amp(:,:,m)<bins(b))));
            
        end
        
    end
    
    bplotrows = [bplotrows expHist(:,b) exp3(:,b) exp5(:,b)];
    bplotpos = [bplotpos b-.2 b b+.2];
    
end

figure('Color',[1,1,1]);
hold on;
axis square;
grid on;
box on;

b = boxplot(bplotrows, 'positions', bplotpos);

for bind = 1:size(b, 2)
    if ismember(bind, 1:3:30)
        set(b(:,bind), {'LineWidth', 'Color'}, {2, [101, 183, 34] ./ 255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    elseif ismember(bind, 2:3:30)
        set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    else
        set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    end
end                                                      
xlim([.5 7.5]);
ylim([-.1e9, 5.5e9])
set(gca, 'XTick', 1:length(bins)+1, 'XTickLabels', binlabels);
xtickangle(45);
set(gca, 'YTick', [0:1:5.5].*1e9, 'YTickLabels', 0:1:5.5);
set(gca, 'FontSize', 36);
ylabel('Exposure (Billions)');
xlabel('Additional days');
set(gca, 'FontSize', 36);



figure('Color',[1,1,1]);
hold on;

y = [squeeze(nanmedian(expHist(:,end),1)) squeeze(nanmedian(expHist(:,end-1),1)); ...
     squeeze(nanmedian(exp3(:,end),1)) squeeze(nanmedian(exp3(:,end-1),1)); ...
     squeeze(nanmedian(exp5(:,end),1)) squeeze(nanmedian(exp5(:,end-1),1))];
bar([1 2 3], y(:,2));
bar([1 2 3], y(:,1));


