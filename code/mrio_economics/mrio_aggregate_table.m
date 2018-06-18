function [aggregated_mriot, climada_mriot] = mrio_aggregate_table(climada_mriot, full_aggregation_flag, RoW_flag)
% mrio aggregate table
% MODULE:
%   climada_advanced
% NAME:
%   mrio_aggregate_table
% PURPOSE:
%   Transforms a full climada mrio table struct (usually "climada_mriot") into an aggregated  
%   table that consists only of the six climada sectors. It does retain the original
%   number of countries, however (exceptions are RoW-subregions, as described in the following).
%
%   Further, it can aggregate tables with several different RoW-subregions
%   into one with only one general RoW-region or a table where RoW-subregions for Asia/Pacific and America
%   (relevant for TCs) are kept while other RoW-subregions, such as Africa
%   and Europe, are aggregated into a general RoW (currently only relevant
%   for the exiobase table). This RoW-aggregation is done on the full climada_mriot struct, not only
%   on the aggregated struct. Hence if the user wants to continue the
%   calculations with a RoW aggregated version of climada_mriot, she or he
%   has to ask for its output.
%   
%   previous call: 
%   climada_mriot = mrio_read_table; 
%   next call: % just to illustrate
%   D_YDS = mrio_direct_risk_calc(climada_mriot, aggregated_mriot);
% CALLING SEQUENCE:
%   [aggregated_mriot, climada_mriot] = mrio_aggregate_table(climada_mriot, full_aggregation_flag, RoW_flag);
% EXAMPLE:
%   aggregated_mriot = mrio_aggregate_table(climada_mriot,'',0); 
%               Already existing climada_mriot struct provided as argument, 
%               only the aggregeated table returned. RoW-regions are kept
%               as they are. Only minimal aggregation is computed; see below.
%   [aggregated_mriot, climada_mriot] = mrio_aggregate_table; 
%               no arguments provided. User is prompted whether a
%               required climada_mriot struct should be created. The latter is
%               returned as the second output. No full aggregation is
%               conducted but RoW-regions are aggregated into one in the
%               returned climada_mriot struct.
%   aggregated_mriot = mrio_aggregate_table; NOT RECOMMENDED. As above, but
%               the created climada_mriot struct is not returned (only the
%               aggregated version).
%   aggregated_mriot = mrio_aggregate_table(climada_mriot,1,2)
%               Full aggregation is computed and RoW regions are partly aggregated, with only
%               RoW Asia/Pacific and RoW America kept, if applicable (Note if table does in fact not
%               contain several RoW-regions, this is noted to the user).
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   climada_mriot: a climada_mriot structure containing a full mriot as
%       imported with the function climada_read_mriot. If not provided, user is
%       prompted whether the climada_read_mriot function should be called prior to 
%       continuing with current function or whether current function should be aborted.
%  full_aggregation_flag: flag sepcifying whether a full aggregation shall
%      be computed (=1; i.e. we aggregate all mrio sector-sector data) or a
%      "minimal" aggregation (=0, default), where the mrio data itself is not
%      aggregated and only the country and sector labels corresponding to the
%      mainsectors as well as info on which subsectors belong to which
%      mainsector are computed.
%      Note: if this flag is 0, but the RoW-flag either 1 or 2, the full
%      aggregations is still computed since it is needed for the RoW
%      aggregation.
%  RoW_flag: integer flag; can be: 
%       1: stating that the aggregation should also include the
%          aggregation of several RoW-regions present in some MRIOTs (e.g.
%          exiobase) into just ONE RoW-region which facilitates calculations further
%          down the line. DEFAULT is 1.
%       2: aggregation includes aggregation of several RoW regions into
%          one general RoW, whereas RoW subregions for America and
%          Asia/Pacific are NOT aggregated but kept as they are.
%          Cautionary note: doing this aggregation has implications for the
%          disaggregation computation too!
%       0: no RoW aggregation takes place.   
% OUTPUTS:
%   aggregated_mriot: 
%       a structure with 13 fields. It represents an 
%       aggregated version of the general climada mriot structure. Aggregated
%       here means that all subsectors as represented in the full mriot are
%       taken together so that only the six climada sectors are represented in
%       the table: agriculture, forestry_fishing, mining_quarrying, manufacturing,
%       utilities supply and services. A field retains the information on which subsectors
%       have been aggregated into each climada sector. 
%       No aggregation is done on the countries.
%       For comparability, the resulting structure retains an 
%       analogous - well - structure,  to the full table. The fields are:
%           countries: a categorical array containing the full list of all
%               countries in the order they appear in the
%               industry-by-industry mriot. 
%               List of countries is repeated m number of times with m =
%               no. of sectors, i.e. here m = 6.
%           countries_iso: 3-digit iso code of each country. As above.
%           sectors: as above for countries, but for all six climada sectors. 
%               List of sectors will be repeated n number of times with n =
%               no. of countries.
%           aggregation_info: itself a struct with six fields, containing for each 
%               climada sector the list of subsectors that constitute it. Each
%               field stands for one cliamda sectors (hence, six fields). The
%               entries in each field will depend on the original mriot type
%               the climada_mriot is based on (exiobase, wiod, etc.).
%           mrio_data: sector-by-sector numerical data matrix (quadratic). 
%               The actual aggregated mriot, without any labels. To get a commodity
%               exchange value of interest, index into here with the
%               corresponding row- and column indices as extracted from the full countries and/or
%               sectors arrays. If it was chosen to only compute a minimal
%               aggregation, this field contains a character array specifying
%               this.
%           table_type: character array simply stating the table type the mriot
%               struct is originally based on. Is unchanged from the
%               climada_mriot struct.
%           filename: character array specifying the full path to the mriot
%               file originally passed as argument to climada_read_mriot to construct 
%               climada mriot structure. Is unchanged from the
%               climada_mriot struct.
%           no_of_countries: integer value stating the number of countries that
%               is contained in the mriot struct (i.e. in the table type the
%               struct is based on). Different for different table types and
%           	might change with future releases. Is unchanged from the
%               climada_mriot struct.
%           no_of_sectors: as above but for number of sectors. Here always 6,
%               unless basic climada sectors are extended in future. 
%           RoW_aggregation: char vector specifying whether RoW aggregation
%               took place and if so, which type.
%           unit: unit used in the original mriot. Same as in full climada_mriot.
%           total_production: a numeric column array containing for all country-sector
%               combinations the total production. Total production includes
%               production flowing into final consumption, i.e. not into other
%               sector for further processing.
%   climada_mriot: if not provided as argument by user newly created. If
%       provided and if asked for RoW-aggregation, the returned
%       climada_mriot struct contains these aggregation and a field
%       informing about type of RoW-aggregation is added.
% GENERAL NOTES:
% No in-depth testing of results conducted yet! 
% In next step, consider extending mrio_read_table with a flag which
% directly calls mrio_aggregate_table from within the prior function,
% returning both the full and the aggregated table directly (could lead to
% some function workspace memory issues)...
% MODIFICATION HISTORY:
% Kaspar Tobler, 20171220 initializing function
% Kaspar Tobler, 20180104 finishing raw prototype version. Basic capabilities are provided and work.
% Kaspar Tobler, 20180112 add climada_mriot as optional output if no such structure is provided as input and it thus created within function using mrio_read_table.
% Kaspar Tobler, 20180118 added an additional field of climada_sect_id analogous to the field in the climada_mriot struct.
% Kaspar Tobler, 20180125-26 provided functionality to deal with mriots which subdivide ROW into several ROW regions (e.g. exiobase): if asked for, aggregation now also aggregated these several ROW regions into just one ROW.
% Kaspar Tobler, 20180129 added functionality that no full aggregation of the mrio data itself is computed if requested (via input argument). 
%       This is due to fact that for "standard" procedure as laid out in mrio_master this is not needed. In a "minimal" aggregation, only the country and sector labels etc. are adjusted to an aggregated table. 
% Kaspar Tobler, 20180410 resolved all major issues surrounding RoW-subregion aggregation.
% Kaspar Tobler, 20180418 added calculations dealing with the (newly implemented) total production vector for each subfunction.
%

