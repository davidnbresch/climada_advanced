function [country_risk,leontief_inverse]=mrio_risk_calc(climada_mriot, country_risk_direct) % uncomment to run as function
% mrio entity
% MODULE:
%   advanced
% NAME:
%   mrio_risk_calc
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
%   [country_risk]=mrio_risk_calc(climada_mriot, country_risk_direct)
% EXAMPLE:
%   climada_read_mriot;
%   mrio_master('Switzerland','Agriculture','100y');
%   [country_risk] = mrio_risk_calc(climada_mriot, country_risk_direct);
% INPUTS:
%   climada_mriot: a structure with ten fields. It represents a general climada
%   mriot structure whose basic properties are the same regardless of the
%   provided mriot it is based on, see climada_read_mriot;
%   country_risk_direct: row vector which contains the direct risk per
%   country based on the risk measure chosen
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   country_risk: the risk per country (direct + indirect) based on the risk measure chosen
%   leontief_inverse: the leontief inverse matrix which relates final demand to production 
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial
% Kaspar Tobler, 20180105, added a few notes/questions. See "Note KT".
% Kaspar Tobler, 20180105, changed order of matrix multiplication in 
    % calculation of country_risk. 


country_risk = []; % init output
leontief_inverse = []; % init output
total_output = [];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%

% Calculate technical coefficient matrix 
[m,n] = size(climada_mriot.mrio_data);
% total_output = sum(climada_mriot.mrio_data); % total output per sector per country (sum up columns)
                % Note KT: Above we have to sum up the individual rows, not columns,
                % I think. The column sum would be total input per sector/country from all
                % other sectors:
     total_output = sum(climada_mriot.mrio_data,2)'; % Transpose to get row vector.
for sector=1:1:m
    leontief_inverse(:,sector) = climada_mriot.mrio_data(:,sector)/total_output(sector); % normalize with total output
end

% Note KT: Maybe calculate Leontief inverse based on technical coefficients first
% and then in separate step final calculation of indirect risk. For
% clarity (also, we might want to offer technical_coeffs matrix as an optional output):
    % First L = (I-A)^-1:
    % technical_coeffs = leontief_inverse;
    % leontief_inverse = inv(eye(size(climada_mriot.mrio_data)) - technical_coeffs);
    % Then final step indir. risk = dirc. risk * L:
    % country_risk = country_risk_direct * leontief_inverse;
    
% country_risk = inv(eye(size(climada_mriot.mrio_data)) - leontief_inverse) * country_risk_direct;
% Change order of matrix multiplication:
    country_risk =  country_risk_direct * inv(eye(size(climada_mriot.mrio_data)) - leontief_inverse);