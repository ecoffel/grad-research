

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
        
        tdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(tas{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        pdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(pr{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        
        tfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        pfdataEthiopia(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
        
        tfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        pfdataBlue(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsBlueCmip5, lonIndsBlueCmip5, :, :), 2), 1)), 2);
        
        tfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        pfdataWhite(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsWhiteCmip5, lonIndsWhiteCmip5, :, :), 2), 1)), 2);
        
        tfdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        pfdataTotal(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}([latIndsBlueCmip5 latIndsWhiteCmip5], [lonIndsBlueCmip5 lonIndsWhiteCmip5], :, :), 2), 1)), 2);
        
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
bwfpTotalFut = zeros(length(2010:10:2080), 5);

for s = 1:5
    decind = 1;
    for dec = 2010:10:2080
        
        bwfpTotalFut(decind, s) = bwfpPc(s) * nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decind, s)));
        
        decind = decind+1;
    end
end

dind = 1;
bwSupplyMeanFut = [];
noWaterFut = [];
for dec = 2010:10:2080
    bwSupplyMeanFut(dind, :) = squeeze(squeeze(nanmean(bwSupplyFutTotalNoPw(dec-2006+1:dec+10-2006+1, :), 1)));
    
    for s = 1:5
        noWaterFut(dind, :, s) = (1-min(bwSupplyMeanFut(dind, :) ./ bwfpTotalFut(dind, s),1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], dind, s)));
    end
    dind = dind+1;
end

