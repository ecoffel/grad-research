% method from http://andrew.rsmas.miami.edu/bmcnoldy/Humidity.html

function [wb, rh] = wbFromDewpt(temp, dewpt)
    
    rh = 100*(exp((17.625*dewpt)/(243.04+dewpt))/exp((17.625*temp)/(243.04+temp)));
    
    wb = temp * atan(0.151977 * sqrt(rh + 8.313659)) + ...
                                     atan(temp + rh) - atan(rh - 1.676331) + ...
                                     0.00391838*(rh^(1.5)) * atan(0.023101*rh) - 4.686035;
end