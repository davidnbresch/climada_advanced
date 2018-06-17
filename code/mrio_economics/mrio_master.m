% function [subsector_risk, country_risk, leontief] = mrio_master(country_name, subsector_name) % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
% CALLING SEQUENCE:
%   mrio_master(country_name, subsector_name)
% EXAMPLE:
%   mrio_master('Switzerland', 'Manufacture of chemicals and chemical products')
%   mrio_master
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   country_name: the country name, either full (like 'Puerto Rico')
%       or ISO3 (like 'PRI'). See climada_country_name for names/ISO3
%   subsector_name: the subsector name, see e.g. mrio_read_table
% OUTPUTS:
%   total_subsector_risk: table with indirect and direct risk (EAD) per subsector/country combination 
%       in one variable and three "label" variables containing corresponding country names, country ISO codes and sector names.
%   total_country_risk: table with indirect and direct risk (EAD) per country
%       in one variable and two "label" variables containing corresponding 
%       country names and country ISO codes.
%   direct_subsector_risk: a table containing as one variable the direct risk (EAD) for each
%       subsector/country combination covered in the original mriot. The
%       order of entries follows the same as in the entire process, i.e.
%       entry mapping is still possible via the climada_mriot.setors and
%       climada_mriot.countries arrays. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%   direct_country_risk: a table containing as one variable the direct risk (EAD) per country (aggregated across all subsectors). 
%       Further a variable with correpsonding country names and country ISO codes, respectively.
%   indirect_subsector_risk: table with indirect risk (EAD) per subsector/country combination 
%       in one variable and three "label" variables containing corresponding country names, 
%       country ISO codes and sector names.
%   indirect_country_risk: table with indirect risk (EAD) per country in one variable and two "label" 
%       variables containing corresponding country names and country ISO codes.
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
[direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, params);toc

% finally, quantifying indirect risk using the Leontief I-O model
fprintf('Quantifying indirect risk using the Leontief I-O model...\n');tic;
[total_subsector_risk, total_country_risk, indirect_subsector_risk, indirect_country_risk, leontief] = mrio_leontief_calc(direct_subsector_risk, climada_mriot, params);toc

% calculating the ratios of direct to indirect risk for both the subsectors
% and the country risk. The resulting values are incorporated into the
% final result tables as an additional variable.
fprintf('Calculating direct to indirect risk ratios...\n');tic;
[total_subsector_risk, total_country_risk] = mrio_risk_ratios_calc(direct_subsector_risk,total_subsector_risk,direct_country_risk,total_country_risk);toc

% if specified in params struct, write final results to an excel file for better readability:
fprintf('Write final results to a simple excel file...\n');tic;
if params.write_xls == 1 
    fprintf('Writing final results to an excel file located in module/data/results ...\n');tic;
    mrio_write_results_xls(direct_subsector_risk,direct_country_risk,total_subsector_risk,total_country_risk);
end 
toc

% Get very simple comparison with global total AED computed from emdat
% database for same period of time as looked at in historical storm set of
% mrio module:
fprintf('Obtain simple comparison values from emdat database...\n');tic;
[glb_direct_risk, glb_indirect_risk, glb_emdat_aed] = mrio_emdat_compare(direct_risk_vector,indirect_risk_vector,climada_mriot,params);toc

% end % mrio_master