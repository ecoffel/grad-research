function [nancorrval] = nancorr(x, y)
    ind = intersect(find(~isnan(x)), find(~isnan(y)));
    nancorrval = corr(x(ind), y(ind));
end