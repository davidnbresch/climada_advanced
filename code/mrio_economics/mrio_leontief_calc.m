function [risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_mainsector_risk, climada_mriot) % uncomment to run as function
% mrio leontief calc
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
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
%   next call:  % just to illustrate
%   
% CALLING SEQUENCE:
%   [risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_mainsector_risk, climada_mriot);
% EXAMPLE:
%   climada_mriot = climada_read_mriot;
%   entity = mrio_entity(climada_mriot); 
%   hazard = climada_hazard_load;
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
%   [risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(direct_mainsector_risk, climada_mriot);
% INPUTS:
%   risk_direct: row vector which contains the direct risk per country based on the risk measure chosen
%   climada_mriot: a structure with ten fields. It represents a general climada
%   mriot structure whose basic properties are the same regardless of the
%   provided mriot it is based on, see climada_read_mriot;
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   risk: risk per country and sector (direct + indirect) based on the risk measure chosen
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial
% Kaspar Tobler, 20180105, added a few notes/questions. See "Note KT".
% Kaspar Tobler, 20180105, changed order of matrix multiplication calculation of country_risk.
%-

climada_nan_mriot = isnan(climada_mriot.mrio_data); % save nan values to trace affected relationships and values
climada_mriot.mrio_data(isnan(climada_mriot.mrio_data)) = 0; % for calculations we need to replace NaN with zeroes

global climada_global
if ~climada_init_vars,return;end % init/import global variables

total_output = nansum(climada_mriot.mrio_data,2); % total output per sector per country (sum up row ignoring NaN-values)

% Calculate technical coefficient matrix
for i = 1:climada_mriot.no_of_sectors*climada_mriot.no_of_countries
    if ~isnan(climada_mriot.mrio_data(:,i)./total_output(i))
        techn_coeffs(:,i) = climada_mriot.mrio_data(:,i)./total_output(i); % normalize with total output
    else 
        techn_coeffs(:,i) = 0;
    end
end

% Note KT: Maybe calculate Leontief inverse based on technical coefficients first
% and then in separate step final calculation of indirect risk. For
% clarity (also, we might want to offer technical_coeffs matrix as an optional output):

leontief_inverse = inv(eye(size(climada_mriot.mrio_data)) - techn_coeffs);

risk = risk_direct * leontief_inverse;

%country_risk = cumsum(risk);

end % mrio leontief calc