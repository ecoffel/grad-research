f = av2_loadSurfaces();

figure('Color', [1,1,1]);
%hold on;

aircraft = 'a380';
surface = [];

if strcmp(aircraft, '787')
    temp1 = 25;
    temp2 = 55;
    weight1 = 420;
    weight2 = 502;
    surface = f{4}{2};
elseif strcmp(aircraft, '737-800')
    temp1 = 25;
    temp2 = 55;
    weight1 = 110;
    weight2 = 174;
    surface = f{1}{2};
elseif strcmp(aircraft, '777-300')
    temp1 = 25;
    temp2 = 55;
    weight1 = 460;
    weight2 = 660;
    surface = f{3}{2};
elseif strcmp(aircraft, 'a320')
    temp1 = 25;
    temp2 = 55;
    weight1 = 100;
    weight2 = 174;
    surface = f{5}{2};
elseif strcmp(aircraft, 'a380')
    temp1 = 25;
    temp2 = 55;
    weight1 = 840;
    weight2 = 1260;
    surface = f{6}{2};
end

x = linspace(temp1, temp2, 50);
y = linspace(weight1, weight2, 50);
[X, Y] = meshgrid(x,y);

Z = surface(X, Y);
Z(Z < 6000) = NaN;
Z(Z > 16000) = NaN;

surf(X, Y, Z, 'EdgeColor', 'none');
xlim([temp1 temp2]);
ylim([weight1 weight2]);
xlabel(['Temperature (' char(176) 'C)'], 'FontSize', 30);
ylabel('Weight (1000 lbs)', 'FontSize', 30);
zlabel('Runway length (ft)', 'FontSize', 30);
set(gca, 'FontSize', 26, 'LineWidth', 2);

cb = colorbar('eastoutside');
caxis([6000 16000]);
set(cb, 'YTick', [6000 8000 10000 12000 14000 16000]);
set(cb, 'YTickLabel', {'6,000', '8,000', '10,000', '12,000', '14,000', '16,000'});
set(cb, 'FontSize', 24);

set(gcf, 'Position', get(0,'Screensize'));

% reset colorbar position
cbPos = get(cb, 'OuterPosition');
set(cb, 'OuterPosition', [cbPos(1)+0.02 cbPos(2)+0.21 cbPos(3) + 0.02 cbPos(4) - 0.45])
