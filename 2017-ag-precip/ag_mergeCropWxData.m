
% load US corn yield
load 2017-ag-precip\ag-data\ag-corn-yield-us.mat
cornYield = cropData;

asosBaseDir = 'f:/data/ag/wx-data/';
cropBaseDir = 'f:/data/ag/crop/';

% load the census database of counties
countyDb = ag_loadCountyDb();

% combined yeild and weather data
mergedCropData = {};

% kilometers between county and station
distThresh = 30;

% loop over each state
for s = 1:length(cropData)
    
    curCropData = cropData{s};
    
    ['processing ' cropData{s}{1} '...']
    
    wxFileName = [asosBaseDir 'asos-' lower(curCropData{1}) '.mat'];
    if ~exist(wxFileName, 'file')
        continue;
    end
    
    % load weather data for this state - stored in asosData
    load(wxFileName);

    % total counties in state
    totalCounties = length(curCropData{3});
    % total counties matched with wx station
    countiesMatched = 0;
    
    for stationInd = 1:length(asosData)
        % get lat/long of the current wx station
        curWxLat = asosData{stationInd}{3};
        curWxLon = asosData{stationInd}{2};
        
        % now find counties within 30 km
        % loop over counties for this state
        for c = 1:length(curCropData{3})
            curCountyLat = curCropData{3}{c}{3};
            curCountyLon = curCropData{3}{c}{4};
            
            % find distance in KM between wx station and county center
            dist = distdim(distance(curWxLat, curWxLon, curCountyLat, curCountyLon), 'degrees', 'km', 'earth');
            
            % if county close enough, add wx data to it
            if dist < distThresh
                
                % if we haven't already added wx data OR if we have and the
                % new wx station is closer
                if length(curCropData{3}{c}) == 5 || ...
                   (length(curCropData{3}{c}) == 7 && dist < curCropData{3}{c}{6})
               
                    % if we haven't matched this county before, count it
                    if length(curCropData{3}{c}) == 5
                        countiesMatched = countiesMatched + 1;
                    end
                    
                    % replace existing wx data with new data
                    curCropData{3}{c}{6} = dist;
                    curCropData{3}{c}{7} = {asosData{stationInd}};
                end 
            end 
        end
    end
    
    ['percent matched: ' num2str(round(countiesMatched / totalCounties * 100.0)) '%...']
    
    cropWxData = curCropData;
    save([cropBaseDir 'cropWxData-' curCropData{1} '.mat'], 'cropWxData', '-v7.3');
    
end

