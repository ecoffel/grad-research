% drought 1987
% flood 

regionBoundsEthiopia = [[5.5 14.8]; [31, 40]];
regionBoundsEgypt = [[22 31.4]; [25, 37]];
regionBoundsSudan = [[4 12]; [24, 34.5]];

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2014);
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2014);
    
    %cmip5p = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1901, 'endYear', 2005); 
    %cmip5t = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', 1901, 'endYear', 2005); 
end

lat=udelt{1};
lon=udelt{2};

[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
[latIndsSudanUdel, lonIndsSudanUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsSudan(1,:), regionBoundsSudan(2,:));

udelpAnnualEthiopia = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, [5 6 7 8 9]), 4), 2), 1));
udeltAnnualEthiopia = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, [5 6 7 8 9]), 4), 2), 1));

udelpAnnualSudan = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsSudanUdel, lonIndsSudanUdel, :, 5:9), 4), 2), 1));
udeltAnnualSudan = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsSudanUdel, lonIndsSudanUdel, :, 5:9), 4), 2), 1));

prcHigh = 65;
prcLow = 35;

threshTEthiopiaHigh = prctile(udeltAnnualEthiopia(1:60), prcHigh);
threshTEthiopiaLow = prctile(udeltAnnualEthiopia(1:60), prcLow);
threshPAnnualEthiopiaLow = prctile(udelpAnnualEthiopia(1:60), prcLow);
threshPAnnualEthiopiaHigh = prctile(udelpAnnualEthiopia(1:60), prcHigh);

udeltAnnualEthiopia = udeltAnnualEthiopia(61:end-1);
udelpAnnualEthiopia = udelpAnnualEthiopia(61:end-1);

udeltAnnualSudan = udeltAnnualSudan(61:end-3);
udelpAnnualSudan = udelpAnnualSudan(61:end-3);

threshTSudan = prctile(udeltAnnualSudan, prcHigh);
threshTSudanLow = prctile(udeltAnnualSudan, prcLow);
threshPAnnualSudanLow = prctile(udelpAnnualSudan, prcLow);
threshPAnnualSudanHigh = prctile(udelpAnnualSudan, prcHigh);

wYearsEthiopia = find(udelpAnnualEthiopia > threshPAnnualEthiopiaHigh);
hYearsEthiopia = find(udeltAnnualEthiopia > threshTEthiopiaHigh);
cYearsEthiopia = find(udeltAnnualEthiopia  < threshTEthiopiaLow);
dYearsEthiopia = find(udelpAnnualEthiopia < threshPAnnualEthiopiaLow & udeltAnnualEthiopia < threshTEthiopiaHigh);
cdYearsEthiopia = find(udelpAnnualEthiopia < threshPAnnualEthiopiaLow & udeltAnnualEthiopia < threshTEthiopiaLow);
hdYearsEthiopia = find(udelpAnnualEthiopia < threshPAnnualEthiopiaLow & udeltAnnualEthiopia > threshTEthiopiaHigh);
cwYearsEthiopia = find(udelpAnnualEthiopia > threshPAnnualEthiopiaHigh & udeltAnnualEthiopia < threshTEthiopiaLow);

wYearsSudan = find(udelpAnnualSudan > threshPAnnualSudanHigh);
hYearsSudan = find(udeltAnnualSudan > threshTSudan);
cYearsSudan = find(udeltAnnualSudan  < threshTSudanLow);
dYearsSudan = find(udelpAnnualSudan < threshPAnnualSudanLow);
hdYearsSudan = find(udelpAnnualSudan < threshPAnnualSudanLow & udeltAnnualSudan > threshTSudan);
cwYearsSudan = find(udelpAnnualSudan > threshPAnnualSudanLow & udeltAnnualSudan < threshTSudanLow);

ethiopiaMaizeYield = importdata('2017-nile-climate\data\ethiopia-maize.txt');
ethiopiaSorghumYield = importdata('2017-nile-climate\data\ethiopia-sorghum.txt');
ethiopiaMilletYield = importdata('2017-nile-climate\data\ethiopia-millet.txt');
ethiopiaBarleyYield = importdata('2017-nile-climate\data\ethiopia-barley.txt');
ethiopiaWheatYield = importdata('2017-nile-climate\data\ethiopia-wheat.txt');
ethiopiaPulsesYield = importdata('2017-nile-climate\data\ethiopia-pulses.txt');
ethiopiaCerealsYield = importdata('2017-nile-climate\data\ethiopia-cereals.txt');

ethiopiaCattle = importdata('2017-nile-climate\data\ethiopia-cattle.txt');
ethiopiaGoats = importdata('2017-nile-climate\data\ethiopia-goats.txt');
ethiopiaChicken = importdata('2017-nile-climate\data\ethiopia-chicken.txt');

