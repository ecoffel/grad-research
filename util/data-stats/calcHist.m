function calcHist(data, bins)

datacat1 = [];
for i = 1:size(data,3)
    datacat1 = [datacat1 data(:,:,i)];
end

datacat2 = [];
for i = 1:size(datacat1,1)
    datacat2 = [datacat2 datacat1(i,:)];
end

hist(datacat2,bins);