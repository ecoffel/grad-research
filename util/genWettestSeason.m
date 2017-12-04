prNcep = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid/world', 'yearStart', 1980, 'yearEnd', 2015);
prNcep{3} = prNcep{3} .* 3600 .* 24;
prNcep = dailyToMonthly(prNcep);
prNcep = prNcep{3};

seasons = [[12 1 2];
               [3 4 5];
               [6 7 8];
               [9 10 11]];

wettestSeason = [];

for xlat = 1:size(prNcep, 1)
    for ylon = 1:size(prNcep, 2)
        
        sind = -1;
        stemp = -1;
        
        for s = 1:size(seasons, 1)
            t = squeeze(nanmean(nanmean(prNcep(xlat, ylon, :, seasons(s,:)), 4), 3));
            if sind == -1 || t > stemp
                sind = s;
                stemp = t;
            end
        end
        
        wettestSeason(xlat, ylon) = sind;
    end
end

save('wettest-season-ncep.mat', 'wettestSeason');
