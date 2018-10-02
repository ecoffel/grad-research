
grid2020 = [];
grid2030 = [];
grid2040 = [];
grid2050 = [];
grid2060 = [];
grid2070 = [];

for m = 1:18
    load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-2020s-rcp85-32C-scenario-' num2str(m)]);
    grid2020=logical(selGrid);
    load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-2030s-rcp85-32C-scenario-' num2str(m)]);
    grid2030=logical(selGrid);
    load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-2040s-rcp85-32C-scenario-' num2str(m)]);
    grid2040=logical(selGrid);
    load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-2050s-rcp85-32C-scenario-' num2str(m)]);
    grid2050=logical(selGrid);
    load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-2060s-rcp85-32C-scenario-' num2str(m)]);
    grid2060=logical(selGrid);
    load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-2070s-rcp85-32C-scenario-' num2str(m)]);
    grid2070=logical(selGrid);



load lat;
load lon;

data = grid2020;
fout = fopen(['exp2020-' num2str(m) '.csv'], 'w');
% output water grid
for x = 1:size(data, 1)
for y = 1:size(data, 2)
if y == size(data, 2)
% no comma
fprintf(fout, '%d', data(x,y));
else
% comma
fprintf(fout, '%d,', data(x,y));
end
end
% new line after each row
fprintf(fout, '\r\n');
end
fclose(fout);

data = grid2030;
fout = fopen(['exp2030-' num2str(m) '.csv'], 'w');
% output water grid
for x = 1:size(data, 1)
for y = 1:size(data, 2)
if y == size(data, 2)
% no comma
fprintf(fout, '%d', data(x,y));
else
% comma
fprintf(fout, '%d,', data(x,y));
end
end
% new line after each row
fprintf(fout, '\r\n');
end
fclose(fout);

data = grid2040;
fout = fopen(['exp2040-' num2str(m) '.csv'], 'w');
% output water grid
for x = 1:size(data, 1)
for y = 1:size(data, 2)
if y == size(data, 2)
% no comma
fprintf(fout, '%d', data(x,y));
else
% comma
fprintf(fout, '%d,', data(x,y));
end
end
% new line after each row
fprintf(fout, '\r\n');
end
fclose(fout);

data = grid2050;
fout = fopen(['exp2050-' num2str(m) '.csv'], 'w');
% output water grid
for x = 1:size(data, 1)
for y = 1:size(data, 2)
if y == size(data, 2)
% no comma
fprintf(fout, '%d', data(x,y));
else
% comma
fprintf(fout, '%d,', data(x,y));
end
end
% new line after each row
fprintf(fout, '\r\n');
end
fclose(fout);

data = grid2060;
fout = fopen(['exp2060-' num2str(m) '.csv'], 'w');
% output water grid
for x = 1:size(data, 1)
for y = 1:size(data, 2)
if y == size(data, 2)
% no comma
fprintf(fout, '%d', data(x,y));
else
% comma
fprintf(fout, '%d,', data(x,y));
end
end
% new line after each row
fprintf(fout, '\r\n');
end
fclose(fout);

data = grid2070;
fout = fopen(['exp2070-' num2str(m) '.csv'], 'w');
% output water grid
for x = 1:size(data, 1)
for y = 1:size(data, 2)
if y == size(data, 2)
% no comma
fprintf(fout, '%d', data(x,y));
else
% comma
fprintf(fout, '%d,', data(x,y));
end
end
% new line after each row
fprintf(fout, '\r\n');
end
fclose(fout);
end

