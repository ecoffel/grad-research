% calculate WR at each weight decile (between low weight MTOW)

aircraftList = {'737-800', 'a320', '787', '777-300', 'a380'};
dataset = 'cmip5';
rcps = {'historical', 'rcp45', 'rcp85'};

trData = {};
wrData = {};

wrBaseDir = '2015-weight-restriction-v2/wr-data/';

% should we plot a histogram of the fleet weight distribution
plotHist = false;

% restriction statistics for each aircraft, along with the TOW distribution
% used
restrictionData = {};

for ac = 1:length(aircraftList)
    aircraft = aircraftList{ac};
    
    ['processing ' aircraft '...']

    % load modeled data
    if ismember('historical', rcps)
        load([wrBaseDir 'wr-' aircraft '-' dataset '-historical.mat']);
        load([wrBaseDir 'tr-' aircraft '-' dataset '-historical.mat']);
        wrModelCur = weightRestriction;
        trModelHistorical = totalRestriction;

        trData{end+1} = trModelHistorical;
        wrData{end+1} = wrModelCur;

        historicalAirports = {};
        for a = 1:length(wrModelCur)
            historicalAirports{end+1} = wrModelCur{a}{1}{1};
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
        selectedAirports = {'PHX','DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        maxWeight = 660;
        minWeight = 450;
    elseif strcmp(aircraft, '787')
        selectedAirports = {'PHX','DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        maxWeight = 502;
        minWeight = 380;
    elseif strcmp(aircraft, 'a320')
        selectedAirports = {'LGA', 'DCA', 'PHX', 'DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        maxWeight = 174;
        minWeight = 100;
    elseif strcmp(aircraft, 'a380')
        selectedAirports = {'PHX', 'DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        maxWeight = 1260;
        minWeight = 800;
    elseif strcmp(aircraft, '737-800')
        selectedAirports = {'LGA', 'DCA', 'MDW', 'PHX','DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        maxWeight = 174;
        minWeight = 100;       
    end
    
    % calculate evenly spaced weights between min and max
    weightDist = linspace(minWeight, maxWeight, 10);

    airports = {};
    for a = 1:length(historicalAirports)
        if ismember(historicalAirports{a}, rcp85Airports) && ...
           ismember(historicalAirports{a}, selectedAirports)
            airports{end+1} = historicalAirports{a};
        end
    end

    restrictionData{ac} = {{aircraft, weightDist}};
    
    for r = 1:length(rcps)

        ['processing ' rcps{r} '...']

        % loop through all selected airports
        for aInd = 1:length(airports)

            % find index of current airport
            wrModelCur = wrData{r};
            aIndCur = -1;
            for a = 1:length(wrModelCur)
                if strcmp(airports{aInd}, wrModelCur{a}{1}{1})
                    aIndCur = a;
                end
            end
            
            % total number of flights
            totalCount = 0;
            
            % # of flights with some restriction at each weight level
            restrictedCount = zeros(length(weightDist), 1);
            
            % total weight reduced at each weight level
            restrictedWeight = zeros(length(weightDist), 1);
            
            % total MTOW weight (if every flight took off at MTOW)
            totalMtow = 0;

            % total weight requested (TOW for each flight) at each weight level
            totalTow = zeros(length(weightDist), 1);
            
            restrictionData{ac}{end+1} = {{airports{aInd}}};

            % all models
            for m = 1:length(wrModelCur{aIndCur})

                % all days
                for d = 1:size(wrModelCur{aIndCur}{m}{3}, 2)
                    % restrictions for all hours of current day (+- 2 hours around
                    % daily max temperature)
                    curDayRestrictions = squeeze(wrModelCur{aIndCur}{m}{3}(:, d))';

                    % loop over hourly restrictions for current day
                    for restriction = curDayRestrictions

                        % if there is some restriction at current hour
                        if ~isnan(restriction) && restriction > 0
                            
                            % loop over weight distribution
                            for w = 1:length(weightDist)
                                
                                % current weight
                                tow = weightDist(w);
                                
                                if maxWeight - restriction < tow
                                    % count flights with some restriction
                                    restrictedCount(w) = restrictedCount(w) + 1;
                                    % count how much payload has to be reduced off of
                                    % the attempted TOW
                                    restrictedWeight(w) = restrictedWeight(w) + (tow - (maxWeight-restriction));
                                end

                                totalTow(w) = totalTow(w) + tow;
                            end
                            
                            % count total number of days simulated
                            totalCount = totalCount + 1;
                            % and total MTOW
                            totalMtow = totalMtow + maxWeight;
                            
                        end
                    end     
                end
            end
            
            % add data to cell:
            % distribution parameters, # restricted flights, total weight
            % removed, total # flights, total TOW for all flights, total MTOW
            % for all flights
            restrictionData{ac}{end}{end+1}  = {restrictedCount, restrictedWeight, totalCount, totalTow, totalMtow};

            [airports{aInd} ' - ' rcps{r} ':']
            ['restricted percent: ']
            restrictedCount / totalCount * 100
            ['restricted TOW weight percent: ']
             restrictedWeight ./ totalTow .* 100
            
        end        
    end
end