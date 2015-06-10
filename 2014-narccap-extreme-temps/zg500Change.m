mapPlot = true;

model = 'crcm/ccsm';
var = 'hus';
plotRange = [0 0.001];
plotRegion = 'north america';

plotTitle = ['narccap ' model ' ' var ' changes, [2051-2069]-[1981-1999]'];

modelParts = strsplit(model, '/');
if mapPlot
    fileTitle = [var 'Change-' modelParts{1} '-' modelParts{2} '.png'];
else
    fileTitle = [var 'Change-' modelParts{1} '-' modelParts{2} '-line.png'];
end

varPast = [];
varFuture = [];

for y = 1981:1999
    ['year ' num2str(y)]

    varPastCur = loadDailyData(['e:/data/narccap/output/' model '/' var], 'yearStart', y, 'yearEnd', y);
    
    lat = varPastCur{1};
    lon = varPastCur{2};
    dataPastCur = reshape(varPastCur{3}, [size(varPastCur{3}, 1), size(varPastCur{3}, 2), size(varPastCur{3}, 3)*size(varPastCur{3}, 4)*size(varPastCur{3}, 5)]);

    varPast(:,:,y-1981+1) = nanmean(dataPastCur, 3);

    clear varPastCur dataPastCur;
end
for y = 2051:2069
    ['year ' num2str(y)]

    varFutureCur = loadDailyData(['e:/data/narccap/output/' model '/' var], 'yearStart', y, 'yearEnd', y);
    
    lat = varFutureCur{1};
    lon = varFutureCur{2};
    dataFutureCur = reshape(varFutureCur{3}, [size(varFutureCur{3}, 1), size(varFutureCur{3}, 2), size(varFutureCur{3}, 3)*size(varFutureCur{3}, 4)*size(varFutureCur{3}, 5)]);

    varFuture(:,:,y-2051+1) = nanmean(dataFutureCur, 3);

    clear varFutureCur dataFutureCur;
end

dataPastMean = nanmean(varPast, 3);
dataFutureMean = nanmean(varFuture, 3);

if mapPlot
    [fg,cb] = plotModelData({lat, lon, dataFutureMean-dataPastMean}, plotRegion, 'caxis', plotRange);
    xlabel(cb, 'm', 'FontSize', 18);
    cbPos = get(cb, 'Position');
    title(plotTitle, 'FontSize', 24);
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf, 'Units', 'normalized');
    set(gca, 'Units', 'normalized');

    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
    myaa('publish');
    exportfig(fileTitle, 'Width', 16);
    close all;
else
    dataPastZonalMean = squeeze(nanmean(dataPastMean, 2));
    dataFutureZonalMean = squeeze(nanmean(dataFutureMean, 2));
    
    figure('Color', [1,1,1]); 
    hold on;
    plot(lat(:,1),dataPastZonalMean,'b','LineWidth',2);
    plot(lat(:,1),dataFutureZonalMean,'r','LineWidth',2);
    xlabel('latitude', 'FontSize', 18);
    ylabel('zg500 (m)', 'FontSize', 18);
    title(plotTitle, 'FontSize', 24);
    l = legend('zonal mean zg500 [1981-1999]', 'zonal mean zg500 [2051-2069]');
    set(l, 'FontSize', 14);
    set(l, 'Location', 'best');
    
    set(gcf, 'Position', get(0,'Screensize'));
    myaa('publish');
    exportfig(fileTitle, 'Width', 16);
    close all;
end





