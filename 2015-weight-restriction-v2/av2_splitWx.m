function wxAirports = splitWx(fileName, wxData)

    baseDir = '2015-weight-restriction-v2\airport-wx\';

    wxDataOld = wxData;
    
    wxAirports = {};

    % loop over airports
    for a = 1:length(wxDataOld{1}{2})
        ['processing ' wxDataOld{1}{2}{a}{1}]
        wxAirports{a} = wxDataOld{1}{2}{a}{1};

        airportData = {};

        % loop over models
        for m = 1:length(wxDataOld)
            % add the name and the dat to the new cell
            airportData{m} = {wxDataOld{m}{1}, wxDataOld{m}{2}{a}};
        end

        wxData = airportData;
        save([baseDir fileName '-' wxData{1}{1} '.mat'], 'wxData');
    end
end

