
dataset = 'e:/data/cmip5/output';

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%           'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', ...
%           'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'inmcm4', ...
%           'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

models = {'bcc-csm1-1-m', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', ...
              'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
      
      
rcp = 'rcp85';

startYear = 2020;
endYear = 2099;

GMTRanges = [[.75 1.25];
             [1.75 2.25];
             [2.75 3.25];
             [3.75 4.24]];
GMTYears = {};

for model = 1:length(models)
    curGMTYears = {};
    
    if exist(['2019-electricity/future-temps/us-eu-pp-' rcp '-tx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], 'file')
        %continue;
    end
        
    fprintf('loading %s/historical...\n', models{model})
    tempHist = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/historical/tas/'], 'tas', 'startYear', 1981, 'endYear', 2005);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempHist{3}))))) > 100
        tempHist{3} = tempHist{3} - 273.15;
    end
    
    histGMT = nanmean(nanmean(nanmean(nanmean(tempHist{3}))));
    
    fprintf('loading %s/future...\n', models{model})
    tempFut = loadMonthlyData(['E:/data/cmip5/output/' models{model} '/mon/r1i1p1/' rcp '/tas/'], 'tas', 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempFut{3}))))) > 100
        tempFut{3} = tempFut{3} - 273.15;
    end

    % loop over all future years
    for y = 1:size(tempFut{3}, 3)
        % mean temp in current future year
        curGMT = nanmean(nanmean(nanmean(tempFut{3}(:, :, y, :))));
        
        diffGMT = curGMT - histGMT;
        
        % over all temp ranges
        for g = 1:size(GMTRanges, 1)
            % if current year falls into current temp range
            if diffGMT >= GMTRanges(g,1) && diffGMT <= GMTRanges(g,2)
                if length(curGMTYears) < g
                    curGMTYears{g} = [];
                end
                
                % add the year to the list of years in this temp range
                curGMTYears{g} = [curGMTYears{g} (y+2020-1)]
            end
        end
    end
    
    GMTYears{model} = curGMTYears;

%     csvwrite(['2019-electricity/future-temps/us-eu-pp-' rcp '-tx-cmip5-' models{model} '-' num2str(startYear) '-' num2str(endYear) '.csv'], modelPlantTxTimeSeries);   
    
end

save('2019-electricity/GMTYears.mat', 'GMTYears');
fid = fopen('2019-electricity/GMTYears.dat', 'w');
for model = 1:length(GMTYears)
    for g = 1:length(GMTYears{model})
        fprintf(fid, '%s,', models{model});
        fprintf(fid, '%d,', g);
        
        for y = 1:(length(GMTYears{model}{g})-1)
            fprintf(fid, '%d,', GMTYears{model}{g}(y));
        end
        
        if length(GMTYears{model}{g}) > 0
            fprintf(fid, '%d\n', GMTYears{model}{g}(end));
        else
            fprintf(fid, '\n');
        end
    end
end
fclose(fid);




gmtMinYear = [-1, -1, -1, -1];
gmtMaxYear = [-1, -1, -1, -1];

gmtMeanYear = [0, 0, 0, 0];
gmtMeanCnt = [0, 0, 0, 0];

for m = 1:length(GMTYears)
    for g = 1:4
        if length(GMTYears{m}) < g || length(GMTYears{m}{g}) == 0
            continue;
        end
        
        gmtMeanYear(g) = gmtMeanYear(g) + nanmin(GMTYears{m}{g});
        gmtMeanCnt(g) = gmtMeanCnt(g) + 1;
        
        if gmtMinYear(g) == -1 || nanmin(GMTYears{m}{g}) < gmtMinYear(g)
            gmtMinYear(g) = nanmin(GMTYears{m}{g});
        end
        
        if gmtMaxYear(g) == -1 || nanmin(GMTYears{m}{g}) > gmtMaxYear(g)
            gmtMaxYear(g) = nanmax(GMTYears{m}{g});
        end
    end
end







