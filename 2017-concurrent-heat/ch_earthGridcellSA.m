load lat
load lon

earthSA = [];

for x = 1:size(lat, 1)
    ['x = ' num2str(x)]
    for y = 1:size(lon, 2)
        earthSA(x, y) = ch_gridcellSA(x, y);
    end
end

save('earthSA', 'earthSA');