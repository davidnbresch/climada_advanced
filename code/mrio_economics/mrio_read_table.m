function climada_mriot=mrio_read_table(mriot_file,table_flag)
% MODULE:
%   climada_advanced
% NAME:
%   read_mriot
% PURPOSE:
%   Reads data from a provided mrio table (mriot) into a climada mriot
%   struct. Currently made to work with EXIOBASE (industry-by-industry)
%   table and WIOD. CHECK USER-REQUIREMENTS FOR TABLES PASSED AS ARGUMENTS. 
%   IF NOT ADHERED TO, FUNCTION DOES NOT WORK AS EXPECTED.
%   
%   previous call:
%
%   next call: climada_aggregate_mriot 
%
% CALLING SEQUENCE:
%  
% EXAMPLE:
%   mrio_read_table; no arguments provided. Prompted for via GUI.
%   mrio_read_table('WIOT2014_Nov16_ROW.xlsx',wiod); importing a WIOD table.
%   mrio_read_table('mrIot_version2.2.2.txt',exio); importing an EXIOBASE table.
%
% INPUTS:
%
% OPTIONAL INPUT PARAMETERS:
%   mriot_file: path to a mriot file (currently either WIOD or EXIOBASE).
%       Promted for via GUI if not provided. 
%   table_flag: flag to mark which table type. If not provided, prompted for
%      via GUI. If still not provided, try to deduce from provided file's 
%       name (RELIES ON CERTAIN NAME STRUCTURE AND FILE EXTENSION!) 
%       (this is currently not fully implemented). 
%       Flag is also used in resulting climada mriot structure to keep info on 
%       table's origins.
% OUTPUTS:
%   climada_mriot: a structure with ten fields. It represents a general climada
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
%
% GENERAL NOTES:
% The function is not as flexible as it could be due to difficulties with
% differing file types and basic structures of the various MRIOT's. It
% relies on internal functions targeted at each of the MRIOT versions.
% Further, it relies on the user following certain requirements for the
% data provided and on several occasions has too hard-coded passages. To be
% removed in future. Generally, the code is longish and
% certainly with lots of potential for improvement (especially regarding 
% parameter definitions). Basic functionality is provided.
%
% Currently, importing a WIOD table takes approx. 130 seconds, a (larger) EXIOBASE 
%   table approx. 80 seconds.
%
% NO IN-DEPTH TESTING OF RESULTS CONDUCTED YET!
%
% POSSIBLE EXTENSIONS TO BE IMPLEMENTED:
% Maybe add an optional input argument "aggregate_flag" or so where, if 1,
% the function directly calls climada_aggregate_mriot in the end and returns
% the aggregated mriot as a second optional output (for more info, check header 
% of function climada_aggregate_mriot).
%
% Possibly also add a "saving-flag" where, if 1, the resulting mriot struct
% is saved as an .m file. So the user can choose do delete the result from
% the workspace if computer working memory is at its limits.
%
%
% MODIFICATION HISTORY:
% Kaspar Tobler, 20171207 initializing function
% Kaspar Tobler, 20171208 adding import capabilities for both WIOD and EXIOBASE table
% Kaspar Tobler, 20171209 finishing raw prototype version such that function works for WIOD and EXIOBASE tables. 
% Kaspar Tobler, 20180117 corrected local function read_exiobase: climada_sector_id was saved as categorical whereas it should be double (otherwise aggregation doesn't work). Now ok.
% Kaspar Tobler, 20180117 adapted Exiobase input to account of fact that there are five different ROW regions and for fact that certain used country names are not recognised by climada_country_name. 
% Kaspar Tobler, 20180125 made import of exiobase more resilient regarding the treatment of the "types" file. Now also possible to have several versions of it in folder and choose one via user-dialog.

climada_mriot=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('mriot_file','var'),mriot_file=[];end 
if ~exist('table_flag','var'),table_flag=[]; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
% account for different directory structures
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir=[climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
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
        mriot_file=fullfile(pathname,filename);
    end
end

%Promt for table_flag (which table type?) if not passed:
if isempty(table_flag) %If empty, provide GUI list.
    [selection, ok] = listdlg('ListString',{'WIOD','EXIOBASE','OTHER'},...
           'SelectionMode','single','Name','Choose MRIO type','ListSize',[300 100]);
    if isequal(selection,3) || isequal(ok,0)  %If 'OTHER' chosen or canceled. 
        error('Currently, this function only works with either WIOD, EXIOBASE OR EORA26 tables.')
    else  
    %Set table_flag based on selection dialog:
    switch selection
        case 1
            table_flag = 'wiod';
        case 2
            table_flag = 'exiobase';
    end
    end
end % if table_flag is empty


% If only filename and no path is passed, add the latter:
% complete path, if missing
% HAVE ANOTHER CLOSE LOOK!
[fP,fN,fE]=fileparts(mriot_file);
if isempty(fP)
    fP=module_data_dir;
    if strcmpi(table_flag,'wiod')
        fP=[fP filesep 'wiod'];
    elseif strcmpi(table_flag(1:4),'exio')
        fP=[fP filesep 'exiobase']; 
    end
    mriot_file=[fP filesep fN fE];
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

%%% If input is a WIOD table:

if strcmpi(table_flag(1:2),'wi') %In case user provided flag containing typo only compare first two letters.
    
    climada_mriot = read_wiod(mriot_file,climada_mriot);
    
end % Read WIOD type mriot 

%%% If input is an EXIOBASE table:

% First attempt for exiobase table:
if strcmpi(table_flag(1:2),'ex') %In case user provided flag containing typo only compare first two letters.
    
    climada_mriot = read_exiobase(mriot_file,climada_mriot,module_data_dir); %% For exiobase we need the path info in the local function since we also have to find and load the exiobase "types" file, ideally automatically.
    % The long categorical arrays climada_mriot.countries etc.
    % are not shown in the matlab variable editor (there seems to be a
    % max. length of around 4000 elements; longer arrays are not shown). 
    % This is normal behavior.
    warning('The long categorical arrays climada_mriot.countries etc. are not shown in the matlab variable editor (there seems to be a max. length of around 4000 elements; longer arrays are not shown). This is NORMAL behavior.')
    
end % read exiobase type mriot

%% LOCAL FUNCTIONS:

%%%%%%%%%%%%%%  READ WIOD TABLES; LOCAL FUNCTION

function climada_mriot = read_wiod(mriot_file,climada_mriot)


% For platform independence, has to be a .xlsx file, not the WIOD default 
    % .xlsb, with which matlab can only deal on windows if excel installed:
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
                                     %Problem: we rely on future wiod releases using the same ordering of the countries.
                                     
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
 %A possible alternative would be to ask for no. of countries (n) and no. of sectors (m) as
 % function inputs and then obtain no. of relevant lines by n*m. 
    
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

% Check whether user requirements for mapping table are met regarding the
% naming of the climada sectors (have to follow syntax of valid matlab
% identifiers). Since this is of later importance, we try to remedy the most
% common possible mistakes here. Currently doesn't fully work. Check back
% later. Once ok, also implement for exiobase subfunction.
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

climada_sect_id_temp = repmat(sectors(2:end,3),no_countries,1); %Stack up 3rd col (corresponding cliamda sector id (1,2,3,4,5 or 6). 
climada_mriot.climada_sect_id = cell2mat(climada_sect_id_temp)';
clear climada_sect_id_temp

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
clear mrio_data
%toc % ~37 seconds
% Full mriot struct is  ~48.6mb, 99.9% of which from the full quadratic
% mrio_data matrix.

% Set no. of countries/sectors fields:
climada_mriot.no_of_countries = no_countries;
climada_mriot.no_of_sectors = no_sectors;

% Final some sanity checks: equal no. of elements in each field and equal length of
% both data matrix dimensions? Otherwise return error, since further calculations
% will be erroneous.
if ~isequal(length(climada_mriot.sectors),length(climada_mriot.countries_iso),...
        length(climada_mriot.countries),length(climada_mriot.climada_sect_name),...
        length(climada_mriot.climada_sect_id),size(climada_mriot.mrio_data,1),...
        size(climada_mriot.mrio_data,2),(climada_mriot.no_of_countries*climada_mriot.no_of_sectors))
    error('Fatal error importing mrio table: sector, country and mapping dimensions do not agree. Cannot proceed.')
end

%end % read_wiod local function


%%%%%%%%%%%%%%   READ EXIO TABLES; LOCAL FUNCTION
function climada_mriot = read_exiobase(mriot_file,climada_mriot,module_data_dir)

global climada_global

   % For EXIOBASE, main table is in a txt file (user input) and label info is 
   % stored in a separate excel file called types_[version_no]. 
   % We first get this filename. It is by default located in same dir as main table:
   exio_types_file = dir([fileparts(mriot_file) filesep '*types*.xls*']);
   %%% In case there are several copies of "types" files found (e.g.
   %%% different versions, let user choose with which one to go forward:
   if length(exio_types_file) > 1
    [selection, ok] = listdlg('ListString',{exio_types_file.name},...
           'SelectionMode','single','Name','Choose "types" file...','PromptString','We found several exiobase "types" files. Please choose one to work with.','ListSize',[400 100]);
    if isequal(ok,0)  %If 'OTHER' chosen or canceled. 
        error('Without choosing an exiobase "types" file the function cannot proceed.')
    else  
    %Set exio_types_file based on selection dialog:
    exio_types_file = exio_types_file(selection);
    end
   end
       
   % If cannot find fitting file at all, open file dialog:
       if isempty(exio_types_file)
            [filename, pathname] = uigetfile([module_data_dir filesep '*.xls*'], 'Open the EXIOBASE types file:');
            if isequal(filename,0) || isequal(pathname,0)
                error('Please choose the EXIOBASE types files. Cannot proceed without.')
                %return; % cancel pressed by user
            else
                exio_types_file = fullfile(pathname,filename);
            end
       else
           exio_types_file = fullfile(exio_types_file.folder,exio_types_file.name);
       end
       
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
   climada_sect_id = exio_sectors{:,'climada_sect_id'};
        climada_mriot.climada_sect_id = repmat(climada_sect_id,no_countries,1)'; % Use row-vector

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
   % Final mriot structure is ~490mb. > 99.9% due to data matrix
   
       %tic
       % mriot.mrio_data = single(mriot.mrio_data);
       %toc % 0.1 seconds.
       % At single precision, full mriot structure ~250mb. Worth
       % considering, since double precision creates illusion of precision of 
       % the highly uncertain values anyway.
       
% Set no. of countries/sectors fields:
climada_mriot.no_of_countries = no_countries;
climada_mriot.no_of_sectors = no_sectors;
       
 % Final sanity checks:
 if ~isequal(length(climada_mriot.sectors),length(climada_mriot.countries_iso),...
        length(climada_mriot.countries),length(climada_mriot.climada_sect_name),...
        length(climada_mriot.climada_sect_id),size(climada_mriot.mrio_data,1),...
        size(climada_mriot.mrio_data,2))
    error('Fatal error importing mrio table: sector, country and mapping dimensions do not agree. Cannot proceed.')
 end
 
%end % Local function read_exio

        

%end % Main function read_mriot (wraps local functions to have shared
%variable workspace --> Currently not necessary.