function [dryDays] = findDryDays(dailyPr)
    thresh = 0.1 / 3600.0 / 24.0;
    dryDays = zeros(size(dailyPr,1), size(dailyPr,2), size(dailyPr,3), size(dailyPr,4));
    for y = 1:size(dailyPr,3)
        for m = 1:size(dailyPr,4)
            for xlat = 1:size(dailyPr,1)
                for ylon = 1:size(dailyPr,2)
                    dryDays(xlat,ylon,y,m) = length(find(squeeze(dailyPr(xlat,ylon,y,m,:)) < thresh));
                end
            end
        end
    end
end