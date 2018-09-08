data = saveData.data{3}(:,1:180);

%wb(hi == 0) = NaN;
%hi(hi == 0) = NaN;

dataHi = [];
for xlat = 1:size(data, 1)
    for ylon = 1:size(data, 2)
        if ~isnan(data(xlat, ylon))
            [ix,iy] = find(abs(wb-data(xlat, ylon)) < .25);
            if nanmean(nanmean(hi(ix,iy))) > 80
                dataHi(xlat, ylon) = nanmean(nanmean(hi(ix,iy)));
            else
                dataHi(xlat, ylon) = NaN;
            end
        else
            dataHi(xlat, ylon) = NaN;
        end
    end
end

%dataHi = dataHi .* 9/5 + 32;