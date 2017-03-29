% show a box plot of projected over-land tasmax/wb change

type = 'multi-model';
years = [2070, 2080];

plotRegion = 'world';
plotRange = [0 6];
plotYUnits = ['Change, ' char(176) 'C'];

meanStr = 'extreme';   
var = 'wb';

varTitle = 'Temperature';
if strcmp(var, 'wb')
    varTitle = 'Wet bulb temperature';
end

% load lat/lon grid
load lat;
load lon;

load waterGrid
waterGrid = logical(waterGrid);

% load rcp45 and rcp85 changes
load(['chg-data/chg-data-' var '-rcp45-' type '-' meanStr '-' num2str(years(1)) '-' num2str(years(2)) '.mat']);
chgData45 = real(chgData);

load(['chg-data/chg-data-' var '-rcp85-' type '-' meanStr '-' num2str(years(1)) '-' num2str(years(2)) '.mat']);
chgData85 = real(chgData);

% throw out the occasional bad grid cell
chgData45(chgData45 > 10 | chgData45 < -5) = NaN;
chgData85(chgData85 > 10 | chgData85 < -5) = NaN;

% eliminate water tiles across all models so that we can calculate
% land-only temp change
for xlat = 1:size(waterGrid, 1)
    for ylon = 1:size(waterGrid, 2)
        % loop over models in chgData
        for m = 1:size(chgData45, 3)
            % if water tile, set to NaN
            if waterGrid(xlat, ylon)
                chgData45(xlat, ylon, m) = NaN;
                chgData85(xlat, ylon, m) = NaN;
            end
        end
    end
end

% compute land-only mean change for each model
meanChg45 = squeeze(nanmean(nanmean(chgData45, 2), 1));
meanChg85 = squeeze(nanmean(nanmean(chgData85, 2), 1));

boxPlotData = [meanChg45, meanChg85];
boxPlotGroup = [0 1];

figure('Color', [1,1,1]);
hold on;
grid on;
b = boxplot(boxPlotData, boxPlotGroup, 'Labels', {'RCP 4.5', 'RCP 8.5'});
%title(airports{aInd}, 'FontSize', 30);
set(findobj(gca, 'Type', 'text'), 'FontSize', 30, 'VerticalAlignment', 'middle');
set(gca, 'FontSize', 30);
ylabel(plotYUnits, 'FontSize', 30);
for ih = 1:length(b)
    set(b(ih,:), 'LineWidth', 2); % Set the line width of the Box outlines here
end
ylim(plotRange);

set(gcf, 'Position', get(0,'Screensize'));
daspect([1 1.5 1])


