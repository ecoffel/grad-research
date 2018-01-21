load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa

regionLatLonInd = {};

region = 7;

load 2017-bowen/hottest-season-ncep.mat;

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

if ~exist('shfRaw', 'var')
    shfRaw=loadDailyData('e:\data\era-interim\output\sshf', 'startYear', 1980, 'endYear', 2016);
end
shfRaw=dailyToMonthly(shfRaw);
shf=shfRaw{3};

if ~exist('lhfRaw', 'var')
    lhfRaw=loadDailyData('e:\data\era-interim\output\slhf', 'startYear', 1980, 'endYear', 2016);
end
lhfRaw=dailyToMonthly(lhfRaw);
lhf=lhfRaw{3};

if ~exist('tmaxRaw', 'var')
    tmaxRaw=loadDailyData('e:\data\era-interim\output\mx2t', 'startYear', 1980, 'endYear', 2016);
end
tmax = tmaxRaw{3}-273.15;

txxShfCorr = [];
txShfCorr = [];
ampShfCorr = [];
txxLhfCorr = [];
txLhfCorr = [];
ampLhfCorr = [];
fluxCorr = [];
amp = [];

for xlat=1:size(lat,1)
    for ylon=1:size(lat,2)
        
        if waterGrid(xlat, ylon)
            txShfCorr(xlat, ylon) = NaN;
            txLhfCorr(xlat, ylon) = NaN;
            txxShfCorr(xlat, ylon) = NaN;
            txxLhfCorr(xlat, ylon) = NaN;
            
            ampShfCorr(xlat, ylon) = NaN;
            ampLhfCorr(xlat, ylon) = NaN;
            
            txBowenCorr(xlat, ylon) = NaN;
            txxBowenCorr(xlat, ylon) = NaN;
            
            fluxCorr(xlat, ylon) = NaN;
            amp(xlat, ylon) = NaN;
            continue;
        end
        
        curShf = squeeze(nanmean(shf(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4));
        curLhf = squeeze(nanmean(lhf(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :)), 4));
        tx = squeeze(nanmean(nanmean(tmax(xlat, ylon, :, seasons(hottestSeason(xlat, ylon), :), :), 5), 4));
        txx = squeeze(nanmax(nanmax(tmax(xlat, ylon, :, :, :), [], 5), [], 4));
        
        txShfCorr(xlat, ylon) = corr(tx, curShf);
        txLhfCorr(xlat, ylon) = corr(tx, curLhf);
        txxShfCorr(xlat, ylon) = corr(txx, curShf);
        txxLhfCorr(xlat, ylon) = corr(txx, curLhf);
        ampShfCorr(xlat, ylon) = corr(txx-tx, curShf);
        ampLhfCorr(xlat, ylon) = corr(txx-tx, curLhf);
        
        fluxCorr(xlat, ylon) = corr(curShf, curLhf);
        amp(xlat, ylon) = nanmean(txx - tx);
    end
end


