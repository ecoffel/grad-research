

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
        tasFut45 = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp45\tas'], 'tas', 'startYear', 2006, 'endYear', 2099);
        tasFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\tas'], 'tas', 'startYear', 2006, 'endYear', 2099);
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\pr'], 'pr', 'startYear', 1900, 'endYear', 2005);
        prFut45 = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp45\pr'], 'pr', 'startYear', 2006, 'endYear', 2099);
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
        
        tdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(tas{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        pdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(pr{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        
        tfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        pfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        
        tfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        tf45dataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut45{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        pfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        pf45dataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut45{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        
        tfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        tf45dataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut45{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        pfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        pf45dataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut45{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        
        tfdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        tf45dataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut45{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        pfdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        pf45dataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut45{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        
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

if ~exist('bwSupplyHistTotalNoPw')
    
    bwSupplyHistTotalNoPw = zeros(length(1900:2005), length(models));
    bwSupplyFutTotalNoPw = zeros(length(2006:2099), length(models));
    bwSupplyFutTotalNoPw45 = zeros(length(2006:2099), length(models));
    
    monthLengths = [31 28 31 30 31 30 31 31 30 31 30 31];
    
    for mind = 1:length(models)
        fprintf('loading %s mrro historical...\n', models{mind});
        mrros = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\mrro'], 'mrro', 'startYear', 1900, 'endYear', 2005);
        mrrosFut45 = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp45\mrro'], 'mrro', 'startYear', 2006, 'endYear', 2099);
        mrrosFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\mrro'], 'mrro', 'startYear', 2006, 'endYear', 2099);
        
        for month = 1:12
            mrros{3}(:, :, :, month) = mrros{3}(:, :, :, month) .* 60 .* 60 .* 24 .* monthLengths(month);
            mrrosFut45{3}(:, :, :, month) = mrrosFut45{3}(:, :, :, month) .* 60 .* 60 .* 24 .* monthLengths(month);
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
        for year = 1:size(mrros{3}, 3)
            % blue nile
            for xind = 1:length(latIndsBlueSSP)
                xlat = latIndsBlueSSP(xind);
                for yind = 1:length(lonIndsBlueSSP)
                    ylon = lonIndsBlueSSP(yind);

                    % not population weighted
                    ittrTotalNoPw = areaTableBlue(xind, yind) * nansum(squeeze(mrros{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3;


                    if ~isnan(ittrTotalNoPw)
                        bwSupplyHistTotalNoPw(year, mind) = bwSupplyHistTotalNoPw(year, mind) + ittrTotalNoPw;
                    end
                end
            end

            % white nile
            for xind = 1:length(latIndsWhiteSSP)
                xlat = latIndsWhiteSSP(xind);
                for yind = 1:length(lonIndsWhiteSSP)
                    ylon = lonIndsWhiteSSP(yind);


                    % not population weighted
                    ittrTotalNoPw = areaTableWhite(xind, yind) * nansum(squeeze(mrros{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3;


                    if ~isnan(ittrTotalNoPw)
                        bwSupplyHistTotalNoPw(year, mind) = bwSupplyHistTotalNoPw(year, mind) + ittrTotalNoPw;
                    end
                end
            end

        end

        for year = 1:size(mrrosFut{3}, 3)
            for xind = 1:length(latIndsBlueSSP)
                xlat = latIndsBlueSSP(xind);
                for yind = 1:length(lonIndsBlueSSP)
                    ylon = lonIndsBlueSSP(yind);

                    % not population weighted
                    ittrTotalNoPw = areaTableBlue(xind, yind) * nansum(squeeze(mrrosFut{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3;


                    if ~isnan(ittrTotalNoPw)
                        bwSupplyFutTotalNoPw(year, mind) = bwSupplyFutTotalNoPw(year, mind) + ittrTotalNoPw;
                    end
                    
                    
                    % not population weighted
                    ittrTotalNoPw45 = areaTableBlue(xind, yind) * nansum(squeeze(mrrosFut45{3}(cmip5LatTableBlue(xind, yind), cmip5LonTableBlue(xind, yind), year, :))) * 1e-3;


                    if ~isnan(ittrTotalNoPw45)
                        bwSupplyFutTotalNoPw45(year, mind) = bwSupplyFutTotalNoPw45(year, mind) + ittrTotalNoPw45;
                    end

                end
            end

            % white nile
            for xind = 1:length(latIndsWhiteSSP)
                xlat = latIndsWhiteSSP(xind);
                for yind = 1:length(lonIndsWhiteSSP)
                    ylon = lonIndsWhiteSSP(yind);

                    % not population weighted
                    ittrTotalNoPw = areaTableWhite(xind, yind) * nansum(squeeze(mrrosFut{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3;


                    if ~isnan(ittrTotalNoPw)
                        bwSupplyFutTotalNoPw(year, mind) = bwSupplyFutTotalNoPw(year, mind) + ittrTotalNoPw;
                    end
                    
                    
                    % not population weighted
                    ittrTotalNoPw45 = areaTableWhite(xind, yind) * nansum(squeeze(mrrosFut45{3}(cmip5LatTableWhite(xind, yind), cmip5LonTableWhite(xind, yind), year, :))) * 1e-3;


                    if ~isnan(ittrTotalNoPw45)
                        bwSupplyFutTotalNoPw45(year, mind) = bwSupplyFutTotalNoPw45(year, mind) + ittrTotalNoPw45;
                    end

                end
            end
        end
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

    % load domind bwfp
    load E:\data\bgwfp\output\domind\bwfp\bwfp_1.mat
    bwfpDomind = bwfp_1;
    
    for m = 1:12
        fprintf('loading bwfp/gwfp month %d...\n', m);

        load(['E:\data\bgwfp\output\ag\bwfp\bwfp_' num2str(m)]);
        eval(['bwfp(:, :, ' num2str(m) ') = bwfp_' num2str(m) '{3};']);

        load(['E:\data\bgwfp\output\ag\gwfp\gwfp_' num2str(m)]);
        eval(['gwfp(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{3};']);

        if m == 1
            bwfpLat = bwfp_1{1};
            bwfpLon = bwfp_1{2};

            [latIndsEthiopiaBW, lonIndsEthiopiaBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
            [latIndsBlueBW, lonIndsBlueBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
            [latIndsWhiteBW, lonIndsWhiteBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
            
            bwfpDomind = regridGriddata(bwfpDomind, {bwfpLat, bwfpLon, []}, false); 
        end

        % add domind onto ag bwfp
        bwfp(:,:,m) = bwfp(:,:,m)+bwfpDomind{3};
        
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

bwfpTotalNoPopWeight = 0;

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
            
            % no pop weight
            ittrTotalNoPopWeight = (curArea * nansum(squeeze(bwfpBlue(xlat, ylon, :))) * 1e-3);

            if ~isnan(ittrTotalNoPopWeight)
                bwfpTotalNoPopWeight = bwfpTotalNoPopWeight + ittrTotalNoPopWeight;
            end
        end
    end
    
    for xlat = 1:size(bwfpWhite, 1)
        latdiff = latBwfpWhite(2,1)-latBwfpWhite(1,1);
        londiff = lonBwfpWhite(1,2)-lonBwfpWhite(1,1);
        for ylon = 1:size(bwfpWhite, 2)

            curArea = areaTableWhite(xlat, ylon);
            
            % no pop weight
            ittrTotalNoPopWeight = (curArea * nansum(squeeze(bwfpWhite(xlat, ylon, :))) * 1e-3);

            if ~isnan(ittrTotalNoPopWeight)
                bwfpTotalNoPopWeight = bwfpTotalNoPopWeight + ittrTotalNoPopWeight;
            end
        end
    end
end

for s = 1:5
    bwfpPc(s) = bwfpTotalNoPopWeight / nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, s)));
end

fprintf('calculating future per capita bw demand...\n');
bwfpTotalFut = zeros(length(2010:10:2080), 5, 3);


% environmental flow requirement
efrPercent = 20:20:80;

% m3/capita
waterScarcityLevel = [500 1000 1700];


for s = 1:5
    decind = 1;
    for dec = 2010:10:2080
        
        for w = 1:length(waterScarcityLevel)
            bwfpTotalFut(decind, s, w) = waterScarcityLevel(w) * nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decind, s)));
        end
        
        decind = decind+1;
    end
end

dind = 1;
bwSupplyMeanFutNormal = [];
bwSupplyMeanFutHotDry = [];
noWaterFutAll = [];
noWaterFutNormal = [];
noWaterFutHotDry = [];
for dec = 2010:10:2080
    for e = 1:length(efrPercent)
        
        for mind = 1:length(models)
            curDecBw = bwSupplyFutTotalNoPw(dec-2006+1:dec+10-2006+1, mind);
            curDecBw45 = bwSupplyFutTotalNoPw45(dec-2006+1:dec+10-2006+1, mind);
            curDecT = tfdataTotal(dec-2006+1:dec+10-2006+1, mind);
            curDecP = pfdataTotal(dec-2006+1:dec+10-2006+1, mind);
            
            [psort,pind] = sort(curDecP);
            [tsort,tind] = sort(curDecT);
            
            hdInd = intersect(pind(1:5),tind(6:end));
            normalInd = setxor(1:length(pind), hdInd);

            bwSupplyMeanFutAll(dind, mind, e) = (1 - (efrPercent(e) / 100.)) .* squeeze(squeeze(nanmean(curDecBw, 1)));
            bwSupplyMeanFutAll45(dind, mind, e) = (1 - (efrPercent(e) / 100.)) .* squeeze(squeeze(nanmean(curDecBw45, 1)));
            bwSupplyMeanFutNormal(dind, mind, e) = (1 - (efrPercent(e) / 100.)) .* squeeze(squeeze(nanmean(curDecBw(normalInd), 1)));
            bwSupplyMeanFutHotDry(dind, mind, e) = (1 - (efrPercent(e) / 100.)) .* squeeze(squeeze(nanmean(curDecBw(hdInd), 1)));
            
            for w = 1:length(waterScarcityLevel)
                for s = 1:5
                    noWaterFutAll(dind, mind, s, w, e) = ((1-min(bwSupplyMeanFutAll(dind, mind, e) ./ bwfpTotalFut(dind, s, w),1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s)))) ./ nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s))) .* 100;
                    noWaterFutAll45(dind, mind, s, w, e) = ((1-min(bwSupplyMeanFutAll45(dind, mind, e) ./ bwfpTotalFut(dind, s, w),1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s)))) ./ nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s))) .* 100;
                    noWaterFutNormal(dind, mind, s, w, e) = ((1-min(bwSupplyMeanFutNormal(dind, mind, e) ./ bwfpTotalFut(dind, s, w),1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s))));% ./ nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s))) .* 100;
                    noWaterFutHotDry(dind, mind, s, w, e) = ((1-min(bwSupplyMeanFutHotDry(dind, mind, e) ./ bwfpTotalFut(dind, s, w),1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s))));% ./ nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s))) .* 100;
                end
            end
        end
        
        
    end
    dind = dind+1;
end

bwSupplyMeanFutSortedNormal = sort(bwSupplyMeanFutNormal, 2);
bwSupplyMeanFutSortedHotDry = sort(bwSupplyMeanFutHotDry, 2);
noWaterFutSortedAll = sort(noWaterFutAll, 2);
noWaterFutSortedAll45 = sort(noWaterFutAll45, 2);
noWaterFutSortedNormal = sort(noWaterFutNormal, 2);
noWaterFutSortedHotDry = sort(noWaterFutHotDry, 2);


colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

il = round(.1*length(models));
ih = round(.9*length(models));

figure('Color', [1,1,1]);
hold on;
box on;
set(gca, 'ygrid', 'on');
pbaspect([2 1 1]);

yyaxis left;
b = boxplot(bwSupplyMeanFutSortedNormal(2:8,il:ih, 3)', 'width', .07, 'positions', [1:7] - .21)
b2 = boxplot(bwSupplyMeanFutSortedHotDry(2:8,il:ih, 3)', 'width', .07, 'positions', [1:7] - .1)

set(b, {'LineWidth', 'Color'}, {2.5, colorW})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b,'tag','Outliers');
for iH = 1:length(h)
    h(iH).MarkerEdgeColor = colorW;
end

set(b2, {'LineWidth', 'Color'}, {2.5, colorD})
lines = findobj(b2, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b2,'tag','Outliers');
for iH = 1:length(h)
    h(iH).MarkerEdgeColor = colorD;
end

% mean of ssp3, 5
p = plot([1:7]-.12, nanmean(bwfpTotalFut(2:8,[3,5],2),2), 'o', 'markersize', 18, 'markerfacecolor', 'w', 'color', colorW, 'linewidth', 3);

ylim([0 0.63e12]);
ylabel('Runoff (m^3/year)');
set(gca, 'YTick', [0 .2 .4 .6] .* 1e12, 'YTickLabels', {'0', '200B', '400B', '600B'});

%legend([p], {'Runoff demand'}, 'location', 'northwest');
%legend boxoff;

yyaxis right;
% mean of ssp3, 5
b = boxplot(nanmean(noWaterFutSortedNormal(2:8,il:ih,[3, 5],2,3),3)', 'width', .07, 'positions', [1:7] + .1)
b2 = boxplot(nanmean(noWaterFutSortedHotDry(2:8,il:ih,[3, 5],2,3),3)', 'width', .07, 'positions', [1:7] + .21)

colors = brewermap(3, 'Reds');

set(b, {'LineWidth', 'Color'}, {2.5, colors(2,:)})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b,'tag','Outliers');
for iH = 1:length(h)
    h(iH).MarkerEdgeColor = colors(2,:);
end

set(b2, {'LineWidth', 'Color'}, {2.5, colors(3,:)})
lines = findobj(b2, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b2,'tag','Outliers');
for iH = 1:length(h)
    h(iH).MarkerEdgeColor = colors(3,:);
end

for i = 1.5:1:6.5
    plot([i i], [0 105], '-', 'color', [.5 .5 .5], 'linewidth', 2);
end

set(gca, 'fontsize', 36);
ylim([0 100]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', 0:20:100);
xlim([.5 7.5]);
ylabel('Unmet demand (% population)');
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-ssp3-5-efr60-ws1000.eps;
close all;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

% browns
colors = brewermap(10, 'BrBG');
colors = colors(1:5,:);

solidLines = [];

for e = 1:size(noWaterFutSortedAll,5)
    % ssp3
    plot(squeeze(nanmedian(noWaterFutSortedAll(2:8,:,3,2,e),2)), 'linewidth', 5, 'color', colors(e,:), 'linestyle', '--');
    % mean of ssp3 and 5
    p = plot(squeeze(nanmedian(nanmean(noWaterFutSortedAll(2:8,:,[3,5],2,e),3),2)), 'linewidth', 5, 'color', colors(e,:), 'linestyle', '-');
    solidLines(e) = p;
    % ssp5
    plot(squeeze(nanmedian(noWaterFutSortedAll(2:8,:,5,2,e),2)), 'linewidth', 5, 'color', colors(e,:), 'linestyle', ':');
end

set(gca, 'fontsize', 50);
ylim([0 100]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', 0:20:100);
xlim([.5 7.5]);
%ylabel('Unmet demand (% population)');
l = legend(solidLines, {'20%', '40%', '60%', '80%'}, 'location', 'northwest');
legend boxoff;
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-ssp3-efr-var-ws1000.eps;
close all;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

% browns
colors = brewermap(3, 'Reds');
colors = colors([2 3],:);

solidLines = [];


% ssp3
plot(squeeze(nanmedian(noWaterFutSortedAll45(2:8,:,2,2,3),2)), 'linewidth', 5, 'color', colors(1,:), 'linestyle', '--');
% mean of ssp3 and 5
p = plot(squeeze(nanmedian(nanmean(noWaterFutSortedAll45(2:8,:,[2,4],2,3),3),2)), 'linewidth', 5, 'color', colors(1,:), 'linestyle', '-');
solidLines(1) = p;
% ssp5
plot(squeeze(nanmedian(noWaterFutSortedAll45(2:8,:,4,2,3),2)), 'linewidth', 5, 'color', colors(1,:), 'linestyle', ':');


% ssp3
plot(squeeze(nanmedian(noWaterFutSortedAll(2:8,:,3,2,3),2)), 'linewidth', 5, 'color', colors(2,:), 'linestyle', '--');
% mean of ssp3 and 5
p = plot(squeeze(nanmedian(nanmean(noWaterFutSortedAll(2:8,:,[3,5],2,3),3),2)), 'linewidth', 5, 'color', colors(2,:), 'linestyle', '-');
solidLines(2) = p;
% ssp5
plot(squeeze(nanmedian(noWaterFutSortedAll(2:8,:,5,2,3),2)), 'linewidth', 5, 'color', colors(2,:), 'linestyle', ':');


set(gca, 'fontsize', 50);
ylim([0 100]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', 0:20:100);
xlim([.5 7.5]);
%ylabel('Unmet demand (% population)');
l = legend(solidLines, {'RCP 4.5', 'RCP 8.5'}, 'location', 'northwest');
legend boxoff;
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-rcp-var-efr60-ws1000.eps;
close all;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

% browns
colors = brewermap(10, 'BrBG');
colors = colors(7:10,:);

solidLines = [];

for w = 1:size(noWaterFutSortedAll,4)
    %ssp3
    plot(squeeze(nanmedian(noWaterFutSortedAll(2:8,:,3,w,3),2)), 'linewidth', 5, 'color', colors(w,:), 'linestyle', '--');
    %ssp3 and 5
    p = plot(squeeze(nanmedian(nanmean(noWaterFutSortedAll(2:8,:,[3, 5],w,3),3),2)), 'linewidth', 5, 'color', colors(w,:), 'linestyle', '-');
    solidLines(w) = p;
    %ssp5
    plot(squeeze(nanmedian(noWaterFutSortedAll(2:8,:,5,w,3),2)), 'linewidth', 5, 'color', colors(w,:), 'linestyle', ':');
end

set(gca, 'fontsize', 50);
ylim([0 100]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', 0:20:100);
xlim([.5 7.5]);
%ylabel('Unmet demand (% population)');
l = legend(solidLines, {'500 m^3', '1000 m^3', '1700 m^3'}, 'location', 'northwest');
legend boxoff;
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-ssp3-efr60-ws-var.eps;
close all;




figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

% browns
colors = brewermap(6, 'Reds');
colors = colors([2 3 6 4 5],:);

for s = 1:5
    plot(squeeze(nanmedian(noWaterFutSortedNormal(2:8,:,s,2,3),2)), 'linewidth', 5, 'color', colors(s,:));
end

set(gca, 'fontsize', 50);
ylim([0 100]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', 0:20:100);
xlim([.5 7.5]);
%ylabel('Unmet demand (% population)');
l = legend({'SSP 1', 'SSP 2', 'SSP 3', 'SSP 4', 'SSP 5'}, 'location', 'northwest');
legend boxoff;
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-supply-demand-ssp-var-efr60-ws1000.eps;
close all;



ihdAnomHist = [];
idAnomHist = [];
ihAnomHist = [];
ihdNoWaterAnomHist = [];
idNoWaterAnomHist = [];
ihNoWaterAnomHist = [];

ihdAnomFut = [];
idAnomFut = [];
ihAnomFut = [];
ihdNoWaterAnomFut = [];
idNoWaterAnomFut = [];
ihNoWaterAnomFut = [];

futBwAnomFreq = [];
fut45BwAnomFreq = [];
histBwAnomFreq = [];

tprc = 83;
pprc = 25;

meanPopHist = nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, 3)));

hdNormalSigHist = [];
hdNormalSigFut = [];

% find hot/dry years and show bw supply anomalies
for mind = 1:length(models)
    ihdTotalHist = find(detrend(tdataTotal(:, mind)) > prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) < prctile(detrend(pdataTotal(:, mind)), pprc));
    idTotalHist = find(detrend(tdataTotal(:, mind)) < prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) < prctile(detrend(pdataTotal(:, mind)), pprc));
    ihTotalHist = find(detrend(tdataTotal(:, mind)) > prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) > prctile(detrend(pdataTotal(:, mind)), pprc));
    inTotalHist = find(detrend(tdataTotal(:, mind)) <= prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) >= prctile(detrend(pdataTotal(:, mind)), pprc));
    
    ihdAnomHist(mind) = squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind) ./ meanPopHist, 1));% - nanmean(bwSupplyHistTotalNoPw(:, mind), 1) ./ meanPopHist);
    idAnomHist(mind) = squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(idTotalHist, mind) ./ meanPopHist, 1));% - nanmean(bwSupplyHistTotalNoPw(:, mind), 1) ./ meanPopHist);
    ihAnomHist(mind) = squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(ihTotalHist, mind) ./ meanPopHist, 1));% - nanmean(bwSupplyHistTotalNoPw(:, mind), 1) ./ meanPopHist);
    inAnomHist(mind) = squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(inTotalHist, mind) ./ meanPopHist, 1));% - nanmean(bwSupplyHistTotalNoPw(:, mind), 1) ./ meanPopHist);
    
    hdNormalSigHist(mind) = ttest2(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind) ./ meanPopHist, .6 .* bwSupplyHistTotalNoPw(inTotalHist, mind) ./ meanPopHist);
    hdDrySigHist(mind) = ttest2(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind) ./ meanPopHist, .6 .* bwSupplyHistTotalNoPw(idTotalHist, mind) ./ meanPopHist);
    
    meanNoWater = (1-min(nanmean(.6 .* bwSupplyHistTotalNoPw(:, mind), 1) ./ bwfpTotalFut(1, 3, 2), 1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, 3)));
                
    ihdNoWaterAnomHist(mind) = (1-min(nanmean(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind), 1) ./ bwfpTotalFut(1, 3, 2), 1));
    idNoWaterAnomHist(mind) = (1-min(nanmean(.6 .* bwSupplyHistTotalNoPw(idTotalHist, mind), 1) ./ bwfpTotalFut(1, 3, 2), 1));
    ihNoWaterAnomHist(mind) = (1-min(nanmean(.6 .* bwSupplyHistTotalNoPw(ihTotalHist, mind), 1) ./ bwfpTotalFut(1, 3, 2), 1));
    inNoWaterAnomHist(mind) = (1-min(nanmean(.6 .* bwSupplyHistTotalNoPw(inTotalHist, mind), 1) ./ bwfpTotalFut(1, 3, 2), 1));

    histBwAnomFreq(mind) = (length(find(.6 .* bwSupplyHistTotalNoPw(end-99:end, mind) < squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind), 1)))) / 10) / 10 * 100; 
    fut45BwAnomFreq(mind) = (length(find(bwSupplyFutTotalNoPw45(5:end, mind) < squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind), 1)))) / 9) / 10 * 100;
    futBwAnomFreq(mind) = (length(find(bwSupplyFutTotalNoPw(5:end, mind) < squeeze(nanmean(.6 .* bwSupplyHistTotalNoPw(ihdTotalHist, mind), 1)))) / 9) / 10 * 100;
    
    
    ihdTotal = find(detrend(tfdataTotal(2020-2006+1:end, mind)) > prctile(detrend(tfdataTotal(2020-2006+1:end, mind)), tprc) & detrend(pfdataTotal(2020-2006+1:end, mind)) < prctile(detrend(pfdataTotal(2020-2006+1:end, mind)), pprc));
    idTotal = find(detrend(tfdataTotal(2020-2006+1:end, mind)) < prctile(detrend(tfdataTotal(2020-2006+1:end, mind)), tprc) & detrend(pfdataTotal(2020-2006+1:end, mind)) < prctile(detrend(pfdataTotal(2020-2006+1:end, mind)), pprc));
    ihTotal = find(detrend(tfdataTotal(2020-2006+1:end, mind)) > prctile(detrend(tfdataTotal(2020-2006+1:end, mind)), tprc) & detrend(pfdataTotal(2020-2006+1:end, mind)) > prctile(detrend(pfdataTotal(2020-2006+1:end, mind)), pprc));
    inTotal = find(detrend(tfdataTotal(2020-2006+1:end, mind)) <= prctile(detrend(tfdataTotal(2020-2006+1:end, mind)), tprc) & detrend(pfdataTotal(2020-2006+1:end, mind)) >= prctile(detrend(pfdataTotal(2020-2006+1:end, mind)), pprc));
    
    
    % find no water for historical
    decIndTotalIhd = (round(ihdTotal+2020,-1)-2000)/10;
    decIndTotalIhd(decIndTotalIhd > 8) = 8;
    
    decIndTotalId = (round(idTotal+2020,-1)-2000)/10;
    decIndTotalId(decIndTotalId > 8) = 8;
    
    decIndTotalIh = (round(ihTotal+2020,-1)-2000)/10;
    decIndTotalIh(decIndTotalIh > 8) = 8;
    
    decIndTotalIn = (round(inTotal+2020,-1)-2000)/10;
    decIndTotalIn(decIndTotalIn > 8) = 8;

    decinds = (round(2006:2090,-1)-2010)/10+1;
    decinds(decinds > 8) = 8;

    decFuturePop = squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 2:9, 3))));
    meanNoWater = squeeze(1-min(nanmean(bwSupplyMeanFutNormal(:, mind), 1) ./ bwfpTotalFut(:, 3, 2), 1)) .* decFuturePop;
    
    ihdAnomFut(mind) = squeeze(nanmean(.6 .* bwSupplyFutTotalNoPw(2020-2006+ihdTotal, mind) ./ decFuturePop(decIndTotalIhd), 1));% - nanmean(bwSupplyFutTotalNoPw(1:85, mind) ./ decFuturePop(decinds), 1));
    idAnomFut(mind) = squeeze(nanmean(.6 .* bwSupplyFutTotalNoPw(2020-2006+idTotal, mind) ./ decFuturePop(decIndTotalId), 1));% - nanmean(bwSupplyFutTotalNoPw(1:85, mind) ./ decFuturePop(decinds), 1));
    ihAnomFut(mind) = squeeze(nanmean(.6 .* bwSupplyFutTotalNoPw(2020-2006+ihTotal, mind) ./ decFuturePop(decIndTotalIh), 1));% - nanmean(bwSupplyFutTotalNoPw(1:85, mind) ./ decFuturePop(decinds), 1));
    inAnomFut(mind) = squeeze(nanmean(.6 .* bwSupplyFutTotalNoPw(2020-2006+inTotal, mind) ./ decFuturePop(decIndTotalIn), 1));% - nanmean(bwSupplyFutTotalNoPw(1:85, mind) ./ decFuturePop(decinds), 1));

    hdNormalSigFut(mind) = ttest2(.6 .* bwSupplyFutTotalNoPw(2020-2006+ihdTotal, mind) ./ decFuturePop(decIndTotalIhd), .6 .* bwSupplyFutTotalNoPw(2020-2006+inTotal, mind) ./ decFuturePop(decIndTotalIn));
    hdDrySigFut(mind) = ttest2(.6 .* bwSupplyFutTotalNoPw(2020-2006+ihdTotal, mind) ./ decFuturePop(decIndTotalIhd), .6 .* bwSupplyFutTotalNoPw(2020-2006+idTotal, mind) ./ decFuturePop(decIndTotalId));
    
    ihdNoWaterAnomFut(mind) = nanmean((1-min(.6 .* bwSupplyFutTotalNoPw(2020-2006+ihdTotal, mind) ./ bwfpTotalFut(decIndTotalIhd, 3, 2), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIhd, 3)))) ./ squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIhd, 3)))));
    idNoWaterAnomFut(mind) = nanmean((1-min(.6 .* bwSupplyFutTotalNoPw(2020-2006+idTotal, mind) ./ bwfpTotalFut(decIndTotalId, 3, 2), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalId, 3)))) ./ squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalId, 3)))));
    ihNoWaterAnomFut(mind) = nanmean((1-min(.6 .* bwSupplyFutTotalNoPw(2020-2006+ihTotal, mind) ./ bwfpTotalFut(decIndTotalIh, 3, 2), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIh, 3)))) ./ squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIh, 3)))));
    inNoWaterAnomFut(mind) = nanmean((1-min(.6 .* bwSupplyFutTotalNoPw(2020-2006+inTotal, mind) ./ bwfpTotalFut(decIndTotalIn, 3, 2), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIn, 3)))) ./ squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIn, 3)))));
