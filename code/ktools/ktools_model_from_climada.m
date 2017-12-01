function ktools_model_from_climada(entity,hazard,doPlot,doCallKtools,ktools_bin_PATH)
% climada ktools OASIS LMF
% MODULE:
%   advanced
% NAME:
%   ktools_model_from_climada
% PURPOSE:
%   This function serves to migrate a climada portfolio and model to a
%   ktools model. From climada we need the 'entity' structure and the
%   'hazard' structure which are the relevant input parameters of this
%   code. This code is written as an example for a tropicaly cyclone wind.
%
%   The code can optionally call ktools, see tag %#ok<ASGLU> and %#ok<NBRAK,ASGLU> in code and
%   ktools_bin_PATH.
%
%   It is meant as a starting point for migrating any model to
%   ktools/Oasis. But there must be code changes depending on the hazard,
%   binning, portfolio etc.
%
%   The output of this code is a set of CSV files which are as specified by the
%   Oasis team in the ktools documentation (GitHub). These CSV files are
%   written into a folder in the user's home directory, into a subfolder
%   named below in the code ('ktools_tcusa' by default).
%
%   From there they can be converted to binary files (.bin) with the standard
%   ktools functions and the loss simulation can be done. We give an example
%   call at the end of this code, but these are as documented in the ktools
%   GitHub.
%
%   It is important to note that we do not expect this code to run for all
%   portfolios and hazards, just because there is a variety of portfolio
%   structures, hazard types and units. But it should serve as a good basis
%   for any climada model.
%
%   Authors of this code:  Marc Wueest and Nadine Koenig (ETH Zurich)
%   Editor of this code: David N. Bresch (ETH Zurich)
%
%   An early version of this code was written and used in a master thesis
%   project in early 2017. The report can be found at 
%   http://www.iac.ethz.ch/the-institute/publications.html?title=&_charset_=UTF-8&authors=koenig&_charset_=UTF-8&rgroup=&pub_type=.
%
% CALLING SEQUENCE:
%   ktools_model_from_climada(entity,hazard,doPlot,doCallKtools)
% EXAMPLE:
%   ktools_model_from_climada; % runs TEST (same entity and hazard as stated below, no execute)
%
%   entity = climada_entity_load('USA_UnitedStates_Florida');
%   hazard = climada_hazard_load('USA_UnitedStates_Florida_atl_TC');
%   ktools_model_from_climada(entity,hazard,1,1,'/usr/local/bin/') % also execute
% INPUTS:
%   entity: an entity structure or an entity .mat file, see climada_assets_encode(climada_assets_read)
%       If a file and no path provided, default path ../data/entities is
%       used (and name can be without extension .mat)
%       > promted for if not given
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       If a file and no path provided, default path ../data/hazards is
%       used (and name can be without extension .mat). If hazard is empty
%       and entity contains hazard in entity.hazard, this hazard is used.
%       > promted for if not given
%       Minimum fileds of hazard struct are:
%       peril_ID, event_ID, centroid_ID, intensity and frequency
% OPTIONAL INPUT PARAMETERS:
%   doPlot: create a check plot of the vulnerability binning (if true), or
%       not (if false, default).
%   doCallKtools: try to call the ktools conversion codes (CSV to BIN) and
%       run the ground-up loss (GUL) simulation. Default=true, hence at least try)
%       If =-1, do not write the .csv files again (only to be used to
%       check/debug ktools once the files have been written).
%   ktools_bin_PATH: to add the path to the (compiled) ktools, 
%       default is='/usr/local/bin/' 
%       On the ETH cluster it will be ='/cluster/apps/climate/ktools/bin'
%       Note that in an earlier version, we used the full system command
%       including 'export PATH=...', e.g. 'export PATH=$PATH:/cluster/apps/climate/ktools/bin'
% OUTPUTS:
% MODIFICATION HISTORY:
% Nadine Koenig, koenigna@student.ethz.ch and maegic@maegic.ch, 20170330, initial
% David N. Bresch, david.bresch@gmail.com, 20170412, climada adjustemnts (no absolute path etc.)
% David N. Bresch, david.bresch@gmail.com, 20170412, ktools_bin_PATH added
% David N. Bresch, david.bresch@gmail.com, 20171201, ktools calling errors catched
% David N. Bresch, david.bresch@gmail.com, 20171201, ktools_bin_PATH prepended to each command
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist( 'entity', 'var' ), entity = []; end
if ~exist( 'hazard', 'var' ), hazard = []; end
if ~exist( 'doPlot', 'var' ), doPlot = []; end
if ~exist( 'doCallKtools', 'var' ), doCallKtools = []; end
if ~exist( 'ktools_bin_PATH', 'var' ), ktools_bin_PATH = ''; end

