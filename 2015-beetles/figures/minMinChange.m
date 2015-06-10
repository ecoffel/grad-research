% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

baseDir = 'e:/data/';
testVar = 'tasmin';
baseVar = 'tmin';
findMax = false;
months = [12 1 2];

basePeriod = 1981:1999;
testPeriod = basePeriod;%2051:2071;
yearStep = 1; % the number of years loaded at a time for memory

baseData = 'ncep-reanalysis/output';
vars = {'narccap/output/ensemble-mean'};

plotTitle = 'NARCCAP ensemble mean [1981-1999] yearly DJF minimum minimum - NCEP [1981-1999]';
fileTitle = 'minMinChange-narccap-em-ncep.png';
%vars = {'crcm/ncep', 'ecp2/ncep', 'hrm3/ncep', 'mm5i/ncep', 'rcm3/ncep', 'wrfg/ncep'};

if ~exist('baseExt')
    baseExt = {};
end

ext = {};

for v = 1:length(vars)
    curModel = vars{v};
    curModelParts = strsplit(curModel, '/');
    
    if length(baseExt) == 0
        ['loading base...']
        baseExt = {};
        for y = basePeriod(1):yearStep:basePeriod(end)
            ['year ' num2str(y) '...']
            baseDaily = loadDailyData([baseDir baseData '/' baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
            baseExt = {baseExt{:} baseExtTmp{:}};
            clear baseDaily;
        end
    end
    
    varNameBase = [curModelParts{end-1}, '_', curModelParts{end}];
    varNameBase(varNameBase == '-') = '_';
    varName = [varNameBase, '_ext'];
    
    if ~exist(varName)
        eval([varName, ' = {};']);
        
        ['loading ', varName]

        for y = testPeriod(1):yearStep:testPeriod(end)
            ['year ' num2str(y) '...']
            % load daily data
            eval([varNameBase, '_daily = loadDailyData(''', baseDir, curModel, ...
                 '/', testVar, ''', ''yearStart'', y, ''yearEnd'', (y+yearStep)-1);']);
            % find extremes
            eval([varNameBase, '_ext_tmp = findYearlyExtremes(', varNameBase, '_daily, months, findMax);']);
            % concat extremes 
            eval([varNameBase, '_ext = {',varNameBase, '_ext{:} ', ...
                  varNameBase, '_ext_tmp{:}};']);
            % clear daily data
            eval(['clear ', varNameBase, '_daily']);
        end
    end
    
    newExt = eval(varName);
    
    if length(ext) == 0
        ext = {newExt};
    else
        ext = {ext{:} newExt};
    end
    
    clear newExt;
end

['done loading...']

for e = 1:length(ext)
    curModelAvg = [];
    baseExtAvg = [];

    for y = 1:min(length(ext{e}), length(baseExt))
        curModelAvg(:,:,y) = ext{e}{y}{3};
        baseExtAvg(:,:,y) = baseExt{y}{3};
    end

    % construct plotable structures
    curModelAvg = {ext{e}{1}{1}, ext{e}{1}{2}, mean(curModelAvg, 3)};
    baseExtAvg = {baseExt{1}{1}, baseExt{1}{2}, mean(baseExtAvg, 3)};

    % regrid the base data
    baseExtAvgRegrid = regrid(baseExtAvg, curModelAvg);
    curModelExtAvgBias = {curModelAvg{1}, curModelAvg{2}, curModelAvg{3}-baseExtAvgRegrid{3}};
    
    [fg,cb] = plotModelData(curModelExtAvgBias, 'usa', 'caxis', [-10 25]);
    xlabel(cb, 'degrees C', 'FontSize', 18);
    cbPos = get(cb, 'Position');
    title(plotTitle, 'FontSize', 18);
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf, 'Units', 'normalized');
    set(gca, 'Units', 'normalized');
    
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
    myaa('publish');
    exportfig(fileTitle, 'Width', 16);
    close all;
end