aggregated_mriot = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('climada_mriot','var'),climada_mriot=[];end 
if ~exist('RoW_flag','var') || isequal(RoW_flag,''),RoW_flag=1;end 
if ~exist('full_aggregation_flag','var') || isequal(full_aggregation_flag,''),full_aggregation_flag=0;end 
% if (isequal(RoW_flag,1) || isequal(RoW_flag,2)) && (full_aggregation_flag==0) % In order to aggregated RoW-regions, we need fulls aggregation for now.
%     [choice] = questdlg('You did not ask for full aggregation, but for RoW-aggregation, which requires the full aggregation. Do you want to proceed? This can take up to 5 minutes.',...
%         'RoW aggregation requires full table aggregation',...
%         'Yes, poceed with both, full table and RoW aggregation.','No, abort.','Yes, poceed with both, full table and RoW aggregation.'); % Repeated string specifies default choice.
%     if isequal(choice,'') || isequal(choice,'No, abort.') % User chose to abort or closed the dialog window without choice.
%         error('Please call the function again with different argument choices.')
%     else
%         full_aggregation_flag=1;
%     end 
% end 

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)

module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data']; %#ok

% PARAMETERS

% If user did not pass a climada_mriot struct, we inquire whether the
% function climada_read_mriot should be called which generates such a
% struct. Without it, we cannot proceed.
if isempty(climada_mriot) %If empty, open file dialog.
    [choice] = questdlg('You did not provide a climada_mriot structure. Should the function mrio_read_table be called to import a mriot table? This takes approx. 1-3 minutes and all necessary user requirements have to be met. If you abort, the entire operation is aborted as without a climada_mriot struct, we cannot proceed.',...
        'Check for climada_mriot structure',...
        'Yes, run necessary function.','No, abort.','Yes, run necessary function.'); % Repeated string specifies default choice.
    if isequal(choice,'') || isequal(choice,'No, abort.') % User chose to abort or closed the dialog window without choice.
        error('Without a climada_mriot structure, function mrio_aggregate_table cannot proceed. Please provide a structure as input argument or let the current function run the necessary procedure.')
    else
        questdlg('The function now runs mrio_read_table to obtain the necessary data. You are promted for several inputs. The import takes approx. 1-3 minutes. Note that if you want to go ahead according to standard procedure, you will need the climada_mriot struct, which is provided by the current function as a second output.',...
            'Import climada_mriot struct.','Ok','Ok'); % Repeated string specifies default choice.
        clear ans
        climada_mriot = mrio_read_table;
    end % isequal
