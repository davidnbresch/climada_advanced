function direct_subsector_risk=mrio_disaggregate_risk(direct_mainsector_risk,climada_mriot,aggregated_mriot, countries)
%
%MODULE:
%   climada_advanced
% NAME:
%   read_mriot
% PURPOSE:
%   Disaggregates a direct main sector risk (row-)vector with direct risk for each
%   main-sector/country combination back into a full resolution vector with
%   direct risk for ALL subsector/country combinations (with no. of sectors
%   coming from originally used mriot). Disaggregation is done based on each
%   subsector's contribution to total production of the respective main sector. 
%   Calculations are done country-wise.
%   
%   previous call: 
%       mrio_direct_risk_calc
%   next call:
%       mrio_leontief_calc 
%
% CALLING SEQUENCE:
%  
% EXAMPLE:
%   
%
% INPUTS:
%   direct_mainsector_risk: a row vector as produced from the core
%       climada risk calculations with direct risk of each main sector for each
%       country. Length has to be "no_of_main_sectors" * "no_of_countries"
%   climada_mriot: a climada mriot struct as produced by mrio_read_table
%   aggregated_mriot: an aggregated climada mriot struct as
%       produced by mrio_aggregate_table.
%   ALSO SEE COMMENTS BELOW ("GENERAL NOTES").   
%
% OPTIONAL INPUT PARAMETERS:
%   countries: a country or a list of countries as a cell array containing
%       country names or iso3 codes specifying which subset of countries one is 
%       interested in. If not provided, calculations are done for all
%       countries (as represented in the originally used mriot).
%       NOTE: if user asks for country which is not covered in the mriot
%       struct (i.e. it is subsummized into ROW) issue a warning of some
%       sort. Likely not in this function but earlier in the entire process
%       though...
% OUTPUTS:
%   direct_subsector_risk: a row vector containing direct risk for each
%       subsector/country combination covered in the original mriot. The
%       order of entries follows the same as in the entire process, i.e.
%       entry mapping is still possible via the climada_mriot.setors and
%       climada_mriot.countries arrays.
%  
%
% GENERAL NOTES:
%
% NO IN-DEPTH TESTING OF RESULTS CONDUCTED YET!
%
% POSSIBLE EXTENSIONS TO BE IMPLEMENTED:
% Could implement similar user-dialogue process as in
% mrio_aggregate_table in case mandatory arguments are not passed. For
% now function returns error if inputs are missing.
% 
% In terms of inputs, we actually only need total sector production for
% each country for both the main sectors and the subsectors... so it's
% not necessary to pass the entire mriot and aggregated mriot structures to
% the function as long as we have the data on total sector production. It
% might be more feasible to do these calculations outside the current
% function and only pass an array with the total productions. For now, such 
% an array is constructed herein. Parameters such as no. of countries could
% be extracted from this too... Probably, this would best be implemented in
% a dedicated helper function mrio_get_total_production or so...
%
% In case we don't use an aggregated table at all (see thoughts below), 
% we could think about defining the six climada sectors as a global variable 
% (added to the climada_global struct in the mrio_master function or so...
%
% Implement plot_flag as optional input so that if requested, function
% plots resulting subsector risk on a color-coded global map.
% Drafts of possible plotting funtions are at the end of the code.
%
% Also output a mainsector risk array which will have the same length as
% the input array but now absolute values since we multiply each input
% (relative) main sector risk with the corresponding main sector
% production. Could also be used for map plotting.
%
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180105 initializing function
% Kaspar Tobler, 20180108 further conceptual work/changes in concept...
% Kaspar Tobler, 20180109-12 keep working on core functionality
% Kaspar Tobler, 20180112 core functionality for no choice of specific countries finished and working.
% Kaspar Tobler, 20180115-16 Further smaller changes as well as begin drafting of plotting functions. 

% ONLY FOR DEVELOPMENT PERIOD: CREATE AN EXAMPLE INPUT ARRAY:
% Assume that the order of values (representing direct risk for each
% country/mainsector-combination) follows the one from climada_aggregated_mriot
% direct_mainsector_risk = rand(1,aggregated_mriot.no_of_countries*aggregated_mriot.no_of_sectors);
%%%%%%%%%%

direct_subsector_risk=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default values where  appropriate
if ~exist('direct_mainsector_risk','var') || ... % Required inputs
        ~exist('climada_mriot','var') || ...
        ~exist('aggregated_mriot','var')
    errordlg('Please provide the required input arguments.','User input error. Cannot proceed.');
    error('Please provide the required input arguments.')
elseif ~exist('countries','var')    % Optional input
    countries=[];       
end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)

module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data']; %#ok

% PARAMETERS

no_of_countries = climada_mriot.no_of_countries;
no_of_mainsectors = aggregated_mriot.no_of_sectors;
no_of_subsectors = climada_mriot.no_of_sectors;

total_mainsector_production = sum(aggregated_mriot.mrio_data,2)';
        % Column vector (transposed to row); each entry representing total production of each
        % main sector within one country.
total_subsector_production = sum(climada_mriot.mrio_data,2)';
        % As above but for all subsectors.

% Assumption: the input values are still normalized, such that we don't need
% a weighting factor here but can obtain the absolute risk per subsector and
% country by simple multiplication with each sector's total production in 
% these countries... 

% tic
        % Temporary array for testing phase:
             test_sel_pos_all = {};
             