% PARAMETERS
%
nDamageBins = 100; % =1000, number of damage bins
%
if isempty( doPlot), doPlot = false; end
if isempty( doCallKtools), doCallKtools = true; end % at least try
%
write_files=1;
if doCallKtools<0,write_files=0;doCallKtools= true;end
%
%if isempty( ktools_bin_PATH),ktools_bin_PATH='export PATH=$PATH:/cluster/apps/climate/ktools/bin';end
if isempty( ktools_bin_PATH),ktools_bin_PATH='/usr/local/bin/';end
%
% define the default folder for ktools output
ktools_dir=[climada_global.results_dir filesep 'ktools'];
if ~isdir(ktools_dir)
    mkdir(climada_global.results_dir,'ktools'); % create it
    fprintf('NOTE: storing ktools output data in %s\n',ktools_dir);
end
%
% set default parameters
if isempty( entity )
    try
        entity = climada_entity_load( 'USA_UnitedStates_Florida' ); % larger portfolio and model
    catch
        disp( 'ERROR: No climada entity was provided and no default/example could be loaded.' );
        disp( 'Please provide an entity structure as input or install and start climada in order for the default/example to be loaded.' );
    end
end
if isempty( hazard )
    try
        hazard = climada_hazard_load( 'USA_UnitedStates_Florida_atl_TC' );
    catch
        disp( 'ERROR: No climada hazard was provided and no default/example could be loaded.' );
        disp( 'Please provide a hazard structure as input or install and start climada so the default/example can be loaded.' );
    end
    
end

pwd_backup=pwd;

if ~write_files,fprintf('WARNING: .csv input not written again, just calling ktools\n');end
    
%% Define a name for the model and give the main peril code
% This name also defines the name of the output sub-folder.
modelName = 'tcusa';

%% Set an output directory for the model, i.e. the CSV written.
% Further below the code can try to convert the CSV files to BIN (binary)
% files. This folder is then the model folder for ktools, i.e. ktools (if
% installed correctly) will run from therein.

pathOut = [ ktools_dir filesep 'ktools_' modelName filesep ];
if ~exist( pathOut, 'dir' )
    mkdir( pathOut )
    mkdir( pathOut, 'input' ) % ktools requires a folder named 'input' for the portfolio (items, coverages ..).
    mkdir( pathOut, 'static' ) % ktools requires a folder named 'static' for the model data (event footprints, damage bins ..).
end

fprintf('writing output to %s and sub-folders input and static\n',pathOut);

%% ktools damage bin dictionary

% This example code uses only a reasonable number of linear bins so the the damage
% function well represented. More bins, tailored for a damage function, especially logarithmic bins (for wind)
% will lead to a better convergence to the original climada losses.

binsDamage = table();
% 1st column (according to the ktools documentation) holds the bin_from values.
binsDamage.bin_from = zeros( nDamageBins, 1 ); % initialize plus zero will be start of first bin.
% 2nd column holds the bin_to values
binsDamage.bin_to = ( linspace( 1/nDamageBins, 1, nDamageBins) )';
% Close the bins, i.e. set the bin_from now.
binsDamage.bin_from(2:end) = binsDamage.bin_to(1:end-1);
% 3rd column holds the expected MDR for the bin. We just interpolate.
binsDamage.interpolation = 0.5 * ( binsDamage.bin_from + binsDamage.bin_to );
% 4th column holds the interval type. We don't find sufficient
% documentation of this in ktools GitHub - just a note on 'closed' or
% 'open', but take the example value from there (1201).
binsDamage.interval_type = repmat( 1201, nDamageBins, 1 ); % INTERVAL_TYPE (e.g. closed or open)

