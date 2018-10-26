% name: run_climada_ed_git
% Main Script to run CLIMADA CD. (version on github)
% for Carbon Delta AG
%
% Before execution:
%       Copy /climada_modules/advanced/code/CD_enterprise_location_risk/config_climada_ed.m
%       to climada_modules/ and customize parameters and settings if required.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PURPOSE:
% Do damage calculation for Carbon Delta's enterprise locations using CLIMADA in octave (try...)
% In case it fails, the error message is written to climada_data/results/ErrorLogs/ (catch...)
%
% CALLING SEQUENCE (in octave):
% 	1. set filename variable (filename = '----.xlsx')
%	2. execute this script
%  
% EXAMPLE:
%	filename = 'all_chunked1_of_31.xlsx';
%	run_climada_ed_git
%
% OUTPUT:
%	A spreadsheet with the annual expected damages per location is saved in 
%	/climada_node/climada_data/results/
%	In the case of the example above, the output file would be called:
%	/climada_node/climada_data/results/ExpectedDamage_all_chunked1_of_31.xlsx 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHANGELOG:
% 20170108 Samuel Eberenz eberenz@posteo.eu, init.
% 20180906 Samuel Eberenz eberenz@posteo.eu, new damage functions
%			(calibration V.04_20181011 based on shape from emanuel et al, TC only)
% 20181026 Samuel Eberenz eberenz@posteo.eu, added explanations in header and 
%		     	changed name of error-log file to allow for several error logs per day.
% 20181026 Samuel Eberenz eberenz@posteo.eu, commited as run_climada_ed_git to github
%               changed location of config_file
%-

try
    % startup of CLIMADA environment:
    if ~exist('climada_global','var') || climada_global.octave_mode
        cd (['~' filesep 'climada_node' filesep 'climada']);
        startup;
    end
    % call config file /climada_modules/config_climada_ed.m and set missing parameters:
    run ([climada_global.modules_dir filesep 'config_climada_ed.m']);

    if ~exist('filename','var')
        filename = inputfilename_default; % entities file: file with locations and coordinates
    end
    printf('input file: %s \n',filename);
    if ~exist('outputfilename','var') % file to write results to
        outputfilename =  [climada_global.results_dir filesep outputfilename_default filename]; 
    end
    if save_EDS_to_mat || save_entity_to_mat
        outputfilename_mat = strsplit(outputfilename,'.');
        outputfilename_mat = outputfilename_mat{1};
    end
    % performing a climada_git_pull every week to keep CLIMADA up to date:
    try
        load([climada_global.results_dir filesep 'timestamp.mat']);
        delta_time = now - timestamp;
    catch
        delta_time = 8;
    end
    if delta_time > 7 % if last git pull has been more than 1 week ago... 
        climada_git_pull; % ...pulling latest version of CLIMADA from github 
        timestamp = now;
        save([climada_global.results_dir filesep 'timestamp.mat'], 'timestamp');
    end
    clear timestamp delta_time

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% beginning of core script
    % load files
    hazard = climada_hazard_load(hazardDef.fn{1});
    vulnerability_config = climada_entity_read(vulnerability_config_fn,hazard);
    entity.assets = climada_assets_read(filename,hazard);

    % build full entity set (except for damage functions)
    % entity.damagefunctions = vulnerability_config.damagefunctions;
    entity.discount = vulnerability_config.discount;
    entity.names = vulnerability_config.names;
    entity.measures = vulnerability_config.measures;
    clear vulnerability_config
    % compute damage functions:
    % load damage functions parameters per region:
    df_parameters_fn_strsplit = strsplit(df_parameters_fn,'.');
    if length(df_parameters_fn_strsplit)~=2 || isequal(df_parameters_fn_strsplit,'mat') 
	load(df_parameters_fn); % works for .mat file as input...
    else % else input has to be an xlsx-file.... use climada_xlsread:
	df_parameters = climada_xlsread(0,df_parameters_fn);
	v0 = df_parameters.v0;
	v_half = df_parameters.v_half;
	scale = df_parameters.scale;
	basinID1 = df_parameters.region_ID;
    end
	clear df_param*;
    for i=1:length(basinID1) % set damage functions for different basins
        if i==1
            entity.damagefunctions = climada_tc_damagefun_emanuel2011([],v0(i),v_half(i),scale(i),basinID1(i),[],[],0);
        else
            entity.damagefunctions = climada_tc_damagefun_emanuel2011(entity.damagefunctions,v0(i),v_half(i),scale(i),basinID1(i),[],[],0);
        end
    end
    
    % set damagefunction TC001 to default for all locatons without a country or not in the regions...:
    if min(entity.damagefunctions.DamageFunID)>1
    	entity.damagefunctions = climada_tc_damagefun_emanuel2011(entity.damagefunctions,25.7,25.7+49,1,1,[],[],0);
    end
   
   	% load variable regions for mapping of countries to world / TC regions:
    load(country_mapping_fn);
    %%%% TODO: compare these two fields for mapping
   
