function [routeDB] = loadRouteDB(fname)

fid = fopen(fname);
routeDB = {};
routeData = textscan(fid, '%s', 'delimiter', '\n');
for r=1:length(routeData{1})
    route = routeData{1}{r};
    routeParts = strsplit(route, ',');
    routeDB{r} = {strrep(routeParts{3},'"', ''), strrep(routeParts{5},'"', '')};
end
fclose(fid);
routeDB = routeDB';