if write_files
    fid = fopen( [ pathOut filesep 'static' filesep  'damage_bin_dict' '.csv' ], 'w' );
    fprintf( fid, '%s\n', 'bin_index,bin_from,bin_to,interpolation,interval_type' );
    for i = 1:size(binsDamage,1)
        fprintf( fid,'%i,%16.14f,%16.14f,%16.14f,%i\n', ... % increased precision
            i, ... 'BIN_INDEX'
            binsDamage.bin_from(i), ... 'BIN_FROM'
            binsDamage.bin_to(i), ... 'BIN_TO'
            binsDamage.interpolation(i), ... 'INTERPOLATION'
            binsDamage.interval_type(i) ... 'INTERVAL_TYPE'
            );
    end % for all records of the binning configuration
    fclose( fid );
end % write_files

% Also define the system (DOS or Linux command line) call to convert from
% the CSV file to the BIN (binary file). This needs to happen from the
% model's 'static' folder.
kCall.DamageBins = 'damagebintobin < damage_bin_dict.csv > damage_bin_dict.bin';

%% ktools coverages & items & gulsummaryxref - i.e. the portfolio
% Note that so far no insurance conditions are implemented. We assume a
% ground-up loss (GUL) is calculated. Conditions can though easily be added
% along the ktools documentation.

if write_files
    fid_cov = fopen( [ pathOut filesep 'input' filesep  'coverages' '.csv' ], 'w' );
    fprintf( fid_cov, '%s\n', 'coverage_id,tiv' );
    
    fid_itm = fopen( [ pathOut filesep 'input' filesep  'items' '.csv' ], 'w' );
    fprintf( fid_itm, '%s\n', 'item_id,coverage_id,areaperil_id,vulnerability_id,group_id' );
    
    fid_gsr = fopen( [ pathOut filesep 'input' filesep  'gulsummaryxref' '.csv' ], 'w' );
    fprintf( fid_gsr, '%s\n', 'coverage_id,summary_id,summaryset_id' );
    
    idCoverage = 1;
    idItem = 1;
    
    % Note that in climada a site and a centroid is technically the same. That
    % is, there is no disaggregation in climada. The following lines simply
    % write a very flat structure of coverages, items etc.
    
    for ic = 1:length( entity.assets.centroid_index )
        
        fprintf( fid_cov, '%i,%f\n', ...
            idCoverage, ...
            entity.assets.Value(ic) ... % Total sum insured / insured value
            );
        
        fprintf( fid_gsr, '%i,%i,%i\n', ...
            idCoverage, ... % links to above sum insured (value)
            1, ... summary ID, in our terms a Site
            1 ... summary set ID, in our terms a Policy/Account
            );
        
        % Ideally add the gamma bin to the first 3 digits of the
        % vulnerability curve ID because these don't vary within a
        % model, usually ....
        
        fprintf( fid_itm, '%i,%i,%i,%i,%i\n', ...
            idItem, ...
            idCoverage, ...
            entity.assets.centroid_index(ic), ... % refers directly as in index to the hazard structure
            entity.assets.DamageFunID(ic), ...
            ic );
        
        idItem = idItem + 1;
        idCoverage = idCoverage + 1;
        
    end % for ic: = sites = coverages = centroids = calculation units
    
    fclose( fid_cov );
    fclose( fid_itm );
    fclose( fid_gsr );
end % write_files

% Also define the system (DOS or Linux command line) calls to convert from
% the CSV file to the BIN (binary file). This needs to happen from the
% model's 'input' folder.
kCall.Coverages = 'coveragetobin < coverages.csv > coverages.bin';
kCall.Items = 'itemtobin < items.csv > items.bin';
kCall.gulSummary = 'gulsummaryxreftobin < gulsummaryxref.csv > gulsummaryxref.bin';

%% Clean up hazard file (maybe not even necessary)
% [ hazard.event_ID, ies ] = sort( hazard.event_ID, 'ascend' );
% hazard.frequency = hazard.frequency(ies); clear ies

