function obst = bi_readRadiosonde(fname)

    fid = fopen(fname, 'r');
    x = fread(fid,inf,'uint8=>char')';
    fclose(fid);

    % parse x into observations in a data structure 
    % find boundaries of each observation (newline character)
    idxs = [0 strfind(x, char(10))];

    % number of records is number of newlines found (subtract index 0)
    nobs = length(idxs)-1;

    % create data structure 
    dat =         struct('station', '*',...      
                         'year', '*',...          
                         'month', '*',...       
                         'day', '*',...           
                         'hour', 0,...           
                         'numLevels', 0,...           
                         'data', []);   

    % populate structure by reading data records observation by observation
    obsCnt = 0;
    curObj = struct('pressure', [], ...  % mb * 100
                      'geopot', [], ...        % m
                      'temp', [], ...          % deg C * 10
                      'dwptDep', [], ...       % deg C * 10
                      'windDir', [], ...       % 0 - 360
                      'windSpd', []);          % (m/s) * 10
                  
    for ii = 1:nobs-1,
      s = x(idxs(ii) + 1:idxs(ii+1) - 1); % copy next observation

      if strcmp(s(1), '#')
          if obsCnt > 0
              dat(obsCnt).data = curObj;
          end
          
          obsCnt = obsCnt + 1;

          % parse the observation header line
          dat(obsCnt).station = s(2:6);
          dat(obsCnt).year = str2num(s(7:10));
          dat(obsCnt).month = str2num(s(11:12));
          dat(obsCnt).day = str2num(s(13:14));
          dat(obsCnt).hour = str2num(s(15:16));
          dat(obsCnt).numLevels = str2num(s(21:24));

          curObj = struct('pressure', [], ...  % mb * 100
                      'geopot', [], ...        % m
                      'temp', [], ...          % deg C * 10
                      'dwptDep', [], ...       % deg C * 10
                      'windDir', [], ...       % 0 - 360
                      'windSpd', []);          % (m/s) * 10
      else
          % parse the data record for each level
          curObj.pressure(end+1) = str2num(s(3:8));
          curObj.geopot(end+1) = str2num(s(10:14));
          curObj.temp(end+1) = str2num(s(16:20));
          curObj.dwptDep(end+1) = str2num(s(22:26));
          curObj.windDir(end+1) = str2num(s(27:31));
          curObj.windSpd(end+1) = str2num(s(32:36));
      end
      
      if mod(ii, 1000) == 0
          ['processed ' num2str(ii) ' lines...']
      end

    end  % for
    
    if obsCnt > 0
        dat(obsCnt).data = curObj;
    end
    
    % create table from structure 
    obst=struct2table(dat);

end % function


