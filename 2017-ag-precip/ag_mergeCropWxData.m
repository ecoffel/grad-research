
% load US corn yield
load 2017-ag-precip\ag-data\ag-corn-yield-us.mat
cornYield = cropData;

asosBaseDir = 'e:/data/asos/wx-data/';

% load the census database of counties
countyDb = ag_loadCountyDb();

% combined yeild and weather data
mergedCropData = {};

% kilometers between county and station
distThresh = 30;

% loop over each state
for s = 1:length(cropData)
    ['processing ' cropData{s}{1} '...']
    
    wxFileName = [asosBaseDir 'asos-' lower(cropData{s}{1}) '.mat'];
    if ~exist(wxFileName, 'file')
        continue;
    end
    
    % load weather data for this state - stored in asosData
    load(wxFileName);

    % total counties in state
    totalCounties = length(cropData{s}{3});
    % total counties matched with wx station
    countiesMatched = 0;
    
    for stationInd = 1:length(asosData)
        % get lat/long of the current wx station
        curWxLat = asosData{stationInd}{3};
        curWxLon = asosData{stationInd}{2};
        
        % now find counties within 30 km
        % loop over counties for this state
        for c = 1:length(cropData{s}{3})
            curCountyLat = cropData{s}{3}{c}{3};
            curCountyLon = cropData{s}{3}{c}{4};
            
            % find distance in KM between wx station and county center
            dist = distdim(distance(curWxLat, curWxLon, curCountyLat, curCountyLon), 'degrees', 'km', 'earth');
            
            if strcmp(lower(cropData{s}{3}{c}{1}), 'russell')
                
            end
            
            % if county close enough, add wx data to it
            if dist < distThresh
                
                % if we haven't already added wx data OR if we have and the
                % new wx station is closer
                if length(cropData{s}{3}{c}) == 5 || ...
                   (length(cropData{s}{3}{c}) == 7 && dist < cropData{s}{3}{c}{6})
               
                    % if we haven't matched this county before, count it
                    if length(cropData{s}{3}{c}) == 5
                        countiesMatched = countiesMatched + 1;
                    end
                    
                    % replace existing wx data with new data
                    cropData{s}{3}{c}{6} = dist;
                    cropData{s}{3}{c}{7} = {asosData{stationInd}};
                end
                
                
            end
            
        end
        
    end
    
    ['percent matched: ' num2str(round(countiesMatched / totalCounties * 100.0)) '%...']

end

cropWxData = cropData;
save('2017-ag-precip/ag-data/cropWxData.mat', cropWxData);