f = av2_loadSurfaces();

figure('Color', [1,1,1]);
%hold on;

aircraft = '737-800';
surface = [];

if strcmp(aircraft, '787')
    temp1 = 15;
    temp2 = 50;
    weight1 = 420;
    weight2 = 502;
    surface = f{2}{2};
elseif strcmp(aircraft, '737-800')
    temp1 = 15;
    temp2 = 50;
    weight1 = 110;
    weight2 = 174;
    surface = f{1}{2};
elseif strcmp(aircraft, '777-300')
    temp1 = 15;
    temp2 = 50;
    weight1 = 460;
    weight2 = 660;
    surface = f{3}{2};
end
x = linspace(temp1, temp2, 50);
y = linspace(weight1, weight2, 50);
[X, Y] = meshgrid(x,y);

Z = surface(X, Y);

surf(X, Y, Z, 'EdgeColor', 'none');
xlabel('Temperature (C)', 'FontSize', 30);
ylabel('Weight (1000 lbs)', 'FontSize', 30);
zlabel('Runway length (ft)', 'FontSize', 30);
set(gca, 'FontSize', 26, 'LineWidth', 2);