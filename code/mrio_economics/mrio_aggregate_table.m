function [aggregated_mriot, climada_mriot]=mrio_aggregate_table(climada_mriot)
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
%   [aggregated_mriot, climada_mriot]= mrio_aggregate_table; no arguments provided. User is prompted whether a
%       required climada_mriot struct should be created. The latter is
%       returned as the second output.
%   aggregated_mriot = mrio_aggregate_table; NOT RECOMMENDED. As above, but
%       the created climada_mriot struct is not returned (only the
%       aggregated version).
%   aggregated_mriot = mrio_aggregate_table(climada_mriot); existing climada_mriot struct provided as argument.
%
% INPUTS:
%
% OPTIONAL INPUT PARAMETERS:
%   climada_mriot: a climada_mriot structure containing a full mriot as
%   imported with the function climada_read_mriot. If not provided, user is
%   prompted whether the climada_read_mriot function should be called prior to 
%   continuing with current function or whether current function should be aborted.
%  
% OUTPUTS:
%   aggregated_mriot: 
%       a structure with ten fields. It represents an 
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
%           sectors arrays. 
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

aggregated_mriot=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('climada_mriot','var'),climada_mriot=[];end 

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

% Get array of unique country ISO3 codes, country names and sector names 
% as well as climada sector names, in order as they appear in the mriot:
unique_iso = unique(climada_mriot.countries_iso,'stable');
unique_countries = unique(climada_mriot.countries,'stable');
unique_sectors = unique(climada_mriot.sectors,'stable'); %#ok
unique_climada_sectors = unique(climada_mriot.climada_sect_name,'stable');
% Use unique() instead of categories() since the latter does not keep the
% original order. The 'stable' argument locks the order of the unique
% values as they appear in the full array.

%TEMPORARY WORK-AROUND FOR PROBLEM THAT ORDER OF CLIMADA SECTORS IS
%CONFUSED DUE TO "SERVICES" APPEARING ONCE BEFOE UTILITIES. BUT SHOULD BE
%LAST (CLIMADA_SECTOR_ID = 6). THIS IS ACTUALLY QUITE A LARGE ISSUE, SINCE
%IT WILL BE DIFFERENT FOR DIFFERENT MRIOTS AND THE ORDER OF THE CLIMADA
%SECTOR DOES NOT NECESSARILY HAVE TO BE ALWAYS THE SAME UNLESS(!) WE DEFINE
%IT TO BE A USER REQUIREMENT FOR THE MAPPING TABLE THAT IT IS. THIS OPTION
%WOULD BE EASIEST TO IMPLEMENT. BUT(!!) IT REQUIRES THAT THE MRIOT IS
%STRUCTURED IN A WAY THAT ALL SUBSECTOR BELONGING TO THE SAME MAINSECTOR
%(NOT EXPLICITLY DEFINED IN A MRIOT) ARE CLUSTERED TOGETHER. THE WIOD AND
%EXIOBASE ARE CURRENTLY BOTH STRUCTURED THIS WAY (AND IT DOES MAKE MUST SENSE
%TO DO SO), BUT WHAT ABOUT OTHER TABLES?..
if contains(char(unique_climada_sectors(end-1)),'service','IgnoreCase',true)
    swap = unique_climada_sectors(end-1);
    unique_climada_sectors(end-1) = unique_climada_sectors(end);
    unique_climada_sectors(end) = swap;
end

% Get no. of climada_sectors (the main sectors):
% (Not hardcoded to 6 in case changes in future)
no_of_climada_sectors = length(categories(climada_mriot.climada_sect_name));

% Data length; the length of the new sectors and countries arrays
% as well as each mrio_data matrix dimension. Simply the product of the no.
% of climada sectors and the no. of countries in the mriot:
data_length = no_of_climada_sectors*no_of_countries;

% Setting up resulting struct:
aggregated_mriot(1).countries = [];
aggregated_mriot(1).countries_iso = [];
aggregated_mriot(1).sectors = [];
aggregated_mriot(1).aggregation_info = [];
aggregated_mriot(1).mrio_data = [];
aggregated_mriot(1).table_type = climada_mriot.table_type;
aggregated_mriot(1).filename = climada_mriot.filename;
aggregated_mriot(1).no_of_countries = climada_mriot.no_of_countries;
aggregated_mriot(1).no_of_sectors = no_of_climada_sectors;
% The set-up for the field aggregation_info (itself a struct):
for i = 1:no_of_climada_sectors
   field_name = char(unique_climada_sectors(i));
   aggregation_info(1).(field_name) = []; % Parentheses allow dynamic creation of field names based on provided string.
end
aggregated_mriot(1).aggregation_info = aggregation_info;
clear aggregation_info;

% Pre-allocate new (aggregated) mrio_data field:
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
        sum_i = ((climada_mriot.climada_sect_id == climada_sector_i) & climada_mriot.countries_iso == unique_iso(country_i))'; % Transpose to a (logical) column vector
        aggregated_mriot.mrio_data(row_i,col_i) = sum(climada_mriot.mrio_data(sum_i,col_i));
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
        sum_i = ((climada_mriot.climada_sect_id == climada_sector_i) & climada_mriot.countries_iso == unique_iso(country_i)); % Here no transposing since we want a row vector.
        aggregated_mriot.mrio_data(row_i,col_i) = sum(aggregated_mriot.mrio_data(row_i,sum_i));
    end %inner column loop
end %outer row loop
% toc % Approx. 5 seconds.
% Remove all now obsolete columns with indices > data_length:
        aggregated_mriot.mrio_data(:,(data_length+1):end) = [];

% Now add remaining fields to the structure:
% First, the more complicated countries and countries_iso fields.
% Note that there is an quivalent loop-construct in function
% climada_read_mriot.
% tic
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
% toc % Approx 0.1 seconds

% Now the simpler sectors:
aggregated_mriot.sectors = repmat(unique_climada_sectors,1,no_of_countries);
 
% Finally, the field with the aggregation info (itself a struct with k
% fields, where k = no. of climada sectors (here 6)).
for i = 1:no_of_climada_sectors
    field_name = char(unique_climada_sectors(i));
    sub_sectors = climada_mriot.sectors(climada_mriot.climada_sect_name == unique_climada_sectors(i));
    aggregated_mriot.aggregation_info.(field_name) = unique(sub_sectors,'stable');
end



