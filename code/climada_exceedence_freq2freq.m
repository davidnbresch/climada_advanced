function event_freq = climada_exceedence_freq2freq(exceedence_freq)
% climada calculate event frequency based on exceedence frequency
% MODULE:
%   advanced
% NAME:
%   climada_exceedence_freq2freq
% PURPOSE:
%   Calculate event frequency based on exceedence frequency. The reverse
%   from climada_damage_exceedence.
% CALLING SEQUENCE:
%   event_freq = climada_exceedence_freq2freq(exceedence_freq)
% EXAMPLE:
%   event_freq = climada_exceedence_freq2freq(1./[70 10])
% INPUTS:
%   exceedence_freq: exceedence frequencies, i.e. 1./return_period (array)
% OPTIONAL INPUT PARAMETERS:
%   none
% OUTPUTS:
%   event_freq: occurrence frequency of each event damage (array)
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160308, init
%-

event_freq = []; % init

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('exceedence_freq','var'), exceedence_freq = []; end;

if isempty(exceedence_freq), return, end

% make sure this is sorted
[exceedence_freq sort_order] = sort(exceedence_freq);

% do the reverse (compare with climada_damage_exceedence
event_freq = diff(exceedence_freq);
event_freq = [min(exceedence_freq) event_freq];

% bring into the correct order
event_freq = event_freq(sort_order);

return;
