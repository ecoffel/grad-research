function [dryDays] = findConsecDryDays(dailyPr)
    thresh = 0.1 / 3600.0 / 24.0;
    dryDays = zeros(size(dailyPr,1), size(dailyPr,2), size(dailyPr,3), size(dailyPr,4));
    for y = 1:size(dailyPr,3)
        for m = 1:size(dailyPr,4)
            for xlat = 1:size(dailyPr,1)
                for ylon = 1:size(dailyPr,2)
                    dd = find(squeeze(dailyPr(xlat,ylon,y,m,:)) < thresh);
                    
                    x = (diff(dd))'==1;
                    f = find([false, x] ~= [x, false]);
                    if length(f) < 2
                        dryDays(xlat,ylon,y,m) = 0;
                    else
                        dryDays(xlat,ylon,y,m) = max(f(2:2:end)-f(1:2:end-1));
                    end
                end
            end
        end
    end
end