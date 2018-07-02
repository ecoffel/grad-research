decades = 2020:10:2070;
threshold = 30:35;
models = 1:18;

for d = 1:length(decades)
    
    load(['E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_' num2str(decades(d)) '.mat']);
    eval(['ssp = ssp5_' num2str(decades(d)) ';']);
    
    exposure = [];
    
    for t = 1:length(threshold)
        for m = 1:length(models)
            load(['C:\git-ecoffel\grad-research\2015-heat-humidity\selGrid\selGrid-' num2str(decades(d)) 's-rcp85-' num2str(threshold(t)) 'C-scenario-' num2str(models(m))]);
            
            exposure(t, m) = sum(sum(ssp{3}(logical(selGrid))));            
        end
    end
    
    csvwrite(['exposure-' num2str(decades(d)) '.csv'], exposure);
end

