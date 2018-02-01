function [aggregated_mriot, climada_mriot]=mrio_aggregate_table(climada_mriot, ROW_flag, full_aggregation_flag)
% MODULE:
%   climada_advanced
% NAME:
%   read_mriot
% PURPOSE:
%   Transforms a full climada mrio table struct (usually "climada_mriot") into an aggregated  
%   table that consists only of the six climada sectors. It does retain the original
%   number of countries, however.
%   
%   previous call: mrio_read_table 
%
%   next call: (function to calculate country- and sector-specific DIRECT tropical
%       cylone risk associated with the six climada sectors as represented
%       in the aggregated mriot.)
%
% CALLING SEQUENCE:
%   mrio_read_table;
%   mrio_aggregate_table;
%  
% EXAMPLE:
%   aggregated_mriot = mrio_aggregate_table(climada_mriot); RECOMMENDED. Already existing climada_mriot struct provided as argument, 
%                                                           only aggregeated table returned.
%   [aggregated_mriot, climada_mriot]= mrio_aggregate_table; no arguments provided. User is prompted whether a
%       required climada_mriot struct should be created. The latter is
%       returned as the second output.
%   aggregated_mriot = mrio_aggregate_table; NOT RECOMMENDED. As above, but
%       the created climada_mriot struct is not returned (only the
%       aggregated version).
%
%
% INPUTS:
%
% OPTIONAL INPUT PARAMETERS:
%   climada_mriot: a climada_mriot structure containing a full mriot as
%       imported with the function climada_read_mriot. If not provided, user is
%       prompted whether the climada_read_mriot function should be called prior to 
%       continuing with current function or whether current function should be aborted.
%  ROW_flag: integer flag; if 1 stating that the aggregation should also include the
%       aggregation of several ROW regions present in some MRIOTs (e.g.
%       exiobase) into just one ROW region which facilitates calculations further
%       down the line. Default is 0, i.e. aggregation follows the
%       original ROW subdivision into several ROW regions, if applicable.
%       Cautionary note: doing this aggregation has implications for the
%       disaggregation computation too!
%  full_aggregation_flag: flag sepcifying whether a full aggregation shall
%      be computed (=1; i.e. we aggregated all mrio sector-sector data) or a
%      "minimal" aggregation (=0, default), where the mrio data itself is not
%      aggregated and only the country and sector labels corresponding to the
%      mainsectors as well as info on which subsectors belong to which
%      mainsector are computed.
%  
% OUTPUTS:
%   aggregated_mriot: 
%       a structure with eleven fields. It represents an 
%       aggregated version of the general climada mriot structure. Aggregated
%       here means that all subsectors as represented in the full mriot are
%       taken together so that only the six climada sectors are represented in
%       the table: agriculture, forestry_fishing, mining_quarrying, manufacturing,
%       utilities supply and services. A field retains the information on which subsectors
%       have been aggregated into each climada sector. 
%       No aggregation is done on the countries.
%       For comparability, the resulting structure retains an 
%       analogous - well - structure,  to the full table. 
%   The fields are:
%       countries: a categorical array containing the full list of all
%           countries in the order they appear in the
%           industry-by-industry mriot. 
%           List of countries is repeated m number of times with m =
%           no. of sectors, i.e. here m = 6.
%       countries_iso: 3-digit iso code of each country. As above.
%       sectors: as above for countries, but for all six climada sectors. 
%           List of sectors will be repeated n number of times with n =
%           no. of countries.
%       aggregation_info: itself a struct with six fields, containing for each 
%           climada sector the list of subsectors that constitute it. Each
%           field stands for one cliamda sectors (hence, six fields). The
%           entries in each field will depend on the original mriot type
%           the climada_mriot is based on (exiobase, wiod, etc.).
%       mrio_data: sector-by-sector numerical data matrix (quadratic). 
%           The actual aggregated mriot, without any labels. To get a commodity
%           exchange value of interest, index into here with the
%           corresponding row- and column indices as extracted from the full countries and/or
%           sectors arrays. If it was chosen to only compute a minimal
%           aggregation, this field contains a character array specifying
%           this.
%       table_type: character array simply stating the table type the mriot
%           struct is originally based on. Is unchanged from the
%           climada_mriot struct.
%       filename: character array specifying the full path to the mriot
%           file originally passed as argument to climada_read_mriot to construct 
%           climada mriot structure. Is unchanged from the
%           climada_mriot struct.
%       no_of_countries: integer value stating the number of countries that
%           is contained in the mriot struct (i.e. in the table type the
%           struct is based on). Different for different table types and
%           might change with future releases. Is unchanged from the
%           climada_mriot struct.
%       no_of_sectors: as above but for number of sectors. Here always 6,
%           unless basic climada sectors are extended in future. 
%       aggregated_ROW: logical. True if the povided mriot has several ROW
%           regions that have been aggregated in this function. Unless ROW_flag is
%           provided, is always false. If original mriot has only one ROW
%           it will always be false (no aggregation possible).
%       
%       
%   climada_mriot: optinally and only if user did not provide a
%       climada_mriot structure as input which was then created within
%       function. A structure as it is created by mrio_read_table.
%
% GENERAL NOTES:
%
% NO IN-DEPTH TESTING OF RESULTS CONDUCTED YET!
%
% In next step, consider extending mrio_read_table with a flag which
% directly calls mrio_aggregate_table from within the prior function,
% returning both the full and the aggregated table directly (could lead to
% some function workspace memory issues)...
%
% MODIFICATION HISTORY:
% Kaspar Tobler, 20171220 initializing function
% Kaspar Tobler, 20180104 finishing raw prototype version. Basic capabilities are provided and work.
% Kaspar Tobler, 20180112 add climada_mriot as optional output if no such structure is provided as input and it thus created within function using mrio_read_table.
% Kaspar Tobler, 20180118 added an additional field of climada_sect_id analogous to the field in the climada_mriot struct.
% Kaspar Tobler, 20180125-26 provided functionality to deal with mriots which subdivide ROW into several ROW regions (e.g. exiobase): if asked for, aggregation now also aggregated these several ROW regions into just one ROW.
% Kaspar Tobler, 20180129 added functionality that no full aggregation of the mrio data itself is computed if requested (via input argument). 
%       This is due to fact that for "standard" procedure as laid out in mrio_master this is not needed. In a "minimal" aggregation, only the country and sector labels etc. are adjusted to an aggregated table. 