end % isempty

% Get no. of sectors and no. of countries in provided mriot:
no_of_sectors = climada_mriot.no_of_sectors;
no_of_countries = climada_mriot.no_of_countries;
% Get no. of climada_sectors (the main sectors):
% (Not hardcoded to 6 in case changes in future)
no_of_mainsectors = length(categories(climada_mriot.climada_sect_name));

% Get array of unique country ISO3 codes, country names and sector names 
% as well as climada sector names and climada sector IDs in order as they appear in the mriot:
unique_iso = unique(climada_mriot.countries_iso,'stable');
unique_countries = unique(climada_mriot.countries,'stable');
unique_sectors = unique(climada_mriot.sectors,'stable'); %#ok
unique_mainsectors = unique(climada_mriot.climada_sect_name,'stable');
unique_mainsector_ids = unique(climada_mriot.climada_sect_id,'stable');
% Use unique() instead of categories() since the latter does not keep the
% original order. The 'stable' argument locks the order of the unique
% values as they appear in the full array.

% Names of RoW regions, if any:
 RoW_names = string(unique_countries(contains(string(unique_countries),'RoW','IgnoreCase',true)));

% Data length; the length of the new sectors and countries arrays
% as well as each mrio_data matrix dimension. Simply the product of the no.
% of climada sectors and the no. of countries in the mriot:
aggregated_data_length = no_of_mainsectors*no_of_countries;
full_data_length = no_of_sectors*no_of_countries;

% Setting up resulting struct:
aggregated_mriot(1).countries = [];
aggregated_mriot(1).countries_iso = [];
aggregated_mriot(1).sectors = [];
aggregated_mriot(1).climada_sect_id = [];
aggregated_mriot(1).aggregation_info = [];
aggregated_mriot(1).mrio_data = [];
aggregated_mriot(1).table_type = climada_mriot.table_type;
aggregated_mriot(1).filename = climada_mriot.filename;
aggregated_mriot(1).no_of_countries = climada_mriot.no_of_countries;
aggregated_mriot(1).no_of_sectors = no_of_mainsectors;
aggregated_mriot(1).RoW_aggregation = 'None';
aggregated_mriot(1).total_production = [];
aggregated_mriot(1).unit = climada_mriot.unit;   
% The set-up for the field aggregation_info (itself a struct):
for mainsector_i = 1:no_of_mainsectors
   field_name = char(unique_mainsectors(mainsector_i));
   aggregation_info(1).(field_name) = []; % Parentheses allow dynamic creation of field names based on provided string.
