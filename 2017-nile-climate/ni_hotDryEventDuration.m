base = 'cmip5';
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1981-2005-each-year-t90-p10.mat']);
hotDryHistorical = hotDryFuture;
load(['2017-nile-climate\output\dryFuture-annual-' base '-historical-1981-2005-each-year-t90-p10.mat']);
dryHistorical = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-' base '-historical-1981-2005-each-year-t90-p10.mat']);
wetHistorical = wetFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2025-2049-each-year-t90-p10-tfull-pfull.mat']);
dryFuture25 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2025-2049-each-year-t90-p10-tfull-pfull.mat']);
wetFuture25 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2025-2049-each-year-t90-p10-tfull-pfull.mat']);
hotDryFuture25 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2050-2074-each-year-t90-p10-tfull-pfull.mat']);
dryFuture50 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2050-2074-each-year-t90-p10-tfull-pfull.mat']);
wetFuture50 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2050-2074-each-year-t90-p10-tfull-pfull.mat']);
hotDryFuture50 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2075-2099-each-year-t90-p10-tfull-pfull.mat']);
dryFuture75 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2075-2099-each-year-t90-p10-tfull-pfull.mat']);
wetFuture75 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2075-2099-each-year-t90-p10-tfull-pfull.mat']);
hotDryFuture75 = hotDryFuture;

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];

regionBoundsNorth = [[15 32]; [29, 34]];
regionBoundsBlue = [[8 14]; [34, 40]];
regionBoundsWhite = [[3 14]; [27, 33.5]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsBlue, lonIndsBlue] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhite, lonIndsWhite] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsBlue = latIndsBlue - latInds(1) + 1;
lonIndsBlue = lonIndsBlue - lonInds(1) + 1;
latIndsWhite = latIndsWhite - latInds(1) + 1;
lonIndsWhite = lonIndsWhite - lonInds(1) + 1;

curLatInds = latIndsBlue;
curLonInds = lonIndsBlue;

meanHotDryLenHist = [];
meanHotDryLenFut = [];
maxHotDryLenHist = [];
maxHotDryLenFut = [];

meanWetLenHist = [];
meanWetLen25 = [];
meanWetLen50 = [];
meanWetLen75 = [];
maxWetLenHist = [];
maxWetLen25 = [];
maxWetLen50 = [];
maxWetLen75 = [];

meanDryLenHist = [];
meanDryLen25 = [];
meanDryLen50 = [];
meanDryLen75 = [];
maxDryLenHist = [];
maxDryLen25 = [];
maxDryLen50 = [];
maxDryLen75 = [];

wetDryStateHist = [];
wetDryStateFuture = [];
wetDryFlipsHist = zeros(size(hotDryHistorical,1), size(hotDryHistorical,2), size(hotDryHistorical,4));
wetDryFlipsFuture = zeros(size(hotDryHistorical,1), size(hotDryHistorical,2), size(hotDryHistorical,4));
hotState = [];

for xlat = 1:size(hotDryHistorical,1)
    for ylon = 1:size(hotDryHistorical,2)
        for m = 1:size(hotDryHistorical,4)
