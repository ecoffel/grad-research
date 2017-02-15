aircraft = '787';
wrBaseDir = '2015-weight-restriction-v2/wr-data/';

surfs = av2_loadSurfaces();

tempRange = 20:55;

if strcmp(aircraft, '737-800')
    runwayRange = 4000:1000:12000;
elseif strcmp(aircraft, 'a320')
    runwayRange = 4000:1000:12000;
elseif strcmp(aircraft, 'a380')
    runwayRange = 6000:1000:15000;
elseif strcmp(aircraft, '777-300')
    runwayRange = 6000:1000:15000;
elseif strcmp(aircraft, '787')
    runwayRange = 6000:1000:15000;
end

colors = distinguishable_colors(length(runwayRange));

wr = [];

for t = 1:length(tempRange)
    for r = 1:length(runwayRange)
        wr(t, r) = av2_calcWeightRestriction(tempRange(t), runwayRange(r), 0, aircraft, surfs);
    end
end

figure('Color', [1,1,1]);
hold on;

lines = [];
legendStr = '';
for i = 1:size(wr, 2)
    lines(end+1) = plot(tempRange(:), wr(:, i), 'LineWidth', 2, 'Color', colors(i, :));
    
    if length(legendStr) > 0
        legendStr = [legendStr ',''' num2str(runwayRange(i)) ' ft '''];
    else
        legendStr = ['''' num2str(runwayRange(i)) ' ft'''];
    end
end

eval(['legend(lines, ' legendStr ');']);
xlabel('Temp (C)', 'FontSize', 24);
ylabel('WR (1000s lbs)', 'FontSize', 24);
title(aircraft, 'FontSize', 30);