end % mainsector_i
aggregated_mriot(1).aggregation_info = aggregation_info;
clear aggregation_info;


%% Dealing with several RoW-Regions:

% Exiobase currently (Version 2.2.2) has five RoW regions:
% RoW Asia and Pacific, RoW America, RoW Europe, RoW Africa, RoW Middle East.
% We implement two different options to deal with this (user-choice).
% Option 1: all RoW regions are aggregated into just one general RoW. Function argument RoW_flag = 1.
% Option 2: we keep the (for this project) most relevant RoW Asia/Pacific and RoW America,
%   but aggregate the remaining three into a general RoW. Function argument RoW_flag = 2.
% We use two separate local functions to do this.

no_of_RoW = nnz(contains(string(unique_countries),'RoW','IgnoreCase',true));

if RoW_flag == 1 && ~(no_of_RoW>1),warning('User asked for aggregation of several RoW regions into one, but provided MRIOT already has only one RoW region.');end

if RoW_flag == 1 && no_of_RoW > 1   % Only aggregate if user wants to. Also, if provided mriot doesn't have several RoW regions, aggregation isn't meaningful.
    
    one_RoW;       % Call with no target and no argument.
                   % One RoW meaning that all RoW regions are aggregated
                   % into just one generic RoW region.
end 

if RoW_flag == 2 && ~(no_of_RoW>1),warning('User asked for aggregation of several RoW regions into fewer ones, but provided MRIOT already has only one RoW region.');end
if RoW_flag == 2 && no_of_RoW > 1
    
    three_RoW;      % Call with no target and no argument.
                    % Three RoW meaning that RoW regions are aggregated
                    % into three regions, one RoW Asia/Pacific, one RoW
                    % America and one generic RoW for everything else (e.g. for exiobase, aggregating RoW Europe, RoW Africa and RoW Middle East into one general RoW).
    
end % if ROW_flag == 2 && no_of_ROW > 1

%% Add label fields to the structure. This is always done, i.e. it constitutes the "minimal" aggregation process;

% First, the slightly more complicated (vs. sectors) countries and countries_iso fields.
% Note that there is an quivalent loop-construct in function
% climada_read_mriot.
   aggregated_mriot.countries = categorical(zeros(1,aggregated_data_length));
   aggregated_mriot.countries_iso = categorical(zeros(1,aggregated_data_length));
   j = 1;     % Needed to index into mriot.countries and mriot.countries_iso at correct positions for
              % insertion of temp_country and temp_iso arrays.
   for country_i = 1:no_of_countries    %#ok
       temp_countries = repmat(unique_countries(country_i),1,no_of_mainsectors);
       temp_iso = repmat(unique_iso(country_i),1,no_of_mainsectors);
       aggregated_mriot.countries(j:j+no_of_mainsectors-1) = temp_countries;
       aggregated_mriot.countries_iso(j:j+no_of_mainsectors-1) = temp_iso;
       j = j + no_of_mainsectors; % See above
   end % country_i
   % Sanity check:
   if ~isequal(length(aggregated_mriot.countries),length(aggregated_mriot.countries_iso),no_of_mainsectors*no_of_countries)
       warning('Something went wrong'); %Specify better warnings later
   end
   
% Now the simpler sectors and equivalently the climada_sect_id:  
    aggregated_mriot.sectors = repmat(unique_mainsectors,1,no_of_countries);
    aggregated_mriot.climada_sect_id = repmat(unique_mainsector_ids,1,no_of_countries);
    
% The field informing about possible RoW-aggregation:
    aggregated_mriot.RoW_aggregation = climada_mriot.RoW_aggregation;

% Finally, the field with the aggregation info (itself a struct with k
% fields, where k = no. of climada sectors (here 6)).
for mainsector_i = 1:no_of_mainsectors
    field_name = char(unique_mainsectors(mainsector_i));
    sub_sectors = climada_mriot.sectors(climada_mriot.climada_sect_name == unique_mainsectors(mainsector_i));
    aggregated_mriot.aggregation_info.(field_name) = unique(sub_sectors,'stable');
end % mainsector_i

%% Full aggregation of the mrio data is only done if the user chose to do so, i.e. if full_aggregation_flag is set to 1. 
if isequal(full_aggregation_flag,1)
    full_aggregation;   % Call with no target and no argument. 
