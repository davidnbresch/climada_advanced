% function [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_master(admin0_name, subsector_name, risk_measure) % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
% CALLING SEQUENCE:
%   mrio_master(country_name, sector_name, risk_measure)
% EXAMPLE:
%   mrio_master('Switzerland', 'Agriculture', 'EAD')
%   mrio_master
% INPUTS:
%  
% OPTIONAL INPUT PARAMETERS:
%   admin0_name: the country name, either full (like 'Puerto Rico')
%       or ISO3 (like 'PRI'). See climada_country_name for names/ISO3
%   subsector_name: the subsector name, see e.g. mrio_read_table
%   risk_measure: the risk measure to be applied (string), default is ='EAD' (Expected Annual Damage)
% OUTPUTS:
%   risk: risk per country and sector based on the risk measure chosen
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial (under construction)

% import/setup global variables
% global climada_global
% if ~climada_init_vars,return;end
         
% poor man's version to check arguments
if ~exist('risk_measure', 'var'), risk_measure = []; end
%if ~exist('admin0_name', 'var'), country_name = []; end
%if ~exist('subsector_name', 'var'), sector_name = []; end
%if ~exist('silent_mode','var'), silent_mode = 0; end

% DEFAULT PARAMETERS; useful in development phase to go through all
% calculations with default values so that no file dialogs etc. are opened:
params = mrio_get_params;   % Can also be used with input arguments 'wiod' or 'exiobase' to choose prefered MRIO table. 
                            % If no argument is passed, default is the WIOD table.
if isempty(risk_measure), risk_measure = 'EAD'; end

% read MRIO table
fprintf('Reading MRIO table...\n');tic;
climada_mriot = mrio_read_table(params.mriot.file_name,params.mriot.table_flag);toc

% aggregated MRIO table:
fprintf('Aggregating MRIO table...\n');tic;
aggregated_mriot = mrio_aggregate_table(climada_mriot,params.full_aggregation);toc

% load (TEST) hazard
fprintf('Loading hazard set...\n');tic;
hazard = climada_hazard_load(params.hazard_file);toc

% load centroids and prepare entities for mrio risk estimation 
fprintf('Loading centroids and prepare entities for mrio risk estimation...\n');tic;
entity = mrio_entity_prep(params.entity_file.agri, params.centroids_file, climada_mriot);toc

% calculate direct risk for all countries and sectors as specified in mrio table
fprintf('Calculating direct risk for all countries and sectors as specified in mrio table...\n');tic;
[direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(entity, hazard, climada_mriot, aggregated_mriot, risk_measure);toc

% finally, quantifying indirect risk using the Leontief I-O model
fprintf('Quantifying indirect risk using the Leontief I-O model...\n');tic;
[total_subsector_risk, total_country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);toc

% calculating the ratios of direct to indirect risk for both the subsectors
% and the country risk. The resulting values are incorporated into the
% final result tables as an additional variable.
fprintf('Calculating direct to indirect risk ratios...\n');tic;
[subsector_risk, country_risk] = mrio_risk_ratios_calc(direct_subsector_risk,subsector_risk,direct_country_risk,country_risk);toc

% if specified in params struct, write final results to an excel file for better readability:
if params.write_xls == 1 
    fprintf('Writing final results to an excel file located in module/data/results ...\n');tic;
    mrio_write_results_xls(direct_subsector_risk,direct_country_risk,subsector_risk,country_risk);
end

% end % mrio_master