if isempty(countries) % No specific countries of interest by user, do for all.
       direct_subsector_risk = zeros(1,no_of_subsectors*no_of_countries);
       
    for mainsector_i = 1:no_of_mainsectors  %#ok
        main_fields = fields(aggregated_mriot.aggregation_info);
        current_mainsector = char(main_fields(mainsector_i));
        
        for subsector_i = 1:numel(aggregated_mriot.aggregation_info.(current_mainsector)) % How many subsectors belong to current mainsector.
            temp_subsectors = aggregated_mriot.aggregation_info.(current_mainsector);
            current_subsector = char(temp_subsectors(subsector_i));           
                
            sel_subsector_pos = climada_mriot.sectors == current_subsector;
            
            % Create testing cell array whith with we can check that we never 
            % overwrite previous entries:
                test_sel_pos_all{end+1} = find(sel_subsector_pos);    %#ok
            
            direct_subsector_risk(sel_subsector_pos) = direct_mainsector_risk(aggregated_mriot.sectors == current_mainsector) .* total_subsector_production(sel_subsector_pos);
            
        end
    end   
    
% Next step: map risks on global map to have a first glance at likeliness of results.    
        
else % User provided one or more countries. We only obtain disaggregated risk 
     % for these. LARGE ISSUE: THIS WILL SIGNIFICANTLY COMPLICATE LEONTIEF 
     % CALCULATIONS SINCE MATRIX/VECTOR DIMENSIONS WILL BE DIFFERENT. THE
     % LEONTIEF FUNCTION WILL HAVE TO WORK WITH A MRIOT TABLE WHERE ONLY
     % THE RELEVANT COUNTRIES ARE IN FULL RESOLUTION, WHICH IS A FORM WE
     % DON'T HAVE YET. COULD BE PROVIDED THOUGH...
     % FOR NOW, WE STICK WITH THE GLOBAL CALCULATIONS ONLY.
     
     %subsectors_risk = mainsectors_risk_global; % For the countries other than the chosen ones, we keep the aggregated risk.      

end

       % Testing; each entry in test_sel_pos should only occure once.
            % pos_as_mat = cell2mat(test_sel_pos_all);
            % unique_pos = unique(pos_as_mat);  
            % test_pos = length(pos_as_mat) == length(unique_pos);
            % Passed test (20180112).

% toc

% Calculate absolute main sector risk (simple element-wise multiplication):
direct_mainsector_risk_abs = direct_mainsector_risk.*total_mainsector_production;

%%% plot_absolute_risk;

%% Plotting subfunctions:
% Not yet integrated into main function workflow. For test runds it is necessary 
% to run main code not as function to get required variables.

% TOTAL MAIN SECTOR PRODUCTION OF EACH MAIN SECTOR for each country:
% One map per main sector:
function plot_production   %#ok
                all_col1 = zeros(no_of_countries,1);
                all_col2 = zeros(no_of_countries,1);
                all_col3 = zeros(no_of_countries,1);
        for mainsector_i = 1:no_of_mainsectors %#ok
            sectors = unique(aggregated_mriot.sectors);
            current_sector = char(sectors(mainsector_i));
            figure('Name',current_sector);
         for country_i = 1:no_of_countries  
            countries = unique(climada_mriot.countries_iso);
            current_country = char(countries(country_i));
            sel_pos = (aggregated_mriot.sectors == current_sector) & (aggregated_mriot.countries_iso == current_country); 
            sel_pos2 = aggregated_mriot.sectors == current_sector;
            % To adapt colors to each country's risk for the current sector, we
            % normalize the risk values:
            col_1 = (total_mainsector_production(sel_pos)-min(total_mainsector_production(sel_pos2)))/...
                        (max(total_mainsector_production(sel_pos2))-min(total_mainsector_production(sel_pos2)));
            col_2 = max(col_1-col_1/3,0);
            col_3 = min(col_1+col_1/3,1);

                all_col1(country_i,1) = col_1;
                all_col2(country_i,1) = col_2;
                all_col3(country_i,1) = col_3;

            climada_plot_world_borders(1,current_country,'','',[col_1 col_2 col_3])
         end
         title(current_sector,'Interpreter','none');
        end
        all_col = table(all_col1,all_col2,all_col3,'VariableNames',{'R','G','B'}); %#ok
end


% DIRECT ABSOLUTE RISK OF EACH MAIN SECTOR for each country. 
% One map per main sector:
function plot_absolute_risk    %#ok
                all_col1 = zeros(no_of_countries,1);
                all_col2 = zeros(no_of_countries,1);
                all_col3 = zeros(no_of_countries,1);

                
        for mainsector_i = 1:no_of_mainsectors  %#ok
            sectors = unique(aggregated_mriot.sectors);
            current_sector = char(sectors(mainsector_i));
            figure('Name',current_sector);
         for country_i = 1:no_of_countries
            countries = unique(climada_mriot.countries_iso);
            current_country = char(countries(country_i));
            sel_pos = (aggregated_mriot.sectors == current_sector) & (aggregated_mriot.countries_iso == current_country); 
            sel_pos2 = aggregated_mriot.sectors == current_sector;
            % To adapt colors to each country's risk for the current sector, we
            % normalize the risk values:
            col_1 = (direct_mainsector_risk_abs(sel_pos)-min(direct_mainsector_risk_abs(sel_pos2)))/...
                        (max(direct_mainsector_risk_abs(sel_pos2))-min(direct_mainsector_risk_abs(sel_pos2)));
            col_2 = max(col_1-col_1/3,0);
            col_3 = min(col_1+col_1/3,1);

                all_col1(country_i,1) = col_1;
                all_col2(country_i,1) = col_2;
                all_col3(country_i,1) = col_3;

            climada_plot_world_borders(1,current_country,'','',[col_1 col_2 col_3])
         end
         title(current_sector,'Interpreter','none');
        end
        all_col = table(all_col1,all_col2,all_col3,'VariableNames',{'R','G','B'}); %#ok
end


end %Wrap local functions to have shared variable workspace.
