% calculate WR at each weight decile (between low weight MTOW)

aircraftList = {'737-800', 'a320', '787', '777-300', 'a380'};
dataset = 'cmip5';
rcps = {'historical', 'rcp45', 'rcp85'};

wrBaseDir = '2015-weight-restriction-v2/wr-data/';

% should we plot a histogram of the fleet weight distribution
plotHist = false;

basePeriodYears = 1985:2004;
futurePeriodYears = 2021:2080;


% should we use payload restriction or total restriction
payload = false;

% restriction statistics for each aircraft, along with the TOW distribution
% used
restrictionData = {};

for ac = 1:length(aircraftList)
    
    trData = {};
    wrData = {};
    
    aircraft = aircraftList{ac};
    
    ['processing ' aircraft '...']

    % load modeled data
    if ismember('historical', rcps)
        load([wrBaseDir 'wr-' aircraft '-' dataset '-historical.mat']);
        load([wrBaseDir 'tr-' aircraft '-' dataset '-historical.mat']);
        curWeightData = weightRestriction;
        trModelHistorical = totalRestriction;

        trData{end+1} = trModelHistorical;
        wrData{end+1} = curWeightData;

        historicalAirports = {};
        for a = 1:length(curWeightData)
            historicalAirports{end+1} = curWeightData{a}{1}{1};
        end
    end

    if ismember('rcp45', rcps)
        load([wrBaseDir 'wr-' aircraft '-' dataset '-rcp45.mat']);
        load([wrBaseDir 'tr-' aircraft '-' dataset '-rcp45.mat']);
        wrModelRcp45 = weightRestriction;
        trModelRcp45 = totalRestriction;

        trData{end+1} = trModelRcp45;
        wrData{end+1} = wrModelRcp45;

        rcp45Airports = {};
        for a = 1:length(wrModelRcp45)
            rcp45Airports{end+1} = wrModelRcp45{a}{1}{1};
        end
    end

    if ismember('rcp85', rcps)
        load([wrBaseDir 'wr-' aircraft '-' dataset '-rcp85.mat']);
        load([wrBaseDir 'tr-' aircraft '-' dataset '-rcp85.mat']);
        wrModelRcp85 = weightRestriction;
        trModelRcp85 = totalRestriction;

        trData{end+1} = trModelRcp85;
        wrData{end+1} = wrModelRcp85;

        rcp85Airports = {};
        for a = 1:length(wrModelRcp85)
            rcp85Airports{end+1} = wrModelRcp85{a}{1}{1};
        end
    end

    if strcmp(aircraft, '777-300')
        excludeAirports = {'DCA', 'LGA', 'MDW', 'SYD'};
        maxWeight = 660;
        minWeight = 450;
    elseif strcmp(aircraft, '787')
        excludeAirports = {'DCA', 'LGA', 'MDW', 'SYD'};
        maxWeight = 502;
        minWeight = 380;
    elseif strcmp(aircraft, 'a320')
        excludeAirports = {'SYD'};
        maxWeight = 174;
        minWeight = 100;
    elseif strcmp(aircraft, 'a380')
        excludeAirports = {'DCA', 'LGA', 'MDW', 'SYD'};
        maxWeight = 1260;
        minWeight = 800;
    elseif strcmp(aircraft, '737-800')
        excludeAirports = {'SYD'};
        maxWeight = 174;
        minWeight = 100;       
    end
    
    % calculate evenly spaced weights between min and max
    weightDist = linspace(minWeight, maxWeight, 10);

    airports = {};
    for a = 1:length(historicalAirports)
        if ismember(historicalAirports{a}, rcp85Airports) && ...
           ~ismember(historicalAirports{a}, excludeAirports)
            airports{end+1} = historicalAirports{a};
        end
    end

    restrictionData{ac} = {{aircraft, weightDist}};
    
    for r = 1:length(rcps)

        ['processing ' rcps{r} '...']

        % make new cell for current RCP - 1st sub-cell will contain RCP
        % summary data
        restrictionData{ac}{1+r} = {rcps{r} };
        
        numModels = length(curWeightData{1});
        
        % how many years in current RCP
        if r == 1
            numYears = length(basePeriodYears);
        else
            numYears = length(futurePeriodYears);
        end
        
        % summary variables for the entire RCP
        
        % total number of flights
        rcpTotalCount = zeros(numModels, numYears, length(weightDist));
        % # of flights with some restriction at each weight level
        rcpRestrictedCount = zeros(numModels, numYears, length(weightDist));
        % total weight reduced at each weight level
        rcpRestrictedWeight = zeros(numModels, numYears, length(weightDist));
        % total weight requested (TOW for each flight) at each weight level
        rcpTotalTow = zeros(numModels, numYears, length(weightDist));
        
        % loop through all selected airports
        for aInd = 1:length(airports)

            % find index of current airport
            if payload
                curWeightData = wrData{r};
            else
                curWeightData = trData{r};
            end
            
            aIndCur = -1;
            for a = 1:length(curWeightData)
                if strcmp(airports{aInd}, curWeightData{a}{1}{1})
                    aIndCur = a;
                end
            end
            
            % summary variables for this RCP & airport
            airportTotalCount = zeros(numModels, numYears, length(weightDist));
            airportRestrictedCount = zeros(numModels, numYears, length(weightDist));
            airportRestrictedWeight = zeros(numModels, numYears, length(weightDist));
            airportTotalTow = zeros(numModels, numYears, length(weightDist));
            
            % add new cell to current RCP for airport data
            restrictionData{ac}{r+1}{end+1} = {airports{aInd}};

            % all models
            for m = 1:length(curWeightData{aIndCur})

                daysPerYear = round(size(curWeightData{aIndCur}{m}{3}, 2)/numYears);
                
                for y = 1:numYears
                    for w = 1:length(weightDist)
                        tow = weightDist(w);
                        
                        % indicies for current year
                        ind1 = (y-1) * daysPerYear + 1;
                        ind2 = y * daysPerYear;
                        
                        % number of restricted days
                        numRestricted = length(find((maxWeight - curWeightData{aIndCur}{m}{3}(:, ind1:ind2) < tow)));
                        % sum of restricted weight
                        restrictedWeight = (tow - (maxWeight - curWeightData{aIndCur}{m}{3}(:, ind1:ind2)));
                        restrictedWeight(restrictedWeight < 0) = 0;
                        restrictedWeight = nansum(nansum(restrictedWeight));
                        
                        airportRestrictedCount(m, y, w) = numRestricted;
                        airportTotalCount(m, y, w) = numel(curWeightData{aIndCur}{m}{3}(:, ind1:ind2));
                        rcpRestrictedCount(m, y, w) = rcpRestrictedCount(m, y, w) + numRestricted;
                        rcpTotalCount(m, y, w) = rcpTotalCount(m, y, w) + numel(curWeightData{aIndCur}{m}{3}(:, ind1:ind2));
                        
                        airportRestrictedWeight(m, y, w) = restrictedWeight;
                        airportTotalTow(m, y, w) = airportTotalCount(m, y, w) * tow;
                        rcpRestrictedWeight(m, y, w) = rcpRestrictedWeight(m, y, w) + restrictedWeight;
                        rcpTotalTow(m, y, w) = rcpTotalTow(m, y, w) + airportTotalCount(m, y, w) * tow;
                    end
                end
            end
                
            % add summary data for current airport
            restrictionData{ac}{r+1}{end}{end+1} = {airportRestrictedCount, airportRestrictedWeight, airportTotalCount, airportTotalTow};
        end
        
        % add summary data for current RCP
        restrictionData{ac}{r+1}{end}{end+1}  = {rcpRestrictedCount, rcpRestrictedWeight, rcpTotalCount, rcpTotalTow};
    end
    
    clear trData wrData;
end

if payload
    save('restrictionData-wr', 'restrictionData');
else
    save('restrictionData-tr', 'restrictionData');
end

