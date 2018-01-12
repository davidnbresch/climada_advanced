function [risk,leontief_inverse] = mrio_leontief_calc(climada_mriot, risk_direct) % uncomment to run as function
% mrio entity
% MODULE:
%   advanced
% NAME:
%   mrio_leontief_calc
% PURPOSE:
%   Derive total risk whereby we are using Leontief I/O model to estimate indirect risk
%
%   NOTE: see PARAMETERS in code
%
%   previous call:
%
%   next call:  % just to illustrate
%
% CALLING SEQUENCE:
%   [risk] = mrio_risk_calc(climada_mriot, risk_direct)
% EXAMPLE:
%   climada_read_mriot;
%   mrio_master('Switzerland','Agriculture','100y');
%   [risk] = mrio_risk_calc(climada_mrio, risk_direct);
% INPUTS:
%   climada_mriot: a structure with ten fields and among them. It represents a general climada
%   mriot structure whose basic properties are the same regardless of the
%   provided mriot it is based on, see climada_read_mriot;
%   risk_direct: row vector which contains the direct risk per country based on the risk measure chosen
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   risk: the risk per country (direct + indirect) based on the risk measure chosen
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial
%-

total_output = [];

risk = zeros(0,climada_mriot.no_of_sectors*climada_mriot.no_of_countries);
country_risk = zeros(0,length(unique(climada_mriot.countries_iso))); % init output

climada_mriot.mrio_data(isnan(climada_mriot.mrio_data)) = 0; 
techn_coeffs = climada_mriot.mrio_data; 

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%

total_output = nansum(climada_mriot.mrio_data,2); % total output per sector per country (sum up row ignoring NaN-values)

% Calculate technical coefficient matrix
for i = 1:climada_mriot.no_of_sectors*climada_mriot.no_of_countries
    sel_pos = find(~isnan(climada_mriot.mrio_data(:,i)));
    sel_nan = find(isnan(climada_mriot.mrio_data(:,i)));
    climada_mriot.mrio_data(sel_nan,i) = 0;
    if ~isnan(climada_mriot.mrio_data(:,i)./total_output(i))
        techn_coeffs(:,i) = climada_mriot.mrio_data(:,i)./total_output(i); % normalize with total output
    else 
        techn_coeffs(:,i) = 0;
    end
end

leontief_inverse = inv(eye(size(climada_mriot.mrio_data)) - techn_coeffs);

risk = risk_direct * leontief_inverse;

%country_risk = cumsum(risk);