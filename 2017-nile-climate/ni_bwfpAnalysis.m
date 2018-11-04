

[regionInds, regions, regionNames] = ni_getRegions();
regionBoundsEthiopia = regions('nile-ethiopia');%[[5.5 14.8]; [31, 40]];
regionBoundsBlue = regions('nile-blue');%[[5.5 14.8]; [31, 40]];
regionBoundsWhite = regions('nile-white');%[[5.5 14.8]; [31, 40]];

if ~exist('ssp1_2010')
    load E:\data\ssp-pop\ssp1\output\ssp1\ssp1_2010.mat;
    [latIndsEthiopiaSSP, lonIndsEthiopiaSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
    [latIndsBlueSSP, lonIndsBlueSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
    [latIndsWhiteSSP, lonIndsWhiteSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
end

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%                       'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                       'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                       'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%                       'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

models = {'bcc-csm1-1-m', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', ...
              'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
if ~exist('tas')
    for mind = 1:length(models)
        fprintf('loading %s tas, pr historical...\n', models{mind});

        tas = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\tas'], 'tas', 'startYear', 1900, 'endYear', 2005);
        tasFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\tas'], 'tas', 'startYear', 2006, 'endYear', 2099);
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\pr'], 'pr', 'startYear', 1900, 'endYear', 2005);
        prFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\pr'], 'pr', 'startYear', 2006, 'endYear', 2099);
        
        [latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5] = latLonIndexRange({tas{1}, tas{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
        [latIndsBlueCmip5, lonIndsBlueCmip5] = latLonIndexRange({tas{1}, tas{2},[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
        [latIndsWhiteCmip5, lonIndsWhiteCmip5] = latLonIndexRange({tas{1}, tas{2},[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

        tdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(tas{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        pdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(pr{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        
        tdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(tas{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        pdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(pr{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        
        tdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(tas{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        pdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(pr{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        
        tfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        pfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        
        tfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        pfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        
        tfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        pfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
    end
end

% load and store ssp data
if ~exist('ssp')
    ssp = [];
    for s = 1:5
        fprintf('loading ssp %d...\n',s);
        decind = 1;
        for dec = 2010:10:2090
            load(['E:\data\ssp-pop\ssp' num2str(s) '\output\ssp' num2str(s) '\ssp' num2str(s) '_' num2str(dec) '.mat']);
            eval(['ssp(:,:,decind,s) = ssp' num2str(s) '_' num2str(dec) '{3};']);
            decind = decind+1;
        end
    end
end

earthradius = almanac('earth','radius','meters');

if ~exist('bwSupplyHistBlue')
    bwSupplyHistBlue = zeros(length(1900:2005), length(models), 5);
    bwSupplySpatialHistBlue = [];
    bwSupplySpatialHistWhite = [];
    bwSupplyFutBlue = zeros(length(2006:2085), length(models), 5);
    bwSupplySpatialFutBlue = [];
    bwSupplySpatialFutWhite = [];
    
    bwSupplyHistWhite = zeros(length(1900:2005), length(models), 5);
    bwSupplyFutWhite = zeros(length(2006:2085), length(models), 5);
    
    bwSupplyHistTotal = zeros(length(1900:2005), length(models), 5);
    bwSupplyFutTotal = zeros(length(2006:2085), length(models), 5);
    
    monthLengths = [31 28 31 30 31 30 31 31 30 31 30 31];
    
    for mind = 1:length(models)
        fprintf('loading %s mrro historical...\n', models{mind});
        mrros = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\mrro'], 'mrro', 'startYear', 1900, 'endYear', 2005);
        mrrosFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\mrro'], 'mrro', 'startYear', 2006, 'endYear', 2099);
        
        for month = 1:12
            mrros{3}(:, :, :, month) = mrros{3}(:, :, :, month) .* 60 .* 60 .* 24 .* monthLengths(month);
            mrrosFut{3}(:, :, :, month) = mrrosFut{3}(:, :, :, month) .* 60 .* 60 .* 24 .* monthLengths(month);
        end
        
        [latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5] = latLonIndexRange({mrros{1}, mrros{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
        [latIndsBlueCmip5, lonIndsBlueCmip5] = latLonIndexRange({mrros{1}, mrros{2},[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
        [latIndsWhiteCmip5, lonIndsWhiteCmip5] = latLonIndexRange({mrros{1}, mrros{2},[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

        latdiff = ssp1_2010{1}(2,1)-ssp1_2010{1}(1,1);
        londiff = ssp1_2010{2}(1,2)-ssp1_2010{2}(1,1);
        
        areaTableBlue = [];
        cmip5LatTableBlue = [];
        cmip5LonTableBlue = [];
        for xind = 1:length(latIndsBlueSSP)
            xlat = latIndsBlueSSP(xind);
            for yind = 1:length(lonIndsBlueSSP)
                ylon = lonIndsBlueSSP(yind);
                curArea = areaint([ssp1_2010{1}(xlat, ylon) ssp1_2010{1}(xlat, ylon)+latdiff ssp1_2010{1}(xlat, ylon)+latdiff ssp1_2010{1}(xlat, ylon)], ...
                                  [ssp1_2010{2}(xlat, ylon) ssp1_2010{2}(xlat, ylon) ssp1_2010{2}(xlat, ylon)+londiff ssp1_2010{2}(xlat, ylon)+londiff], earthradius);


                [curCmip5LatInd, curCmip5LonInd] = latLonIndex({mrros{1}, mrros{2},[]}, [ssp1_2010{1}(xlat, ylon), ssp1_2010{2}(xlat, ylon)]);
                cmip5LatTableBlue(xind, yind) = curCmip5LatInd;
                cmip5LonTableBlue(xind, yind) = curCmip5LonInd;
                
                areaTableBlue(xind, yind) = curArea;
            end
        end
        
        areaTableWhite = [];
        cmip5LatTableWhite = [];
        cmip5LonTableWhite = [];
        for xind = 1:length(latIndsWhiteSSP)
            xlat = latIndsWhiteSSP(xind);
            for yind = 1:length(lonIndsWhiteSSP)
                ylon = lonIndsWhiteSSP(yind);
                curArea = areaint([ssp1_2010{1}(xlat, ylon) ssp1_2010{1}(xlat, ylon)+latdiff ssp1_2010{1}(xlat, ylon)+latdiff ssp1_2010{1}(xlat, ylon)], ...
                                  [ssp1_2010{2}(xlat, ylon) ssp1_2010{2}(xlat, ylon) ssp1_2010{2}(xlat, ylon)+londiff ssp1_2010{2}(xlat, ylon)+londiff], earthradius);


                [curCmip5LatInd, curCmip5LonInd] = latLonIndex({mrros{1}, mrros{2},[]}, [ssp1_2010{1}(xlat, ylon), ssp1_2010{2}(xlat, ylon)]);
                cmip5LatTableWhite(xind, yind) = curCmip5LatInd;
                cmip5LonTableWhite(xind, yind) = curCmip5LonInd;
                
                areaTableWhite(xind, yind) = curArea;
            end
        end
            
        fprintf('computing bw supply...\n');
        for s = 1:5
            
            for year = 1:size(mrros{3}, 3)
                % blue nile
                for xind = 1:length(latIndsBlueSSP)
                    xlat = latIndsBlueSSP(xind);
                    for yind = 1:length(lonIndsBlueSSP)
                        ylon = lonIndsBlueSSP(yind);
                        
                        bwSupplySpatialHistBlue(xind, yind, year, mind, s) = areaTableBlue(xind, yind) * ...
                                                                       nansum(squeeze(mrros{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3 ...
                                                                       / ssp(xlat, ylon, 1, s);
                        
                        ittr = (areaTableBlue(xind, yind) * nansum(squeeze(mrros{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, 1, s)) * ...
                                                     (ssp(xlat, ylon, 1, s) / nansum(nansum(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s))));
                                                 
                        % could be nan if div by 0 pop
                        if ~isnan(ittr)
                            bwSupplyHistBlue(year, mind, s) = bwSupplyHistBlue(year, mind, s) + ittr;
                        end
                        
                        ittrTotal = (areaTableBlue(xind, yind) * nansum(squeeze(mrros{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, 1, s)) * ...
                                                     (ssp(xlat, ylon, 1, s) / (nansum(nansum(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s))) + nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));
                                                 
                        % could be nan if div by 0 pop
                        if ~isnan(ittrTotal)
                            bwSupplyHistTotal(year, mind, s) = bwSupplyHistTotal(year, mind, s) + ittrTotal;
                        end
                    end
                end
                
                % white nile
                for xind = 1:length(latIndsWhiteSSP)
                    xlat = latIndsWhiteSSP(xind);
                    for yind = 1:length(lonIndsWhiteSSP)
                        ylon = lonIndsWhiteSSP(yind);
                        
                        bwSupplySpatialHistWhite(xind, yind, year, mind, s) = areaTableWhite(xind, yind) * ...
                                                                       nansum(squeeze(mrros{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3 ...
                                                                       / ssp(xlat, ylon, 1, s);
                        
                        ittr = (areaTableWhite(xind, yind) * nansum(squeeze(mrros{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, 1, s)) * ...
                                                     (ssp(xlat, ylon, 1, s) / nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s))));
                                                 
                        % could be nan if div by 0 pop
                        if ~isnan(ittr)
                            bwSupplyHistWhite(year, mind, s) = bwSupplyHistWhite(year, mind, s) + ittr;
                        end               
                        
                        ittrTotal = (areaTableWhite(xind, yind) * nansum(squeeze(mrros{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, 1, s)) * ...
                                                     (ssp(xlat, ylon, 1, s) / (nansum(nansum(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s))) + nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));
                                                 
                        % could be nan if div by 0 pop
                        if ~isnan(ittrTotal)
                            bwSupplyHistTotal(year, mind, s) = bwSupplyHistTotal(year, mind, s) + ittrTotal;
                        end
                    end
                end
                
            end
            
            for year = 1:(2085-2006)+1
                decind = (round(year + 2006 - 1, -1) - 2010)/10+1;
                for xind = 1:length(latIndsBlueSSP)
                    xlat = latIndsBlueSSP(xind);
                    for yind = 1:length(lonIndsBlueSSP)
                        ylon = lonIndsBlueSSP(yind);
                        
                        bwSupplySpatialFutBlue(xind, yind, year, mind, s) = areaTableBlue(xind, yind) * ...
                                                                       nansum(squeeze(mrrosFut{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3 ...
                                                                       / ssp(xlat, ylon, decind, s);
                        
                        ittr = (areaTableBlue(xind, yind) * nansum(squeeze(mrrosFut{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, decind, s)) * ...
                                                     (ssp(xlat, ylon, decind, s) / nansum(nansum(ssp(latIndsBlueSSP, lonIndsBlueSSP, decind, s))));
                        if ~isnan(ittr)
                            bwSupplyFutBlue(year, mind, s) = bwSupplyFutBlue(year, mind, s) + ittr;
                        end
                        
                        ittrTotal = (areaTableBlue(xind, yind) * nansum(squeeze(mrrosFut{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, decind, s)) * ...
                                                     (ssp(xlat, ylon, 1, s) / (nansum(nansum(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s))) + nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));
                                                 
                        % could be nan if div by 0 pop
                        if ~isnan(ittrTotal)
                            bwSupplyFutTotal(year, mind, s) = bwSupplyFutTotal(year, mind, s) + ittrTotal;
                        end
                                                     
                    end
                end
                
                % white nile
                for xind = 1:length(latIndsWhiteSSP)
                    xlat = latIndsWhiteSSP(xind);
                    for yind = 1:length(lonIndsWhiteSSP)
                        ylon = lonIndsWhiteSSP(yind);
                        
                        bwSupplySpatialFutWhite(xind, yind, year, mind, s) = areaTableWhite(xind, yind) * ...
                                                                       nansum(squeeze(mrrosFut{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3 ...
                                                                       / ssp(xlat, ylon, decind, s);
                        
                        ittr = (areaTableWhite(xind, yind) * nansum(squeeze(mrrosFut{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, decind, s)) * ...
                                                     (ssp(xlat, ylon, decind, s) / nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, decind, s))));
                        if ~isnan(ittr)
                            bwSupplyFutWhite(year, mind, s) = bwSupplyFutWhite(year, mind, s) + ittr;
                        end
                        
                        ittrTotal = (areaTableWhite(xind, yind) * nansum(squeeze(mrrosFut{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3 / ssp(xlat, ylon, decind, s)) * ...
                                                     (ssp(xlat, ylon, decind, s) / (nansum(nansum(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s))) + nansum(nansum(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));
                                                 
                        % could be nan if div by 0 pop
                        if ~isnan(ittrTotal)
                            bwSupplyFutTotal(year, mind, s) = bwSupplyFutTotal(year, mind, s) + ittrTotal;
                        end
                                                     
                    end
                end
            end
        end
                

        mdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(mrros{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        mdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(mrros{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        mdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(mrros{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        
        mfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(mrrosFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        mfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(mrrosFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        mfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(mrrosFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
    end
end


if ~exist('gldasRunoff')
    fprintf('loading gldas...\n');
    load 2017-nile-climate\output\gldas_qs.mat
    load 2017-nile-climate\output\gldas_qsb.mat
    load 2017-nile-climate\output\gldas_pr.mat
    load 2017-nile-climate\output\gldas_t.mat

    latGldas = gldas_t{1};
    lonGldas = gldas_t{2};
    [latIndsEthiopiaGldas, lonIndsEthiopiaGldas] = latLonIndexRange({latGldas, lonGldas,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
    [latIndsBlueGldas, lonIndsBlueGldas] = latLonIndexRange({latGldas, lonGldas,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
    [latIndsWhiteGldas, lonIndsWhiteGldas] = latLonIndexRange({latGldas, lonGldas,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

    gldasRunoff = gldas_qs{3}(:, :, :, :) + gldas_qsb{3}(:, :, :, :);
    gldasRunoffEthiopia = squeeze(nanmean(nanmean(nansum(gldasRunoff(latIndsEthiopiaGldas, lonIndsEthiopiaGldas,:,:),4),2),1));
    gldasTEthiopia = squeeze(nanmean(nanmean(nanmean(gldas_t{3}(latIndsEthiopiaGldas, lonIndsEthiopiaGldas,:,:),4),2),1));
    gldasPrEthiopia = squeeze(nanmean(nanmean(nanmean(gldas_pr{3}(latIndsEthiopiaGldas, lonIndsEthiopiaGldas,:,:),4),2),1));

    gldasRunoffBlue = squeeze(nanmean(nanmean(nansum(gldasRunoff(latIndsBlueGldas, lonIndsBlueGldas,:,:),4),2),1));
    gldasTBlue = squeeze(nanmean(nanmean(nanmean(gldas_t{3}(latIndsBlueGldas, lonIndsBlueGldas,:,:),4),2),1));
    gldasPrBlue = squeeze(nanmean(nanmean(nanmean(gldas_pr{3}(latIndsBlueGldas, lonIndsBlueGldas,:,:),4),2),1));

    gldasRunoffWhite = squeeze(nanmean(nanmean(nansum(gldasRunoff(latIndsWhiteGldas, lonIndsWhiteGldas,:,:),4),2),1));
    gldasTWhite = squeeze(nanmean(nanmean(nanmean(gldas_t{3}(latIndsWhiteGldas, lonIndsWhiteGldas,:,:),4),2),1));
    gldasPrWhite = squeeze(nanmean(nanmean(nanmean(gldas_pr{3}(latIndsWhiteGldas, lonIndsWhiteGldas,:,:),4),2),1));
end

if ~exist('bwfpEthiopia')
    bwfpLat = [];
    bwfpLon = [];
    bwfp = [];
    bwfpEthiopia = [];
    bwfpBlue = [];
    bwfpWhite = [];
    gwfp = [];
    gwfpEthiopia = [];
    gwfpBlue = [];
    gwfpWhite = [];

    sspEthiopiaLon = ssp1_2010{2}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
    sspEthiopiaLat = ssp1_2010{1}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
    sspEthiopia = ssp1_2010{3}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);

    for m = 1:12
        fprintf('loading bwfp/gwfp month %d...\n', m);

        load(['E:\data\bgwfp\output\bwfp\bwfp_' num2str(m)]);
        eval(['bwfp(:, :, ' num2str(m) ') = bwfp_' num2str(m) '{3};']);

        load(['E:\data\bgwfp\output\gwfp\gwfp_' num2str(m)]);
        eval(['gwfp(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{3};']);

        if m == 1
            bwfpLat = bwfp_1{1};
            bwfpLon = bwfp_1{2};

            [latIndsEthiopiaBW, lonIndsEthiopiaBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
            [latIndsBlueBW, lonIndsBlueBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
            [latIndsWhiteBW, lonIndsWhiteBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
        end

        % ethiopia
        tmp = regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), gwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, ...
                             {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, ...
                             false);
        gwfpEthiopia(:, :, m) = tmp{3};

        tmp = regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), gwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, ...
                             {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, ...
                             false);
        bwfpEthiopia(:, :, m) =  tmp{3};


        % blue nile
        tmp = regridGriddata({bwfpLat(latIndsBlueBW, lonIndsBlueBW), bwfpLon(latIndsBlueBW, lonIndsBlueBW), gwfp(latIndsBlueBW, lonIndsBlueBW, m)}, ...
                             {ssp1_2010{1}(latIndsBlueSSP,lonIndsBlueSSP), ssp1_2010{2}(latIndsBlueSSP,lonIndsBlueSSP), ssp1_2010{3}(latIndsBlueSSP,lonIndsBlueSSP)}, ...
                             false);
        gwfpBlue(:, :, m) = tmp{3};

        tmp = regridGriddata({bwfpLat(latIndsBlueBW, lonIndsBlueBW), bwfpLon(latIndsBlueBW, lonIndsBlueBW), gwfp(latIndsBlueBW, lonIndsBlueBW, m)}, ...
                             {ssp1_2010{1}(latIndsBlueSSP,lonIndsBlueSSP), ssp1_2010{2}(latIndsBlueSSP,lonIndsBlueSSP), ssp1_2010{3}(latIndsBlueSSP,lonIndsBlueSSP)}, ...
                             false);
        bwfpBlue(:, :, m) =  tmp{3};

        tmp = regridGriddata({bwfpLat(latIndsWhiteBW, lonIndsWhiteBW), bwfpLon(latIndsWhiteBW, lonIndsWhiteBW), gwfp(latIndsWhiteBW, lonIndsWhiteBW, m)}, ...
                             {ssp1_2010{1}(latIndsWhiteSSP,lonIndsWhiteSSP), ssp1_2010{2}(latIndsWhiteSSP,lonIndsWhiteSSP), ssp1_2010{3}(latIndsWhiteSSP,lonIndsWhiteSSP)}, ...
                             false);
        gwfpWhite(:, :, m) = tmp{3};

        tmp = regridGriddata({bwfpLat(latIndsWhiteBW, lonIndsWhiteBW), bwfpLon(latIndsWhiteBW, lonIndsWhiteBW), gwfp(latIndsWhiteBW, lonIndsWhiteBW, m)}, ...
                             {ssp1_2010{1}(latIndsWhiteSSP,lonIndsWhiteSSP), ssp1_2010{2}(latIndsWhiteSSP,lonIndsWhiteSSP), ssp1_2010{3}(latIndsWhiteSSP,lonIndsWhiteSSP)}, ...
                             false);
        bwfpWhite(:, :, m) =  tmp{3};

        eval(['clear bwfp_' num2str(m) ';']);
        eval(['clear gwfp_' num2str(m) ';']);
    end
end

% find runoff relative to bwfp data period (1996-2005)
mdiffBlue = mdataBlue ./ nanmean(mdataBlue(end-9:end,:),1);
mdiffWhite = mdataWhite ./ nanmean(mdataWhite(end-9:end,:),1);
mfdiffBlue = mfdataBlue ./ nanmean(mdataBlue(end-9:end,:),1);
mfdiffWhite = mfdataWhite ./ nanmean(mdataWhite(end-9:end,:),1);

% find runoff difference in hot/dry years in past and future
tprc = 74;
pprc = 34;
pprcW = 80;

mAnomHd = [];
mAnomD = [];
mAnomH = [];
for mind = 1:length(models)
    mAnomHd(mind) = (mean(mdataEthiopia(find(tdataEthiopia(:,mind)>prctile(tdataEthiopia(:,mind),tprc) & pdataEthiopia(:,mind)<prctile(pdataEthiopia(:,mind),pprc)), mind))-mean(mdataEthiopia(:,mind)))/mean(mdataEthiopia(:,mind));
    mAnomD(mind) = (mean(mdataEthiopia(find(tdataEthiopia(:,mind)<prctile(tdataEthiopia(:,mind),tprc) & pdataEthiopia(:,mind)<prctile(pdataEthiopia(:,mind),pprc)), mind))-mean(mdataEthiopia(:,mind)))/mean(mdataEthiopia(:,mind));
    mAnomH(mind) = (mean(mdataEthiopia(find(tdataEthiopia(:,mind)>prctile(tdataEthiopia(:,mind),tprc) & pdataEthiopia(:,mind)>prctile(pdataEthiopia(:,mind),pprc)), mind))-mean(mdataEthiopia(:,mind)))/mean(mdataEthiopia(:,mind));
end

mAnomHdBlue = [];
mAnomDBlue = [];
mAnomHBlue = [];
for mind = 1:length(models)
    mBWAnomHdBlue(mind) = (mean(mdiffBlue(find(tdataBlue(:,mind)>prctile(tdataBlue(:,mind),tprc) & pdataBlue(:,mind)<prctile(pdataBlue(:,mind),pprc)), mind))-mean(mdiffBlue(:,mind)))/mean(mdiffBlue(:,mind));
    mBWAnomDBlue(mind) = (mean(mdiffBlue(find(tdataBlue(:,mind)<prctile(tdataBlue(:,mind),tprc) & pdataBlue(:,mind)<prctile(pdataBlue(:,mind),pprc)), mind))-mean(mdiffBlue(:,mind)))/mean(mdiffBlue(:,mind));
    mBWAnomHBlue(mind) = (mean(mdiffBlue(find(tdataBlue(:,mind)>prctile(tdataBlue(:,mind),tprc) & pdataBlue(:,mind)>prctile(pdataBlue(:,mind),pprc)), mind))-mean(mdiffBlue(:,mind)))/mean(mdiffBlue(:,mind));
    mBWAnomWBlue(mind) = (mean(mdiffBlue(find(pdataBlue(:,mind)>prctile(pdataBlue(:,mind),pprcW)), mind))-mean(mdiffBlue(:,mind)))/mean(mdiffBlue(:,mind));
    
    mBWAnomHdBlueF(mind) = (mean(mfdiffBlue(find(tfdataBlue(:,mind)>prctile(tfdataBlue(:,mind),tprc) & pfdataBlue(:,mind)<prctile(pfdataBlue(:,mind),pprc)), mind))-mean(mdiffBlue(:,mind)))/mean(mdiffBlue(:,mind));
    mBWAnomWBlueF(mind) = (mean(mfdiffBlue(find(pfdataBlue(:,mind)>prctile(pfdataBlue(:,mind),pprcW)), mind))-mean(mdiffBlue(:,mind)))/mean(mdiffBlue(:,mind));
end

pcBwfpBlue = 0;
pcBwfpBlueSpatial = [];
pcBwfpWhite = 0;
pcBwfpWhiteSpatial = [];
pcBwfpTotal = 0;

% bwfp and ssp are on same grid now
latBwfpBlue = ssp1_2010{1}(latIndsBlueSSP,lonIndsBlueSSP);
lonBwfpBlue = ssp1_2010{2}(latIndsBlueSSP,lonIndsBlueSSP);

latBwfpWhite = ssp1_2010{1}(latIndsWhiteSSP,lonIndsWhiteSSP);
lonBwfpWhite = ssp1_2010{2}(latIndsWhiteSSP,lonIndsWhiteSSP);

% calc historical per capita bw footprint -------------------
fprintf('calculating historical per capita bw footprint...\n');
for s = 1:5
    for xlat = 1:size(bwfpBlue, 1)
        latdiff = latBwfpBlue(2,1)-latBwfpBlue(1,1);
        londiff = lonBwfpBlue(1,2)-lonBwfpBlue(1,1);
        for ylon = 1:size(bwfpBlue, 2)
            curArea = areaTableBlue(xlat, ylon);
            
            pcBwfpBlueSpatial(xlat, ylon) = curArea * nansum(squeeze(bwfpBlue(xlat, ylon, :))) * 1e-3 / ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), 1, s);
                                   
            ittrBlue = (curArea * nansum(squeeze(bwfpBlue(xlat, ylon, :))) * 1e-3 / ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), 1, s)) * ...
                                       (ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), 1, s) / nansum(nansum(squeeze(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s)))));

            if ~isnan(ittrBlue)
                pcBwfpBlue = pcBwfpBlue + ittrBlue;
            end
            
            ittrTotal = (curArea * nansum(squeeze(bwfpBlue(xlat, ylon, :))) * 1e-3 / ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), 1, s)) * ...
                                       (ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), 1, s) / (nansum(nansum(squeeze(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s)))) + ...
                                                                                                 nansum(nansum(squeeze(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s))))));

            if ~isnan(ittrTotal)
                pcBwfpTotal = pcBwfpTotal + ittrTotal;
            end
            
        end
    end
    
    for xlat = 1:size(bwfpWhite, 1)
        latdiff = latBwfpWhite(2,1)-latBwfpWhite(1,1);
        londiff = lonBwfpWhite(1,2)-lonBwfpWhite(1,1);
        for ylon = 1:size(bwfpWhite, 2)

            curArea = areaTableWhite(xlat, ylon);
            
            pcBwfpWhiteSpatial(xlat, ylon) = curArea * nansum(squeeze(bwfpWhite(xlat, ylon, :))) * 1e-3 / ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), 1, s);
                                   
            ittrWhite = (curArea * nansum(squeeze(bwfpWhite(xlat, ylon, :))) * 1e-3 / ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), 1, s)) * ...
                                       (ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), 1, s) / nansum(nansum(squeeze(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));

            if ~isnan(ittrWhite)
                pcBwfpWhite = pcBwfpWhite + ittrWhite;
            end
            
            ittrTotal = (curArea * nansum(squeeze(bwfpWhite(xlat, ylon, :))) * 1e-3 / ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), 1, s)) * ...
                                       (ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), 1, s) / (nansum(nansum(squeeze(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s)))) + ...
                                                                                                 nansum(nansum(squeeze(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s))))));

            if ~isnan(ittrTotal)
                pcBwfpTotal = pcBwfpTotal + ittrTotal;
            end
            
        end
    end
end

fprintf('calculating future per capita bw demand...\n');
pcBwfpBlueSpatialFut = [];
pcBwfpBlueFut = zeros(length(2010:10:2080), 5);
pcBwfpWhiteSpatialFut = [];
pcBwfpWhiteFut = zeros(length(2010:10:2080), 5);
pcBwfpTotalFut = zeros(length(2010:10:2080), 5);

noWaterBlueFut = zeros(length(2010:10:2080), length(models), 5);
noWaterSpatialBlueFut = zeros(length(2010:10:2080), length(models), 5);
noWaterWhiteFut = zeros(length(2010:10:2080), length(models), 5);
noWaterSpatialWhiteFut = zeros(length(2010:10:2080), length(models), 5);
noWaterTotalFut = zeros(length(2010:10:2080), length(models), 5);

for s = 1:5
    decind = 1;
    for dec = 2010:10:2080
        pcBwfpBlueSpatialFut(:, :, decind, s) = pcBwfpBlueSpatial .* ...
                                                (ssp(latIndsBlueSSP, lonIndsBlueSSP, decind, s) ...
                                                 ./ ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s));

        for xlat = 1:size(bwfpBlue, 1)
            latdiff = latBwfpBlue(2,1)-latBwfpBlue(1,1);
            londiff = lonBwfpBlue(1,2)-lonBwfpBlue(1,1);
        
            for ylon = 1:size(bwfpBlue, 2)

                curArea = areaTableBlue(xlat, ylon);
                
                ittr = pcBwfpBlueSpatialFut(xlat, ylon, decind, s) * ...
                                    (ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), decind, s) / nansum(nansum(squeeze(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s)))));
                
                if ~isnan(ittr)
                    pcBwfpBlueFut(decind, s) = pcBwfpBlueFut(decind, s) + ittr;
                end
                
                ittrTotal = pcBwfpBlueSpatialFut(xlat, ylon, decind, s) * ...
                                    (ssp(latIndsBlueSSP(xlat), lonIndsBlueSSP(ylon), decind, s) / (nansum(nansum(squeeze(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s)))) + ...
                                                                                                   nansum(nansum(squeeze(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s))))));
                
                if ~isnan(ittrTotal)
                    pcBwfpTotalFut(decind, s) = pcBwfpTotalFut(decind, s) + ittrTotal;
                end
                
            end
        end
        
     
        pcBwfpWhiteSpatialFut(:, :, decind, s) = pcBwfpWhiteSpatial .* ...
                                                (ssp(latIndsWhiteSSP, lonIndsWhiteSSP, decind, s)  ...
                                                 ./ ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s));
                                             
        for xlat = 1:size(bwfpWhite, 1)
            latdiff = latBwfpWhite(2,1)-latBwfpWhite(1,1);
            londiff = lonBwfpWhite(1,2)-lonBwfpWhite(1,1);
        
            for ylon = 1:size(bwfpWhite, 2)

                curArea = areaTableWhite(xlat, ylon);

                ittr = pcBwfpWhiteSpatialFut(xlat, ylon, decind, s) * ...
                                    (ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), decind, s) / nansum(nansum(squeeze(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s)))));
                
                if ~isnan(ittr)
                    pcBwfpWhiteFut(decind, s) = pcBwfpWhiteFut(decind, s) + ittr;
                end
                
                ittrTotal = pcBwfpWhiteSpatialFut(xlat, ylon, decind, s) * ...
                                    (ssp(latIndsWhiteSSP(xlat), lonIndsWhiteSSP(ylon), decind, s) / (nansum(nansum(squeeze(ssp(latIndsBlueSSP, lonIndsBlueSSP, 1, s)))) + ...
                                                                                                   nansum(nansum(squeeze(ssp(latIndsWhiteSSP, lonIndsWhiteSSP, 1, s))))));
                
                if ~isnan(ittrTotal)
                    pcBwfpTotalFut(decind, s) = pcBwfpTotalFut(decind, s) + ittrTotal;
                end
            end
        end
        
        % calculate # people water short
        for model = 1:length(models)
            for year = dec-2006+1:dec+10-2006+1
                if year > 80
                    continue;
                end
                
                noWaterSpatialBlueFut(decind, model, s) = noWaterSpatialBlueFut(decind, model, s) + ...
                                                   nansum(nansum((pcBwfpBlueSpatialFut(:, :, decind, s) > bwSupplySpatialFutBlue(:, :, year, model, s)) .* ssp(latIndsBlueSSP, lonIndsBlueSSP, decind, s)));
                noWaterSpatialWhiteFut(decind, model, s) = noWaterSpatialWhiteFut(decind, model, s) + ...
                                                   nansum(nansum((pcBwfpWhiteSpatialFut(:, :, decind, s) > bwSupplySpatialFutWhite(:, :, year, model, s)) .* ssp(latIndsWhiteSSP, lonIndsWhiteSSP, decind, s)));
                
                noWaterBlueFut(decind, model, s) = noWaterBlueFut(decind, model, s) + ...
                                                   nansum(nansum((pcBwfpBlueSpatialFut(:, :, decind, s) > bwSupplyFutBlue(year, model, s)) .* ssp(latIndsBlueSSP, lonIndsBlueSSP, decind, s)));
                noWaterWhiteFut(decind, model, s) = noWaterWhiteFut(decind, model, s) + ...
                                                   nansum(nansum((pcBwfpWhiteSpatialFut(:, :, decind, s) > bwSupplyFutWhite(year, model, s)) .* ssp(latIndsWhiteSSP, lonIndsWhiteSSP, decind, s)));
            end
            nyears = 10;
            if dec == 2080
                nyears = 5;
            end
            
            % divide by 10 years to give ppl per year
            noWaterBlueFut(decind, model, s) = noWaterBlueFut(decind, model, s) / nyears;
            noWaterWhiteFut(decind, model, s) = noWaterWhiteFut(decind, model, s) / nyears;
            noWaterTotalFut(decind, model, s) = noWaterBlueFut(decind, model, s) + noWaterWhiteFut(decind, model, s);
            
            noWaterSpatialBlueFut(decind, model, s) = noWaterSpatialBlueFut(decind, model, s) / nyears;
            noWaterSpatialWhiteFut(decind, model, s) = noWaterSpatialWhiteFut(decind, model, s) / nyears;
            noWaterSpatialTotalFut(decind, model, s) = noWaterSpatialBlueFut(decind, model, s) + noWaterSpatialWhiteFut(decind, model, s);
        end
        
        decind = decind+1;
    end
end

dind = 1;
bwSupplyMeanFutWhite = [];
bwSupplyMeanFutBlue = [];
for dec = 2010:10:2070
    bwSupplyMeanFutWhite(dind, :, :) = squeeze(squeeze(nanmean(bwSupplyFutWhite(dec-2006+1:dec+10-2006+1, :, :), 1)));
    bwSupplyMeanFutBlue(dind, :, :) = squeeze(squeeze(nanmean(bwSupplyFutBlue(dec-2006+1:dec+10-2006+1, :, :), 1)));
    bwSupplyMeanFutTotal(dind, :, :) = squeeze(squeeze(nanmean(bwSupplyFutTotal(dec-2006+1:dec+10-2006+1, :, :), 1)));
    dind = dind+1;
end

bwSupplyMeanFutTotal = sort(bwSupplyMeanFutTotal, 2);
noWaterTotalFut = sort(noWaterTotalFut, 2);

colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

il = round(.1*length(models));
ih = round(.9*length(models));

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([2 1 1]);

yyaxis left;
b = boxplot(bwSupplyMeanFutTotal(:,il:ih,3)', 'width', .2, 'positions', [1:7] - .15)

set(b, {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([1:7]-.15, pcBwfpTotalFut(2:8,3), 'linewidth', 2, 'color', colorD);

ylim([0 12000]);
ylabel('Blue water (m^3/year/person)');

yyaxis right;
b = boxplot(noWaterSpatialTotalFut(2:8,il:ih,3)', 'width', .2, 'positions', [1:7] + .15)

set(b, {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(gca, 'fontsize', 36);
ylim([0 2e8]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', [0 .5 1 1.5 2] .* 1e8, 'YTickLabels', {'0', '50M', '100M', '150M', '200M'});
xlim([.5 7.5]);
ylabel('Unmet demand (people/year)');
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-5.eps;
close all;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([2 1 1]);

yyaxis left;
b = boxplot(bwSupplyMeanFutTotal(:,il:ih,5)', 'width', .2, 'positions', [1:7] - .15)

set(b, {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([1:7]-.15, pcBwfpTotalFut(2:8,5), 'linewidth', 2, 'color', colorD);

ylim([0 12000]);
ylabel('Blue water (m^3/year/person)');

yyaxis right;
b = boxplot(noWaterSpatialTotalFut(2:8,il:ih,5)', 'width', .2, 'positions', [1:7] + .15)

set(b, {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(gca, 'fontsize', 36);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
ylim([0 1.1e8]);
set(gca, 'YTick', [0 .25 .5 .75 1] .* 1e8, 'YTickLabels', {'0', '25M', '50M', '75M', '100M'});
xlim([.5 7.5]);
ylabel('Unmet demand (people/year)');
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-3.eps;
close all;