aggregated_mriot=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('climada_mriot','var'),climada_mriot=[];end 
if ~exist('ROW_flag','var'),ROW_flag=0;end 
if ~exist('full_aggregation_flag','var'),full_aggregation_flag=0;end 


% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)

module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data']; %#ok

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
    end
end

% Get no. of sectors and no. of countries in provided mriot:
no_of_sectors = climada_mriot.no_of_sectors; %#ok
no_of_countries = climada_mriot.no_of_countries;
% Get no. of climada_sectors (the main sectors):
% (Not hardcoded to 6 in case changes in future)
no_of_climada_sectors = length(categories(climada_mriot.climada_sect_name));

% Get array of unique country ISO3 codes, country names and sector names 
% as well as climada sector names and climada sector IDs in order as they appear in the mriot:
unique_iso = unique(climada_mriot.countries_iso,'stable');
unique_countries = unique(climada_mriot.countries,'stable');
unique_sectors = unique(climada_mriot.sectors,'stable'); %#ok
unique_climada_sectors = unique(climada_mriot.climada_sect_name,'stable');
unique_climada_sect_ids = 1:no_of_climada_sectors;
% Use unique() instead of categories() since the latter does not keep the
% original order. The 'stable' argument locks the order of the unique
% values as they appear in the full array.

%SIDENOTE: FURTHER REFLECT ON (POTENTIAL) ISSUE OF SIGNIFICANCE OF ORDER OF CLIMADA
%SECTORS IN MAPPING TABLE USER INPUT. 

% Data length; the length of the new sectors and countries arrays
% as well as each mrio_data matrix dimension. Simply the product of the no.
% of climada sectors and the no. of countries in the mriot:
data_length = no_of_climada_sectors*no_of_countries;

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
aggregated_mriot(1).no_of_sectors = no_of_climada_sectors;
aggregated_mriot(1).aggregated_ROW = false;
% The set-up for the field aggregation_info (itself a struct):
for i = 1:no_of_climada_sectors
   field_name = char(unique_climada_sectors(i));
   aggregation_info(1).(field_name) = []; % Parentheses allow dynamic creation of field names based on provided string.
end
aggregated_mriot(1).aggregation_info = aggregation_info;
clear aggregation_info;

%%% The following few dozens of lines deal with the aggregation of the mrio
%%% data. We only do this if the user chose to do so, i.e. if the
%%% full_aggregation_flag is set to 1. 
if isequal(full_aggregation_flag,1)

% Pre-allocate new (aggregated) mrio_data field. 
aggregated_mriot.mrio_data = zeros(data_length,data_length);

