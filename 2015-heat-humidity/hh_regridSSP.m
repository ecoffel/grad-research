popYears = 2010:10:2100;

sspNum = 3;

sspInputDir = ['C:/git-ecoffel/grad-research/ssp/ssp' num2str(sspNum) '/output/ssp' num2str(sspNum)];
sspOutputDir = ['C:/git-ecoffel/grad-research/ssp/ssp' num2str(sspNum) '/output/ssp' num2str(sspNum) '/regrid'];

load('E:/data/cmip5/output/gfdl-cm3/r1i1p1/historical/tasmax/regrid/19800101-19841231/tasmax_1980_01_01.mat');
baseLat = tasmax_1980_01_01{1};
baseLon = tasmax_1980_01_01{2};

for y = 1:length(popYears)
    newSSP = [];
    
    sspFileName = ['ssp' num2str(sspNum) '_' num2str(popYears(y))];
    
    load([sspInputDir '/' sspFileName '.mat']);
    eval(['ssp = ssp' num2str(sspNum) '_' num2str(popYears(y)) ';']);
    eval(['clear ssp' num2str(sspNum) '_' num2str(popYears(y)) ';']);
    
    sspLat = ssp{1};
    sspLon = ssp{2};
    sspData = ssp{3};
    
    for xlat = 1:size(baseLat, 1)
        for ylon = 1:size(baseLat, 2)
            minLat = baseLat(xlat, ylon);
            maxLat = minLat + 2;
            minLon = baseLon(xlat, ylon);
            maxLon = minLon + 2;
            
            if minLon > 180
                minLon = minLon-360;
            end
            if maxLon > 180
                maxLon = maxLon-360;
            end
            
            xlativ = find(squeeze(sspLat(:,1)) >= minLat & squeeze(sspLat(:,1)) <= maxLat);
            yloniv = find(squeeze(sspLon(1,:)) >= minLon & squeeze(sspLon(1,:)) <= maxLon);
            
            newSSP(xlat, ylon) = nansum(nansum(sspData(xlativ, yloniv)));
        end
    end
    
    eval([sspFileName ' = {baseLat, baseLon, newSSP};']);
    save([sspOutputDir '/' sspFileName '.mat'], sspFileName);
    
    clear ssp sspLat sspLon sspData;
end
    
    

    
    