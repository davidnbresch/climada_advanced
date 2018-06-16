function climada_mriot = mrio_read_table(mriot_file, table_flag)
% mrio read table
% MODULE:
%   climada_advanced
% NAME:
%   mrio_read_table
% PURPOSE:
%   Reads data from a provided mrio table (mriot) into a climada mriot
%   struct. Currently made to work with EXIOBASE (industry-by-industry)
%   table and WIOD. CHECK USER-REQUIREMENTS FOR TABLES PASSED AS ARGUMENTS. 
%   IF NOT ADHERED TO, FUNCTION DOES NOT WORK AS EXPECTED.
%   
%   previous call:
%
%   next call:  % just to illustrate
%       aggregated_mriot = mrio_aggregate_table(climada_mriot, full_aggregation_flag, RoW_flag);
% CALLING SEQUENCE:
%  climada_mriot = mrio_read_table(mriot_file, table_flag);
% EXAMPLE:
%   mrio_read_table; % no arguments provided. Prompted for via GUI.
%   mrio_read_table('WIOT2014_Nov16_ROW.xlsx',wiod); % importing a WIOD table.
%   mrio_read_table('mrIot_version2.2.2.txt',exio); % importing an EXIOBASE table.
%   mrio_read_table('Eora26_2013_bp_T.txt',eora); % importing an EORA26 table.
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   mriot_file: path to a mriot file (currently either WIOD, EXIOBASE or EORA26).
%       Promted for via GUI if not provided. 
%   table_flag: flag to mark which table type. If not provided, prompted for
%      via GUI. If still not provided, try to deduce from provided file's 
%       name (RELIES ON CERTAIN NAME STRUCTURE AND FILE EXTENSION!) 
%       (this is currently not fully implemented). 
%       Flag is also used in resulting climada mriot structure to keep info on 
%       table's origins.
% OUTPUTS:
%   climada_mriot: a structure with 13 fields. It represents a general climada
%   mriot structure whose basic properties are the same regardless of the
%   provided mriot it is based on. The fields are:
%       countries: a categorical array containing the full list of all
%           countries in the order they appear in the
%           industry-by-industry mriot. Index into here with row- or/and 
%           column index of a numeric value in mrio_data (see below) to get
%           origin or/and target country of the commodity exchange represented 
%           by the numeric value.
%           List of countries is repeated m number of times with m =
%           no. of sectors. Memory is no issue due to datatype categorical.
%       countries_iso: 3-digit iso code of each country. As above.
%       sectors: as above for countries, but for all sectos. 
%           List of sectors will be repeated n number of times with n =
%           no. of countries. Memory is no issue due to datatype categorical.
%       climada_sect_name: a categorical array containing the climada
%           sector names as they correspond to the sectors in the "sectors" field
%       climada_sect_id: as for "climada_sect_name" but with the respective
%           cliamda sector id.
%       mrio_data: sector-by-sector numerical data matrix (quadratic). 
%           The actual mriot, without any labels. To get a commodity
%           exchange value of interest, index into here with the
%           corresponding index as extracted from the full countries and/or
%           sectors arrays.
%       table_type: character array simply stating the table type the mriot
%           struct is originally based on.
%       filename: character array specifying the full path to the mriot
%           file originally passed as argument to climada_read_mriot to construct 
%           climada mriot structure.
%       no_of_countries: integer value stating the number of countries that
%           is contained in the mriot struct (i.e. in the table type the
%           struct is based on). Different for different table types and
%           might change with future releases.
%       no_of_sectors: as above but for number of sectors.
%       unit: unit used in the original mriot.
%       RoW_aggregation: a char vector informing about whether several
%           RoW-regions have been aggregated into one. At this step always
%           set to 'None', might be changed by function
%           mrio_aggregate_table.
%       total_production: a numeric column array containing for all country-sector
%           combinations the total production. Total production includes
%           production flowing into final consumption, i.e. not into other
%           sector for further processing.
% GENERAL NOTES:
%   The function is not as flexible as it could be due to difficulties with
%   differing file types and basic structures of the various MRIOT's. It
%   relies on internal functions targeted at each of the MRIOT versions.
%   Further, it relies on the user following certain requirements for the
%   data provided and on several occasions has too hard-coded passages. To be
%   removed in future. Generally, the code is longish and
%   certainly with lots of potential for improvement (especially regarding 
%   parameter definitions). Basic functionality is provided.
%
%   Currently, importing a WIOD table takes approx. 130 seconds, an EXIOBASE 
%   table approx. 80 seconds.
% POSSIBLE EXTENSIONS TO BE IMPLEMENTED:
%   Maybe add an optional input argument "aggregate_flag" or so where, if 1,
%   the function directly calls climada_aggregate_mriot in the end and returns
%   the aggregated mriot as a second optional output (for more info, check header 
%   of function climada_aggregate_mriot).
%
%   Possibly also add a "saving-flag" where, if 1, the resulting mriot struct
%   is saved as an .m file. So the user can choose do delete the result from
%   the workspace if computer working memory is at its limits.
% MODIFICATION HISTORY:
% Kaspar Tobler, 20171207 initializing function
% Kaspar Tobler, 20171208 adding import capabilities for both WIOD and EXIOBASE table
% Kaspar Tobler, 20171209 finishing raw prototype version such that function works for WIOD and EXIOBASE tables. 
% Kaspar Tobler, 20180117 corrected local function read_exiobase: climada_sector_id was saved as categorical whereas it should be double (otherwise aggregation doesn't work). Now ok.
% Kaspar Tobler, 20180117 adapted Exiobase input to account of fact that there are five different ROW regions and for fact that certain used country names are not recognised by climada_country_name. 
% Kaspar Tobler, 20180125 made import of exiobase more resilient regarding the treatment of the "types" file. Now also possible to have several versions of it in folder and choose one via user-dialog.
% Kaspar Tobler, 20180215 finished extension to also provide capabilities to read an EORA26 database.
% Kaspar Tobler, 20180219 small changes to how climada_sect_id is dealt with; now not requiring a user input anymore but using helper function mrio_mainsector_mapping to map existing mainsector names (in climada_sect_name) to the corresponding IDs...
% Kaspar Tobler, 20180418 also import info on total production (including production for final consumption etc.). For now working for WIOD. Eora26 and exiobase follow soon.
% Ediz Herms, ediz.herms@outlook.com, 20180606, save climada_mriot struct as .mat file for fast access
%

climada_mriot = []; % init output

global climada_global
if ~climada_init_vars, return; end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('mriot_file','var'), mriot_file = []; end 
if ~exist('table_flag','var'), table_flag = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
% account for different directory structures
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS

% Prompt for mriot file if not passed
% THE FOLLOWING TWO PROMPTS WILL BE MADE MORE RESILIENT BY TRYING TO CATCH
% ERRORS. CURRENTLY FUNCTION RETURNS ERROR IF USER INPUT FAILES.
if isempty(mriot_file) %If empty, open file dialog.
    [filename, pathname] = uigetfile([module_data_dir filesep '*.*'], 'Open a mrio table file that meets user requirements:');
    if isequal(filename,0) || isequal(pathname,0)
        error('Please choose a mriot file.')
        %return; % cancel pressed by user
    else
        mriot_file = fullfile(pathname,filename);
    end
end

%Promt for table_flag (which table type?) if not passed:
if isempty(table_flag) %If empty, provide GUI list.
    selection_list = {'WIOD','EXIOBASE','EORA26','OTHER'};
    [selection, ok] = listdlg('ListString',selection_list,...
           'SelectionMode','single','Name','Choose MRIO type','ListSize',[300 100]);
     other_index = length(selection_list);
    if isequal(selection,other_index) || isequal(ok,0)  %If 'OTHER' chosen or canceled. 
        error('Currently, this function only works with either WIOD, EXIOBASE OR EORA26 tables.')
    else  
    %Set table_flag based on selection dialog:
    switch selection
        case 1
            table_flag = 'wiod';
        case 2
            table_flag = 'exiobase';
        case 3
            table_flag = 'eora';
    end
    end
end % if table_flag is empty

% If only filename and no path is passed, add the latter:
% complete path, if missing
[fP,fN,fE] = fileparts(mriot_file);
if isempty(fP)
    fP = module_data_dir;
    if strcmpi(table_flag,'wiod')
        fP = [fP filesep 'wiod'];
    elseif strcmpi(table_flag(1:4),'exio')
        fP = [fP filesep 'exiobase']; 
    elseif strcmpi(table_flag(1:4),'eora')
        fP = [fP filesep 'eora26']; 
    end
    mriot_file = [fP filesep fN fE];
end
    
[fP,fN,fE] = fileparts(mriot_file);
if isempty(fE), fE = climada_global.spreadsheet_ext;end
if isempty(fP) % complete path, if missing
    mrio_file = [module_data_dir filesep fN fE];
    if ~exist(mrio_file,'file');
        fprintf('Note: %s does nor exist, switched to .xlsx\n',mrio_file)
        mriot_file = [module_data_dir filesep fN '.xlsx']; % try this, too
    end
end
[fP,fN] = fileparts(mriot_file);
mriot_save_file = [fP filesep fN '.mat'];

if climada_check_matfile(mriot_file, mriot_save_file)
    % there is a .mat file more recent than the Excel
    load(mriot_save_file)
    
    % check for valid/correct climada_mriot.filename
    if isfield(climada_mriot,'mrio_data')
        if ~isfield(climada_mriot,'filename'), climada_mriot.filename = mriot_save_file; end
        if ~strcmp(mriot_save_file ,climada_mriot.filename)
            climada_mriot.filename = mriot_save_file;
            try
                save(mriot_save_file,'climada_mriot')
            catch
                save(mriot_save_file,'climada_mriot','-v7.3')
            end
        end
    end % isfield(climada_mriot,'mrio_data')  
    
else

    % For eora26, there are various files for the table available, depending
    % on which info one is interested in; sector-sector relations, final demand,
    % satellite accounts, value added, etc. Our analysis only works with the first, which in
    % eora26 terminology is termed the "T" matrix (check manual for meaning). We check whether user chose
    % such a T matrix as input. We herebey rely on fixed file name conventions.
    % This has to be stated in the user manual.

    if strcmpi(table_flag(1:3),'eor')
        [~,fN] = fileparts(mriot_file);
        if ~strcmpi(fN(end-1:end),'_T')
            error(['Please provide a file representing the T matrix. You provided a ',...
                fN(end-2:end),' matrix. Check user manual for more details.']);
        end
    end

    % Setting up mriot structure:
    climada_mriot(1).countries = [];
    climada_mriot(1).countries_iso = [];
    climada_mriot(1).sectors = [];
    climada_mriot(1).climada_sect_name = [];
    climada_mriot(1).climada_sect_id = [];
    climada_mriot(1).mrio_data = [];
    climada_mriot(1).table_type = table_flag;
    climada_mriot(1).filename = mriot_file;
    climada_mriot(1).no_of_countries = 0;
    climada_mriot(1).no_of_sectors = 0;
    climada_mriot(1).unit = '';
    climada_mriot(1).total_production = [];
    climada_mriot(1).RoW_aggregation = 'None';

    %%% If input is a WIOD table:

    if strcmpi(table_flag(1:3),'wio') %In case user provided flag containing typo only compare first three letters.

        climada_mriot = read_wiod(mriot_file,climada_mriot);

    end % Read WIOD type mriot 

    %%% If input is an EXIOBASE table:

    if strcmpi(table_flag(1:3),'exi') %In case user provided flag containing typo only compare first three letters.

        climada_mriot = read_exiobase(mriot_file,climada_mriot,module_data_dir); %% For exiobase we need the path info in the local function since we also have to find and load the exiobase "types" file, ideally automatically.
        % The long categorical arrays climada_mriot.countries etc.
        % are not shown in the matlab variable editor (there seems to be a
        % max. length of around 4000 elements; longer arrays are not shown). 
        % This is normal behavior.
        warning('The long categorical arrays climada_mriot.countries etc. are not shown in the matlab variable editor (there seems to be a max. length of around 4000 elements; longer arrays are not shown). This is NORMAL behavior.')

    end % read exiobase type mriot

    %%% If input is an EORA26 table:

    if strcmpi(table_flag(1:3),'eor') %In case user provided flag containing typo only compare first three letters.

        climada_mriot = read_eora26(mriot_file,climada_mriot,module_data_dir); %% For eora26 we need the path info in the local function since we also have to find and load the eora26 "labels" and "FD" files, ideally automatically.

    end % read eora26 type mriot
    
    % save climada_mriot struct as .mat file for fast access
    fprintf('saving mrio struct as %s\n', mriot_save_file);
    try
        save(mriot_save_file,'climada_mriot')
    catch
        save(mriot_save_file,'climada_mriot','-v7.3')
    end
    
end % climada_check_matfile

%%% (TEMPORARY) WORK-AROUND TO REMEDY PROBLEMS WITH SECTORS WITH NEGATIVE
%%% VALUE-ADDED (THESE ARE NOT TOLERABLE FOR UPCOMING CALCULATIONS):
%
%intermediate_consumption = sum(climada_mriot.mrio_data);
%probl_i = find(climada_mriot.total_production' < intermediate_consumption);
%climada_mriot.total_production(probl_i) = climada_mriot.total_production(probl_i)+(intermediate_consumption(probl_i)' - climada_mriot.total_production(probl_i))+1;


%% LOCAL FUNCTIONS:

%%%%%%%%%%%%%%  READ WIOD TABLES; LOCAL FUNCTION

function climada_mriot = read_wiod(mriot_file,climada_mriot)


% For platform independence, has to be a .xlsx file, not the WIOD default .xlsb, with which matlab can only deal on windows if excel installed:
    [~,~,mriot_ext] = fileparts(mriot_file);
    if strcmpi(mriot_ext,'.xlsb') % We can't deal with binary excel files
        error('You provided a binary excel file (.xlsb). Please check user requirements in manual and first change filetype to a non-binary excel file and try again.')
    end
    
    %First read text, i.e. all labels for countries and sectors used in WIOD:
    [~,labels] = xlsread(mriot_file,1); %First sheet contains actual WIOD table.
    %We look in which column we have the country ISO code (in case future
    %WIOD releases change column order):
    for col_i = 1:size(labels,2)
        if any(contains(labels(50,col_i),'AUS')) %We check in the first 50 rows of each column 
                                     %whether it contains the iso-code for Australia (AUS), if it does,
                                     %we assume this to be our countries-column.
                                     %Problem: we rely on future wiod releases using the same ordering of the countries (alphabetical, which is reasonable).
                                     
            countries_column = col_i;
            break
        end
    end
    
    no_header_lines = 0; % Get no. of header lines above actual data matrix
    for row_i = 1:size(labels,1)
        if strcmpi(labels{row_i,countries_column},'AUS')
            no_header_lines = row_i-1;
            break
        end
    end
% Now we need the no. of relevant rows to read, since the last few rows are not Industry-by-industry 
% trade values (rather transport margins, value-added and others). The WIOD table combines these in one large
% table. For now, we are only interested in the actual sector-by-sector commodity exchanges:
% SUBOPTIMAL SEMI-HARDCODED VERSION AS FIRST DRAFT (again relying on non-changing wiod nomenclature):
  no_relevant_lines = 0;
    for i = 0:size(labels,1)
        if ~strcmpi(labels{end-i,countries_column},'TOT') %Using 'TOT' as indicator whether the corresponding row contains non-sector-by-sector data.
            no_relevant_lines = size(labels,1)-i;
            break
        end
    end  

% Now check whether last column contains total output, which we need
% separately. The case for current version of WIOD (wiot2014_Nov16). We
% assume it does not change in future releases. If it does, we calculate it
% directly from the imported data below (uses more resources):
if strcmpi(labels(no_header_lines-2,end),'total output')
    tot_last_row = true;
end
    
% We can now read the countries (here only ISO-codes) column into the mriot structure:
climada_mriot.countries_iso = categorical(labels(no_header_lines+1:no_relevant_lines,countries_column))'; %Store as row vector (hence the ').

% Reading sectors via provided climada_mapping sheet in WIOD table file.
% Here, we rely on properly prepared user input, which for now is only primitively checked:
% This input check is not in ideal place here... 
[~,sheets] = xlsfinfo(mriot_file);
if ~any(contains(sheets,'climada_mapping'))
    error('The provided excel file does not meet user requirements. Please consult manual for proper usage.')
end
% Actually read sectors:
[~, ~,sectors] = xlsread(mriot_file,'climada_mapping');

% To store full sector list corresponding to all entries in the mriot (so we can index into it), 
% we replicate the sector list n no. of times, where n = no. of countries.
no_countries = length(categories(climada_mriot.countries_iso));
%   Vertically stack the sector n no. of times (we do it column-by-column for
%   memory reasons):
%   We again assume a fixed no. of header lines of 1 (for variable names); should be made more
%   flexible or checked for in future versions.
sector_name_temp = repmat(sectors(2:end,1),no_countries,1); %Stack up first column (wiod sector namme)
climada_mriot.sectors = categorical(sector_name_temp)';
% Delete sector_name (frees up approx. 500kb; not too lavish):
clear sector_name_temp

climada_sect_name_temp = repmat(sectors(2:end,2),no_countries,1); %Stack up 2nd col (corresponding climada main-sector name). 
climada_mriot.climada_sect_name = categorical(climada_sect_name_temp)';
clear climada_sect_name_temp

% Climada_sect_id using helper function to map given names to corresponding
% id. For info on how sector names are mapped to an id, see manual.
climada_mriot.climada_sect_id = mrio_mainsector_mapping(climada_mriot.climada_sect_name);


% Check whether user requirements for mapping table are met regarding the
% naming of the climada sectors (have to follow syntax of valid matlab
% identifiers). Since this is of later importance, we try to remedy the most
% common possible mistakes here. Currently doesn't fully work. Check back
% later. Once ok, also implement for exiobase/eora26 subfunction.
%     unique_climada_sectors = unique(climada_mriot.climada_sect_name,'stable');
%         for sector_i = 1:length(unique_climada_sectors)
%             if ~isvarname(char(unique_climada_sectors(sector_i)))
%                 warning('The names used for the sector mapping did not follow the requirements. Trying to remedy.')
%                 % Construct a valid matlab identifier:
%                 valid_name = matlab.lang.makeValidName(char(unique_climada_sectors(sector_i)));
%                 valid_categorical = categorical({valid_name});
%                 % Now we have to change all relevant entries in the
%                 % climada_mriot struct to avoid:
%                 sel_pos = climada_mriot.climada_sect_name == unique_climada_sectors(sector_i);
%                 climada_mriot.climada_sect_name(sel_pos) = valid_categorical;
%             end
%         end
% Finished test/remedy block.


% Use climada_country_name to also obtain full country NAMES corresponding to the ISO-3 codes
% provided in the WIOD table. Process: we work with a categorical array
% from the beginning. We loop through the countries_iso fields in increments equal 
% to the no. of sectors. With this index, we extraxt the ISO-code of each country
% once and use climada_country_name to obtain corresponding country name.
% We replicate the name m no. of times (m = no. of sectors) and save result as
% categorical array which is added to the mriot.countries field. Note that
% the last country group is ROW, which is not an ISO-code, thus
% climada_country_name returns and empty string. 
%tic
climada_mriot.countries = categorical(zeros(1,length(climada_mriot.countries_iso)));
% First obtain no of sectors in WIOD:
no_sectors = length(categories(climada_mriot.sectors));
for country_i = 1:no_sectors:length(climada_mriot.countries_iso)
    country_name = {climada_country_name(climada_mriot.countries_iso(country_i))}; % We convert to cell array en route since char arrays can't be converted to categoricals
    if isempty(country_name{1})
        country_name = {'Rest of World'}; 
    end
    countries_temp = repmat(country_name,1,no_sectors);
    climada_mriot.countries(country_i:country_i+no_sectors-1) = categorical(countries_temp);
end
%toc % Just ~6.5 seconds

% Here, mriot struct only ~5.5kb large due to use of categorical for long arrays.

% Finally read actual sector-by-sector matrix (be careful of last rows and columns 
% which we don't need as of now (containing tranpsport margins, final demand, etc.)!
% --> no. of relevant columns equals that of relevant lines, since the sector-by-sector IOT is
% a quadratic matrix):
%tic
mrio_data_temp = xlsread(mriot_file); % Only reads numeric values, no text
climada_mriot.mrio_data = mrio_data_temp(1:length(climada_mriot.sectors),1:length(climada_mriot.sectors)); %Could also use length of climada_mriot.countries etc.

% Now extract last line containing the total output (i.e. total production)
% of each sector, including all production for final consumers etc. If last
% line does not contain total output, as checked above, calculate it via
% row-sum:
if tot_last_row == true
    climada_mriot.total_production = mrio_data_temp(1:length(climada_mriot.sectors),end);   % Last column of the table.
else
    climada_mriot.total_production = sum(mrio_data_temp(1:length(climada_mriot.sectors),1:end-1),2); % Refine later since if last row did not contain tot, we likely would need to go to 1:end, not end-1...
end

clear mrio_data_temp
%toc % ~37 seconds
% Full mriot struct is  ~48.6mb, 99.9% of which from the full quadratic
% mrio_data matrix.


% Set no. of countries/sectors fields:
climada_mriot.no_of_countries = no_countries;
climada_mriot.no_of_sectors = no_sectors;

% Unit:
climada_mriot.unit = '1e6USD';


% Finally some sanity checks: equal no. of elements in each field and equal length of
% both data matrix dimensions? Otherwise return error, since further calculations
% will be erroneous.
if ~isequal(length(climada_mriot.sectors),length(climada_mriot.countries_iso),...
        length(climada_mriot.countries),length(climada_mriot.climada_sect_name),...
        length(climada_mriot.climada_sect_id),size(climada_mriot.mrio_data,1),...
        size(climada_mriot.mrio_data,2),(climada_mriot.no_of_countries*climada_mriot.no_of_sectors))
    error('Fatal error importing mrio table: sector, country and mapping dimensions do not agree. Cannot proceed.')
end

%end % read_wiod


function climada_mriot = read_eora26(mriot_file,climada_mriot,module_data_dir)

   % For EORA26, main table is in a txt file (user input) and label info is 
   % stored in a separate excel file called 'labels_T.txt'. Further we need
   % data on final demand, which are found in the 'Eora26_2013_bp_FD.txt'
   % file and accompanying labels for the final demand data in the 'labels_FD.txt' file. 
   % Finally, we need the "structure" file (.xls) as the sector mapping by the user is most easily done there. 
   % We first get these addtional filenames. They are by default located in same dir as main table:
   eora_labels_file = dir([fileparts(mriot_file) filesep '*labels_T*']);
   eora_fd_file = dir([fileparts(mriot_file) filesep '*bp_FD*']);
   eora_fd_labels_file = dir([fileparts(mriot_file) filesep '*labels_FD*']);
   eora_structure_file = dir([fileparts(mriot_file) filesep '*tructure.xls*']);
   
   %%% Because the following file check is done on each of above files, it is outsourced to local function "check_file". 
   %%% It first accounts for the  case where there are several copies of "labels", "FD" or "structure" files found (e.g. from several different years), 
   %%% and lets the user choose with which one to go forward and then
   %%% accounts for the case where no file(s) are found in which case a
   %%% file dialog opens as last resort.
   
   eora_labels_file = check_file(eora_labels_file,'*.txt*','eora26 "labels"',module_data_dir);
   eora_fd_file = check_file(eora_fd_file,'*.txt*','eora26 "FD"',module_data_dir);
   eora_fd_labels_file = check_file(eora_fd_labels_file,'*.txt*','eora26 "FD labels"',module_data_dir);
   eora_structure_file = check_file(eora_structure_file,'*.xls*','eora26 "structure"',module_data_dir);
 
  % First, read labels from labels_T file:
  labels = readtable(eora_labels_file,'ReadVariableNames',0);
  % Since the labels_T file already contains the full list of countries and
  % sectors as they appear in the data matrix (i.e. country list repeated m
  % times and sector list n times, with m = no. of sectors and n = no. of
  % countries), the process is straight-forward. Also, the file already contains ISO3 codes.
  
  % To make it one step more resilient against future changes in the order
  % of the columns in the label file, we don't hardcode which column
  % contains which information but find out dynamically. Still, there is some 
  % hardcoded stuff which relies on certain fixed properties of the user input
  % which shall be mentioned in the user manual:
  for col_i = 1:length(labels.Properties.VariableNames)
      if iscell(labels{10,col_i}) % To avoid error that the contains function is applied to a double type. 
          if any(contains(unique(labels{:,col_i}),'Afghanistan'))
                  labels.Properties.VariableNames{col_i} = 'Countries';
          elseif any(contains(unique(labels{:,col_i}),'AFG'))
                  labels.Properties.VariableNames{col_i} = 'ISO3';
          elseif any(contains(unique(labels{:,col_i}),'Agriculture'))
                  labels.Properties.VariableNames{col_i} = 'Sectors';
          end
      end
  end
  
  % Now convert the columns of the table into the different fields of
  % the climada_mriot struct (we also transpose to row vector):
  climada_mriot.countries = categorical(labels{:,'Countries'})';
  climada_mriot.countries_iso = categorical(labels{:,'ISO3'})';
  climada_mriot.sectors = categorical(labels{:,'Sectors'})';
  
  % The eora26 labels file contains a "Total" entry in the last position
  % of the sector column. We remove it:
  tot = climada_mriot.sectors(end);
  if contains(char(tot),'total','IgnoreCase',1)
      sel_rows = find(climada_mriot.sectors == tot);
      climada_mriot.sectors(sel_rows) = [];
  end
  
  % Further, the labels file contains a dummy country for balancing of statistical
  % discrepancies. This has to be removed:
  dummy = climada_mriot.countries(end);
  if contains(char(dummy),'statist','IgnoreCase',1)  % In case is removed in further releases; make sure that we don't accidentally remove an actual country.
    sel_rows = find(climada_mriot.countries == dummy);
    climada_mriot.countries(sel_rows) = [];
    climada_mriot.countries_iso(sel_rows) = [];
  end
  
  % Sanity check:
  if ~isequal(length(climada_mriot.countries),length(climada_mriot.countries_iso),length(climada_mriot.sectors))
      error('Something went wrong. Country, country iso and sector dimensions do not agree.')
  end
  
  % Set no_of_countries and no_of_sectors field:
  climada_mriot.no_of_countries = length(unique(climada_mriot.countries));
  climada_mriot.no_of_sectors = length(unique(climada_mriot.sectors));
  
  % Now import the climada_sector mapping from the structure file:
            % Suppress Matlab warning that variable names where changed upon import: 
                warning('off','MATLAB:table:ModifiedVarnames')
  mapping_ds = datastore(eora_structure_file,'Sheets','climada_mapping');
  mapping_ds.SelectedVariableNames = {'climada_sect_name'};
  climada_sectors = read(mapping_ds);
  climada_sectors = categorical(climada_sectors{:,1})';
  
  % Use repmat to repeat n number of times (n = no. of countries) to match
  % full sector array:
  climada_mriot.climada_sect_name = repmat(climada_sectors,1,climada_mriot.no_of_countries);
  
  % Climada_sect_id using helper function to map given names to corresponding
  % id. For info on how sector names are mapped to an id, see funtion.
  climada_mriot.climada_sect_id = mrio_mainsector_mapping(climada_mriot.climada_sect_name);
          
  % Now read actual mrio data:
  mrio_data = dlmread(mriot_file,'\t');
  
  % If there was a statistical correction term (see above), we have to
  % remove the corresponding values in the matrix (we re-use sel_rows from above):
  sel_cols = sel_rows; % For terminological clarity
  if exist('sel_rows','var') % Only exists if we found any correction terms above
      mrio_data(:,sel_cols) = [];
      mrio_data(sel_rows,:) = [];
  end
  
  % Sanity check:
  if ~isequal(size(mrio_data,1),size(mrio_data,2),length(climada_mriot.countries))
            error('Something went wrong. Data and label dimensions do not agree.')
  end
  
  climada_mriot.mrio_data = mrio_data;

  % The unit is nowhere in the above mentioned files explicitly mentioned. The project's
  % website states it's all in 10^3USD (20180215). We have to assume this
  % remains the same in future versions.
  climada_mriot.unit = '1e3USD';
  
      
  % IMPORTING FINAL DEMAND DATA FOR TOTAL PRODUCTION CALCULATION:
  % First getting labels of final demand file:
  labels_fd = readtable(eora_fd_labels_file,'ReadVariableNames',0);
  % Count how many different final demand categories we have (might change
  % in future). We need this to know how many lines to sum up later in the
  % fd data to obtain total FD for each country.
  first_name = labels_fd{1,1};
  first_name = first_name{1};
  no_of_fd = nnz(count(string(labels_fd{:,1}),first_name));
  
  % Load actual FD data:
  fd_data = dlmread(eora_fd_file,'\t');
  % Remove statistical balance terms, if any:
  smallest_dim = find(size(fd_data) == min(size(fd_data)));
  no_of_additional = min(size(fd_data))- no_of_fd*climada_mriot.no_of_countries;  
  if smallest_dim == 2
      fd_data(:,end-(no_of_additional-1):end) = [];
  else
      fd_data(end-(no_of_additional-1):end,:) = [];
  end
  % Remove equivalent to above TOT term, if any:
  switch smallest_dim
      case 1
          if size(fd_data,2) > length(climada_mriot.countries)
              diff = size(fd_data,2) - length(climada_mriot.countries);
              fd_data(:,end-(diff-1)) = [];
          end
      case 2
          if size(fd_data,1) > length(climada_mriot.countries)
              diff = size(fd_data,1) - length(climada_mriot.countries);
              fd_data(end-(diff-1):end,:) = [];
          end
  end
  
  % Now calculate total output to final demand of each sector:
  output_to_fd = sum(fd_data,2);
  % From here and with previous mrio_data, calculate actual total production of each sector including output to final demand:
  climada_mriot.total_production = sum(climada_mriot.mrio_data,2) + output_to_fd;
  
  %end % read_eora26
    

%%%%%%%%%%%%%%   READ EXIO TABLES; LOCAL FUNCTION
function climada_mriot = read_exiobase(mriot_file,climada_mriot,module_data_dir)

global climada_global

   % For EXIOBASE, main table is in a txt file (user input) and label info is 
   % stored in a separate excel file called types_[version_no]. Further,
   % there is the mrFinalDemand_[version_no] file which we need to calculate total
   % production.
   % We first get the latter two filenames. They are by default located in same dir as the main table:
   exio_types_file = dir([fileparts(mriot_file) filesep '*types*.xls*']);
   exio_fd_file = dir([fileparts(mriot_file) filesep '*FinalDemand*.txt*']);
   %%% In case there are several copies of "types" and/o final deman files found (e.g.
   %%% different versions) or none at all, let user choose (done by
   %%% internal function check_file:
   exio_types_file = check_file(exio_types_file,'*.xls*','exiobase "types"',module_data_dir);
   exio_fd_file = check_file(exio_fd_file,'*.txt*','exiobase "findal demand"',module_data_dir); 
       
   % Now read in and prepare datastore for each relevant sheet in excel file. 
   % First country names:
   %Future Versions: implement check whether "countries" sheet exists and
   %if not promt for user input of relevant sheet name in case future
   %releases change name of sheet containing the countries. Similar below
   %for variable name "CountryName". These requirements for the user input
   %shall also be documented in manual (similar to requirements for entity
   %excel files; see funtion header)...
   country_ds = datastore(exio_types_file,'Sheets','countries');
   country_ds.SelectedVariableNames = {'CountryName'}; % We only want country names since EXIOBASE uses ISO-2, not ISO-3 codes
   country_ds.ReadVariableNames = 1;
   exio_countries = read(country_ds); % Datastore reads in tables.
   exio_countries = categorical(exio_countries.CountryName);
   
   % Store no. of countries used in EXIOBASE:
   no_countries = length(exio_countries);
   % Now create list of ISO-3 codes analogous to current exio_countries
   % list using climada_country_name:
   exio_iso3 = categorical(zeros(no_countries,1));
   for country_i = 1:no_countries
       current_country = char(exio_countries(country_i));
       if contains(current_country,{'south korea'},'IgnoreCase',true) || contains(current_country,{'republic of korea'},'IgnoreCase',true)
            current_country = 'Korea';  % climada_country_name only accepts "Korea" as country name for South Korea;
       elseif contains(current_country,{'russi'},'IgnoreCase',true)
            current_country = 'Russia';  % E.g. Russian Federation (as used in Exiobase types_version2.2.2) not accepted for Russia.
       elseif contains(current_country,{'slovak'},'IgnoreCase',true)
            current_country = 'Slovakia'; % E.g. Slovak Republic not accepted
       end
       % Above test could be made more general, e.g. by checking whether
       % current_country is contained in list = climada_country_name; (all valid argument names) and, if not, user dialog to 
       % choose actual country of interest out of drop-down list with all accepted countries.
                 
       [~,iso3] = climada_country_name(current_country);
       
       iso3 = {iso3}; % Convert to (one-element) cell array so it can be converted to categorical
       if isempty(iso3{1}) % The EXIO Rest of World names don't correspond to an ISO-code. 
                           % There are several different ROW-regions in
                           % EXIOBASe. We keep the original name also for
                           % the ISO Code to avoid confusion.
           iso3 = matlab.lang.makeValidName(char(current_country));
           iso3 = {iso3};
                
       end
       exio_iso3(country_i) = categorical(iso3);
   end
   % Now get sector names, corresponding climada sector names and ids:
   % (In future, include similar sheet name checks as suggested above)
   sector_ds = datastore(exio_types_file,'Sheets','climada_mapping');
   % Future include checks for correct variable names and return error if
   % are not as specified in user manual.
   exio_sectors = read(sector_ds);
   
   % Create mriot struct with sectors and countries field representing
   % full table length; i.e. replicating country list m no. of times (m = no.
   % of sectors) and sector list n no. of times (n = no. of countries).
   % First, also get no. of sectors (no. of countries obtained above):
   no_sectors = length(exio_sectors.sector_name);
   % Pre-allocate mriot.countries and mriot.countries_iso:
   %tic
   climada_mriot.countries = categorical(zeros(1,no_countries*no_sectors));
   climada_mriot.countries_iso = categorical(zeros(1,no_countries*no_sectors));
   j = 1;     % Needed to index into mriot.countries and mriot.countries_iso at correct positions for
              % insertion of temp_country and temp_iso arrays.
   for country_i = 1:no_countries
       temp_countries = repmat(exio_countries(country_i),1,no_sectors);
       temp_iso = repmat(exio_iso3(country_i),1,no_sectors);
       climada_mriot.countries(j:j+no_sectors-1) = temp_countries;
       climada_mriot.countries_iso(j:j+no_sectors-1) = temp_iso;
       j = j + no_sectors; % See above
   end
   if ~isequal(length(climada_mriot.countries),length(climada_mriot.countries_iso),no_sectors*no_countries)
       warning('Something went wrong'); %Specify better warnings later
   end
   %toc % only ~0.1 seconds
   
   % Next, we obtain full sector list as in full table length.
   % Here, we can simply stack the current exio_sectors variables
   % vertically n times, with n = no. of countries:
   sector_name = categorical(exio_sectors{:,'sector_name'}); % Index into table
        climada_mriot.sectors = repmat(sector_name,no_countries,1)'; % Use row-vector
   climada_sect_name = categorical(exio_sectors{:,'climada_sect_name'});
        climada_mriot.climada_sect_name = repmat(climada_sect_name,no_countries,1)'; % Use row-vector
        
   % Climada_sect_id using helper function to map given names to corresponding
   % id. For info on how sector names are mapped to an id, see manual.
   climada_mriot.climada_sect_id = mrio_mainsector_mapping(climada_mriot.climada_sect_name);

   % Now import actual mrio table data from main EXIOBASE table file (txt);
   % ignore labels and only import commodity exchange value matrix. Note,
   % raw text file is ~800mb. Import will be a 
   % (no_countries*no_sectors)*(no_countries*no_sectors) quadratic matrix.
   % Pre-allocate:
   climada_mriot.mrio_data = zeros(no_countries*no_sectors);
   %tic
   climada_mriot.mrio_data = dlmread(mriot_file,'\t',2,3); 
   % Row and column offset (2 and 3, respectively) as specified in readme file provided by
   % EXIOBASE. However, should made more flexible to ensure proper working
   % also in future EXIOBASE releases where no. of header lines and label
   % columns might change.
   %toc % ~45 seconds
   % Final mriot structure is ~490mb. 
   
       %tic
       % mriot.mrio_data = single(mriot.mrio_data);
       %toc % 0.1 seconds.
       % At single precision, full mriot structure ~250mb. Worth
       % considering, since double precision creates illusion of precision of 
       % the highly uncertain values anyway.
       
% Set no. of countries/sectors fields:
climada_mriot.no_of_countries = no_countries;
climada_mriot.no_of_sectors = no_sectors;

% Now import final demand data to calculate total sector production. The
% final demand file (.txt) is built up analogously to the full
% sectot-sector table file:
final_demand = dlmread(exio_fd_file,'\t',2,3); 

% Total production of each sector equals sum of total production for other
% sectors and total production for final demand in all countries:
climada_mriot.total_production = sum(climada_mriot.mrio_data,2) + sum(final_demand,2);

% Unit:
% (Currently highly inefficient since entire column is read even though
% only one value needed. Still only takes ~10s, but nevertheless too long... Check back later.
fid = fopen(mriot_file);
units = textscan(fid, '%*s %*s %s %*[^\n]','HeaderLines',2,'Delimiter','\t');
fclose(fid);
units = units{1};
if contains(units,'M.EUR','IgnoreCase',true)
    units = [num2str(1e6*1.20),'USD'];   % RELIES ON EXCHANGE RATE!
else
    units = inputdlg('We could not find the mrio table''s unit. Please specify the unit IN USD as in the examples given:',...
                'Enter unit',[1,70],{'1e6USD, 1000USD, 1USD, etc.'});
            if isempty(units)
                warning('No unit was given by user. 1e6*1.20 USD (1e6EUR) is used as default.')
            else
               units = units{1}; 
            end
end                
climada_mriot.unit = units;
       
 % Final sanity checks:
 if ~isequal(length(climada_mriot.sectors),length(climada_mriot.countries_iso),...
        length(climada_mriot.countries),length(climada_mriot.climada_sect_name),...
        length(climada_mriot.climada_sect_id),size(climada_mriot.mrio_data,1),...
        size(climada_mriot.mrio_data,2))
    error('Fatal error importing mrio table: sector, country and mapping dimensions do not agree. Cannot proceed.')
 end
 
%end % read_exio   

%%% Small local helper function to check for various special cases for user
%%% file input:

function file_variable = check_file(file_variable_in,file_abbr,file_name,module_data_dir)

    if length(file_variable_in) > 1
        [selection, ok] = listdlg('ListString',{file_variable_in.name},...
               'SelectionMode','single','Name','Choose "types" file...','PromptString',['We found several ' file_name ' files. Please choose one to work with.'],'ListSize',[400 100]);
        if isequal(ok,0)  %If 'OTHER' chosen or canceled. 
            error(['Without choosing an ' file_name ' file the function cannot proceed.'])
        else  
        %Set file based on selection dialog:
        file_variable_in = file_variable_in(selection);
        end
    end
    % If cannot find fitting file at all, open file dialog, else save final file name with full path included:    
    if isempty(file_variable_in)
        [filename, pathname] = uigetfile([module_data_dir filesep file_abbr], ['Open the ' file_name ' file.']);
        if isequal(filename,0) || isequal(pathname,0)
            error(['Please choose the ' file_name ' file. Cannot proceed without.'])
            %return; % cancel pressed by user
        else
            file_variable = fullfile(pathname,filename);
        end
    else
        file_variable = fullfile(file_variable_in.folder,file_variable_in.name);
    end
    
    
%end local function check_file

%end % mrio_read_table
%variable workspace --> Currently not necessary.