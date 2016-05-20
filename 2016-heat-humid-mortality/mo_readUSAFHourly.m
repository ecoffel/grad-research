function obst = mo_readUSAFHourly(USAFName)

fid = fopen(USAFName, 'r');
x = fread(fid,inf,'uint8=>char')';
fclose(fid);

% parse x into observations in a data structure 
% find boundaries of each observation (newline character)
idxs = [0 strfind(x, char(10))];

% number of records is number of newlines found (subtract index 0)
nobs = length(idxs)-1;

% create data structure 
dat(nobs-1,1)=struct('station','*',...      
                   'wban','*',...          
                   'date','*',...       
                   'time','*',...           
                   'windDir',0,...           
                   'windSpd',0,...           
                   'windGst',0,...           
                   'ceil','*',...          
                   'sky','*',...           
                   'vsb',0,...                
                   'temp',0,...                
                   'dwpt',0,...                
                   'slp',0,...                 
                   'alt',0);

% populate structure by reading data records observation by observation 
for ii = 1:nobs-1,
  s = x(idxs(ii+1) + 1:idxs(ii+2) - 1); % copy next observation
  
  parts = strsplit(s);
  
  % remove any blank cells
  partsTrim = {};
  for p = 1:length(parts)
      if length(strtrim(parts{p})) == 0
          continue;
      else
          partsTrim{end+1} = strtrim(parts{p});
      end
  end
  
  parts = partsTrim;
  
  % parse the observation
  dat(ii).station = parts{1};
  dat(ii).wban = parts{2};
  dat(ii).date = parts{3}(1:8);
  dat(ii).time = parts{3}(9:12);
  
  if length(strfind(parts{4}, '*')) == 0
      dat(ii).windDir = str2num(parts{4});
  else
      dat(ii).windDir = NaN;
  end
  
  if length(strfind(parts{5}, '*')) == 0
      dat(ii).windSpd = str2num(parts{5});
  else
      dat(ii).windSpd = NaN;
  end
  
  if length(strfind(parts{6}, '*')) == 0
      dat(ii).windGst = str2num(parts{6});
  else
      dat(ii).windGst = NaN;
  end
  
  if length(strfind(parts{7}, '*')) == 0
      dat(ii).ceil = str2num(parts{7});
  else
      dat(ii).ceil = NaN;
  end
  
  if length(strfind(parts{8}, '*')) == 0
      dat(ii).sky = parts{8};
  else
      dat(ii).sky = '*';
  end
  
  if length(strfind(parts{12}, '*')) == 0
      dat(ii).vsb = str2num(parts{12});
  else
      dat(ii).vsb = NaN;
  end
  
  if length(strfind(parts{22}, '*')) == 0
      dat(ii).temp = (str2num(parts{22}) - 32) * 5.0/9.0;
  else
      dat(ii).temp = NaN;
  end
  
  if length(strfind(parts{23}, '*')) == 0
      dat(ii).dwpt = (str2num(parts{23}) - 32) * 5.0/9.0;
  else
      dat(ii).dwpt = NaN;
  end
  
  if length(strfind(parts{24}, '*')) == 0
      dat(ii).slp = str2num(parts{24});
  else
      dat(ii).slp = NaN;
  end
  
  if length(strfind(parts{25}, '*')) == 0
      dat(ii).alt = str2num(parts{25});
  else
      dat(ii).alt = NaN;    
  end
  
  if mod(ii, 1000) == 0
      ['processed ' num2str(ii) ' lines...']
  end
  
end  % for

% create table from structure 
obst=struct2table(dat);

end % function