%     entity.assets.ID_CCA3 and regions.countries.ISO3
%     set  entity.assets.DamageFunID
    for i=1:length(regions.countries.ISO3)
        ind = find(strcmp(entity.assets.ID_CCA3, regions.countries.ISO3{i}));
        if ~isempty(ind)          
            entity.assets.DamageFunID(ind) = regions.countries.TCBasinID(i);
        end
    end

    % initiate output_matrix with candidate_id 
    output_matrix = cell(length(entity.assets.Value)+1,length(hazardDef.fn)+4);
    meta_matrix = cell(2,length(hazardDef.fn)+4);
    output_matrix{1,1} = 'candidate_id';
    output_matrix{1,2} = 'Owner';
    output_matrix{1,3} = 'ISIN';
    output_matrix{1,4} = 'ID_CCA3';
    
    meta_matrix{1,1} = hazard.reference_year;
    for j=1:length(entity.assets.Value)
        % str = strsplit(entity.assets.Owner{j},', '); % out-dated
        output_matrix{1+j,1} = entity.assets.candidate_id(j); % 'candidate_id'
        output_matrix{1+j,2} = entity.assets.Owner{j};  % str{1};                        % 'Owner'
        output_matrix{1+j,3} = entity.assets.ISIN{j}; % strrep(str{2},' [Enterprise]','');        % 'ISIN'
        output_matrix{1+j,4} = entity.assets.ID_CCA3{j};      % 'ID_CCA3' country ID
    end

    % compute expected annual damage per location (loop over hazards)
    % and write to output_matrix
    for i = 1:length(hazardDef.fn)
        if i>1, hazard = climada_hazard_load(hazardDef.fn{i}); end

        EDS=climada_EDS_calc(entity, hazard); % damage computation (climada core module)

        output_matrix{1,i+4} = hazardDef.headers{i};
        meta_matrix{1,i+4} = [hazardDef.headers{i} '_year'];
        meta_matrix{2,i+4} = hazard.reference_year;
        for j = 1:length(entity.assets.Value)
            output_matrix{1+j,i+4} = EDS.ED_at_centroid(j);
        end
        if save_EDS_to_mat % saving results to MAT files if set to 1 in config
            save('-mat7-binary', [outputfilename_mat '_EDS_' hazardDef.headers{i} '.mat'],'EDS');
        end
        clear hazard EDS
    end
    if save_entity_to_mat % saving entity to MAT file if set to 1 in config
    	save('-mat7-binary',[outputfilename_mat '_entity.mat'],'entity');
    end
    clear entity str

    meta_matrix{1,1} = 'Version';
    meta_matrix{1,2} = 'Date';
    meta_matrix{1,3} = 'Lead';
    meta_matrix{1,4} = 'Comment';
    meta_matrix{2,1} = meta.climada_config_version; % 'Version'
    meta_matrix{2,2} = datestr(date,'yyyymmdd'); % 'Date YYYYMMDD'
    meta_matrix{2,3} = meta.lead;
    meta_matrix{2,4} = meta.comment;

    % save to xlsx file --> output_filename
    if exist(outputfilename,'file')
	delete(outputfilename);
    end
    if climada_global.octave_mode
        xlswrite(outputfilename,output_matrix,'results');
        xlswrite(outputfilename,meta_matrix,'meta_data');
    else, warning('Output was not exported to XLSX!')
    end

    printf('output file: %s \n',outputfilename);
    % end of core script
%%%%%%%%%%%%%%%%%%%%%%%%%%%
catch ME % In case core script fails, the error message is written to a text file in climada_data/results/ErrorLogs/ 
    try
        myfile = fopen([climada_global.results_dir '/ErrorLogs/Climada_Error_Message_' datestr(now,30) '.txt'],'w'); % Open the file 
    catch 
        try % if climada environment not loaded correctly, write to hardwired location (adjust if machine changes!):
            myfile = fopen(['/home/climada/climada_node/climada_data/results/ErrorLogs/Climada_Error_Message_' datestr(now,30) '.txt'],'w'); 
        catch
            myfile = fopen(['Climada_Error_Message_' datestr(now,30) '.txt'],'w'); % If this fails as well, create error log in current folder.
        end
    end
    try 
        fprintf(myfile,'ERROR: %s \n %s \n in: %s \n line: %i \n',ME.identifier,ME.message,ME.stack(end).name,ME.stack(end).line); % Write a description 
    end
    fprintf('ERROR: %s \n %s \n in: %s \n line: %i \n',ME.identifier,ME.message,ME.stack(end).name,ME.stack(end).line); % Write a description 
    fclose(myfile); % Close the file (very important) 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
