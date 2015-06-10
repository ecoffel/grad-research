% TODO: add narccap ncep

baseDir = 'e:/';

yearStart = 1981;
yearEnd = 1999;

yearStep = 1; % the number of years loaded at a time for memory

vars = {'narr/output/tasmax', 'narr/output/tasmin', ...
        'ncep-reanalysis/output/tmax', 'ncep-reanalysis/output/tmin', ...
        'narccap/output/crcm/ccsm/tasmax', 'narccap/output/crcm/ccsm/tasmin', ...
        'narccap/output/crcm/cgcm3/tasmax', 'narccap/output/crcm/cgcm3/tasmin', ...
        'narccap/output/ecp2/gfdl/tasmax', 'narccap/output/ecp2/gfdl/tasmin', ...
        'narccap/output/hrm3/gfdl/tasmax', 'narccap/output/hrm3/gfdl/tasmin', ...
        'narccap/output/hrm3/hadcm3/tasmax', 'narccap/output/hrm3/hadcm3/tasmin', ...
        'narccap/output/mm5i/ccsm/tasmax', 'narccap/output/mm5i/ccsm/tasmin', ...
        'narccap/output/mm5i/hadcm3/tasmax', 'narccap/output/mm5i/hadcm3/tasmin', ...
        'narccap/output/rcm3/cgcm3/tasmax', 'narccap/output/rcm3/cgcm3/tasmin', ...
        'narccap/output/rcm3/gfdl/tasmax', 'narccap/output/rcm3/gfdl/tasmin', ...
        'narccap/output/wrfg/ccsm/tasmax', 'narccap/output/wrfg/ccsm/tasmin', ...
        'narccap/output/wrfg/cgcm3/tasmax', 'narccap/output/wrfg/cgcm3/tasmin'};
        %, 'crcm/cgcm3', 'ecp2/gfdl', 'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', 'mm5i/hadcm3', ...
        %'rcm3/cgcm3', 'rcm3/gfdl', 'wrfg/ccsm', 'wrfg/cgcm3'};
%vars = {'crcm/ncep', 'ecp2/ncep', 'hrm3/ncep', 'mm5i/ncep', 'rcm3/ncep', 'wrfg/ncep'};

lineWidths = [3 3 3 3 ones(1,(length(vars)-4)) 3 3];
styles = {'r', ':r', 'g', ':g', 'c', ':c', 'm', ':m', 'y', ':y'};

slopes = {};

ensembleDataMax = [];
vMaxInd = 1;
ensembleDataMin = [];
vMinInd = 1;

for v = 1:length(vars)
    curModel = vars{v};
    curModelParts = strsplit(curModel, '/');
    
    dataMean = zeros(365, 1);
    ['loading ' vars{v} '...']

    validYear = false;
    yindex = 1;

    for y = yearStart:yearStep:yearEnd
        ['year ' num2str(y)]
        daily = loadDailyData([baseDir 'data/' vars{v}], 'yearStart', y, 'yearEnd', y+(yearStep-1));

        lat = daily{1};
        lon = daily{2};
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(daily, [38 40], [279 281]);

        dtmp = daily{3};
        dindex = 1;
        for m=1:size(dtmp, 4)
            for d=1:size(dtmp, 5)
                % some data on this day
                if length(find(~isnan(dtmp(latIndexRange,lonIndexRange,1,m,d)))) ~= 0
                    dataMean(dindex, yindex) = nanmean(nanmean(dtmp(latIndexRange,lonIndexRange,1,m,d)));
                    dindex = dindex+1;
                    validYear = true;
                end
            end
        end

        if validYear
            yindex = yindex + 1;
        end
        clear daily lat lon;
    end
    
    if length(findstr('narccap', vars{v})) ~= 0
        [ind1, ind2] = ind2sub(size(dataMean(:,:)), find(dataMean(:,:) ~= 0));
        if length(ind2) > 0
            if length(findstr('tasmax', vars{v})) == 0
                ensembleDataMax(min(ind1):max(ind1),min(ind2):max(ind2),vMaxInd) = dataMean(min(ind1):max(ind1),min(ind2):max(ind2));
                vMaxInd = vMaxInd+1;
            elseif length(findstr('tasmin', vars{v})) == 0
                ensembleDataMin(min(ind1):max(ind1),min(ind2):max(ind2),vMinInd) = dataMean(min(ind1):max(ind1),min(ind2):max(ind2));
                vMinInd = vMinInd+1;
            end
        end
    end
    
    for d=1:size(dataMean,1)
        [ind1, ind2] = ind2sub(size(dataMean(d,:)), find(dataMean(d,:) ~= 0));
        if length(dataMean(d,ind2)) > 2
            rx = 1:size(dataMean(d,ind2),2);
            mdl = fit(rx', dataMean(d,ind2)', 'poly1');
            if d > 1
                slopes{v} = [slopes{v}, mdl.p1];
            else
                slopes{v} = [mdl.p1];
            end
        end
    end
