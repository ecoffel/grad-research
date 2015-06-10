%%% Converting new NARCCAP RCM netCDF files to mat files
tic

%//////////////////////////////////////////////////////////////////////////
%//////////////////////////////////////////////////////////////////////////

dir1 = dir;
filname2 = {dir1(3:end).name};
filname = {};
for i = 1:length(filname2)
    if strcmp(filname2{i}(end-1:end),'nc')
        filname = [filname filname2{i}];
    end
end

leapd1 = 7; leapd2 = 7;

%%%loops through files
for b = 1:length(filname)
    
    %%%extracts variable name, gcm and rcm from file name
    uscore = 0; variable2 = []; gcm = []; rcm = []; plvl = [];
    for i = 1:(length(filname{b}) - 14)
        %%%counts underscores
        if strcmp(filname{b}(i),'_')
            uscore = uscore + 1; continue; end;
        %%%stores variable name
        if uscore == 0
            variable2 = [variable2 filname{b}(i)]; end;
        %%%stores rcm name
        if uscore == 1
            rcm = lower([rcm filname{b}(i)]); end;
        %%%stores gcm name
        if uscore == 2
            gcm = upper([gcm filname{b}(i)]); end;
        %%%stores plvl (if it exists)
        if uscore == 3 && ~strcmp(filname{b}(i),'p')
            plvl = [plvl filname{b}(i)]; end;
    end %%% extract names - loop
    
    %%%designate new variable names
    switch variable2
        case {'pr','zg500'}
            variable = variable2;
        case 'tas'
            variable = 'tmp2m';
        case 'tasmax'
            variable = 'tmp2mmax';
        case 'tasmin'
            variable = 'tmp2mmin';
        case 'psl'
            variable = 'mslp';
        case 'rsds'
            variable = 'dswrf';
        case 'ua'
            eval(['variable = ''uwind' plvl ''';']);
        case 'va'
            eval(['variable = ''vwind' plvl ''';']);
        case 'zg'
            eval(['variable = ''zg' plvl ''';']);
        case 'snd' 
	    variable = 'snd';
        case 'swe' 
	    variable = 'swe';
        case 'mrso' 
	    variable = 'mrso';
	case 'hfss'
	    variable = 'hfss'; 
	case 'hfls'
	    variable = 'hfls'; 
	case 'rsus'
	    variable = 'rsus'; 
	case 'rlus'
	    variable = 'rlus'; 
	case 'rlds'
	    variable = 'rlds'; 
        otherwise
            disp(' '); disp('*'); disp('**');
            disp('*** Variable name not logged in script. See section starting at line 34 ***');
            return;
    end       

    %loads .nc file
    eval(['disp(''-- ' filname{b}(1:end-3) ' started:  ' datestr(now) ' --'')']); disp(' ');
    eval(['ncid = netcdf.open(''' filname{b} ''',''nowrite'');']);
    
    %%%finds number of dimensions, variables, attributes unlimdimid
    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid);
    
    %%%stores NetCDF dimension data
    for a = 1:ndims
        [dimname, dimlen] = netcdf.inqDim(ncid,a-1);
        dimmInfo{a,1} = dimname;
        dimmInfo{a,2} = dimlen;
    end
    
    %%%finds variables' info in netCDF file
    for i = 1:nvars
        [varname,xtype,dimids,natts] = netcdf.inqVar(ncid,i-1);
        vaarInfo{i,1} = varname;
        vaarInfo{i,2} = dimids;
        vaarInfo{i,3} = natts;
    end
    
    %%%finds the dimension ID and dimension size for different variables
    timeInfo(1,1) = find(strcmp(vaarInfo(:,1),'time')) - 1;
    for z = 1:length(vaarInfo{timeInfo(1,1)+1,2})
        timeInfo(1,z+1) = dimmInfo{vaarInfo{timeInfo(1,1)+1,2}(z)+1,2};
    end
    latInfo(1,1) = find(strcmp(vaarInfo(:,1),'lat')) - 1;
    for zz = 1:length(vaarInfo{latInfo(1,1)+1,2})
        latInfo(1,zz+1) = dimmInfo{vaarInfo{latInfo(1,1)+1,2}(zz)+1,2};
    end
    lonInfo(1,1) = find(strcmp(vaarInfo(:,1),'lon')) - 1;
    for y = 1:length(vaarInfo{lonInfo(1,1)+1,2})
        lonInfo(1,y+1) = dimmInfo{vaarInfo{lonInfo(1,1)+1,2}(y)+1,2};
    end
    eval(['datInfo(1,1) = find(strcmp(vaarInfo(:,1),''' variable2 ''')) - 1;']);
    for yy = 1:length(vaarInfo{datInfo(1,1)+1,2})
        datInfo(1,yy+1) = dimmInfo{vaarInfo{datInfo(1,1)+1,2}(yy)+1,2};
    end
    
    %%%finds basedate
    timeUnits = netcdf.getAtt(ncid,timeInfo(1,1),'units');
    if strcmp(timeUnits(19),'-')
        [basedate(1,1)] = str2double(timeUnits(12:15));
        [basedate(1,2)] = str2double(timeUnits(18));
        [basedate(1,3)] = str2double(timeUnits(21));
        [basedate(1,4)] = 0;
        [basedate(1,5)] = 0;
        [basedate(1,6)] = 0;
    else if strcmp(timeUnits(18),'-')
            [basedate(1,1)] = str2double(timeUnits(12:15));
            [basedate(1,2)] = str2double(timeUnits(17));
            [basedate(1,3)] = str2double(timeUnits(19));
            [basedate(1,4)] = 0;
            [basedate(1,5)] = 0;
            [basedate(1,6)] = 0;
        else
            disp('*** Warning: Basedate Misaligned ***')
            keyboard
        end
    end

    %%%sets start and end index for extraction
    switch variable
        case {'tmp2mmax','tmp2mmin'}
            %ideal time vector
            t(:,1) = netcdf.getVar(ncid,timeInfo(1),[0]):1:netcdf.getVar(ncid,timeInfo(1),[timeInfo(2) - 1]);
        otherwise

            if ~strcmp(rcm,'hrm3')
	    disp('test')
                %%%ideal time vector
                t(:,1) = netcdf.getVar(ncid,timeInfo(1),[0]):0.125:netcdf.getVar(ncid,timeInfo(1),[timeInfo(2) - 1]);
            else
                %%%startind
                if netcdf.getVar(ncid,timeInfo(1),[0]) ~= round(netcdf.getVar(ncid,timeInfo(1),[0]))
                    startind = netcdf.getVar(ncid,timeInfo(1),[0]);
                else
                    startind = netcdf.getVar(ncid,timeInfo(1),[0]) + 0.125;
                end
                
                %%%endind
                if netcdf.getVar(ncid,timeInfo(1),[timeInfo(2) - 1]) == round(netcdf.getVar(ncid,timeInfo(1),[timeInfo(2) - 1]))
                    endind = netcdf.getVar(ncid,timeInfo(1),[timeInfo(2) - 1]);
                else
                    endind = round(netcdf.getVar(ncid,timeInfo(1),[timeInfo(2) - 1]));
                end

                
                %%%ideal time vector
                t(:,1) = startind:0.125:endind;
            end
    end

    %%%stores the actual time vector
    tt = floor(netcdf.getVar(ncid,timeInfo(1),[0],[timeInfo(2)])*1000)/1000; ttcount = 1;
    dcount = 1; %counts days of a month so it can be reset at end of month
    miss = 1; %counts number of missing data points - reset at end of loop
    dday = 0; %counts up to 30 days and is reset at end on month
    
    %%%checks for start of actual time vector at 0Z instead of 3Z and adjusts
    if (tt(1) < t(1))
        if (t(1) - tt(1)) == 0.125
            tt = tt + 0.125;
        else
            disp('*** Unexpected start and end times ***');
            %check t(1)/tt(1) and t(end)/tt(end)
            return;
        end
    end

    %%%data extraction
    for e = 1:length(t)

    %e
       %%%HadCM3 condition
        if strcmp(gcm,'hadcm3')
            %%%day tracker for saving at end of 30 days
           if ~strcmp(variable,'tmp2mmax') || ~strcmp(variable,'tmp2mmin')
                dday = dday + 0.125; end;
            if strcmp(variable,'tmp2mmax') || strcmp(variable,'tmp2mmin')
                dday = dday + 1; end;
        end

        %%%checks for missing data and then stores data
        if t(e) == tt(ttcount) %%% ideal time index == real time index

            %%%finds filled missing values
            filledmiss = find(netcdf.getVar(ncid,datInfo(1),[0 0 (ttcount-1)],[datInfo(2) datInfo(3) 1]) > 1000000);

            %%%for the if statement below, rather than making the whole
            if ~isempty(filledmiss)
               
                %%%replaces filledmissing values with NaNs
                temphold = netcdf.getVar(ncid,datInfo(1),[0 0 (ttcount-1)],[datInfo(2) datInfo(3) 1]);
                temphold(filledmiss) = NaN;
                eval([ variable '(dcount,:,:) = temphold;']);
                dcount = dcount + 1;
                if e < timeInfo(2)
                    ttcount = ttcount + 1; end;
                if e >= timeInfo(2)
                    ttcount = timeInfo(2); end;
                %missvar(miss,1) = cellstr(variable);
                %missdat(miss,:) = datevec(datenum(basedate) + t(e,1));
                %miss = miss + 1;
            else                
                eval([ variable '(dcount,:,:) = netcdf.getVar(ncid,datInfo(1),[0 0 (ttcount-1)],[datInfo(2) datInfo(3) 1]);']);
                if e < timeInfo(2)
                    ttcount = ttcount + 1; end;
                if e >= timeInfo(2)
                    ttcount = timeInfo(2); end;
                dcount = dcount + 1;
            end
        else if t(e) ~= tt(ttcount)
               
                %%% fills missing time with NaNs
                eval([ variable '(dcount,:,:) = ones(datInfo(2),datInfo(3)) * NaN;']);
                dcount = dcount + 1;
                %missvar(miss,1) = cellstr(variable);
                %missdat(miss,:) = datevec(datenum(basedate) + t(e,1));
                %miss = miss + 1;
            else
                disp('*** Warning: Time Index Mismatch ***');
            end %%% ideal time index ~= real time index
        end %%% checking for real time index == ideal time index

        %%% calculates date and stores in caldate with form [yyyy mm dd hh mm ss]
        if ~strcmp(gcm,'NCEP')
            if ~strcmp(gcm,'hadcm3')
                switch variable                    
                    case {'tmp2mmax','tmp2mmin'}
                        if ~exist('leapd1','var')
                            leapd1 = 0; leapd2 = 0; end;
                        caldate1 = datevec(datenum(basedate) + t(e,1) + 1 + leapd1);
                        %%%resets leapd if starting at the beginning of a new 30 yrs
                        if (caldate1(1) == 1968 && caldate1(2) == 1) || (caldate1(1) == 2038 && caldate1(2) == 1)
                            leapd1 = 0; leapd2 = 0;
                            caldate1 = datevec(datenum(basedate) + t(e,1) + 1 + leapd1);
                        end
                        %%% corrects for leap days
                        if ((caldate1(2) == 2) && (caldate1(3) == 29))
                            leapd1 = leapd1 + 1;
                            caldate1 = datevec(datenum(basedate) + t(e,1) + 1 + leapd1);
                        end
                        caldate2 = datevec(datenum(basedate) + t(e,1) + leapd2);
                        %%% corrects for leap days
                        if ((caldate2(2) == 2) && (caldate2(3) == 29))
                            leapd2 = leapd2 + 1;
                            caldate2 = datevec(datenum(basedate) + t(e,1) + leapd2);
                        end
                        
                    otherwise                        
                        if ~exist('leapd1','var')
                            leapd1 = 0; leapd2 = 0; end;
                        caldate1 = datevec(datenum(basedate) + t(e,1) + leapd1);
                        %%%resets leapd if starting at the beginning of a new 30 yrs
                        if (caldate1(1) == 1968 && caldate1(2) == 1) || (caldate1(1) == 2038 && caldate1(2) == 1)
                            leapd1 = 0; leapd2 = 0;
                            caldate1 = datevec(datenum(basedate) + t(e,1) + leapd1);
                        end;
                        %%% corrects for leap days
                        if ((caldate1(2) == 2) && (caldate1(3) == 29))
                            leapd1 = leapd1 + 1;
                            caldate1 = datevec(datenum(basedate) + t(e,1) + leapd1);
                        end
                        if e ~= 1
                            caldate2 = datevec(datenum(basedate) + t(e-1,1) + leapd2);
                            %%% corrects for leap days
                            if ((caldate2(2) == 2) && (caldate2(3) == 29))
                                leapd2 = leapd2 + 1;
                                caldate2 = datevec(datenum(basedate) + t(e,1) + leapd2);
                            end
                        else
                            caldate2 = datevec(datenum(basedate) + t(e,1) + leapd2);
                            %%% corrects for leap days
                            if ((caldate2(2) == 2) && (caldate2(3) == 29))
                                leapd2 = leapd2 + 1;
                                caldate2 = datevec(datenum(basedate) + t(e,1) + leapd2);
                            end
                        end
                end

            else %%%date calculation for hadcm3 files

                if e == 1 %%%only for e == 1, b/c it just counts days from here
                    yyears = (t(e)/360);
                    leapyears = leapyear(basedate(1):(basedate(1) + yyears));
                    addDays = (yyears*5) + sum(leapyears);
                    caldate1 = datevec(datenum(basedate) + t(e,1) + addDays);
                    caldate = [caldate1(1) caldate1(2)];
                end
            end
        else %%% date calculation for NCEP files
            switch variable
                case {'tmp2mmax','tmp2mmin'}
                    caldate1 = datevec(datenum(basedate) + t(e,1) + 1);
                    caldate2 = datevec(datenum(basedate) + t(e,1));
                    
                otherwise
                    caldate1 = datevec(datenum(basedate) + t(e,1));
                    if e ~= 1
                        caldate2 = datevec(datenum(basedate) + t(e-1,1));
                    else
                        caldate2 = datevec(datenum(basedate) + t(e,1));
                    end
            end
            
        end %%% date calculation conditions

        %%%end of the month operations
        if ~strcmp(gcm,'hadcm3')      


            if caldate1(2) ~= (caldate2(2)) %%% condition for end of month
            

%if ccheck == 0;                
%keyboard
                %%%% creates missing data variable for whole .nc file
                %if exist('missdat','var')
                %    if ~exist('fileMissingDat','var')
                %        fileMissingDat = missdat;
                %        fileMissingVar = missvar;
                %    else
                %        fileMissingDat = [fileMissingDat; missdat];
                %        fileMissingVar = [fileMissingVar; missvar];
                %    end
                %end
                
               %%%convert data from 3 hourly to daily
               switch variable2
                   %%% non-cumulative data
                   case {'tas','zg500','zg','psl','ua','va','rsds','snd','mrso','swe','hfss','hfls','rsus','rlus','rlds'}
                        eval([ variable ' = (' variable '(1:8:end,:,:) + ' variable '(2:8:end,:,:)'...
                        '+ ' variable '(3:8:end,:,:) + ' variable '(4:8:end,:,:) + ' variable '(5:8:end,:,:)'...
                       '+ ' variable '(6:8:end,:,:) + ' variable '(7:8:end,:,:) + ' variable '(8:8:end,:,:))/8;']);
                        
                    %%%cumulative data
                    case 'pr'
                        eval([ variable ' = ' variable '(1:8:end,:,:) + ' variable '(2:8:end,:,:)'...
                        '+ ' variable '(3:8:end,:,:) + ' variable '(4:8:end,:,:) + ' variable '(5:8:end,:,:)'...
                        '+ ' variable '(6:8:end,:,:) + ' variable '(7:8:end,:,:) + ' variable '(8:8:end,:,:);']);
                    
		    disp('done')

                    case {'tasmax','tasmin'}
                        %do nothing. Tmax/tmin data comes in as a daily value so it doesn't need to be summed or averaged.
                    
                    otherwise
                        disp(' '); disp('*'); disp('**');
                        disp('*** Variable name not logged in script. See section starting at line 317 ***');
                        return;                        
                end
                
                yyz = num2str(caldate2(1));
                mmz = num2str(caldate2(2));
                if caldate2(2) < 10
                    mmz = ['0' num2str(caldate1(2) - 1)]; end;
                
                %%%permutes data from (time x lon x lat) into (time x lat x lon)
                eval([ variable ' = permute(' variable ',[1 3 2]);']);
                
                %%%makes sure data is of class 'double'
                eval(['ttype = isa(' variable ',''double'');']);
                if ttype == 0
                    eval([ variable ' = double(' variable ');']); end;
                
                %%%creates directory if it doesn't exist
                %eval(['if ~exist(''//home/dbader/CCSR/Data/NARCCAP-new/' gcm '/' rcm '/rawfiles'',''dir'');'...
                %    'mkdir(''/home/dbader/CCSR/Data/NARCCAP-new'',''' gcm '/' rcm '/rawfiles'');end;']);
                
                eval(['if ~exist(''c:\svn-google\grad-narccap\' gcm '\' rcm '\rawfiles'',''dir'');'...
                    'mkdir(''c:\svn-google\grad-narccap\'',''' gcm '\' rcm '\rawfiles'');end;']);
               
                %%%saves data
                eval(['save c:\svn-google\grad-narccap\' gcm '\' rcm '\rawfiles\daily' variable ''...
                    '' gcm rcm yyz mmz ' ' variable ]);
                eval(['disp(''' variable ' ' gcm rcm '  ' yyz mmz ''')']);
                
                eval(['clear missdat missvar missDayMeans diurnalAnoms missing ' variable ]);
                
                dcount = 1; miss = 1;
            end %%% end of month condition
        else


            if dday == 30
                %%%% creates missing data variable for whole .nc file
                %if exist('missdat','var')
                %    if ~exist('fileMissingDat','var')
                %        fileMissingDat = missdat;
                %        fileMissingVar = missvar;
                %    else
                %        fileMissingDat = [fileMissingDat; missdat];
                %        fileMissingVar = [fileMissingVar; missvar];
                %    end
                %end

                %%%convert data from 3 hourly to daily
                switch variable2
                    %%% non-cumulative data
                    case {'tas','zg500','zg','psl','ua','va','rsds','snd','mrso','swe','hfss','hfls','rsus','rlus','rlds'}
                        eval([ variable ' = (' variable '(1:8:end,:,:) + ' variable '(2:8:end,:,:)'...
                        '+ ' variable '(3:8:end,:,:) + ' variable '(4:8:end,:,:) + ' variable '(5:8:end,:,:)'...
                        '+ ' variable '(6:8:end,:,:) + ' variable '(7:8:end,:,:) + ' variable '(8:8:end,:,:))/8;']);
                        
                    %%%cumulative data
                    case 'pr'
                        eval([ variable ' = ' variable '(1:8:end,:,:) + ' variable '(2:8:end,:,:)'...
                        '+ ' variable '(3:8:end,:,:) + ' variable '(4:8:end,:,:) + ' variable '(5:8:end,:,:)'...
                        '+ ' variable '(6:8:end,:,:) + ' variable '(7:8:end,:,:) + ' variable '(8:8:end,:,:);']);
                    
                    case {'tasmax','tasmin'}
                        %do nothing. tmax/tmin data comes in as a daily value so it doesn't need to be summed or averaged.
                    
                    otherwise
                        disp(' '); disp('*'); disp('**');
                        disp('*** Variable name not logged in script. See section starting at line 369 ***');
                        return;                        
                end
                
                yyz = num2str(caldate2(1));
                mmz = num2str(caldate2(2));
                if caldate(2) < 10
                    mmz = ['0' num2str(caldate2(2))]; end;
                
                %%%permutes data from (time x lon x lat) into (time x lat x lon)
                eval([ variable ' = permute(' variable ',[1 3 2]);']);
                
                %%%makes sure data is of class 'double'
                eval(['ttype = isa(' variable ',''double'');']);
                if ttype == 0
                    eval([ variable ' = double(' variable ');']); end;
                
                %%%creates directory if it doesn't exist
                eval(['if ~exist(''c:\svn-google\grad-narccap\' gcm '\' rcm '\rawfiles'',''dir'');'...
                    'mkdir(''c:\svn-google\grad-narccap\'',''' gcm '\' rcm '\rawfiles'');end;']);
                
                %%%saves data
                eval(['save c:\svn-google\grad-narccap\' gcm '\' rcm '\rawfiles\daily' variable ''...
                    '' gcm rcm yyz mmz ' ' variable ]);
                eval(['disp(''' variable ' ' gcm rcm '  ' yyz mmz ''')']);
                
                eval(['clear missdat missvar missvar missDayMeans diurnalAnoms missing ' variable ]);
                
                dcount = 1; miss = 1; dday = 0;
                %%%advances caldates
                if caldate(2) ~= 12
                    caldate(2) = caldate(2) + 1;
                else
                    caldate(1) = caldate(1) + 1; caldate(2) = 1;
                end
            end %%%end of dday == 30 condition
        end %%%end of month operations - loop
        
        clear caldate1 caldate2 filledmiss temphold
        
    end %length(t)-loop
    
    %%%saves missing data for GCM-rcm set
    %if exist('fileMissingDat','var')
    %    eval(['filname2 = ''/home/dbader/CCSR/Data/NARCCAP_done/' gcm '/' rcm '/' gcm rcm 'missingDatFile.mat'';']);
    %    if exist(filname2,'file')
    %        eval(['load /home/dbader/CCSR/DataNARCCAP_done/' gcm '/' rcm '/' gcm rcm 'missingDatFile']);
    %        missingData = [missingData; fileMissingDat];
    %        missingVar = [missingVar; fileMissingVar];
    %        eval(['save /home/dbader/CCSR/Data/NARCCAP_done/' gcm '/' rcm '/' gcm rcm 'missingDatFile.mat missingData missingVar']);
    %    else
    %        missingData = fileMissingDat; missingVar = fileMissingVar;
    %        eval(['save /home/dbader/CCSR/Data/NARCCAP_done/' gcm '/' rcm '/' gcm rcm 'missingDatFile.mat missingData missingVar']);
    %    end
    %end
    
    eval(['clear gcm rcm basedate vaar ncid datdim t tt dcount ttcount '...
        'startind endind caldate fileMissingDat missdat missvar timeUnits '...
        'missingData missinfVar timeInfo latInfo lonInfo datInfo vaarInfo '...
        'dimmInfo variable variable2 ' variable ]);
    
    disp(' ');
    eval(['disp(''-- ' filname{b}(1:end-3) ' complete:  ' datestr(now) ' --'')']); disp(' ');
    
end %filename{b}-loop
toc