else 
    aggregated_mriot.mrio_data = 'No full aggregation on mrio data was computed to save memory and computing time. If such an aggregation is sought, please pass the respective flag argument to function mrio_aggregate_table.';
    aggregated_mriot.total_prduction = 'No full aggregation also holds true for total_production vector';
end % if isequal(full_aggregation_flag,1)

%% Local functions (aggregation of RoW regions and full table aggregation)
  
function one_RoW

    RoW_data_length = no_of_sectors*(no_of_countries-(no_of_RoW-1));
    RoW_mrio_data = climada_mriot.mrio_data;
    RoW_total_production  = climada_mriot.total_production;
    RoW_locations = find(ismember(climada_mriot.countries,categorical(RoW_names)));

     % First aggregate along the columns: 
    for row_i = 1:full_data_length
        location_i = 1;
        for col_i = RoW_locations(location_i):RoW_locations(no_of_sectors)   % All entries beyond we "reach" via the sum_indices below.
                sum_indices = zeros(1,no_of_RoW);            
                for RoW_i = 1:no_of_RoW
                    sum_indices(RoW_i) = col_i + no_of_sectors*(RoW_i-1);
                end
                %jump_test(1).(['col_' num2str(col_i)]) = sum_indices;
                RoW_mrio_data(row_i,col_i) = sum(RoW_mrio_data(row_i,sum_indices)); 
            location_i = location_i + 1;
        end % col_i   
    end % row_i
    RoW_mrio_data(:,RoW_locations(no_of_sectors+1:end)) = []; 
    
    % Now along the rows. This includes aggregation of the total production array: 
    for col_i = 1:RoW_data_length 
        location_i = 1;
        for row_i = RoW_locations(location_i):RoW_locations(no_of_sectors)   % All entries beyond we "reach" via the sum_indices below.
                sum_indices = zeros(1,no_of_RoW);
                for RoW_i = 1:no_of_RoW
                    sum_indices(RoW_i) = row_i + no_of_sectors*(RoW_i-1);
                end
                %jump_test(1).(['col_' num2str(col_i)]) = sum_indices;
                RoW_mrio_data(row_i,col_i) = sum(RoW_mrio_data(sum_indices,col_i)); 
                RoW_total_production(row_i,1) = sum(RoW_total_production(sum_indices,1)); % For now not efficient since newly calculated every time. But conditional will be inefficient too. Time-loss seems negligible. 
           location_i = location_i + 1;
        end % row_i
    end % col_i
    RoW_mrio_data(RoW_locations(no_of_sectors+1:end),:) = []; 
    RoW_total_production(RoW_locations(no_of_sectors+1:end),:) = []; 
    
    % We now have new RoW_locations (only one RoW left) which can then be used to adjust the labels:
    new_RoW_locations = RoW_locations(1:no_of_sectors);
    obsolete_RoW_locations = setdiff(RoW_locations,new_RoW_locations,'stable');
    
    %%% Now add fields to climada_mriot that correspond to the adapted RoW
    %%% structure, i.e. above RoW_mrio_data field as well as adapted countries and sectors arrays:
    RoW_countries = climada_mriot.countries;
        RoW_countries(obsolete_RoW_locations) = [];
    RoW_countries_iso = climada_mriot.countries_iso;
        RoW_countries_iso(obsolete_RoW_locations) = [];
    RoW_sectors = climada_mriot.sectors;
        RoW_sectors(obsolete_RoW_locations) = [];
    RoW_mainsector_id = climada_mriot.climada_sect_id;
        RoW_mainsector_id(obsolete_RoW_locations) = [];
    RoW_mainsector_name = climada_mriot.climada_sect_name;
        RoW_mainsector_name(obsolete_RoW_locations) = [];        

    RoW_countries(new_RoW_locations) = categorical(repmat({'RoW'},1,no_of_sectors));
    RoW_countries_iso(new_RoW_locations) = categorical(repmat({'RoW'},1,no_of_sectors)); 
    climada_mriot.countries = RoW_countries;
    climada_mriot.countries_iso = RoW_countries_iso;
    climada_mriot.sectors = RoW_sectors;
    climada_mriot.climada_sect_id = RoW_mainsector_id;
    climada_mriot.climada_sect_name = RoW_mainsector_name;
    climada_mriot.mrio_data = RoW_mrio_data;
    climada_mriot.no_of_countries = no_of_countries-(no_of_RoW-1);
    climada_mriot.RoW_aggregation = 'all into one';
    climada_mriot.total_production = RoW_total_production;
    
    % We now have new values for the fuction-wide variables
    % no_of_countries, unique_iso, unique_countries and data length:
    unique_iso = unique(climada_mriot.countries_iso,'stable');
    unique_countries = unique(climada_mriot.countries,'stable');
    no_of_countries = climada_mriot.no_of_countries;
    aggregated_data_length = no_of_mainsectors*no_of_countries;
    full_data_length = no_of_sectors*no_of_countries;

