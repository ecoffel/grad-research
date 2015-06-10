function [ret] = kToc(data)
    ret = {data{1}, data{2}, data{3}-273.15};
end