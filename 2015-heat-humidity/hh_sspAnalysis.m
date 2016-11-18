ssps = 1:5;
decades = 2010:10:2080;

sspData = [];

colors = distinguishable_colors(5);

figure('Color', [1,1,1]);
hold on;
for ssp = ssps
    for d = 1:length(decades)
        decade = decades(d);
        load(['C:\git-ecoffel\grad-research\ssp\ssp' num2str(ssp) '\output\ssp' num2str(ssp) '\regrid\ssp' num2str(ssp) '_' num2str(decade)]);
        eval(['curSsp = ssp' num2str(ssp) '_' num2str(decade) ';']);
        
        sspData(ssp, d) = sum(sum(curSsp{3}));
    end
    
    plot(decades, sspData(ssp, :), 'LineWidth', 2, 'Color', colors(ssp, :));
end

title('SSP population scenarios', 'FontSize', 40);
legend('SSP1', 'SSP2', 'SSP3', 'SSP4', 'SSP5');
ylabel('Global population', 'FontSize', 30);
set(gca, 'FontSize', 28);