end

ensembleDataMax(ensembleDataMax == 0) = NaN;
ensembleDataMin(ensembleDataMin == 0) = NaN;

ensembleDataMax = nanmean(ensembleDataMax, 3);
ensembleDataMin = nanmean(ensembleDataMin, 3);
for d=1:min(size(ensembleDataMax,1), size(ensembleDataMin,1))
    [ind1, ind2] = ind2sub(size(ensembleDataMax(d,:)), find(ensembleDataMax(d,:) ~= 0));
    if length(ind2) > 0
        rx = 1:size(ensembleDataMax(d,ind2),2);            
        mdl = fit(rx', ensembleDataMax(d,ind2)', 'poly1');
        if d > 1
            slopes{v+1} = [slopes{v+1}, mdl.p1];
        else
            slopes{v+1} = [mdl.p1];
        end
    end
    
    [ind1, ind2] = ind2sub(size(ensembleDataMin(d,:)), find(ensembleDataMin(d,:) ~= 0));
    if length(ind2) > 0
        rx = 1:size(ensembleDataMin(d,ind2),2);            
        mdl = fit(rx', ensembleDataMin(d,ind2)', 'poly1');
        if d > 1
            slopes{v+2} = [slopes{v+2}, mdl.p1];
        else
            slopes{v+2} = [mdl.p1];
        end
    end
end

figure;
hold on;
smoothing = 15;
t = 1:360;
x = linspace(1, 12, max(t));
l = [];
handles = [];
for s=[5:length(slopes) 1 2 3 4]
    curSlope = slopes{s};
    if s == 1
        style = 'k';
    elseif s == 2
        style = ':k';
    elseif s == 3
        style = 'r';
    elseif s == 4
        style = ':r';
    elseif s == length(slopes)-1
        style = 'b';
    elseif s == length(slopes)
        style = ':b';
    else
        style = styles{mod(s-1,length(styles))+1};
    end
    
    h = plot(x, tsmovavg(curSlope(t), 's', smoothing), style, 'LineWidth', lineWidths(s));
    
    if s <= length(vars)
        if length(findstr(vars{s}, 'narccap')) == 0
            if length(l) ~= 0
                l = [l, ', ', ['''', vars{s}, '''']];
            else
                l = ['''', vars{s}, ''''];
            end
            handles(length(handles)+1) = h;
        end
    end
    
    if s == length(slopes)-1
        handles(length(handles)+1) = h;
        if length(l) ~= 0
            l = [l, ', ', ['''', 'narccap ensemble mean tasmax', '''']];
        else
            l = ['''', 'narccap ensemble mean tasmax', ''''];
        end
    elseif s == length(slopes)
        handles(length(handles)+1) = h;
        if length(l) ~= 0
            l = [l, ', ', ['''', 'narccap ensemble mean tasmin', '''']];
        else
            l = ['''', 'narccap ensemble mean tasmin', ''''];
        end
    end
end
size(handles)
set(gca, 'XTick', 1:12);
xlim([1 12]);
xlabel('month [since Jan. 1]', 'FontSize', 20);
ylabel(['regression slope of average max temp between ', num2str(yearStart), ' and ', num2str(yearEnd)], 'FontSize', 14);
title(['max tasmax/tasmin regression slopes [38-40 N, 279-281 W], ', num2str(yearStart), ' - ', num2str(yearEnd)], 'FontSize', 20);
%l = [l ', ''ensemble mean tasmax'', ''ensemble mean tasmin'''];
set(gcf, 'Position', get(0,'Screensize'));
eval(['legend(handles(:), ', l, ', ''Location'', ''Best'');']);
myaa('publish');
exportfig('extremes-daily-regression.png', 'Width', 16);
close all;
