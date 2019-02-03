ssps = 1:5;
decades = 2010:10:2080;

sspData = [];

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;

colors = brewermap(7,'Reds');
colors = colors([3 5 7 6 4],:);

for ssp = ssps
    for d = 1:length(decades)
        decade = decades(d);
        load(['E:\data\ssp-pop\ssp' num2str(ssp) '\output\ssp' num2str(ssp) '\regrid\ssp' num2str(ssp) '_' num2str(decade)]);
        eval(['curSsp = ssp' num2str(ssp) '_' num2str(decade) ';']);
        
        sspData(ssp, d) = sum(sum(curSsp{3}));
    end
    
    plot(decades, sspData(ssp, :), 'LineWidth', 4, 'Color', colors(ssp, :));
end

set(gcf, 'units', 'points', 'position', [0, 0, 1000, 1000]);
set(gca, 'xtick', 2010:10:2080);
xlim([2005 2085]);
xtickangle(45);
set(gca, 'yticklabels', {'6B', '7B', '8B', '9B', '10B', '11B', '12B'});
legend('SSP 1', 'SSP 2', 'SSP 3', 'SSP 4', 'SSP 5', 'location', 'northwest');
legend boxoff;
ylabel('Global population', 'FontSize', 30);
set(gca, 'FontSize', 40);

set(gcf, 'Position', get(0,'Screensize'));
export_fig ssp-analysis.png -m3;
close all;
