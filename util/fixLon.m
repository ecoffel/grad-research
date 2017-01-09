load E:\data\cmip5\output\gfdl-cm3\r1i1p1\historical\tos\19700101-19741231\tos_1970_01_01.mat
tos = tos_1970_01_01;
tos{3}=tos{3}(:,:,1);

gridSpacing = 2;

latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
baseGrid = {latGrid, lonGrid, []};

tos{2} = tos{2} + 360;
tos{2}(tos{2} > 360) = tos{2}(tos{2} > 360) - 360;

x = regridGriddata(tos, baseGrid);

for x = 1:size(tos{2},1)
    lonRowTos = tos{2}(x,:);
    diff = lonRowTos(1);
    % this is how many units each cell should be shifted
    ind = find(abs(lonRowTos)==min(abs(lonRowTos)));
    
    tos{1}(x,:) = circshift(tos{1}(x,:), -ind(1)+1, 2);
    tos{2}(x,:) = circshift(tos{2}(x,:), -ind(1)+1, 2);
    tos{3}(x,:) = circshift(tos{3}(x,:), -ind(1)+1, 2);
    
end


