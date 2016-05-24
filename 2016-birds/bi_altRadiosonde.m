% read the station list
f = fopen('2016-birds/radiosonde/stations.txt');
stationCodes = [];
stationNames = {};
line = fgets(f);
while line ~= -1
    parts = strsplit(line, ',');
    stationCodes(end+1) = str2num(parts{1});
    stationNames{end+1} = parts{2};
    
    line = fgets(f);
end

% read the hourly profile data
fid = fopen('2016-birds/radiosonde/temp_00z.mly', 'r');
f = fread(fid, inf, 'uint8=>char')';
fclose(fid);

idxs = [0 strfind(f, char(10))];
nobs = length(idxs)-1;

stationNum = {};
year = {};
month = {};
pressLev = {};
meanVal = {};

for ii = 1:nobs-1,
    line = f(idxs(ii) + 1:idxs(ii+1) - 1);
    
    curStationNum = str2num(line(1:5));
    
    if curStationNum == 94287
        stationNum{end+1} = curStationNum;
        year{end+1} = str2num(line(7:10));
        month{end+1} = str2num(line(12:13));
        pressLev{end+1} = str2num(line(15:18));
        meanVal{end+1} = str2num(line(20:24));
    end
    
    if mod(ii, 10000) == 0
        ['processed ' num2str(ii) ' lines...']
    end
end

