tasmaxNcep = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1980, 'yearEnd', 2015);
tasmaxNcep{3} = tasmaxNcep{3} - 273.15;
tasmaxNcep = dailyToMonthly(tasmaxNcep);
tasmaxNcep = tasmaxNcep{3};

seasons = [[12 1 2];
               [3 4 5];
               [6 7 8];
               [9 10 11]];

hottestSeason = [];

for xlat = 1:size(tasmaxNcep, 1)
    for ylon = 1:size(tasmaxNcep, 2)
        
        sind = -1;
        stemp = -1;
        
        for s = 1:size(seasons, 1)
            t = squeeze(nanmean(nanmean(tasmaxNcep(xlat, ylon, :, seasons(s,:)), 4), 3));
            if sind == -1 || t > stemp
                sind = s;
                stemp = t;
            end
        end
        
        hottestSeason(xlat, ylon) = sind;
    end
end

save('hottest-season-ncep.mat', 'hottestSeason');
