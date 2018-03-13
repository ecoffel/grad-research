function [posAnom, thresh] = findPosZgAnom(dailyZg, startingThresh)
    posAnom = zeros(size(dailyZg,1), size(dailyZg,2), size(dailyZg,3));
    for xlat = 1:size(dailyZg,1)
        for ylon = 1:size(dailyZg,2)
            
            if startingThresh == -1
                z = reshape(squeeze(dailyZg(xlat, ylon, :, :, :)), [numel(dailyZg(xlat, ylon, :, :, :)), 1]);
                thresh(xlat, ylon) = prctile(z, 90);
            else
                thresh(xlat, ylon) = startingThresh(xlat, ylon)
            end
            
            for year = 1:size(dailyZg,3)
                z = reshape(permute(squeeze(dailyZg(xlat, ylon, year, :, :)), [2 1]), [numel(dailyZg(xlat, ylon, year, :, :)), 1]);
                z = find(z >= thresh(xlat, ylon));
                x = (diff(z))'==1;
                f = find([false, x] ~= [x, false]);
                if length(f) < 2
                    posAnom(xlat,ylon,year) = 0;
                else
                    posAnom(xlat,ylon,year) = max(f(2:2:end)-f(1:2:end-1));
                end
            end
        end
    end
end