% Aggregate original mrio_data to aggregated version, where all subsector
% commodity exchanges are summed up under the respective climada main
% sector...
%
% First, summarize the row-sectors and keep the column-sectors in original
% resolution. In second summarizing step, also aggregate column sectors.
% tic
for col_i = 1:length(climada_mriot.sectors) % Full resolution length for column index
        climada_sector_i = 0;
        country_i = 1;
    for row_i = 1:data_length % Aggregated length for row index
        % Explanation of the following if-clause:
        % Since we loop through the length of data_length in the parent
        % loops, the climada_sector_i would add up to much
        % more than the actual length of the array it represents an index of (i.e. the climada_sectors array). 
        % So whenever it reaches that length (currently 6) we have to set
        % it back to 1 and restart counting from there...
        if climada_sector_i == no_of_climada_sectors
            climada_sector_i = climada_sector_i/climada_sector_i;
            % Further, whenever all six sectors have been gone through, we
            % want to advance the index for the country by one, since for
            % the next iteration of summing up to the climada sectors we
            % are interested in the next country:
            country_i = country_i + 1;
        else
            climada_sector_i = climada_sector_i+1;
        end
        % First get all positions (i.e. row-indices) over which we have to sum up the original mrio data:
        sum_indices = ((climada_mriot.climada_sect_id == climada_sector_i) & climada_mriot.countries_iso == unique_iso(country_i))'; % Transpose to a (logical) column vector
        aggregated_mriot.mrio_data(row_i,col_i) = sum(climada_mriot.mrio_data(sum_indices,col_i));
    end %inner row loop
end %outer column loop
%toc % Approx. 1 minute.

% Second step is to aggregate across columns too, so that we get a quadratic
% matrix again. The procedure is similar to the one above:
% tic
for row_i = 1:data_length 
        climada_sector_i = 0;
        country_i = 1;
    for col_i = 1:data_length  % Explanation for following if clause see above in first aggregation step.
        if climada_sector_i == no_of_climada_sectors
            climada_sector_i = climada_sector_i/climada_sector_i;
            country_i = country_i + 1;
        else
            climada_sector_i = climada_sector_i+1;
        end
        % First get all positions (i.e. here column-indices) over which we have to sum up the original mrio data:
        sum_indices = ((climada_mriot.climada_sect_id == climada_sector_i) & climada_mriot.countries_iso == unique_iso(country_i)); % Here no transposing since we want a row vector.
        aggregated_mriot.mrio_data(row_i,col_i) = sum(aggregated_mriot.mrio_data(row_i,sum_indices));
    end %inner column loop
end %outer row loop
% toc % Approx. 5 seconds.
% Remove all now obsolete columns with indices > data_length:
        aggregated_mriot.mrio_data(:,(data_length+1):end) = [];
        
else % Corresponding to if isequal(full_aggregation_flag,1)
    aggregated_mriot.mrio_data = 'No full aggregation on mrio data was computed to save memory and computing time. If such an aggregation is sought, please pass the respective flag argument to function mrio_aggregate_table.';
end  % if isequal(full_aggregation_flag,1)
%%%%%%%%%%%%

% Now add remaining fields to the structure:
% First, the more complicated countries and countries_iso fields.
% Note that there is an quivalent loop-construct in function
% climada_read_mriot.
   aggregated_mriot.countries = categorical(zeros(1,no_of_countries*no_of_climada_sectors));
   aggregated_mriot.countries_iso = categorical(zeros(1,no_of_countries*no_of_climada_sectors));
   j = 1;     % Needed to index into mriot.countries and mriot.countries_iso at correct positions for
              % insertion of temp_country and temp_iso arrays.
   for country_i = 1:no_of_countries
       temp_countries = repmat(unique_countries(country_i),1,no_of_climada_sectors);
       temp_iso = repmat(unique_iso(country_i),1,no_of_climada_sectors);
       aggregated_mriot.countries(j:j+no_of_climada_sectors-1) = temp_countries;
       aggregated_mriot.countries_iso(j:j+no_of_climada_sectors-1) = temp_iso;
       j = j + no_of_climada_sectors; % See above
   end
   if ~isequal(length(aggregated_mriot.countries),length(aggregated_mriot.countries_iso),no_of_climada_sectors*no_of_countries)
       warning('Something went wrong'); %Specify better warnings later
   end