hazard.intensityAdj = hazard.intensity; % .* hazard.fraction; currently unclear what 'fraction' does exactly.
hazard.intensityAdj = full( hazard.intensityAdj ); % sparse not allowed in below interpolation

%% Intensity bins

% The ktools allow calculating the hazard uncertainty while creating the model.
% I.e. and event & grid point combination can show up multiple times, with
% different bin indices and probabilities, summing up to 1. For now we only
% create one intensity bin per event, with probability 1. All we need is
% the start of the intensity bins, i.e. a bin_from
binsIntensity = table();
% Below example is for the wind of a tropical cyclone, as a 3-second gust
% in m/s. Therefore we use a maximum of about 120 m/s.
binsIntensity.bin_from = linspace( 0, 119, 120 )';
binsIntensity.bin_to   = [ binsIntensity.bin_from(2:end); 999 ]; % high-enough limit
binsIntensity = binsIntensity(1:end-1,:); % cut out last record because of above

% Actually bin the hazard
[~,hazard.bin_index] = histc( hazard.intensityAdj, binsIntensity.bin_from );

%% ktools footprint
% Write the wind fields into a CSV file.

if write_files
    
    fid = fopen( [ pathOut filesep 'static' filesep  'footprint' '.csv' ], 'w' );
    fprintf( fid, '%s\n', 'event_id,areaperil_id,intensity_bin_index,prob' );
    
    % Note that here we don't write the hazard intensity, but its bin!!!
    
    % Order by event_id and areaperil_id (the latter are our calculation units.
    for ie = 1:size(hazard.bin_index,1) % filtered events
        for ic = 1:size(hazard.bin_index,2) % filtered calculation units
            
            if hazard.bin_index(ie,ic) > 1 % Oasis wants no zero hazard records, either, i.e. not bins 1.
                fprintf( fid, '%i,%i,%i,%f\n', ...
                    hazard.event_ID(ie), ...
                    ic, ... % hazard.centroid_ID(ic), ... I can't find the centroid ID in the entity structure in this moment.
                    hazard.bin_index(ie,ic), ...
                    1.0 ); % 'prob', currently set to 1 (100%) because hazard uncertainty already in our hazard set.
            end % if positive hazard
            
        end % for ie all events
    end % for ic in ihc all calculation units
    
    fclose( fid );
    
end % write_files

% As long as we write 'prob' = 1 records we are advise in the ktools
% documentation to create a binary file with option '-n' (no hazard
% uncertainty).

% Also define the system (DOS or Linux command line) call to convert from
% the CSV file to the BIN (binary file). This needs to happen from the
% model's 'static' folder.
kCall.Footprints = [ 'footprinttobin -i ' num2str( size(binsIntensity.bin_from,1) ) ...
    ' -n < footprint.csv > footprint.bin' ];

%% ktools occurrence

% Note that in ktools there are so far no event frequencies!  These must be
% kept outside ktools in reference data. But we can provide an occurrence
% table which is basically an often called 'year loss table' (YLT).

if write_files
    
    % Write a CSV file.
    fid = fopen( [ pathOut filesep 'static' filesep  'occurrence' '.csv' ], 'w' );
    fprintf( fid, '%s\n', 'event_id,period_no,occ_year,occ_month,occ_day' );
    
    % !!! There might be a problem here that an Oasis event can have only one
    % time stamp. If so, shall we just repeat the event with a new reference/ID?
    
    for i = 1:numel(hazard.event_ID)
        
        thisYear = hazard.yyyy(i);
        thisMonth = hazard.mm(i);
        thisDay = hazard.dd(i);
        
        fprintf( fid, '%i,%i,%i,%i,%i\n', ...
            hazard.event_ID(i), ... event_id
            thisYear+1, ... period_no, here 1 calendar year (defined in this static table!!!)
            thisYear, ...
            thisMonth, ...
            thisDay );
        
    end % for all event records
    
    fclose( fid );
end % write_files

% Convert to a binary with parameter '-P' to give the total number of
% periods (1 million years e.g.).

% Also define the system (DOS or Linux command line) call to convert from
% the CSV file to the BIN (binary file). This needs to happen from the
% model's 'static' folder.
kCall.Occurrence = [ 'occurrencetobin -P ' num2str( max(hazard.yyyy) -min(hazard.yyyy) + 1 ) ...
    ' < occurrence.csv > occurrence.bin' ];

%% ktools random numbers
% Currently not pre-sampled, but could be done to make results
% reproducable.

%% ktools areaperil
% This would be the centroids (model grid) but this table does not really exist
% in ktools. The disaggregation happens outside ktools and no areaperil
% attributes are transferred to the kernel (?). Something like it exists in
% the Oasis 1.5.03 distribution for the S1 module though.

% Note that ktools 'getmodel' looks into input/items.csv and only prepares the
% CDF for the calculation units needed for the portfolio.

%% ktools vulnerability

% Identify the damage functions actually needed in the encoded portfolio.
listDamageFunctionID = unique( entity.assets.DamageFunID );

if write_files
    
    % Write a CSV file.
    fid = fopen( [ pathOut filesep 'static' filesep 'vulnerability' '.csv' ], 'w' );
    fprintf( fid, '%s\n', 'vulnerability_id,intensity_bin_index,damage_bin_index,prob' );
    
    for thisDamFunID = listDamageFunctionID
        
        % Identify the records for the damage functions already stored in the encoded structure
        irdf = find( entity.damagefunctions.DamageFunID == thisDamFunID & ...
            ismember( entity.damagefunctions.peril_ID, hazard.peril_ID ) );
        
        % It is important to have a record for all bin combinations (not just for
        % the supporting points).
        for intensityBin = 1:numel( binsIntensity.bin_from )
            
            intensityOfThisBin = ( binsIntensity.bin_from(intensityBin) + binsIntensity.bin_to(intensityBin) ) / 2; % for WS BEL in m/s
            
            % For this intensity bin, ONLY the fill the loss samples
            thisIntList = [];
            
            mddSample = interp1( entity.damagefunctions.Intensity(irdf), ...
                entity.damagefunctions.MDD(irdf), intensityOfThisBin );
            paaSample =  interp1( entity.damagefunctions.Intensity(irdf), ...
                entity.damagefunctions.PAA(irdf), intensityOfThisBin );
            
            % Two parameters for normal distribution
            mdrMu = mddSample .* paaSample; % take this as mean (expected) of the normal distribution
            mdrSigma = 1e-6 .* mdrMu; % for now make it small because beta can 'explode'
            
            % The Matlab beta distribution requires parameters a & b. Calculate these
            % from the expected value mdrMu and the variance mdrSigma^2.
            c = mdrMu .* (1 - mdrMu) ./ (mdrSigma^2) - 1; % c is a helper variable / shortcut
            a = c .* mdrMu;
            b = c .* ( 1 - mdrMu );
            
            % Add a loop over the bins to realize normal distribution
            for idb = 1:size(binsDamage,1)-1
                
                % Each bin gets is share of the CDF. Note that the distribtion
                % goes beyond the range 0..1. So we need to normalize later.
                samplePrb = ...
                    betacdf( binsDamage.bin_to(idb), a, b ) - ...
                    betacdf( binsDamage.bin_from(idb), a, b );
                
                % Catch some special beta distributions.
                if mdrMu == 0 && isnan(c) % These are damage function supporting points with zero MDR.
                    samplePrb = 0;
                end
                
                thisIntList = [ thisIntList; [ ... % actually not necessary if only one loss uncertainty sample
                    thisDamFunID, ... take the ID
                    intensityBin, ... intensity_bin_index
                    idb, ... damage_bin_index
                    samplePrb ... % probability
                    ] ]; %#ok<AGROW>
                
            end % for idb
            
            % Now make sure the total probability is 1.0
            % thisIntList(:,4) = thisIntList(:,4) ./ sum( thisIntList(:,4) );
            
            % Merge samples if they end up in the same bin (for a given
            % intensity). Eliminate damage_bin=0 as we get a 'Segmentation Fault'
            % from ktools 'getmodel'.
            thisIntList = thisIntList( thisIntList(:,3) > 0, :); %
            
            if ~isempty( thisIntList ) % It is actually for intensities with MDD = 0
                
                % Compile a unique list for the damage bins
                UthisIntList = []; % init
                UthisIntList(:,3) = unique( thisIntList(:,3) );
                
                for iu = 1:size( UthisIntList, 1 )
                    
                    tf = ismember( thisIntList(:,3), UthisIntList(iu,3) );
                    
                    UthisIntList(iu,1) = unique( thisIntList(tf,1) ); % ktools (gammafied) vulnerability curve ID: there must only be one
                    UthisIntList(iu,2) = unique( thisIntList(tf,2) ); % intensity_bin_index: there must only be one
                    UthisIntList(iu,4) = sum( thisIntList(tf,4) ); % probability
                    
                end
                
                % Write this intensity's damage bins
                for iu = 1:size( UthisIntList, 1 )
                    
                    fprintf( fid, '%i,%i,%i,%f\n', ... for the safety write the uniques so it crashes or misaligns if not as expected
                        UthisIntList(iu,1), ... ktools (gammafied) vulnerability curve ID
                        UthisIntList(iu,2), ... intensity_bin_index
                        UthisIntList(iu,3), ... damage_bin_index
                        UthisIntList(iu,4) ); % probability
                    
                end % for all damage bins left
                
                %% Plotting the binned vulnerability
                if doPlot
                    if ~exist( 'nColorClasses', 'var' ) % nothing plotted yet
                        
                        % Plot bins grid
                        figure()
                        xlabel( 'intensity (bins)' );
                        ylabel( 'damage ratio (MDR)' );
                        hold on
                        for i=1:numel(binsIntensity.bin_from), plot( [ binsIntensity.bin_from(i), binsIntensity.bin_from(i) ], [0, 1], 'Color', [ 0.8 0.8 0.8] ); end
                        for i=1:size(binsDamage,1), plot( [min(binsIntensity.bin_from), max(binsIntensity.bin_to)], [ binsDamage.bin_from(i), binsDamage.bin_from(i) ], 'Color', [ 0.8 0.8 0.8] ); end
                        
                    end
                    
                    % Color for the intensity/damage probabilities iterated here
                    nColorClasses = 10;
                    colorClassBorders = linspace( 0, 1.0001, nColorClasses+1 );
                    [ ~, UthisIntList(:,5) ] = histc( UthisIntList(:,4), colorClassBorders );
                    
                    for iu = 1:size( UthisIntList, 1 )
                        
                        idb = UthisIntList(iu,3);
                        
                        fill( [ binsIntensity.bin_from(intensityBin), binsIntensity.bin_to(intensityBin), binsIntensity.bin_to(intensityBin), binsIntensity.bin_from(intensityBin) ], ...
                            [ binsDamage.bin_from(idb), binsDamage.bin_from(idb), binsDamage.bin_to(idb), binsDamage.bin_to(idb) ], ...
                            [ 1.0, (nColorClasses-UthisIntList(iu,5))/nColorClasses, (nColorClasses-UthisIntList(iu,5))/nColorClasses ] );
                        
                    end % for iu all bins used by this intensity
                    
                end % if doPlot
                
            end % if positive MDR at all
            
        end % for all ih intensity bins
        clear nColorClasses
        
    end % for all curves
    
    fclose( fid );
end % write_files

% Also define the system (DOS or Linux command line) call to convert from
% the CSV file to the BIN (binary file). This needs to happen from the
% model's 'static' folder.
kCall.Vulnerability = [ 'vulnerabilitytobin -d ' num2str( size(binsDamage.bin_from,1) ) ...
    ' < vulnerability.csv > vulnerability.bin' ];

%% ktools events

% Our understanding from the ktools.pdf is that the list of event ID is
% needed here such that calculations could be partitioned (event buckets)
% and distributed to multiple CPU.

% Note that the event list is actually part of the 'input' (i.e. benchmark
% potfolio specific), i.e. shall not go to the 'static' folder, but the
% 'input' folder.

% Currently I assume that we do first exercises on one CPU so I just copy
% all event ID into the file and assume a call like
%     eve 1 1 | getmodel ...

if write_files
    
    fid = fopen( [ pathOut filesep 'input' filesep  'events' '.csv' ], 'w' );
    fprintf( fid, '%s\n', 'event_id' );
    
    for i = 1:numel(hazard.event_ID)
        
        fprintf( fid, '%i\n', hazard.event_ID(i) );
        
    end % for all event records
    
    fclose( fid );
end % write_files

% Also define the system (DOS or Linux command line) call to convert from
% the CSV file to the BIN (binary file). This needs to happen from the
% model's 'input' folder.
kCall.Events = 'evetobin < events.csv > events.bin';

if doCallKtools
    
    %% Do the CSV (comma separated values) to BIN (binary) conversion
    % This only works if ktools is installed on the same computer and can be
    % found in the shell call. If it fails, try to call ktools manually and/or
    % follow the ktools documentation in GitHub.
    
    % try to add the PATH
    %[ status, cmdout ] = system(ktools_bin_PATH); %#ok<ASGLU>
    
    fprintf('switching to: %s\n',[ pathOut 'input' ]);
    cd( [ pathOut 'input' ] )
    
    fprintf('issuing: %s\n',kCall.Coverages);
    %[ status, cmdout ] = system( kCall.Coverages ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.Coverages] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    fprintf('issuing: %s\n',kCall.Items);
    %[ status, cmdout ] = system( kCall.Items ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.Items] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    fprintf('issuing: %s\n',kCall.gulSummary);
    %[ status, cmdout ] = system( kCall.gulSummary ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.gulSummary] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    fprintf('issuing: %s\n',kCall.Events);
    %[ status, cmdout ] = system( kCall.Events ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.Events] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    %% Try to call a ground-up loss (GUL) simulation.
    % This only works if ktools is installed on the same computer and can be
    % found in the shell call. If it fails, try to call ktools manually and/or
    % follow the ktools documentation in GitHub.
    fprintf('switching to: %s\n',[ pathOut 'static' ]);
    cd( [ pathOut 'static' ] )
    
    fprintf('issuing: %s\n',kCall.DamageBins);
    %[ status, cmdout ] = system( kCall.DamageBins ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.DamageBins] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    fprintf('issuing: %s\n',kCall.Vulnerability);
    %[ status, cmdout ] = system( kCall.Vulnerability ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.Vulnerability] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    fprintf('issuing: %s\n',kCall.Footprints);
    %[ status, cmdout ] = system( kCall.Footprints ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.Footprints] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    fprintf('issuing: %s\n',kCall.Occurrence);
    %[ status, cmdout ] = system( kCall.Occurrence ); %#ok<ASGLU>
    [ status, cmdout ] = system( [ktools_bin_PATH kCall.Occurrence] ); %#ok<ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
    % try to add the
    %[ status, cmdout ] = system(ktools_bin_PATH); %#ok<ASGLU>
    
    % The following produces an event loss table (ELT) for the exported
    % portfolio, using -R random numbers and -S samples. This ELT should
    % correspond to the EDS, if the damage bin sampling is fine enough.
    fprintf('switching to: %s\n',pathOut);
    cd( [ pathOut ] ) %#ok<NBRAK>
    system_call_str=sprintf('eve 1 1 | getmodel | gulcalc -R 100000 -S%i -c - | summarycalc -g -1 - | eltcalc > elt.csv',nDamageBins);
    
    fprintf('issuing: %s\n',system_call_str);
    system_call_str=strrep(system_call_str,'| ',['| ' ktools_bin_PATH]); % full path
    %[ status, cmdout ] = system(system_call_str); %#ok<NBRAK,ASGLU>
    [ status, cmdout ] = system([ktools_bin_PATH system_call_str]); %#ok<NBRAK,ASGLU>
    if status>0 % = 0 means success
        fprintf('ERROR: %s',cmdout) % seems to contain EoL, hence no \n
    else
        fprintf('%s',cmdout); % seems to contain EoL, hence no \n
    end
    
end % if to call ktools

disp( [ 'Your model should be ready now in ' pathOut '.' ] );
disp( [ 'Completed running ' mfilename '.' ] );

cd(pwd_backup) % switch back

end % ktools_model_from_climada