end % one_RoW

function three_RoW 

    RoW_data_length = no_of_sectors*(no_of_countries-(no_of_RoW-3));
    RoW_names(contains(RoW_names,{'asia','america'},'IgnoreCase',true)) = []; % Here we leave RoW Asia/Pacific and RoW America as they are.    
    RoW_mrio_data = climada_mriot.mrio_data;
    RoW_locations = find(ismember(climada_mriot.countries,categorical(RoW_names)));
    RoW_total_production = climada_mriot.total_production;
    
    % First, aggregate along the columns:
    
    for row_i = 1:full_data_length
        location_i = 1;
        for col_i = RoW_locations(location_i):RoW_locations(no_of_sectors)
                           % Attention: Here we have to use different a approach to sum_indices since it could be that 
                           % the RoW-regions we are interested in are not following each other directly.
                sum_indices = RoW_locations(location_i:no_of_sectors:end); 
                location_i = location_i + 1;
                %jump_test(1).(['col_' num2str(col_i)]) = sum_indices;
                RoW_mrio_data(row_i,col_i) = sum(RoW_mrio_data(row_i,sum_indices));
        end % col_i 
    end % row_i  
    RoW_mrio_data(:,RoW_locations(no_of_sectors+1:end)) = [];   
    
    % Now aggregate along the rows. This includes the total production array:
    
    for col_i = 1:RoW_data_length
        location_i = 1;
        for row_i = RoW_locations(location_i):RoW_locations(no_of_sectors)
                      
                sum_indices = RoW_locations(location_i:no_of_sectors:end); 
                location_i = location_i + 1;
                %jump_test(1).(['col_' num2str(col_i)]) = sum_indices;
                RoW_mrio_data(row_i,col_i) = sum(RoW_mrio_data(sum_indices,col_i));
                RoW_total_production(row_i,1) = sum(RoW_total_production(sum_indices,1));
        end % col_i 
    end % row_i  
    RoW_mrio_data(RoW_locations(no_of_sectors+1:end),:) = [];   
    RoW_total_production(RoW_locations(no_of_sectors+1:end),:) = [];
    
    % We now have new RoW_locations which can then be
    % used to adjust the labels. Note that the RoW-regions we did not
    % smum up are treated as normal countries and hene needn't be addressed specifically.
    new_RoW_locations = RoW_locations(1:no_of_sectors);
    obsolete_RoW_locations = setdiff(RoW_locations,new_RoW_locations,'stable');
    
    %%% Now add fields to climada_mriot that correspond to the adapted RoW
    %%% structure, i.e. above RoW_mrio_data field as well as adapted countries and sectors arrays:
    RoW_countries = climada_mriot.countries;
        RoW_countries(obsolete_RoW_locations) = [];
    RoW_countries_iso = climada_mriot.countries_iso;
        RoW_countries_iso(obsolete_RoW_locations) = [];
    RoW_sectors = climada_mriot.sectors;
        RoW_sectors(obsolete_RoW_locations) = [];
    RoW_mainsector_id = climada_mriot.climada_sect_id;
        RoW_mainsector_id(obsolete_RoW_locations) = [];
    RoW_mainsector_name = climada_mriot.climada_sect_name;
        RoW_mainsector_name(obsolete_RoW_locations) = [];        

    RoW_countries(new_RoW_locations) = categorical(repmat({'RoW'},1,no_of_sectors));
    RoW_countries_iso(new_RoW_locations) = categorical(repmat({'RoW'},1,no_of_sectors)); 
    climada_mriot.countries = RoW_countries;
    climada_mriot.countries_iso = RoW_countries_iso;
    climada_mriot.sectors = RoW_sectors;
    climada_mriot.climada_sect_id = RoW_mainsector_id;
    climada_mriot.climada_sect_name = RoW_mainsector_name;
    climada_mriot.mrio_data = RoW_mrio_data;
    climada_mriot.no_of_countries = no_of_countries-(no_of_RoW-3);
    climada_mriot.RoW_aggregation = 'all into one except RoW-Asia/Pacific and RoW-America';
    climada_mriot.total_production = RoW_total_production;
    
    % We now have new values for the fuction-wide variables
    % no_of_countries, unique_iso, unique_countries and data length:
    unique_iso = unique(climada_mriot.countries_iso,'stable');
    unique_countries = unique(climada_mriot.countries,'stable');
    no_of_countries = climada_mriot.no_of_countries;
    aggregated_data_length = no_of_mainsectors*no_of_countries;
    
