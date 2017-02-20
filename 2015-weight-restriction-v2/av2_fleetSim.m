% simulate a fleet of flights departing at different weight distributions
% within the simulated WR period (daily max temp +/ 2 hours)

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

for a = 1:length(aircraftList)
    aircraft = aircraftList{a};
    
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

    % how many random weights to simulate
    N = 10000;

    % normal distibution parameters
    if strcmp(aircraft, '777-300')
        selectedAirports = {'PHX','DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        mu = 570;
        sigma = 80;
        maxWeight = 660;
        minWeight = 450;
        bins = 450:20:660;
    elseif strcmp(aircraft, '787')
        selectedAirports = {'PHX','DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        mu = 440;
        sigma = 30;
        maxWeight = 502;
        minWeight = 380;
        bins = 380:20:502;
    elseif strcmp(aircraft, 'a320')
        selectedAirports = {'LGA', 'DCA', 'PHX', 'DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        mu = 140;
        sigma = 20;
        maxWeight = 174;
        minWeight = 100;
        bins = 100:10:180;
    elseif strcmp(aircraft, 'a380')
        selectedAirports = {'PHX', 'DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        mu = 1000;
        sigma = 150;
        maxWeight = 1260;
        minWeight = 800;
        bins = 800:50:1260;
    elseif strcmp(aircraft, '737-800')
        selectedAirports = {'LGA', 'DCA', 'MDW', 'PHX','DEN', 'DXB', 'JFK', 'LAX', 'IAH', 'MIA', 'ORD', 'ATL', 'LHR'};
        mu = 140;
        sigma = 20;
        maxWeight = 174;
        minWeight = 100;
        bins = 100:10:180;
    end

    ['building distribution...']
    
    % make a normal distribution
    dist = makedist('Normal', 'mu', mu, 'sigma', sigma);

    randWeights = [];
    % generate random values
    for i = 1:N
        v = 0;
        while v < minWeight || v > maxWeight
            v = dist.random();
        end

        randWeights(end+1) = v;
    end

    filledBins = hist(randWeights, bins) ./ length(randWeights) .* 100;

    if plotHist
        figure('Color', [1,1,1]);
        hold on;
        bar(bins, filledBins);
        plot(ones(50, 1) .* maxWeight, linspace(-5, 50, 50), '--k');
        ylim([0 30]);
        xlabel('Takeoff weight, 1000s lbs', 'FontSize', 24);
        ylabel('Percent', 'FontSize', 24);
        set(gca, 'FontSize', 24);
        title([aircraft ' weight distribution'], 'FontSize', 30);
    end

    airports = {};
    for a = 1:length(historicalAirports)
        if ismember(historicalAirports{a}, rcp85Airports) && ...
           ismember(historicalAirports{a}, selectedAirports)
            airports{end+1} = historicalAirports{a};
        end
    end

    for r = 1:length(rcps)

        ['processing ' rcps{r} '...']

        % total number of flights
        totalCount = 0;
        % # of flights with some restriction
        restrictedCount = 0;
        % total weight reduced
        restrictedWeight = 0;
        % total MTOW weight (if every flight took off at MTOW)
        totalMtow = 0;
        % total weight requested (TOW for each flight)
        totalTow = 0;

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
                            % select 10 random flights from weight distribution
                            randInd = randi([1 length(randWeights)], 1, 10);

                            % loop over random weights
                            for i = randInd
                                tow = randWeights(i);

                                if maxWeight - restriction < tow
                                    % count flights with some restriction
                                    restrictedCount = restrictedCount + 1;
                                    % count how much payload has to be reduced off of
                                    % the attempted TOW
                                    restrictedWeight = restrictedWeight + (tow - (maxWeight-restriction));
                                end

                                totalCount = totalCount + 1;
                                totalMtow = totalMtow + maxWeight;
                                totalTow = totalTow + tow;
                            end
                        end
                    end     
                end
            end
        end

        % add data to cell:
        % distribution parameters, # restricted flights, total weight
        % removed, total # flights, total TOW for all flights, total MTOW
        % for all flights
        restrictionData{a} = {{randWeights, bins, minWeight, maxWeight}, restrictedCount, restrictedWeight, totalCount, totalTow, totalMtow};
        
        [rcps{r} ':']
        ['restricted fraction: ' num2str(restrictedCount/totalCount*100) '%']
        ['restricted TOW weight fraction: ' num2str(restrictedWeight/totalTow*100) '%']
        ['restricted MTOW weight fraction: ' num2str(restrictedWeight/totalMtow*100) '%']
    end
end