
relHum = 10:5:100;
temps = 15:50;
hi = [];
wb = [];

for t = 1:length(temps)
    for r = 1:length(relHum)
        
        T_c = temps(t);
        T_f = temps(t) * 9/5 + 32;
        RH = relHum(r);

        hi(t, r) = (0.5 * (T_f + 61.0 + ((T_f-68.0)*1.2) + (RH*0.094)) + T_f) / 2.0;
        
        if hi(t, r) > 80
            hi(t, r) = -42.379 + 2.04901523*T_f + 10.14333127*RH  - ...
                            .22475541*T_f*RH - .00683783*T_f*T_f - .05481717*RH*RH + ...
                            .00122874*T_f*T_f*RH + .00085282*T_f*RH*RH - .00000199*T_f*T_f*RH*RH;

            if T_f > 80 && T_f < 112 && RH < 13
                hi(t, r) = hi(t, r) - ((13.0-RH)/4)*sqrt((17.0-abs(T_f-95.0))/17);
            elseif T_f > 80 && T_f < 87 && RH > 85
                hi(t, r) = hi(t, r) +  ((RH-85)/10) * ((87-T_f)/5);
            end
        end
           
        wb(t, r) = kopp_wetBulb(T_c, 101325, RH, 1);
    end
end

wb = wb .* 9/5 + 32;

hi(wb > 35.5 * 9/5 + 32 | isnan(wb) | hi < 80) = 0;
wb(wb > 35.5 * 9/5 + 32 | hi == 0) = 0;

csvwrite('heat-index.csv', round(hi));
csvwrite('wet-bulb.csv', round(wb));