end % three_RoW

function full_aggregation
    
    % NOTE: ONE COULD PROBABLY MAKE BELOW CALCULATIONS FASTER FOLLOWING
    % SIMILAR APPROACHES AS FOR THE ROW-AGGREGATION (WHICH WERE IMPLEMENTED
    % AFTER BELOW CODE. FOR NOW THIS IS NO PRIORITY THOUGH HENCE THE CODE
    % IS LEFT AS IS.
        
    % Pre-allocate new (aggregated) mrio_data field. 
    aggregated_mriot.mrio_data = zeros(aggregated_data_length,aggregated_data_length);

    % Aggregate original mrio_data to aggregated version, where all subsector
    % commodity exchanges are summed up under the respective climada main
    % sector...
    %
    % First, aggregate along rows.  This also aggregates the total_production array: 
    
    for col_i = 1:length(climada_mriot.sectors) % Full resolution length for column index
            mainsector_i = 0;
            country_i = 1;
        for row_i = 1:aggregated_data_length % Aggregated length for row index
            % Explanation of the following if-clause:
            % Since we loop through the length of data_length in the parent
            % loops, the climada_sector_i would add up to much
            % more than the actual length of the array it represents an index of (i.e. the climada_sectors array). 
            % So whenever it reaches that length (currently 6) we have to set
            % it back to 1 and restart counting from there...
            if mainsector_i == no_of_mainsectors
                mainsector_i = mainsector_i/mainsector_i;
                % Further, whenever all six sectors have been gone through, we
                % want to advance the index for the country by one, since for
                % the next iteration of summing up to the climada sectors we
                % are interested in the next country:
                country_i = country_i + 1;
            else
                mainsector_i = mainsector_i+1;
            end
            % First get all positions (i.e. row-indices) over which we have to sum up the original mrio data:
            sum_indices = ((climada_mriot.climada_sect_id == mainsector_i) & climada_mriot.countries_iso == unique_iso(country_i))'; % Transpose to a (logical) column vector
            aggregated_mriot.mrio_data(row_i,col_i) = sum(climada_mriot.mrio_data(sum_indices,col_i));
            aggregated_mriot.total_production(row_i,1) = sum(climada_mriot.total_production(sum_indices,1));
        end % row_i
    end % col_i
    %toc % Approx. 1 minute.

    % Second step is to aggregate along columns too, so that we get a quadratic
    % matrix again. The procedure is similar to the one above.
    % tic
    for row_i = 1:aggregated_data_length 
            mainsector_i = 0;
            country_i = 1;
        for col_i = 1:aggregated_data_length  % Explanation for following if clause see above in first aggregation step.
            if mainsector_i == no_of_mainsectors
                mainsector_i = mainsector_i/mainsector_i;
                country_i = country_i + 1;
            else
                mainsector_i = mainsector_i+1;
            end
            % First get all positions (i.e. here column-indices) over which we have to sum up the original mrio data:
            sum_indices = ((climada_mriot.climada_sect_id == mainsector_i) & climada_mriot.countries_iso == unique_iso(country_i)); % Here no transposing since we want a row vector.
            aggregated_mriot.mrio_data(row_i,col_i) = sum(aggregated_mriot.mrio_data(row_i,sum_indices));
        end % col_i
    end % row_i
    % toc % Approx. 5 seconds.
    % Remove all now obsolete columns with indices > data_length:
            aggregated_mriot.mrio_data(:,(aggregated_data_length+1):end) = [];
            
    % Add RoW-label:
    aggregated_mriot.RoW_aggregation = climada_mriot.RoW_aggregation;  

end % full_aggregation
        
end % mrio_aggregate_table