years = 1987:2000;
%years=1997;
cities = {'nyc'};

for c = 1:length(cities)
    
    wxTable = table;

    % read ISH data into a table
    data = mo_readUSAFHourly(['2016-heat-humid-mortality\ish-wx\' cities{c} '-wx.txt']);

    % remove any non-hourly obs (any with type different than 'SAO')
%         ['removing non-hourly obs']
%         i = 1;
%         while i < size(data, 1)
%             if ~(strcmp(strtrim(data.type{i}), 'SAO') || strcmp(strtrim(data.type{i}), 'NSRDB'))
%                 data(i, :) = [];
%                 i = i - 1;
%             end
%             i = i + 1
%         end

    % loop through each row of table and convert date into year, month,
    % day
    dates = data.date;
    times = data.time;
    year = [];
    month = [];
    day = [];
    hour = [];

    for w = 1:length(dates)
        year(w, 1) = str2num(dates{w}(1:4));
        month(w, 1) = str2num(dates{w}(5:6));
        day(w, 1) = str2num(dates{w}(7:8));
        hour(w, 1) = str2num(times{w}(1:2));
    end

    data.year = year;
    data.month = month;
    data.day = day;
    data.hour = hour;

    % join this year's table to the existing one
%     if y > years(1)
%         wxTable = union(wxTable, data);
%     else
	wxTable = data;
%     end

    ['processed ' cities{c}]
end

% sort by first date and then time
wxTable = sortrows(wxTable, [3 4]);
wxTable.temp(wxTable.temp > 900) = NaN;
wxTable.dwpt(wxTable.dwpt > 900) = NaN;

% add wb data from dew point and temperature
temps = wxTable.temp;
dwpts = wxTable.dwpt;

wb = [];
rh = [];
for i = 1:min(length(temps), length(dwpts))
    [wb(i,1), rh(i,1)] = mo_wbFromDewpt(temps(i), dwpts(i));
end

wxTable.wb = wb;
wxTable.rh = rh;

save('nyWx', 'wxTable');