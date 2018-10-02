ssps = 1:5;
decades = 2010:10:2080;

sspData = [];

colors = [[66, 134, 244]; ...
          [61, 191, 113]; ...
          [219, 87, 100]; ...
          [224, 123, 51]; ...
          [229, 66, 71]];
      
colors = colors ./ 255.0;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;
for ssp = ssps
    for d = 1:length(decades)
        decade = decades(d);
        load(['E:\data\ssp-pop\ssp' num2str(ssp) '\output\ssp' num2str(ssp) '\regrid\ssp' num2str(ssp) '_' num2str(decade)]);
        eval(['curSsp = ssp' num2str(ssp) '_' num2str(decade) ';']);
        
        sspData(ssp, d) = sum(sum(curSsp{3}));
    end
    
    plot(decades, sspData(ssp, :), 'LineWidth', 3, 'Color', colors(ssp, :));
end

set(gcf, 'units', 'points', 'position', [0, 0, 1000, 1000]);
legend('SSP1', 'SSP2', 'SSP3', 'SSP4', 'SSP5');
ylabel('Global population', 'FontSize', 30);
set(gca, 'FontSize', 28);

