function obst = mo_readISDHourly(fname)

fid = fopen(fname, 'r');
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
                   'temp',0,...                
                   'dwpt',0);

% populate structure by reading data records observation by observation 
for ii = 1:nobs-1,
  s = x(idxs(ii+1) + 1:idxs(ii+2) - 1); % copy next observation
  
  parts = strsplit(s, ',');
  
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
  dat(ii).station = strrep(parts{3}, '"', '');
  dat(ii).wban = strrep(parts{4}, '"', '');
  dat(ii).date = strrep(parts{5}, '"', '');
  dat(ii).time = strrep(parts{6}, '"', '');
  
  if length(strfind(parts{27}, '*')) == 0
      dat(ii).temp = (str2num(strrep(parts{27}, '"', '')))/10;
  else
      dat(ii).temp = NaN;
  end
  
  if length(strfind(parts{29}, '*')) == 0
      dat(ii).dwpt = (str2num(strrep(parts{29}, '"', ''))/10);
  else
      dat(ii).dwpt = NaN;
  end
  
  if mod(ii, 1000) == 0
      ['processed ' num2str(ii) ' lines...']
  end
  
end  % for

% create table from structure 
obst=struct2table(dat);

end % function


