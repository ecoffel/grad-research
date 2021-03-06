
function selectDataRegion(fileDir, outputDir, baseYears, futureYears, bc_futureDecades, bc_variable, bc_model, bc_rcp, region, biasCorrect, v7, skipExisting)
    %fileDir = ['E:\data\ncep-reanalysis\output\tmax\' num2str(y)];
    %outputDir = 'C:\git-ecoffel\climate-som\data\ncep\tmax';

    fileNames = dir([fileDir, '\', '*.mat']);
    fileNames = {fileNames.name};
    
    if strcmp(region, 'usne')
        latBounds = [30 55];
        lonBounds = [-100 -62] + 360;
    elseif strcmp(region, 'nepal')
        latBounds = [15 45];
        lonBounds = [70 100];
    elseif strcmp(region, 'cambodia')
        latBounds = [5 20];
        lonBounds = [95 120];
    elseif strcmp(region, 'nh')
        latBounds = [25 60];
        lonBounds = [0 359];
    elseif strcmp(region, 'china')
        latBounds = [20, 55];
        lonBounds = [75, 135];  
    elseif strcmp(region, 'west_africa')
        latBounds = [0, 30];
        lonBounds = [340, 40];
    elseif strcmp(region, 'world')
        latBounds = [-90, 90];
        lonBounds = [0 360];
    elseif strcmp(region, 'india')
        latBounds = [8, 34];
        lonBounds = [67, 90];
    elseif strcmp(region, 'mexico')
        latBounds = [10 35];
        lonBounds = [-120, -85] + 360;
    elseif strcmp(region, 'nyc')
        latBounds = [40 42];
        lonBounds = [-75 -73] + 360;
    end

    load('waterGrid.mat');
    load('e:\data\cmip5\output\gfdl-cm3\r1i1p1\historical\tasmax\regrid\world-bc\19800101-19841231\tasmax_1980_01_01');
    [latIndexRange, lonIndexRange] = latLonIndexRange(tasmax_1980_01_01, latBounds, lonBounds);
    waterGrid = waterGrid(latIndexRange, lonIndexRange);
    clear tasmax_1980_01_01;
    
    for i = 1:length(fileNames)
        fname = fileNames{i};
        fNameParts = strsplit(fname, '.');

        load([fileDir '\' fname]);
        eval(['data = ' fNameParts{1} ';']);

        [latIndexRange, lonIndexRange] = latLonIndexRange(data, latBounds, lonBounds);
        data{1} = data{1}(latIndexRange, lonIndexRange);
        data{2} = data{2}(latIndexRange, lonIndexRange);
        data{3} = data{3}(latIndexRange, lonIndexRange, :);
        
        dataOld = data{3};
        
        
        if data{3}(1) > 100
            data{3} = data{3} - 273.15;
        end
        
        fNameYear = strsplit(fNameParts{1}, '_');
        fNameYear = str2num(fNameYear{2});
        if ~(ismember(fNameYear, baseYears) || ismember(fNameYear, futureYears))
            continue;
        end
        
        if exist([outputDir '\' fname], 'file') && skipExisting
            ['skipping ' outputDir '\' fname]
            continue;
        end
        
		% ----------------------------------------- APPLICATION OF BIAS CORRECTION ------------------------------------------------
        if biasCorrect
            
            if strcmp(bc_rcp, 'historical')
                bc_rcp = 'rcp85';
            end
            
            %load the bias correction file created by biasCorrect.m
            load(['cmip5BiasCorrection_' bc_variable '_' region '_' bc_rcp '.mat']);
            eval(['cmip5BiasCor = cmip5BiasCorrection_' bc_variable '_' region ';']);
            
			% search the correction file for the current cmip5 model
            biasModel = -1;
            for mn = 1:length(cmip5BiasCor)
                if strcmp(cmip5BiasCor{mn}{1}, bc_model)
                    biasModel = mn;
                    break;
                end
            end
            
            isBaseYear = false;
            if ismember(fNameYear, baseYears)
                isBaseYear = true;
            end

            roundedYear = roundn(fNameYear, 1);
            closestDecade = 3 + find(bc_futureDecades == roundedYear);
            if roundedYear >= bc_futureDecades(end)
                closestDecade = closestDecade - 1;
            end
            
			% loop over every gridbox
            for xlat = 1:size(data{3}, 1)
                for ylon = 1:size(data{3}, 2)
					% skip water tiles
                    if waterGrid(xlat, ylon)
                        continue;
                    end
					% loop over every day in new model data
                    for day = 1:size(data{3}, 3)
						% loop over each decile
                        for p = 10:-1:1
							% if it is in the historical period...
                            if isBaseYear
                                % test against historical period decile cutoffs
                                if p == 1
                                    % if we have reached p = 1, then cell
                                    % is either between p = 1 and 2 or < p
                                    % = 1, both of which result in applying
                                    % p = 1 correction
                                    data{3}(xlat, ylon, day) = data{3}(xlat, ylon, day) + cmip5BiasCor{biasModel}{2}(xlat, ylon, p);
                                    break;
                                else
                                    if data{3}(xlat, ylon, day) > cmip5BiasCor{biasModel}{3}{2}(xlat, ylon, p)
                                        data{3}(xlat, ylon, day) = data{3}(xlat, ylon, day) + cmip5BiasCor{biasModel}{2}(xlat, ylon, p);
                                        break;
                                    end
                                end
                            else
                                % test against future decile cutoffs
                                if p == 1
                                    data{3}(xlat, ylon, day) = data{3}(xlat, ylon, day) + cmip5BiasCor{biasModel}{2}(xlat, ylon, p);
                                    break;
                                else
                                    if data{3}(xlat, ylon, day) > cmip5BiasCor{biasModel}{closestDecade}{2}(xlat, ylon, p)
                                        data{3}(xlat, ylon, day) = data{3}(xlat, ylon, day) + cmip5BiasCor{biasModel}{2}(xlat, ylon, p);
                                        break;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
		% ------------------------------------------ END OF BIAS CORRECTION APPLICATION --------------------------------------------------
        if ~exist(outputDir)
            mkdir(outputDir);
        end
        
        eval([fNameParts{1} ' = data;']);
        if v7
            save([outputDir '\' fname], fNameParts{1}, '-v7');
        else
            save([outputDir '\' fname], fNameParts{1}, '-v7.3');
        end
        ['processed ' fNameParts{1}]
        clear data;
        eval(['clear ' fNameParts{1} ';']);
    end
end

    
    