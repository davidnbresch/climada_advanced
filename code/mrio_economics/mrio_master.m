% mrio_master % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
% CALLING SEQUENCE:
%   mrio_master
% EXAMPLE:
%   mrio_master
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   subsector_risk_tb: a table containing as one variable the direct risk
%       subsector/country combination selected. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%   country_risk_tb: a table containing as one variable the direct risk per country 
%       (aggregated across all subsectors selected). Further a variable with corresponding 
%       country names and country ISO codes, respectively.
%   IO_YDS, the Input-Output year damage set, a struct with the fields:
%       direct, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       indirect, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       hazard: itself a structure, with:
%           filename: the filename of the hazard event set
%           comment: a free comment
%   leontief: a structure with 5 fields. It represents a general climada
%       leontief structure whose basic properties are the same regardless of the
%       provided mriot it is based on. The fields are:
%           risk_structure: industry-by-industry table of expected annual damages (in millions
%               of US$) that, for each industry, contains indirect risk implicitly
%               obtained from the different industry.
%           inverse: the leontief inverse matrix which relates final demand to production
%           coefficients: either the technical coefficient matrix which gives the amount of input that a 
%               given sector must receive from every other sector in order to create one dollar of 
%               output or the allocation coefficient matrix that indicates the allocation of outputs
%               of each sector
%           layers: the first 5 layers and a remainder term that gives the
%               user information on which stage/tier the risk incurs
%           climada_mriot: struct that contains information on the mrio table used
%           climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial (under construction)
%

% import/setup global variables
% global climada_global
% if ~climada_init_vars,return;end

% Set max encoding distance to 30km (well enough for our purpose):
climada_global.max_encoding_distance_m = 30000;
         
% poor man's version to check arguments
%if ~exist('country_name', 'var'), country_name = []; end
%if ~exist('subsector_name', 'var'), sector_name = []; end
%if ~exist('silent_mode','var'), silent_mode = 0; end

% DEFAULT PARAMETERS; useful in development phase to go through all
% calculations with default values so that no file dialogs etc. are opened:
params = mrio_get_params; % Can also be used with input arguments 'wiod' or 'exiobase' to choose prefered MRIO table. 
                          % If no argument is passed, default is the WIOD table.

% read MRIO table
fprintf('Reading MRIO table...\n');tic;
climada_mriot = mrio_read_table(params.mriot.file_name,params.mriot.table_flag);toc

% aggregated MRIO table:
fprintf('Aggregating MRIO table...\n');tic;
[aggregated_mriot, climada_mriot] = mrio_aggregate_table(climada_mriot,params.full_aggregation,0);toc

% calculate direct risk for all countries and sectors as specified in mrio table
fprintf('Calculating direct risk for all countries and sectors as specified in mrio table...\n');tic;
IO_YDS = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, params);toc

% finally, quantifying indirect risk using the Leontief I-O model
fprintf('Quantifying indirect risk using the Leontief I-O model...\n');tic;
[IO_YDS, leontief] = mrio_leontief_calc(IO_YDS, climada_mriot, params);toc

% Return final results (annual expected damage per sector and country) as tables
fprintf('Return final results (annual expected damage per sector and country) as tables...\n');tic;
[subsector_risk_tb, country_risk_tb] = mrio_get_risk_table(IO_YDS, 'ALL', 'ALL', 0);toc

% calculating the ratios of direct to indirect risk for both the subsectors
% and the country risk. The resulting values are incorporated into the
% final result tables as an additional variable.
fprintf('Calculating direct to indirect risk ratios...\n');tic;
[subsector_risk_tb, country_risk_tb] = mrio_risk_ratios_calc(direct_subsector_risk,subsector_risk_tb,direct_country_risk,country_risk_tb);toc

% if specified in params struct, write final results to an excel file for better readability:
fprintf('Write final results to a simple excel file...\n');tic;
if params.write_xls == 1 
    fprintf('Writing final results to an excel file located in module/data/results ...\n');tic;
    mrio_write_results_xls(direct_subsector_risk,direct_country_risk,subsector_risk_tb,country_risk_tb);
end 
toc

% Get very simple comparison with global total AED computed from emdat
% database for same period of time as looked at in historical storm set of
% mrio module:
fprintf('Obtain simple comparison values from emdat database...\n');tic;
[glb_direct_risk, glb_indirect_risk, glb_emdat_aed] = mrio_emdat_compare(direct_risk_vector,indirect_risk_vector,climada_mriot,params);toc

% end % mrio_master