%             hdh = squeeze(hotDryHistorical(xlat,ylon,:,m));
%             start1 = strfind([0,hdh'==1],[0 1]);
%             end1 = strfind([hdh'==1,0],[1 0]);
%             len = end1 - start1 + 1;
%             meanHotDryLenHist(xlat, ylon, m) = nanmean(len);
%             if length(len) > 0
%                 maxHotDryLenHist(xlat, ylon, m) = nanmax(len);
%             else
%                 maxHotDryLenHist(xlat, ylon, m) = 0;
%             end
%             
%             hdf = squeeze(hotDryFutureLate85(xlat,ylon,:,m));
%             start1 = strfind([0,hdf'==1],[0 1]);
%             end1 = strfind([hdf'==1,0],[1 0]);
%             len = end1 - start1 + 1;
%             meanHotDryLenFut(xlat, ylon, m) = nanmean(len);
%             if length(len) > 0
%                 maxHotDryLenFut(xlat, ylon, m) = nanmax(len);
%             else
%                 maxHotDryLenFut(xlat, ylon, m) = 0;
%             end
%             
            
            % ------------------ WET ---------------------
            wh = squeeze(wetHistorical(xlat,ylon,:,m));
            start1 = strfind([0,wh'==1],[0 1]);
            end1 = strfind([wh'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanWetLenHist(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxWetLenHist(xlat, ylon, m) = nanmax(len);
            else
                maxWetLenHist(xlat, ylon, m) = 0;
            end
            
            wf = squeeze(wetFuture25(xlat,ylon,:,m));
            start1 = strfind([0,wf'==1],[0 1]);
            end1 = strfind([wf'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanWetLen25(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxWetLen25(xlat, ylon, m) = nanmax(len);
            else
                maxWetLen25(xlat, ylon, m) = 0;
            end
            
            wf = squeeze(wetFuture50(xlat,ylon,:,m));
            start1 = strfind([0,wf'==1],[0 1]);
            end1 = strfind([wf'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanWetLen50(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxWetLen50(xlat, ylon, m) = nanmax(len);
            else
                maxWetLen50(xlat, ylon, m) = 0;
            end
            
            wf = squeeze(wetFuture75(xlat,ylon,:,m));
            start1 = strfind([0,wf'==1],[0 1]);
            end1 = strfind([wf'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanWetLen75(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxWetLen75(xlat, ylon, m) = nanmax(len);
            else
                maxWetLen75(xlat, ylon, m) = 0;
            end
            
            % ------------------ DRY ---------------------
            dh = squeeze(dryHistorical(xlat,ylon,:,m));
            start1 = strfind([0,dh'==1],[0 1]);
            end1 = strfind([dh'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanDryLenHist(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxDryLenHist(xlat, ylon, m) = nanmax(len);
            else
                maxDryLenHist(xlat, ylon, m) = 0;
            end
            
            df = squeeze(dryFuture25(xlat,ylon,:,m));
            start1 = strfind([0,df'==1],[0 1]);
            end1 = strfind([df'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanDryLen25(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxDryLen25(xlat, ylon, m) = nanmax(len);
            else
                maxDryLen25(xlat, ylon, m) = 0;
            end
            
            df = squeeze(dryFuture50(xlat,ylon,:,m));
            start1 = strfind([0,df'==1],[0 1]);
            end1 = strfind([df'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanDryLen50(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxDryLen50(xlat, ylon, m) = nanmax(len);
            else
                maxDryLen50(xlat, ylon, m) = 0;
            end
            
            df = squeeze(dryFuture75(xlat,ylon,:,m));
            start1 = strfind([0,df'==1],[0 1]);
            end1 = strfind([df'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanDryLen75(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxDryLen75(xlat, ylon, m) = nanmax(len);
            else
                maxDryLen75(xlat, ylon, m) = 0;
            end
            
            % ------------------ HOT/DRY ---------------------
            hdh = squeeze(hotDryHistorical(xlat,ylon,:,m));
            start1 = strfind([0,hdh'==1],[0 1]);
            end1 = strfind([hdh'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanHotDryLenHist(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxHotDryLenHist(xlat, ylon, m) = nanmax(len);
            else
                maxHotDryLenHist(xlat, ylon, m) = 0;
            end
            
            hdf = squeeze(hotDryFuture25(xlat,ylon,:,m));
            start1 = strfind([0,hdf'==1],[0 1]);
            end1 = strfind([hdf'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanHotDryLen25(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxHotDryLen25(xlat, ylon, m) = nanmax(len);
            else
                maxHotDryLen25(xlat, ylon, m) = 0;
            end
            
            hdf = squeeze(hotDryFuture50(xlat,ylon,:,m));
            start1 = strfind([0,hdf'==1],[0 1]);
            end1 = strfind([hdf'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanHotDryLen50(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxHotDryLen50(xlat, ylon, m) = nanmax(len);
            else
                maxHotDryLen50(xlat, ylon, m) = 0;
            end
            
            hdf = squeeze(hotDryFuture75(xlat,ylon,:,m));
            start1 = strfind([0,hdf'==1],[0 1]);
            end1 = strfind([hdf'==1,0],[1 0]);
            len = end1 - start1 + 1;
            meanHotDryLen75(xlat, ylon, m) = nanmean(len);
            if length(len) > 0
                maxHotDryLen75(xlat, ylon, m) = nanmax(len);
            else
                maxHotDryLen75(xlat, ylon, m) = 0;
            end
            
%             for year = 1:length(wh)
%                 if wh(year)
%                     wetDryStateHist(xlat, ylon, year, m) = 1;
%                 elseif dh(year)
%                     wetDryStateHist(xlat, ylon, year, m) = -1;
%                 else
%                     wetDryStateHist(xlat, ylon, year, m) = 0;
%                 end
%                 
%                 if wf(year)
%                     wetDryStateFuture(xlat, ylon, year, m) = 1;
%                 elseif df(year)
%                     wetDryStateFuture(xlat, ylon, year, m) = -1;
%                 else
%                     wetDryStateFuture(xlat, ylon, year, m) = 0;
%                 end
%                 
%                 if year > 1
%                     if (wh(year) == 1 && dh(year-1) == 1) || (dh(year) == 1 && wh(year-1) == 1)
%                         wetDryFlipsHist(xlat, ylon, m) = wetDryFlipsHist(xlat, ylon, m) + 1;
%                     end
%                     
%                     if (wf(year) == 1 && df(year-1) == 1) || (df(year) == 1 && wf(year-1) == 1)
%                         wetDryFlipsFuture(xlat, ylon, m) = wetDryFlipsFuture(xlat, ylon, m) + 1;
%                     end
%                 end
%                 
%             end
        end
    end
end

% divide by # years
% wetDryFlipsHist = wetDryFlipsHist ./ 25;
% wetDryFlipsFuture = wetDryFlipsFuture ./ 25;
