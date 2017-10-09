clear
clc

tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
%soilwBase = loadDailyData('e:/data/ncep-reanalysis/output/soilw10/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);
hgtBase = loadDailyData('e:/data/ncep-reanalysis/output/hgt/regrid', 'yearStart', 1980, 'yearEnd', 2010);
hgtBase{3}(:,end,:,:,:)=hgtBase{3}(:,1,:,:,:);

% select paris lat/lon
%[latInd, lonInd] = latLonIndexRange(hgtBase, [45 45], [9 9]);
[latInd, lonInd] = latLonIndexRange(hgtBase, [41 41], [269 269]);
%[latInd, lonInd] = latLonIndexRange(hgtBase, [33 33], [248 248]);

lat = hgtBase{1};
lon = hgtBase{2};

% find heat waves
tmax = nanmean(nanmean(tmaxBase{3}(latInd, lonInd, :, :, :),2), 1)-273.15;
thresh = prctile(reshape(tmax, [numel(tmax),1]), 95);
tmax = reshape(tmax, [numel(tmax), 1]);
heatWaveInd = find(tmax > thresh);

% find 3 day heat waves
%heatWaveInd = heatWaveInd(find(diff(diff(heatWaveInd))==1));

regionLat = latInd(1)-20:latInd(1)+20;
regionLon = lonInd(1)-20:lonInd(1)+20;

regionLon(regionLon<1) = regionLon(regionLon<1)+size(lon,2);

hgt = hgtBase{3}(regionLat, regionLon, :, :, :);

% take calendar day hgt anomaly
for month = 1:size(hgt, 4)
    hgt(:, :, :, month, :) = hgt(:, :, :, month, :) - nanmean(hgt(:, :, :, month, :), 3);
end

hgtC = [];
row = 1;
for xlat = 1:size(hgt,1)
    for ylon = 1:size(hgt, 2)
        x = squeeze(reshape(hgt(xlat, ylon, :, :, :), [numel(hgt(xlat, ylon, :, :, :)), 1]));
        %x = x(heatWaveInd);
        hgtC(row, :) = x;
        row = row+1;
    end
end

hgtC(find(isnan(hgtC)))=0;
% only summer soil moisture during 3 day heat waves
% soilw = soilwBase{3}(regionLat, regionLon, :, 6:8, :);
% 
% % monthly mean summer soilw during the heat wave months
% soilw = nanmean(soilw, 5);
% 
% sz = size(squeeze(soilw(1,1,:,:)));
% 
% % get indices of heat waves
% [y,m,d] = ind2sub(squeeze(sz), heatWaveIndExtended);
% 
% % take monthly anomaly
% for month = 1:size(soilw,4)
%     soilw(:,:,:,month) = soilw(:,:,:,month)-nanmean(soilw(:,:,:,month), 3);
% end
% 
% soilwFiltered = [];
% %soilwFiltered = soilw;
% for i = 1:length(y)
%     soilwFiltered(:,:,i) = squeeze(soilw(:,:,y(i),m(i)));
% end
% 
% % combine spatially into cols
% soilwC = [];
% row = 1;
% for xlat = 1:size(soilwFiltered,1)
%     for ylon = 1:size(soilwFiltered,2)
%         soilwC(row,:)=squeeze(reshape(soilwFiltered(xlat,ylon,:),[1,numel(soilwFiltered(xlat,ylon,:))]));
%         row = row+1;
%     end
% end

%soilw(soilw>1)=0;

%nonNan = find(~isnan(somTmax) & ~isnan(somSoilw) & ~isnan(somwb));

X = [hgtC];
Xn = [hgtC];%[somTmax(nonNan), somSoilw(nonNan), somwb(nonNan)]';

%X = normc(X);

dims = [3 3];

som = selforgmap(dims);
som.trainParam.epochs = 100;
som = configure(som, Xn);
som = train(som, Xn);

y = som(Xn);
classSets = {1:size(hgtC,2)};% 38:74};
classes = vec2ind(y);
classVals = [];
for k = 1:length(classSets)
    for i = 1:max(classes)
        ind = find(classes(classSets{k}) == i);
        prc = length(ind)/length(classes(classSets{k}))*100;
        prcHeat = length(intersect(ind, heatWaveInd)) / length(heatWaveInd)*100;
        
        fprintf('Class %i, %.1f, heat wave: %.1f\n', i, prc, prcHeat-prc);
        
        for v = 1:size(Xn, 1)
            cV = nanmean(X(v, ind));
            classVals(k,i,v) = cV;
            %fprintf('Var %i = %f\n', v, cV)
        end
        fprintf('\n\n')
    end
end



m=[];
fcount = 1;
%figure('Color',[1,1,1]);
for k=1:size(classVals,1)
    for c=1:size(classVals,2)
        m(k,c,:,:)=reshape(classVals(k,c,:),[length(regionLat) length(regionLon)]);
        %subplot(dims(1),dims(2),fcount);
        fcount = fcount+1;
        %plotModelData({lat(regionLat,regionLon),lon(regionLat,regionLon),squeeze(m(k,c,:,:))'},'north america', 'caxis', [-200 200], 'nonewfig', true);
        %title(['Class ' num2str(c)]);
    end
end

result = {lat(regionLat,regionLon),lon(regionLat,regionLon),squeeze(m(k,c,:,:))'};

saveData = struct('data', {result}, ...
                  'plotRegion', 'north america', ...
                  'plotRange', [-200 200], ...
                  'cbXTicks', -200:50:200, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['som-z500.png'], ...
                  'plotXUnits', ['m'], ...
                  'blockWater', true, ...
                  'colormap', cmocean('thermal'), ...
                  'magnify', '2');
plotFromDataFile(saveData);

