
function selectDataRegion(fileDir, outputDir, baseYears, futureYears, variable, model, region, biasCorrect, v7, skipExisting)
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
    elseif strcmp(region, 'nh')
        latBounds = [25 60];
        lonBounds = [0 359];
    elseif strcmp(region, 'china')
        latBounds = [20, 55];
        lonBounds = [75, 135];  
    elseif strcmp(region, 'west_africa')
        latBounds = [0, 30];
        lonBounds = [340, 40];
    end

    for i = 1:length(fileNames)
        fname = fileNames{i};
        fNameParts = strsplit(fname, '.');

        load([fileDir '\' fname]);
        eval(['data = ' fNameParts{1} ';']);

        [latIndexRange, lonIndexRange] = latLonIndexRange(data, latBounds, lonBounds);
        data{1} = data{1}(latIndexRange, lonIndexRange);
        data{2} = data{2}(latIndexRange, lonIndexRange);
        data{3} = data{3}(latIndexRange, lonIndexRange, :);

        fNameYear = strsplit(fNameParts{1}, '_');
        fNameYear = str2num(fNameYear{2});
        if ~(ismember(fNameYear, baseYears) || ismember(fNameYear, futureYears))
            continue;
        end
        
        if exist([outputDir '\' fname], 'file') && skipExisting
            ['skipping ' outputDir '\' fname]
            continue;
        end
        
        if biasCorrect
            
            load(['cmip5BiasCorrection_' variable '_' region '.mat']);
            eval(['cmip5BiasCor = cmip5BiasCorrection_' variable '_' region ';']);
            
            biasModel = -1;
            for mn = 1:length(cmip5BiasCor)
                if strcmp(cmip5BiasCor{mn}{1}, model)
                    biasModel = mn;
                    break;
                end
            end
            
            isBaseYear = false;
            if ismember(fNameYear, baseYears)
                isBaseYear = true;
            end

            for xlat = 1:size(data{3}, 1)
                for ylon = 1:size(data{3}, 2)
                    for day = 1:size(data{3}, 3)
                        for p = 10:-1:1
                            if isBaseYear
                                % test against base cutoffs
                                if data{3}(xlat, ylon, day) > cmip5BiasCor{biasModel}{3}(xlat, ylon, p)
                                    data{3}(xlat, ylon, day) = data{3}(xlat, ylon, day) + cmip5BiasCor{biasModel}{2}(xlat, ylon, p);
                                    break;
                                end
                            else
                                % test against future cutoffs
                                if data{3}(xlat, ylon, day) > cmip5BiasCor{biasModel}{4}(xlat, ylon, p)
                                    data{3}(xlat, ylon, day) = data{3}(xlat, ylon, day) + cmip5BiasCor{biasModel}{2}(xlat, ylon, p);
                                    break;
                                end
                            end
                        end
                    end
                end
            end
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

    
    