bwSupplyMeanFutSorted = sort(bwSupplyMeanFut, 2);
noWaterFutSorted = sort(noWaterFut, 2);

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
b = boxplot(bwSupplyMeanFutSorted(2:8,il:ih)', 'width', .15, 'positions', [1:7] - .12)

set(b, {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

p = plot([1:7]-.12, bwfpTotalFut(2:8,3), 'o', 'markersize', 18, 'markerfacecolor', 'w', 'color', colorD, 'linewidth', 3);

ylim([0 1.2e12]);
ylabel('BW (m^3/year)');
set(gca, 'YTick', [0 .3 .6 .9 1.2] .* 1e12, 'YTickLabels', {'0', '300B', '600B', '900B', '1.2T'});

legend([p], {'BW demand'});
legend boxoff;

yyaxis right;
b = boxplot(noWaterFutSorted(2:8,il:ih,3)', 'width', .15, 'positions', [1:7] + .12)

set(b, {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(gca, 'fontsize', 36);
ylim([0 4e8]);
set(gca, 'XTick', 1:7, 'XTickLabels', 2020:10:2080);
set(gca, 'YTick', [0 1 2 3 4] .* 1e8, 'YTickLabels', {'0', '100M', '200M', '300M', '400M'});
xlim([.5 7.5]);
ylabel('Unmet demand (people/year)');
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bw-supply-demand-3.eps;
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

tprc = 74;
pprc = 34;

% find hot/dry years and show bw supply anomalies
for mind = 1:length(models)
    ihdTotal = find(detrend(tdataTotal(:, mind)) > prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) < prctile(detrend(pdataTotal(:, mind)), pprc));
    idTotal = find(detrend(tdataTotal(:, mind)) < prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) < prctile(detrend(pdataTotal(:, mind)), pprc));
    ihTotal = find(detrend(tdataTotal(:, mind)) > prctile(detrend(tdataTotal(:, mind)), tprc) & detrend(pdataTotal(:, mind)) > prctile(detrend(pdataTotal(:, mind)), pprc));
    
    ihdAnomHist(mind) = squeeze(nanmean(bwSupplyHistTotalNoPw(ihdTotal, mind), 1) - nanmean(bwSupplyHistTotalNoPw(:, mind), 1));
    idAnomHist(mind) = squeeze(nanmean(bwSupplyHistTotalNoPw(idTotal, mind), 1) - nanmean(bwSupplyHistTotalNoPw(:, mind), 1));
    ihAnomHist(mind) = squeeze(nanmean(bwSupplyHistTotalNoPw(ihTotal, mind), 1) - nanmean(bwSupplyHistTotalNoPw(:, mind), 1));
                
    meanNoWater = (1-min(nanmean(bwSupplyHistTotalNoPw(:, mind), 1) ./ bwfpTotalFut(1, 3), 1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, 3)));
                
    ihdNoWaterAnomHist(mind) = (1-min(nanmean(bwSupplyHistTotalNoPw(ihdTotal, mind), 1) ./ bwfpTotalFut(1, 3), 1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, 3))) - ...
                                meanNoWater;
    idNoWaterAnomHist(mind) = (1-min(nanmean(bwSupplyHistTotalNoPw(idTotal, mind), 1) ./ bwfpTotalFut(1, 3), 1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, 3))) - ...
                                meanNoWater;
    ihNoWaterAnomHist(mind) = (1-min(nanmean(bwSupplyHistTotalNoPw(ihTotal, mind), 1) ./ bwfpTotalFut(1, 3), 1)) .* nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 1, 3))) - ...
                                meanNoWater;

                            
                
    ihdTotal = find(detrend(tfdataTotal(:, mind)) > prctile(detrend(tfdataTotal(:, mind)), tprc) & detrend(pfdataTotal(:, mind)) < prctile(detrend(pfdataTotal(:, mind)), pprc));
    idTotal = find(detrend(tfdataTotal(:, mind)) < prctile(detrend(tfdataTotal(:, mind)), tprc) & detrend(pfdataTotal(:, mind)) < prctile(detrend(pfdataTotal(:, mind)), pprc));
    ihTotal = find(detrend(tfdataTotal(:, mind)) > prctile(detrend(tfdataTotal(:, mind)), tprc) & detrend(pfdataTotal(:, mind)) > prctile(detrend(pfdataTotal(:, mind)), pprc));
    
    ihdAnomFut(mind) = squeeze(nanmean(bwSupplyFutTotalNoPw(ihdTotal, mind), 1) - nanmean(bwSupplyFutTotalNoPw(:, mind), 1));
    idAnomFut(mind) = squeeze(nanmean(bwSupplyFutTotalNoPw(idTotal, mind), 1) - nanmean(bwSupplyFutTotalNoPw(:, mind), 1));
    ihAnomFut(mind) = squeeze(nanmean(bwSupplyFutTotalNoPw(ihTotal, mind), 1) - nanmean(bwSupplyFutTotalNoPw(:, mind), 1));
                    
    % find no water for historical
    
    decIndTotalIhd = (round(ihdTotal+2006,-1)-2000)/10;
    decIndTotalIhd(decIndTotalIhd > 8) = 8;
    
    decIndTotalId = (round(idTotal+2006,-1)-2000)/10;
    decIndTotalId(decIndTotalId > 8) = 8;
    
    decIndTotalIh = (round(ihTotal+2006,-1)-2000)/10;
    decIndTotalIh(decIndTotalIh > 8) = 8;

    decinds = (round(2006:2090,-1)-2010)/10+1;
    decinds(decinds > 8) = 8;

    meanNoWater = squeeze(1-min(nanmean(bwSupplyMeanFut(:, mind), 1) ./ bwfpTotalFut(:, 3), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], 2:9, 3))));
    
    ihdNoWaterAnomFut(mind) = nanmean((1-min(bwSupplyFutTotalNoPw(ihdTotal, mind) ./ bwfpTotalFut(decIndTotalIhd, 3), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIhd, 3)))) - ...
                                meanNoWater(decIndTotalIhd),1);
    idNoWaterAnomFut(mind) = nanmean((1-min(bwSupplyFutTotalNoPw(idTotal, mind) ./ bwfpTotalFut(decIndTotalId, 3), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalId, 3)))) - ...
                                meanNoWater(decIndTotalId),1);
    ihNoWaterAnomFut(mind) = nanmean((1-min(bwSupplyFutTotalNoPw(ihTotal, mind) ./ bwfpTotalFut(decIndTotalIh, 3), 1)) .* squeeze(nansum(nansum(ssp([latIndsBlueSSP latIndsWhiteSSP], [lonIndsBlueSSP lonIndsWhiteSSP], decIndTotalIh, 3)))) - ...
                                meanNoWater(decIndTotalIh),1);
end

ihdAnomHist = sort(ihdAnomHist);
idAnomHist = sort(idAnomHist);
ihAnomHist = sort(ihAnomHist);

