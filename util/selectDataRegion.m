
fileDir = 'E:\data\cmip5\output\gfdl-cm3\r1i1p1\rcp85\rh\regrid\2006101-21001231';
outputDir = 'C:\git-ecoffel\climate-som\data\gfdl-cm3\rh-usne';

fileNames = dir([fileDir, '\', '*.mat']);
fileNames = {fileNames.name};

usEast = true;

if usEast
    latBounds = [30 50];
    lonBounds = [260 300];
else
    latBounds = [20 50];
    lonBounds = [60 100];
end

for i = 1:length(fileNames)
    fname = fileNames{i};
    fNameParts = strsplit(fname, '.');
    
    load([fileDir '\' fname]);
    eval(['data = ' fNameParts{1} ';']);
    
    [latIndexRange, lonIndexRange] = latLonIndexRange(data, latBounds, lonBounds);
    data{1} = data{1}(latIndexRange, lonIndexRange);
    data{2} = data{2}(latIndexRange, lonIndexRange);
    data{3} = data{3}(latIndexRange, lonIndexRange, :);
    
    eval([fNameParts{1} ' = data;']);
    save([outputDir '\' fname], fNameParts{1}, '-v7');
    ['processed ' fNameParts{1}]
    clear data;
    eval(['clear ' fNameParts{1} ';']);
end
    
    