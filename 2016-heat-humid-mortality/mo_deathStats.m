% find mean death anomalies for days of the week
dowMeans = [];
for d = 1:7
    ind = find(dow == d);
    dowMeans(d) = nanmean(deathsDetrend(ind));
end

moyMeans = [];
for m = 1:12
    ind = find(moy == m);
    moyMeans(m) = nanmean(deathsDetrend(ind));
end
