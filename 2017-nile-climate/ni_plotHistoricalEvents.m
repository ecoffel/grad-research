% drought 1987
% flood 

[1988 1994 1996 1998 1999 2001 2003

regionBounds = [[2 32]; [25, 44]];
%regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsHighlands = [[8 13]; [34, 40]];
regionBoundsNorth = [[13 32]; [29, 34]];

regionBoundsBlue = [[9 14]; [34, 40]];
regionBoundsWhite = [[9 14]; [30, 34]];

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2005);
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2005);
    
    cmip5p = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1901, 'endYear', 2005); 
    cmip5t = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', 1901, 'endYear', 2005); 
end

lat=udelt{1};
lon=udelt{2};
[latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteUdel, lonIndsWhiteUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

udelpAnnualBlue = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));
udelpAnnualWhite = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsWhiteUdel, lonIndsWhiteUdel, :, :), 4), 2), 1));
udelpJJAS = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :, [6 7 8 9]), 4), 2), 1));
udeltAnnual = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));
udelpAnnual = udelpAnnualBlue + udelpAnnualWhite;
udelpsmooth = smooth(udelpAnnual,3);

threshT = prctile(udeltAnnual(1:80), 80);
threshPAnnualLow = prctile(udelpAnnual(1:80), 20);
threshPAnnualHigh = prctile(udelpAnnual(1:80), 90);

threshPJJASLow = prctile(udelpJJAS(1:80), 20);
threshPJJASHigh = prctile(udelpJJAS(1:80), 80);

wYears = find(udelpAnnual > threshPAnnualHigh);
hYears = find(udeltAnnual > threshT);
dYears = find(udelpAnnual < threshPAnnualLow);
hdYears = find(udelpAnnual < threshPAnnualLow & udeltAnnual > threshT);


pdata = udelpAnnual;
threshlow = threshPAnnualLow;
threshhigh = threshPAnnualHigh;

x = 1901:2005;

figure('Color',[1,1,1]);
hold on;
yyaxis left;
plot(x, udeltAnnual, '--');
plot(x, udeltAnnual, 'o');
yyaxis right;
plot(x, pdata, '--');
plot(x, pdata, 'o');
plot([1901 2013], [threshlow threshlow], 'k--');
plot([1901 2013], [threshhigh threshhigh], 'k--');

for year = 1:length(wYears)
    plot([1900+wYears(year) 1900+wYears(year)], [150 300], 'k');
end

