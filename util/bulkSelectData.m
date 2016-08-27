var = 'pr';
models = {'bnu-esm', 'ccsm4', 'cnrm-cm5', 'hadgem2-es', 'noresm1-m'};
%models = {''};
rcps = {'historical', 'rcp85'};
%rcps = {''};
years = [1985:2080];
ensembles = 1;

inputBaseDir = 'e:\data\cmip5\output';
%inputBaseDir = 'e:\data\ncep-reanalysis\output';
outputBaseDir = 'c:\data';

region = 'cambodia';

for m = 1:length(models)
    for r = 1:length(rcps)
        for e = ensembles

            inputDir = [inputBaseDir '\' models{m} '\r' num2str(e) 'i1p1\' rcps{r} '\' var '\regrid\' region '\'];
            %inputDir = [inputBaseDir '\' var '\regrid\'];

            dirNames = dir(inputDir);
            dirIndices = [dirNames(:).isdir];
            dirNames = {dirNames(dirIndices).name}';

            outputFinalDir = [outputBaseDir '\' region '\' models{m} '\r' num2str(e) 'i1p1\' rcps{r} '\' var];
            
            for d = 1:length(dirNames)
                if strcmp(dirNames{d}, '.') || strcmp(dirNames{d}, '..')
                    continue;
                end
                
                selectDataRegion([inputDir dirNames{d}], outputFinalDir, years, years, [], '', '', '', region, false, true, true);
            end

        end
    end
end

