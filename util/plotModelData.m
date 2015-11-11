% add options to make subplots

function [fg, cb] = plotModelData(data, region, varargin)

step = -1;
caxisRange = [];
fgNum = 1;
contour = false;
cb = 0;
fg = 0;

fgTitle = '';
fgXaxis = '';
fgYaxis = '';
noNewFig = false;
colormapVal = '';
vectorData = {};
plotCountries = false;

if mod(length(varargin), 2) ~= 0
    'error: must have an even # of arguments.'
else
    for i=1:2:length(varargin)-1
        key = varargin{i};
        val = varargin{i+1};
        switch key
            case 'contour'
                contour = val;
            case 'step'
                step = val;
            case 'caxis'
                caxisRange = val;
            case 'fgNum'
                fgNum = val;
            case 'title'
                fgTitle = val;
            case 'xaxis'
                fgXaxis = val;
            case 'yaxis'
                fgYaxis = val;
            case 'nonewfig'
                noNewFig = val;
            case 'colormap'
                colormapVal = val;
            case 'vectorData'
                vectorData = val;
            case 'countries'
                plotCountries = val;
        end
    end
end

fgHandles = findobj('Type','figure');
fgNum = 1;
if length(fgHandles) > 0
    fgNum = max(fgHandles)+1;
end
if ~noNewFig
    fg = figure(fgNum);
    set(fg, 'Color', [1,1,1]);
    axis off;

    title(fgTitle);
    xlabel(fgXaxis);
    ylabel(fgYaxis);
end

if strcmp(region, 'world')
    worldmap world;
    data{1}(:, end+1) = data{1}(:, end) + (data{1}(:, end)-data{1}(:, end-1));
    data{2}(:, end+1) = data{2}(:, end) + (data{2}(:, end)-data{2}(:, end-1));
    data{3}(:, end+1) = data{3}(:, end) + (data{3}(:, end)-data{3}(:, end-1));
    
    mlabel off; plabel off;
elseif strcmp(region, 'north atlantic')
    worldmap([25 75], [-75 10]);
elseif strcmp(region, 'usa')
    axesm('mercator','MapLatLimit',[23 50],'MapLonLimit',[-128 -63]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'usa-exp')
    axesm('mercator','MapLatLimit',[23 60],'MapLonLimit',[-135 -55]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'africa')
    axesm('mercator','MapLatLimit',[-30 30],'MapLonLimit',[-20 60]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'west-africa')
    axesm('mercator','MapLatLimit',[0 30],'MapLonLimit',[-20 40]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'north-america')
    axesm('mercator','MapLatLimit',[20 75],'MapLonLimit',[-160 -35]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'usne')
    axesm('mercator','MapLatLimit',[36 50],'MapLonLimit',[-90 -60]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'middle')
    axesm('mercator','MapLatLimit',[-40 40],'MapLonLimit',[0 359]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'nepal')
    axesm('mercator','MapLatLimit',[15 40],'MapLonLimit',[70 100]);
    framem off; gridm off; mlabel off; plabel off;
elseif strcmp(region, 'asia-heat')
    axesm('mercator','MapLatLimit',[0 60],'MapLonLimit',[-40 180]);
    
else
    worldmap(region);
    data{1}(:, end+1) = data{1}(:, end) + (data{1}(:, end)-data{1}(:, end-1));
    data{2}(:, end+1) = data{2}(:, end) + (data{2}(:, end)-data{2}(:, end-1));
end

if length(colormapVal) > 0
    colormap(colormapVal);
else
    colormap('jet');
end

if step == -1
    step = (max(max(data{3}))-min(min(data{3})))/10;
end

caxis_min = round2(min(min(data{3})), step, 'floor');
caxis_max = round2(max(max(data{3})), step, 'ceil');

if contour
    if step ~= -1    
        contourfm(data{1}, data{2}, data{3}, 'LevelStep', step);    
    else
        contourfm(data{1}, data{2}, data{3});
    end
    
    if length(caxisRange) == 0
        caxis([caxis_min, caxis_max]);
    else
        caxis(caxisRange);
    end
    
    if ~noNewFig
        cb = contourcbar('Location', 'southoutside');
    end
else
    pcolorm(data{1}, data{2}, data{3});
    
    if length(caxisRange) == 0
        caxis([caxis_min, caxis_max]);
    else
        caxis(caxisRange);
    end
    
    if ~noNewFig
        cb = colorbar('Location', 'southoutside');
    end
end

if length(vectorData) ~= 0
    quiverm(vectorData{1}, vectorData{2}, vectorData{3}, vectorData{4}, 'k');
end

load coast;
plotm(lat, long, 'Color', [0 0 0], 'LineWidth', 2);

%if strcmp(region, 'usa')
    states = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
             {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
    geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
    
    if plotCountries
        countries = shaperead('countries', 'UseGeoCoords', true);
        geoshow(countries, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
        tightmap;
    end
%end
    
end

