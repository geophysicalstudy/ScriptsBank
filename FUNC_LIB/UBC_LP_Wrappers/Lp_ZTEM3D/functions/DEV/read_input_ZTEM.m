function [ndata,beta_in,alpha,phid,phi,meshfile,obs_file,logfile,topo,target]=read_input


% addpath ([home_dir '\functions']);  
file_list=ls;

mesh = [];
logfile = [];
topo = [];
topo_model = [];
topo_check = [];
obs_file = [];
phid = [];
phi = [];
target = [];
% Extract file names
for ii = 1:size(file_list,1)-2;

    look_at = strtrim(file_list(ii+2,:));

        if strcmp(look_at,'mt3dinv.log')==1

            logfile =look_at;

        elseif strcmp(look_at(end-2:end),'msh')==1

            meshfile = look_at;

        elseif strcmp(look_at(end-3:end),'topo')==1

            topo =  look_at;

        elseif strcmp(look_at,'topo_model.txt')==1

            topo_check =  look_at;

        elseif strcmp(look_at(end-2:end),'obs')==1

            obs_file =  look_at;

        end

end


    if isempty(topo_check)==1

    % Run a topo check if not done already
    fprintf('Computing Topocheck - might take few minutes')
    dos (['topocheck ' meshfile ' ' topo])
    end




%% Read information from log file
fid=fopen(logfile,'rt');


max_num_lines = 30000;
% Go through the log file and extract data and the last achieved misfit
for ii=1:max_num_lines         	
line=fgets(fid); %gets next line 

    if line==-1
        fprintf('File ended at line %i\n',ii);
        fprintf('Did not find the information needed - review log file\n')
        break
    end

    if length(strtrim(line))>=length('# of data:')
        description = strtrim(line);
        if strcmp(description(1:10),'# of data:')==1
            ndata = str2num(description(11:end));
        end
    end

    if length(strtrim(line))>=length('========== BETA = ')
        description = strtrim(line);
        if strcmp(description(1:18),'========== BETA = ')==1
            beta_in = str2num(description(19:31));
        end
    end

    % Extract alpha values
    if length(strtrim(line))>=length('alpha (s,x,y,z):')
        description = strtrim(line);
        if strcmp(description(1:16),'alpha (s,x,y,z):')==1
            alpha = str2num(description(18:end));
        end
    end

    if length(strtrim(line))>=length('phi_d:')
        description = strtrim(line);
        if strcmp(description(1:6),'phi_d:')==1
            phid = str2num(description(7:end));
        end
    end

    if length(strtrim(line))>=length('objective function:')
        description = strtrim(line);
        if strcmp(description(1:19),'objective function:')==1
            phi = str2num(description(20:end));
        end
    end
    
    if length(strtrim(line))>=length('target misfit:')
        description = strtrim(line);
        if strcmp(description(1:14),'target misfit:')==1
            target = str2num(description(15:end));
        end
    end

    if isempty(phid)==0 && isempty(phi)==0
        break
    end

end
fclose(fid);


        