ihdAnomFut = sort(ihdAnomFut);
idAnomFut = sort(idAnomFut);
ihAnomFut = sort(ihAnomFut);

ihdNoWaterAnomHist = sort(ihdNoWaterAnomHist);
idNoWaterAnomHist = sort(idNoWaterAnomHist);
ihNoWaterAnomHist = sort(ihNoWaterAnomHist);

ihdNoWaterAnomFut = sort(ihdNoWaterAnomFut);
idNoWaterAnomFut = sort(idNoWaterAnomFut);
ihNoWaterAnomFut = sort(ihNoWaterAnomFut);

il = round(.1*length(models));
ih = round(.9*length(models));

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 2 1]);

b = boxplot([ihdAnomHist(il:ih)' idAnomHist(il:ih)', ihAnomHist(il:ih)'], 'width', .15, 'positions', [.85 1.85 2.85]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,3), {'LineWidth', 'Color'}, {3, colorH})
lines = findobj(b(:,3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

b = boxplot([ihdAnomFut(il:ih)' idAnomFut(il:ih)', ihAnomFut(il:ih)'], 'width', .15, 'positions', [1.15 2.15 3.15]);
 
set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,3), {'LineWidth', 'Color'}, {3, colorH})
lines = findobj(b(:,3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b(:, 1),'Tag','Box');
for j=1:length(h)
    patch(get(h(j), 'XData'), get(h(j),'YData'),colorHd,'FaceAlpha',.5, 'EdgeColor', 'none');
end
h = findobj(b(:, 2), 'Tag', 'Box');
for j=1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), colorD, 'FaceAlpha', .5, 'EdgeColor', 'none');
end
h = findobj(b(:, 3),'Tag','Box');
for j=1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), colorH, 'FaceAlpha', .5, 'EdgeColor', 'none');
end

plot([0 4], [0 0], '--k', 'linewidth', 2);
xlim([.5 3.5]);
ylim([-1.25 .5].*1e11);
set(gca, 'ytick', [-1.25:.25:.5] .* 1e11, 'yticklabels', {'-125B', '-100B', '-75B', '-50B', '-25B', '0', '25B', '50B'});
set(gca, 'fontsize', 36);
ylabel('BW anomaly (m^3/year)');
set(gca, 'xtick', [1 2 3], 'xticklabels', {'Hot & dry', 'Dry', 'Hot'});
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-anom-hd-years-3.eps;
close all;





figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 2 1]);

b = boxplot([ihdNoWaterAnomHist(il:ih)' idNoWaterAnomHist(il:ih)', ihNoWaterAnomHist(il:ih)'], 'width', .15, 'positions', [.85 1.85 2.85]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,3), {'LineWidth', 'Color'}, {3, colorH})
lines = findobj(b(:,3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

b = boxplot([ihdNoWaterAnomFut(il:ih)' idNoWaterAnomFut(il:ih)', ihNoWaterAnomFut(il:ih)'], 'width', .15, 'positions', [1.15 2.15 3.15]);
 
set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,2), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
set(b(:,3), {'LineWidth', 'Color'}, {3, colorH})
lines = findobj(b(:,3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

h = findobj(b(:, 1),'Tag','Box');
for j=1:length(h)
    patch(get(h(j), 'XData'), get(h(j),'YData'),colorHd,'FaceAlpha',.5, 'EdgeColor', 'none');
end
h = findobj(b(:, 2), 'Tag', 'Box');
for j=1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), colorD, 'FaceAlpha', .5, 'EdgeColor', 'none');
end
h = findobj(b(:, 3),'Tag','Box');
for j=1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), colorH, 'FaceAlpha', .5, 'EdgeColor', 'none');
end

plot([0 4], [0 0], '--k', 'linewidth', 2);
xlim([.5 3.5]);
ylim([-4e7 3e7]);
set(gca, 'ytick', [-4:1:3] .* 1e7, 'yticklabels', {'-40M', '-30M', '-20M', '-10M', '0M', '10M', '20M', '30M'});
set(gca, 'fontsize', 36);
ylabel('Unmet demand (people/year)');
set(gca, 'xtick', [1 2 3], 'xticklabels', {'Hot & dry', 'Dry', 'Hot'});
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig no-water-anom-hd-years-3.eps;
close all;