end

histBwAnomFreq = sort(histBwAnomFreq);
fut45BwAnomFreq = sort(fut45BwAnomFreq);
futBwAnomFreq = sort(futBwAnomFreq);

ihdAnomHist = sort(ihdAnomHist);
idAnomHist = sort(idAnomHist);
ihAnomHist = sort(ihAnomHist);

ihdAnomFut = sort(ihdAnomFut);
idAnomFut = sort(idAnomFut);
ihAnomFut = sort(ihAnomFut);

ihdNoWaterAnomHist = sort(ihdNoWaterAnomHist);
idNoWaterAnomHist = sort(idNoWaterAnomHist);
ihNoWaterAnomHist = sort(ihNoWaterAnomHist);
inNoWaterAnomHist = sort(inNoWaterAnomHist);

ihdNoWaterAnomFut = sort(ihdNoWaterAnomFut);
idNoWaterAnomFut = sort(idNoWaterAnomFut);
ihNoWaterAnomFut = sort(ihNoWaterAnomFut);
inNoWaterAnomFut = sort(inNoWaterAnomFut);

il = round(.1*length(models));
ih = round(.9*length(models));

% figure('Color', [1,1,1]);
% hold on;
% box on;
% pbaspect([1 2 1]);
% set(gca, 'YGrid', 'on');
% 
% b1 = boxplot([histBwAnomFreq(il:ih)' fut45BwAnomFreq(il:ih)' futBwAnomFreq(il:ih)'], 'positions', [1 1.5 2], 'widths', [.25 .25 .25]);
% 
% colors = brewermap(10, 'Greens');
% set(b1(:, 1), {'LineWidth', 'Color'}, {2, colors(7,:)});
% colors = brewermap(10, 'Blues');
% set(b1(:, 2), {'LineWidth', 'Color'}, {2, colors(7,:)});
% colors = brewermap(10, 'Reds');
% set(b1(:, 3), {'LineWidth', 'Color'}, {2, colors(7,:)});
% 
% lines = findobj(b1, 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
% 
% ylim([0 40]);
% 
% set(gca,'TickLabelInterpreter', 'tex');    
% xtickangle(0);
% 
% set(gca, 'XTick', [1 1.5 2], 'XTickLabels', {'Historical', 'RCP 4.5', 'RCP 8.5'});
% xtickangle(45);
% ylabel('Frequency (% of years)');
% set(gca, 'FontSize', 36);
% set(gca, 'YTick', [0:10:40]);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig(['bw-anom-recurrence.eps']);
% close all;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 2 1]);

b = boxplot([inAnomHist(il:ih)', ihdAnomHist(il:ih)'], 'width', .15, 'positions', [.85 1.15]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

b2 = boxplot([inAnomFut(il:ih)', ihdAnomFut(il:ih)'], 'width', .15, 'positions', [1.85 2.15]);
 
set(b2(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b2(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b2(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b2(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b2(:, 1),'Tag','Box');
for j=1:length(h)
    patch(get(h(j), 'XData'), get(h(j),'YData'),colorW,'FaceAlpha',.5, 'EdgeColor', 'none');
end
h = findobj(b2(:, 2), 'Tag', 'Box');
for j=1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), colorHd, 'FaceAlpha', .5, 'EdgeColor', 'none');
end


xlim([.5 2.5]);
ylim([0 2750]);
set(gca, 'ytick', [0:500:2500]);
set(gca, 'fontsize', 36);
ylabel('Runoff supply (m^3/person/year)');
set(gca, 'xtick', [1 2], 'xticklabels', {'1901 - 2005', '2020 - 2090'});
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-anom-hd-years-3.eps;
close all;





figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 2 1]);

b = boxplot(100 .* [inNoWaterAnomHist(il:ih)' ihdNoWaterAnomHist(il:ih)'], 'width', .15, 'positions', [.85 1.15]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

b = boxplot(100 .* [inNoWaterAnomFut(il:ih)' ihdNoWaterAnomFut(il:ih)'], 'width', .15, 'positions', [1.85 2.15]);
 
set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b(:, 1),'Tag','Box');
for j=1:length(h)
    patch(get(h(j), 'XData'), get(h(j),'YData'),colorW,'FaceAlpha',.5, 'EdgeColor', 'none');
end
h = findobj(b(:, 2), 'Tag', 'Box');
for j=1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), colorHd, 'FaceAlpha', .5, 'EdgeColor', 'none');
end

%plot([0 4], [0 0], '--k', 'linewidth', 2);
xlim([.5 2.5]);
ylim([0 100]);
%set(gca, 'ytick', [-4:1:3] .* 1e7, 'yticklabels', {'-40M', '-30M', '-20M', '-10M', '0M', '10M', '20M', '30M'});
set(gca, 'fontsize', 36);
ylabel('Unmet demand (% population)');
set(gca, 'xtick', [1 2], 'xticklabels', {'1901 - 2005', '2020 - 2090'});
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig no-water-anom-hd-years-3.eps;
close all;





