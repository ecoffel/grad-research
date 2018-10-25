%[raw_city, raw_date, raw_dow, rawraw_tmpd, raw_tmax, raw_tmin, raw_tmean, raw_dptp] = textread('2016-heat-humid-mortality/mortality-data/ny8700.csv', '%s%s%s%s%s%s%s%s%*[^\n]', 'headerlines', 1, 'delimiter', ',');

cities = ["akr", "anch", "arlv", "bake", "batr", "bidd", "buff", "cayc", "cdrp", "clmg", "clmo", "colo", "corp", "covt", "dlft"];

for city = cities

    city = city{1};

rawData = textread(['e:/data/projects/mortality/' city '.csv'], '%s', 'headerlines', 1, 'delimiter', '\n');

headers = {'city', 'date', 'dow', 'death', 'tmpd', 'tmax', 'tmin', 'tmean', 'dptp', 'wbmean', 'wbmax'};
cols = [2 3 4 9 14 15 16 17 18];

dataHeaders = {'year', 'month', 'day', 'dow', 'death', 'tmpd', 'tmax', 'tmin', 'tmean', 'dptp', 'wbmean', 'wbmax'};
data = [];

for i = 1:length(rawData)
    line = rawData{i};
    
    parts = strsplit(line, ',');
    
    % process date
    date = parts{cols(find(strcmp(headers, 'date')))};
    
    year = str2num(date(1:4));
    month = str2num(date(5:6));
    day = str2num(date(7:8));
    
    data(i, find(strcmp(dataHeaders, 'year'))) = year;
    data(i, find(strcmp(dataHeaders, 'month'))) = month;
    data(i, find(strcmp(dataHeaders, 'day'))) = day;
    
    dow = parts{cols(find(strcmp(headers, 'dow')))};
    if ~strcmp(dow, 'NA')
        data(i, find(strcmp(dataHeaders, 'dow'))) = str2num(dow);
    else
        data(i, cols(find(strcmp(dataHeaders, 'dow')))) = -999;
    end
    
    death = parts{cols(find(strcmp(headers, 'death')))};
    if ~strcmp(death, 'NA')
        data(i, find(strcmp(dataHeaders, 'death'))) = str2num(death);
    else
        data(i, find(strcmp(dataHeaders, 'death'))) = -999;
    end
    
    tmpd = parts{cols(find(strcmp(headers, 'tmpd')))};
    if ~strcmp(tmpd, 'NA')
        data(i, find(strcmp(dataHeaders, 'tmpd'))) = (str2num(tmpd)-32)*5.0/9.0;
    else
        data(i, find(strcmp(dataHeaders, 'tmpd'))) = -999;
    end
    
    tmax = parts{cols(find(strcmp(headers, 'tmax')))};
    if ~strcmp(tmax, 'NA')
        data(i, find(strcmp(dataHeaders, 'tmax'))) = (str2num(tmax)-32)*5.0/9.0;
    else
        data(i, find(strcmp(dataHeaders, 'tmax'))) = -999;
    end
    
    tmin = parts{cols(find(strcmp(headers, 'tmin')))};
    if ~strcmp(tmin, 'NA')
        data(i, find(strcmp(dataHeaders, 'tmin'))) = (str2num(tmin)-32)*5.0/9.0;
    else
        data(i, find(strcmp(dataHeaders, 'tmin'))) = -999;
    end
    
    tmean = parts{cols(find(strcmp(headers, 'tmean')))};
    if ~strcmp(tmean, 'NA')
        data(i, find(strcmp(dataHeaders, 'tmean'))) = (str2num(tmean)-32)*5.0/9.0;
    else
        data(i, find(strcmp(dataHeaders, 'tmean'))) = -999;
    end
    
    dptp = parts{cols(find(strcmp(headers, 'dptp')))};
    if ~strcmp(dptp, 'NA')
        data(i, find(strcmp(dataHeaders, 'dptp'))) = (str2num(dptp)-32)*5.0/9.0;
    else
        data(i, find(strcmp(dataHeaders, 'dptp'))) = -999;
    end
    
    if ~strcmp(tmean, 'NA') & ~strcmp(dptp, 'NA')
        data(i, length(dataHeaders)-1) = mo_wbFromDewpt((str2num(tmean)-32)*5/9, (str2num(dptp)-32)*5/9);
    end
    
    if ~strcmp(tmax, 'NA') & ~strcmp(dptp, 'NA')
        data(i, length(dataHeaders)) = mo_wbFromDewpt((str2num(tmax)-32)*5/9, (str2num(dptp)-32)*5/9);
    end
    
end

mortData = {dataHeaders, data};
save([city 'MortData'], 'mortData');
end
