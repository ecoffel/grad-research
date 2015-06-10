function [airportDB] = loadAirportDB(fname)

fid = fopen(fname);
airportDB = {};
airportData = textscan(fid, '%s', 'delimiter', '\n');
for r=1:length(airportData{1})
    airport = airportData{1}{r};
    airportParts = strsplit(airport, ',');
    airportDB{r} = {strrep(airportParts{5},'"', ''), double(str2num(airportParts{7})), double(str2num(airportParts{8}))};
end
fclose(fid);
airportDB = airportDB';