% Now the simpler sectors:
aggregated_mriot.sectors = repmat(unique_climada_sectors,1,no_of_countries);
% And equivalently the climada_sect_id:
aggregated_mriot.climada_sect_id = repmat(unique_climada_sect_ids,1,no_of_countries);

 
% Finally, the field with the aggregation info (itself a struct with k
% fields, where k = no. of climada sectors (here 6)).
for i = 1:no_of_climada_sectors
    field_name = char(unique_climada_sectors(i));
    sub_sectors = climada_mriot.sectors(climada_mriot.climada_sect_name == unique_climada_sectors(i));
    aggregated_mriot.aggregation_info.(field_name) = unique(sub_sectors,'stable');
end

%%% For use of exiobase with current (January, 2018) risk calculation
%%% functions, we aggregate the separated ROW regions into just one. Having several
%%% ROW regions causes difficulties with the entity countries that might be
%%% remediated later. For now, implementing necessary changes here (at the
%%% price of losing the higher level of detail), is more straight-forward.
%%% To save resources, we only do this when asked for (ROW_flag). 

no_of_ROW = nnz(count(string(unique_countries),'RoW'));
if isequal(no_of_ROW,0), no_of_ROW = nnz(count(string(unique_countries),'ROW'));end
if ROW_flag == 1 && ~(no_of_ROW>1),warning('User asked for aggregation of several ROW regions into one, but provided MRIOT only has one ROW region.');end

if ROW_flag == 1 && no_of_ROW > 1   % Only aggregate if user wants to. Also, if provided mriot doesn't subdived ROW, aggregation isn't meaningful.

ROW_data_length = no_of_climada_sectors*(no_of_countries-(no_of_ROW-1));
ROW_mrio_data = aggregated_mriot.mrio_data;

% First aggregate along the columns: 
for row_i = 1:data_length  
    for col_i = (no_of_climada_sectors*(no_of_countries - no_of_ROW)+1):ROW_data_length  
        
        sum_indices = zeros(1,no_of_ROW);
        for ROW_i = 1:no_of_ROW
            sum_indices(ROW_i) = col_i + no_of_climada_sectors*(ROW_i-1);
        end
        %jump_test(1).(['col_' num2str(col_i)]) = sum_indices;
        ROW_mrio_data(row_i,col_i) = sum(ROW_mrio_data(row_i,sum_indices)); 
    end
end % row_i
ROW_mrio_data(:,ROW_data_length+1:end) = [];

% Now aggregate along the rows. This is only relevant for the ROW-ROW
% interactions in the lower part of the matrix.

for col_i = (no_of_climada_sectors*(no_of_countries - no_of_ROW)+1):ROW_data_length
    for row_i = no_of_climada_sectors*(no_of_countries - no_of_ROW)+1:ROW_data_length
            sum_indices = zeros(1,no_of_ROW);
            for ROW_i = 1:no_of_ROW
                sum_indices(ROW_i) = row_i + no_of_climada_sectors*(ROW_i-1);
            end
            % jump_test(1).(['row_' num2str(row_i)]) = sum_indices;   %#ok
            ROW_mrio_data(row_i,col_i) = sum(ROW_mrio_data(sum_indices,col_i)); 
    end
end % col_i
ROW_mrio_data(ROW_data_length+1:end,:) = [];

% test = ROW_mrio_data == aggregated_mriot.mrio_data(1:end-24,1:end-24); 

%%% Now add fields to aggregated_mriot that correspond to the adapted ROW
%%% structure, i.e. above ROW_mrio_data field as well as adapted countries arrays:
ROW_countries = aggregated_mriot.countries(1:ROW_data_length);
ROW_countries_iso = aggregated_mriot.countries_iso(1:ROW_data_length);
ROW_sectors = aggregated_mriot.sectors(1:ROW_data_length);
ROW_climada_sect_id = aggregated_mriot.climada_sect_id(1:ROW_data_length);

ROW_countries(ROW_data_length-no_of_ROW:ROW_data_length) = categorical(repmat({'ROW'},1,no_of_climada_sectors));
ROW_countries_iso(ROW_data_length-no_of_ROW:ROW_data_length) = categorical(repmat({'ROW'},1,no_of_climada_sectors)); 
aggregated_mriot(1).ROW_countries = ROW_countries;
aggregated_mriot(1).ROW_countries_iso = ROW_countries_iso;
aggregated_mriot(1).ROW_sectors = ROW_sectors;
aggregated_mriot(1).ROW_climada_sect_id = ROW_climada_sect_id;
aggregated_mriot(1).ROW_mrio_data = ROW_mrio_data;
aggregated_mriot(1).ROW_no_of_countries = no_of_countries-(no_of_ROW-1);
aggregated_mriot(1).aggregated_ROW = true;

end % if ROW_flag && no_of_ROW > 1







