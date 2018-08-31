% drought 1987
% flood 

%[1988 1994 1996 1998 1999 2001 2003

regionBounds = [[2 32]; [25, 44]];
%regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsHighlands = [[8 13]; [34, 40]];
regionBoundsNorth = [[13 32]; [29, 34]];

regionBoundsBlue = [[9 14]; [34, 40]];
regionBoundsWhite = [[9 14]; [30, 34]];
regionBoundsEthiopia = [[3.4 14.8]; [31, 45.5]];

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2016);
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2016);
    
    %cmip5p = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1901, 'endYear', 2005); 
    %cmip5t = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', 1901, 'endYear', 2005); 
end

lat=udelt{1};
lon=udelt{2};
[latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteUdel, lonIndsWhiteUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

udelpAnnualBlue = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));
udelpAnnualWhite = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsWhiteUdel, lonIndsWhiteUdel, :, :), 4), 2), 1));
udelpAnnualEthiopia = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, :), 4), 2), 1));

udelpJJAS = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :, [6 7 8 9]), 4), 2), 1));
udeltAnnual = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));
udeltAnnualEthiopia = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, :), 4), 2), 1));

udelpAnnual = udelpAnnualBlue + udelpAnnualWhite;
udelpsmooth = smooth(udelpAnnual,3);

threshT = prctile(udeltAnnualEthiopia(1:80), 75);
threshTLow = prctile(udeltAnnualEthiopia(1:80), 25);
threshPAnnualLow = prctile(udelpAnnualEthiopia(1:80), 25);
threshPAnnualHigh = prctile(udelpAnnualEthiopia(1:80), 75);

wYears = find(udelpAnnualEthiopia > threshPAnnualHigh);
hYears = find(udeltAnnualEthiopia > threshT);
cYears = find(udeltAnnualEthiopia  < threshTLow);
dYears = find(udelpAnnualEthiopia < threshPAnnualLow);
hdYears = find(udelpAnnualEthiopia < threshPAnnualLow & udeltAnnualEthiopia > threshT);
cwYears = find(udelpAnnualEthiopia > threshPAnnualLow & udeltAnnualEthiopia < threshTLow);

hdYears = hdYears + 1900;
hdYears = hdYears(hdYears >= 1961) - 1961 + 1;

cwYears = cwYears + 1900;
cwYears = cwYears(cwYears >= 1961) - 1961 + 1;

dYears = dYears + 1900;
dYears = dYears(dYears >= 1961) - 1961 + 1;

hYears = hYears + 1900;
hYears = hYears(hYears >= 1961) - 1961 + 1;

cYears = cYears + 1900;
cYears = cYears(cYears >= 1961) - 1961 + 1;

wYears = wYears + 1900;
wYears = wYears(wYears >= 1961) - 1961 + 1;

ethiopiaMaizeYield = importdata('2017-nile-climate\data\ethiopia-maize.txt');
ethiopiaMilletYield = importdata('2017-nile-climate\data\ethiopia-millet.txt');
ethiopiaSorghumYield = importdata('2017-nile-climate\data\ethiopia-sorghum.txt');
yieldMaize_dt = detrend(ethiopiaMaizeYield);
yieldMillet_dt = detrend(ethiopiaMilletYield);
yieldSorghum_dt = detrend(ethiopiaSorghumYield);


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

