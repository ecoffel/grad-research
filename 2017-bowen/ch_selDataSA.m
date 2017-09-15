function [sa] = ch_selDataSA(selData, earthSA)
% selDataSA Find surface area on earth of a particular selection grid
%   selData: 2D lat/lon boolean grid of selected grid cells

    sa = 0;
    
    load earthSA;
    
    for x = 1:size(selData, 1)
        for y = 1:size(selData, 2)
            if selData(x, y)
                sa = sa + earthSA(x, y);
            end
        end
    end
    
end