
if ~exist('tmaxBase','var')
    tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
    hgtBase = loadDailyData('e:/data/ncep-reanalysis/output/hgt/regrid', 'yearStart', 1980, 'yearEnd', 2010);
    lhfBase = loadDailyData('e:/data/ncep-reanalysis/output/lhtfl/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
    soilwBase = loadDailyData('e:/data/ncep-reanalysis/output/soilw10/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
end

% select paris lat/lon
[latInd, lonInd] = latLonIndexRange(tmaxBase, [44 48], [7 11]);
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [38 42], [260 269]);
%[latInd, lonInd] = latLonIndexRange(hgtBase, [33 33], [248 248]);

load lat;
load lon;

tmax = nanmean(nanmean(tmaxBase{3}(latInd, lonInd, :, 6:8, :),2), 1)-273.15;
tmax = reshape(tmax, [numel(tmax), 1]);
tmax = tmax-nanmean(tmax);

ind = find(tmax>prctile(tmax,0));

soilw = nanmean(nanmean(soilwBase{3}(latInd,lonInd,:,6:8,:),2),1);
soilw = reshape(soilw, [numel(soilw), 1]);
soilw = soilw-nanmean(soilw);

hgt = nanmean(nanmean(hgtBase{3}(latInd,lonInd,:,6:8,:),2),1);
hgt = reshape(hgt, [numel(hgt), 1]);
hgt = hgt-nanmean(hgt);

lhtfl = nanmean(nanmean(lhfBase{3}(latInd,lonInd,:,6:8,:),2),1);
lhtfl = reshape(lhtfl, [numel(lhtfl), 1]);
lhtfl = lhtfl-nanmean(lhtfl);

tmax=tmax(ind);
soilw=soilw(ind);
hgt=hgt(ind);
lhtfl=lhtfl(ind);

X = [normc(tmax), normc(hgt), normc(soilw), normc(lhtfl)];

[coeff,score,latent,tsquared,explained,mu]=pca(X);
biplot(coeff(:,1:min(3,size(X,2))),'scores',score(:,1:min(3,size(X,2))));