wbMax = mortData{2}(:,14);
tMax = mortData{2}(:,17);
tMax(abs(tMax)>100)=NaN;
madj = mo_removeSeasonal(  mortData{2}(:,5)-smooth(mortData{2}(:,5), 365));

figure;
hold on;
cpwb = [];
cpt = [];
cwb = [];
ct = [];
r2wb=[];
r2t=[];
for p=50:99
    i=find(tMax>prctile(tMax,p));
    fwb=fitlm(madj(i),wbMax(i));
    ft=fitlm(madj(i),tMax(i));

    cwb(end+1) = fwb.Coefficients.Estimate(2);
    ct(end+1) = ft.Coefficients.Estimate(2);
    
    cpwb(end+1) = fwb.Coefficients.pValue(2)<.05;
    cpt(end+1) = ft.Coefficients.pValue(2)<.05;
    
    r2wb(end+1)=fwb.Rsquared.Ordinary;
    r2t(end+1)=ft.Rsquared.Ordinary;
end

plot(cwb.*cpwb,'b');
plot(ct .* cpt,'r');