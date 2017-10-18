clear
clc

tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
prBase = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid', 'yearStart', 1980, 'yearEnd', 2010);
qBase = loadDailyData('e:/data/ncep-reanalysis/output/shum/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);

% select lat/lon
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [45 45], [9 9]); % milan
[latInd, lonInd] = latLonIndexRange(tmaxBase, [41 41], [269 269]); % iowa
%[latInd, lonInd] = latLonIndexRange(tmaxBase, [33 33], [248 248]); % phoenix

lat = tmaxBase{1};
lon = tmaxBase{2};

% construct surrounding region indicies
regionLat = latInd(1)-20:latInd(1)+20;
regionLon = lonInd(1)-20:lonInd(1)+20;
regionLon(regionLon<1) = regionLon(regionLon<1)+size(lon,2);

% variables
tmax = nanmean(nanmean(tmaxBase{3}(latInd, lonInd, :, :, :), 2), 1)-273.15;
tmax = reshape(tmax, [numel(tmax), 1]);

% build arrays of year, month
[y, m, d] = ind2sub(size(squeeze(tmaxBase{3}(latInd, lonInd, :, :, :))), 1:length(tmax));

% daily difference in temperature
tmaxDiff = diff(tmax);

pr = nanmean(nanmean(prBase{3}(latInd, lonInd, :, :, :), 2), 1).*60.*60.*24; % mm/day
pr = reshape(pr, [numel(pr), 1]);

q = nanmean(nanmean(qBase{3}(latInd, lonInd, :, :, :), 2), 1); % percent
q = reshape(q, [numel(q), 1]);
%q = arrayfun(@(i) mean(q(i:i+4-1)),1:4:length(q)-4+1)'; 

% remove 1st element to harmonize lengths with difference array
tmax = tmax(2:end);
pr = pr(2:end);
q = q(2:end);
m = m(2:end);

% eliminate nans
nn = find(~isnan(tmaxDiff) & ~isnan(tmax) & ~isnan(pr) & ~isnan(q));
pr = pr(nn);
tmax = tmax(nn);
q = q(nn);
tmaxDiff = tmaxDiff(nn);
m = m(nn);

monthlyTmax = [];
monthlyTmaxDiff = [];
monthlyPr = [];
monthlyq = [];

for month = 1:12
    % find indicies for current month
    ind = find(m == month);
    
    % cluster variables for this month
    monthlyTmax(month) = nanmean(tmax(ind));
    monthlyTmaxDiff(month) = nanmean(tmaxDiff(ind));
    monthlyPr(month) = nanmean(pr(ind));
    monthlyq(month) = nanmean(q(ind));
end

figure('Color', [1,1,1]);
hold on;

subplot(2,2,1);
plot(1:12, monthlyTmax, 'LineWidth', 2);
xlim([0.5 12.5]);
set(gca, 'XTick', 1:12);
ylabel([char(176) 'C']);
title('Daily max temperature');
set(gca,'FontSize',24);

subplot(2,2,2);
plot(1:12, monthlyTmaxDiff, 'LineWidth', 2);
xlim([0.5 12.5]);
set(gca, 'XTick', 1:12);
ylabel([char(176) 'C']);
title('1-day temperature change');
set(gca,'FontSize',24);

subplot(2,2,3);
plot(1:12, monthlyPr, 'LineWidth', 2);
xlim([0.5 12.5]);
set(gca, 'XTick', 1:12);
ylabel('mm/day');
title('Precipitation');
set(gca,'FontSize',24);

subplot(2,2,4);
plot(1:12, monthlyq, 'LineWidth', 2);
xlim([0.5 12.5]);
set(gca, 'XTick', 1:12);
ylabel('kg/m3');
title('Q');
set(gca,'FontSize',24);
xlabel('Month');


% convert spatial variables to SOM-style row
% hgtC = [];
% row = 1;
% for xlat = 1:size(hgt,1)
%     for ylon = 1:size(hgt, 2)
%         x = squeeze(reshape(hgt(xlat, ylon, :, :, :), [numel(hgt(xlat, ylon, :, :, :)), 1]));
%         %x = x(heatWaveInd);
%         hgtC(row, :) = x;
%         row = row+1;
%     end
% end

X = [tmax, tmaxDiff, pr, q]';
Xn = [normc(tmax), normc(tmaxDiff), normc(pr), normc(q)]';

dims = [2 3];

som = selforgmap(dims);
som.trainParam.epochs = 5000;
som = configure(som, Xn);
som = train(som, Xn);

y = som(Xn);
classes = vec2ind(y);
classVals = [];
varNames = {'Tmax', 'TmaxDiff', 'Pr', 'Q'};
for i = 1:max(classes)
    ind = find(classes == i);
    prc = length(ind)/length(classes)*100;

    topMonth = mode(m(ind));
    figure;
    hist(m(ind), unique(m(ind)));
    
    fprintf('Class %i, %.1f, month = %i\n', i, prc, topMonth);

    for v = 1:size(Xn, 1)
        cV = nanmean(X(v, ind));
        classVals(i,v) = cV;
        fprintf('%s = %f\n', varNames{v}, cV)
    end
    fprintf('\n\n')
end
plotsompos(som,Xn);
% 
% 
% 
% m=[];
% fcount = 1;
% %figure('Color',[1,1,1]);
% for k=1:size(classVals,1)
%     for c=1:size(classVals,2)
%         m(k,c,:,:)=reshape(classVals(k,c,:),[length(regionLat) length(regionLon)]);
%         %subplot(dims(1),dims(2),fcount);
%         fcount = fcount+1;
%         %plotModelData({lat(regionLat,regionLon),lon(regionLat,regionLon),squeeze(m(k,c,:,:))'},'north america', 'caxis', [-200 200], 'nonewfig', true);
%         %title(['Class ' num2str(c)]);
%     end
% end
% 
% result = {lat(regionLat,regionLon),lon(regionLat,regionLon),squeeze(m(k,c,:,:))'};
% 
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'north america', ...
%                   'plotRange', [-200 200], ...
%                   'cbXTicks', -200:50:200, ...
%                   'plotTitle', [''], ...
%                   'fileTitle', ['som-z500.png'], ...
%                   'plotXUnits', ['m'], ...
%                   'blockWater', true, ...
%                   'colormap', cmocean('thermal'), ...
%                   'magnify', '2');
% plotFromDataFile(saveData);

