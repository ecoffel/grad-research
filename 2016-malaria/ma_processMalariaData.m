vars = {'hurs', 'tas', 'pr'};

modelBaseDir = 'cmip5/raw';
models = {'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'cnrm-cm5'};

ensembles = 1;
rcps = {'historical', 'rcp85', 'rcp45'};
      
for m = 1:length(models)
    for e = 1:length(ensembles)
        for r = 1:length(rcps)
            for v = 1:length(vars)
                cmip5NcToMat_monthly(['e:/data/' modelBaseDir '/' models{m} '/r' num2str(ensembles(e)) 'i1p1/' rcps{r} '/' vars{v}], 'e:/data/cmip5/output', vars{v}, -1);
            end
        end
    end
end