slope = [];
s = [];
p=[];
for x = 1:size(tempCpc,1)
    for y = 1:size(tempCpc,2)
        for year = 1:size(tempCpc,3)
            s(x,y,year) = length(find(tempCpc(x,y,year,:) > 15 & tempCpc(x,y,year,:) < 22));
        end
        
        cs = squeeze(s(x,y,:));
        f = fit((1:size(tempCpc,3))',cs,'poly1');
        slope(x,y)=f.p1;
        p(x,y)=Mann_Kendall(cs',0.05);
        
    end
end