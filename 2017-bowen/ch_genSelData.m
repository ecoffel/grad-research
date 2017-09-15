function [selData] = ch_genSelData(temps, thresh, landOnly)
% genSelData Find grid cells that exceed a threshold
%   temps: 4D grid of base temperatures. Dims: x, y, day, year
%   thresh: 2D grid of threshold temperatures. Dims: x, y
%   landOnly: boolean, should we only consider land temps. Requires
%   waterGrid.

    if landOnly
        load waterGrid;
        waterGrid = logical(waterGrid);
    end

    selData = [];

    for year = 1:size(temps, 4)
        curSelData = [];
        for x = 1:size(temps, 1)
            for y = 1:size(temps, 2)

                curSelData(x, y) = length(find(squeeze(temps(x, y, :, year)) > thresh(x, y)));

            end
        end
        if landOnly
            curSelData(waterGrid) = NaN;    
        end
        selData(:, :, year) = curSelData;
    end
end