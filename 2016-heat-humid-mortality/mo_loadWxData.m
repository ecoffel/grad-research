years = 1987:2000;
cities = {'knyc'};

for c = 1:length(cities)
    
    wxTable = table;
    
    for y = years
        % read ISH data into a table
        data = pvl_readISH(['2016-heat-humid-mortality\ish-wx\' cities{c} '-' num2str(y)]);
        
        if y > years(1)
            wxTable = union(wxTable, data);
        else
            wxTable = data;
        end
        
        ['processed ' cities{c} ' ' num2str(y)]
    end
end

% sort by first date and then time
wxTable = sortrows(wxTable,[4 5]);