ethiopiaMaizeCal = importdata('2017-nile-climate\data\ethiopia-cal-maize.txt');
ethiopiaSorghumCal = importdata('2017-nile-climate\data\ethiopia-cal-sorghum.txt');
ethiopiaMilletCal = importdata('2017-nile-climate\data\ethiopia-cal-millet.txt');
ethiopiaBarleyCal = importdata('2017-nile-climate\data\ethiopia-cal-barley.txt');
ethiopiaWheatCal = importdata('2017-nile-climate\data\ethiopia-cal-wheat.txt');
ethiopiaPulsesCal = importdata('2017-nile-climate\data\ethiopia-cal-pulses.txt');
ethiopiaCerealsCal = importdata('2017-nile-climate\data\ethiopia-cal-cereals.txt');

ethiopiaMeanLivestock = nanmean([normc(ethiopiaCattle), normc(ethiopiaGoats) normc(ethiopiaChicken)], 2);
ethiopiaMeanYield = nanmean([normc(ethiopiaMaizeYield) normc(ethiopiaSorghumYield) normc(ethiopiaMilletYield) normc(ethiopiaWheatYield) normc(ethiopiaCerealsYield) normc(ethiopiaPulsesYield)], 2);
ethiopiaMeanCal = nanmean([normc(ethiopiaMaizeCal) normc(ethiopiaSorghumCal) normc(ethiopiaMilletCal) normc(ethiopiaBarleyCal) normc(ethiopiaWheatCal) normc(ethiopiaPulsesCal) normc(ethiopiaCerealsCal)], 2);

yieldMaizeEthiopia_dt = ethiopiaMaizeYield - smooth(ethiopiaMaizeYield, 10); 
yieldMilletEthiopia_dt = ethiopiaMilletYield - smooth(ethiopiaMilletYield, 10); 
yieldBarleyEthiopia_dt = ethiopiaBarleyYield - smooth(ethiopiaBarleyYield, 10); 
yieldWheatEthiopia_dt = ethiopiaWheatYield - smooth(ethiopiaWheatYield, 10); 
yieldSorghumEthiopia_dt = ethiopiaSorghumYield - smooth(ethiopiaSorghumYield, 10);
yieldCerealsEthiopia_dt = ethiopiaCerealsYield - smooth(ethiopiaCerealsYield, 10);
yieldMeanEthiopia_dt = ethiopiaMeanYield - smooth(ethiopiaMeanYield, 10);

cattleEthiopia_dt = ethiopiaCattle - smooth(ethiopiaCattle, 10);
goatsEthiopia_dt = ethiopiaGoats - smooth(ethiopiaGoats, 10);
livestockEthiopia_dt = ethiopiaMeanLivestock- smooth(ethiopiaMeanLivestock, 10);
calEthiopia_dt = ethiopiaMeanCal- smooth(ethiopiaMeanCal, 10);

sudanMaizeYield = importdata('2017-nile-climate\data\sudan-maize.txt');
sudanSorghumYield = importdata('2017-nile-climate\data\sudan-sorghum.txt');
sudanMilletYield = importdata('2017-nile-climate\data\sudan-millet.txt');
sudanWheatYield = importdata('2017-nile-climate\data\sudan-wheat.txt');
sudanPulsesYield = importdata('2017-nile-climate\data\sudan-pulses.txt');

sudanMeanYield = nanmean([sudanMaizeYield sudanSorghumYield sudanMilletYield sudanWheatYield sudanPulsesYield], 2);
yieldMeanSudan_dt = sudanMeanYield - smooth(sudanMeanYield, 10);

nanmean(yieldMeanEthiopia_dt(hdYearsEthiopia))
nanmean(yieldMeanEthiopia_dt(dYearsEthiopia))
[h,p] = ttest(yieldMeanEthiopia_dt(hdYearsEthiopia))
[h,p] = ttest(yieldMeanEthiopia_dt(dYearsEthiopia))

nanmean(livestockEthiopia_dt(hdYearsEthiopia))
nanmean(livestockEthiopia_dt(dYearsEthiopia))
[h,p] = ttest(livestockEthiopia_dt(hdYearsEthiopia))
[h,p] = ttest(livestockEthiopia_dt(dYearsEthiopia))

nanmean(calEthiopia_dt(hdYearsEthiopia))
nanmean(calEthiopia_dt(dYearsEthiopia))
[h,p] = ttest(calEthiopia_dt(hdYearsEthiopia))
[h,p] = ttest(calEthiopia_dt(dYearsEthiopia))

nanmean(yieldWheatEthiopia_dt(hdYearsEthiopia))
nanmean(yieldWheatEthiopia_dt(dYearsEthiopia))
[h,p] = ttest(yieldWheatEthiopia_dt(hdYearsEthiopia))
[h,p] = ttest(yieldWheatEthiopia_dt(dYearsEthiopia))

length(dYearsEthiopia)
length(hdYearsEthiopia)