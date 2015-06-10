yearStart = 2051;
yearEnd = 2071;
yearStep = 1; % the number of years loaded at a time for memory  reasons

% vars = {'narccap/output/crcm/ccsm', 'narccap/output/crcm/cgcm3', ...
%         'narccap/output/ecp2/gfdl', 'narccap/output/hrm3/gfdl', ...
%         'narccap/output/hrm3/hadcm3', 'narccap/output/mm5i/ccsm', ...
%         'narccap/output/mm5i/hadcm3', 'narccap/output/rcm3/cgcm3', ...
%         'narccap/output/rcm3/gfdl', 'narccap/output/wrfg/ccsm', ...
%         'narccap/output/wrfg/cgcm3'};

baseDir = 'e:/data/';
var = 'narccap/output/ensemble-mean';
titleModelStr = 'narccap ensemble mean zg500 EOF [2051-2071]';
fileNameModelStr = 'narccap-ensemble-mean-zg500-eof-future.png';

if length(findstr(var, 'narccap')) ~= 0
    tempVar = 'tasmax';
    tempPlev = -1;

    zg500Var = 'zg500';
    zg500Plev = -1;
    
    if length(findstr(var, 'ensemble-mean')) == 0
        isRegridded = true;
    else
        isRegridded = false;
    end
elseif length(findstr(var, 'narr')) ~= 0
    tempVar = 'tasmax';
    tempPlev = -1;

    zg500Var = 'hgt';
    zg500Plev = 2;
    
    isRegridded = false;
elseif length(findstr(var, 'ncep')) ~= 0
    tempVar = 'tmax';
    tempPlev = -1;

    zg500Var = 'hgt';
    zg500Plev = 6;
    
    isRegridded = false;
end

lat = [];
lon = [];
baseGrid = {};

tempLatRange = [38 41];
tempLonRange = [284 287];

if isRegridded
    tempStr = [baseDir var '/' tempVar '/regrid'];
    zg500Str = [baseDir var '/' zg500Var '/regrid'];
else
    tempStr = [baseDir var '/' tempVar];
    zg500Str = [baseDir var '/' zg500Var];
end

% if tempPlev ~= -1
%     dailyTemp = loadDailyData(tempStr, 'yearStart', yearStart, 'yearEnd', yearEnd, 'plev', tempPlev);
% else
%     dailyTemp = loadDailyData(tempStr, 'yearStart', yearStart, 'yearEnd', yearEnd);
% end

if zg500Plev ~= -1
    dailyZg500 = loadDailyData(zg500Str, 'yearStart', yearStart, 'yearEnd', yearEnd, 'plev', zg500Plev);
else
    dailyZg500 = loadDailyData(zg500Str, 'yearStart', yearStart, 'yearEnd', yearEnd);
end

lat = dailyZg500{1};
lon = dailyZg500{2};
zg500DailyData = single(dailyZg500{3});

% create eof matrix
X = reshape(zg500DailyData, [size(zg500DailyData,1)*size(zg500DailyData,2), ...
                            size(zg500DailyData,3)*size(zg500DailyData,4)*size(zg500DailyData,5)]);

clear dailyZg500 zg500DailyData;

N = size(X,2);
nEof = 100;
for x = 1:size(X, 1)
    X(x, :) = detrend(X(x,:));
end
                        
[U,S,V] = svd(X);
clear X;
E = U(:,1:nEof);
clear U;

E = double(E);
P = S*transpose(V);
clear V;

D = S*transpose(S)/(N-1);
clear S;

percPerVar = diag(D)./(trace(D));
percPerVar = percPerVar(1:nEof);
clear D;

eofs = [];
for e = 1:size(E,2)
    eofs(:,:,e) = reshape(E(:,e), [size(lat,1), size(lat,2)]);
end
clear E;

fg = figure('Color', [1 1 1]);
hold on;
for i=1:9
    ax = subaxis(3,3,i, 'Spacing', 0.1, 'SpacingHoriz', 0, 'Padding', 0, 'MarginRight', 0.1, 'MarginTop', 0.15);
    plotModelData({lat,lon,eofs(:,:,i)},'north america','nonewfig', true);
    title(['EOF ', num2str(i), ' (' num2str(percPerVar(i),2), ')'], 'FontSize', 12);
    cb = colorbar('Location', 'eastoutside');
    cbInitPos = get(cb, 'Position');
    set(cb, 'Position', [cbInitPos(1)+cbInitPos(3)*1.25 cbInitPos(2) cbInitPos(3)*0.5 cbInitPos(4)]);
end
h = suptitle(titleModelStr);
set(h, 'FontSize', 18);
set(gcf, 'Position', get(0,'Screensize'));
myaa('publish');
exportfig(fileNameModelStr, 'Width', 16);



