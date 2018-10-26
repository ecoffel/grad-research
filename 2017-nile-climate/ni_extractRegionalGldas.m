regionBounds = [[2 32]; [25, 44]];
monthLengths = [31 28 31 30 31 30 31 31 30 31 30 31];
fprintf('loading GLDAS qs...\n');

gldas_qs = loadMonthlyData('E:\data\gldas-noah-v2\output\Qs_acc', 'Qs_acc', 'startYear', 1961, 'endYear', 2010);

[latInds, lonInds] = latLonIndexRange({gldas_qs{1},gldas_qs{2},[]}, regionBounds(1,:), regionBounds(2,:));

gldas_qs = {gldas_qs{1}(latInds, lonInds), gldas_qs{2}(latInds, lonInds), gldas_qs{3}(latInds, lonInds, :, :)};

save(['2017-nile-climate/output/gldas_qs.mat'], 'gldas_qs');
clear gldas_qs;

fprintf('loading GLDAS qsb...\n');
gldas_qsb = loadMonthlyData('E:\data\gldas-noah-v2\output\Qsb_acc', 'Qsb_acc', 'startYear', 1961, 'endYear', 2010);
gldas_qsb = {gldas_qsb{1}(latInds, lonInds), gldas_qsb{2}(latInds, lonInds), gldas_qsb{3}(latInds, lonInds, :, :)};
save(['2017-nile-climate/output/gldas_qsb.mat'], 'gldas_qsb');
clear gldas_qsb;

fprintf('loading GLDAS pr...\n');
gldas_pr = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1961, 'endYear', 2010);
gldas_pr = {gldas_pr{1}(latInds, lonInds), gldas_pr{2}(latInds, lonInds), gldas_pr{3}(latInds, lonInds, :, :)};
save(['2017-nile-climate/output/gldas_pr.mat'], 'gldas_pr');
clear gldas_pr;

fprintf('loading GLDAS t...\n');
gldas_t = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1961, 'endYear', 2010);
gldas_t = {gldas_t{1}(latInds, lonInds), gldas_t{2}(latInds, lonInds), gldas_t{3}(latInds, lonInds, :, :)};
save(['2017-nile-climate/output/gldas_t.mat'], 'gldas_t');
clear gldas_t;
