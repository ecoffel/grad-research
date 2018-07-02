
relHum = 10:5:100;
temps = 15:50;
hi = [];
wb = [];

for t = 1:length(temps)
    for r = 1:length(relHum)
        
        T_c = temps(t);
        T_f = temps(t) * 9/5 + 32;
        RH = relHum(r);

        if T_f > 80 & T_f < 110 & RH > 40
            hi(t, r) = -42.379 + 2.04901523*T_f + 10.14333127*RH  - ...
                            .22475541*T_f*RH - .00683783*T_f*T_f - .05481717*RH*RH + ...
                            .00122874*T_f*T_f*RH + .00085282*T_f*RH*RH - .00000199*T_f*T_f*RH*RH;

            if T_f > 80 & T_f < 112 & RH < 13
                hi(t, r) = hi(t, r) - ((13-RH)/4)*sqrt((17-abs(T_f-95))/17);
            end
        else
            hi(t, r) = 0;
        end
           
        wb(t, r) = kopp_wetBulb(T_c, 101325, RH, 1) * 9/5 + 32;
        
    end
end

%csvwrite('heat-index.csv', hi);
csvwrite('wet-bulb.csv', wb);