function hazard=climada_hazard_merge(hazard,hazard2,merge_direction)
% climada WS Europe
% MODULE:
%   advanced
% NAME:
%   hazard=climada_hazard_merge(hazard,hazard2)
% PURPOSE:
%   add hazard2 to hazard, either along centroids or along events or in
%   both directions
%
%   WARNING: this is an expert-level function, some consistency checks are
%   performed, but the output needs to be carefully checked
%
%   previous call: many
%   next call: climada_EDS_calc or e.g. climada_hazard_plot(hazard,0)
% CALLING SEQUENCE:
%   hazard=climada_hazard_merge(hazard,hazard2,merge_direction
% EXAMPLE:
%   hazard=climada_hazard_merge(hazard,hazard2);
% INPUTS:
%   hazard, hazard2: climada hazard event sets, see manual for description
% OPTIONAL INPUT PARAMETERS:
%   merge_direction: if ='centroids', merge in centroids direction, i.e.
%       add centroids, but assume same events.
%       ='events': merge in events direction, i.e. add events, but assume
%       same centroids.
%       ='both': add in both directions, i.e. just add centroids to
%       centroids and events to events
% OUTPUTS:
%   hazard: a climada hazard even set structure, see e.g. climada_tc_hazard_set
%       for a detailed description of all fields. Key fields are:
%       hazard.lon(c): longitude (decimal) of centroid c
%       hazard.lat(c): latitude (decimal) of centroid c
%       hazard.intensity(e,c): the wind speed for event e at centroid c
%       hazard.units: the physical units of intensity, here m/s
%       hazard.event_ID(e): ID of event e (usually 1..hazard.event_count)
%       hazard.event_count: the number of events
%       hazard.frequency(e): the frequency of event e = 1/hazard.orig_years
%       hazard.yyyy(e): the year of event e
%       hazard.mm(e): the month of event e
%       hazard.dd(e): the day of event e
%       hazard.comment: a free comment, contains the regexp passed to this function
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20171108, initial
% David N. Bresch, david.bresch@gmail.com, 20181229, orig_yearset treated, too
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),return;end
if ~exist('hazard2','var'),return;end
if ~exist('merge_direction','var'),merge_direction='events';end

if hazard.reference_year ~= hazard2.reference_year
    fprintf(['Warning: Reference years are not equal: ' int2str(hazard.reference_year) ' and ' int2str(hazard2.reference_year) '\n']);
end

if hazard.peril_ID ~= hazard2.peril_ID
    fprintf(['Warning: Peril IDs are not equal: ' hazard.peril_ID ' and ' hazard2.peril_ID '\n']);
end

if strcmpi(merge_direction,'centroids')
    
    if hazard.orig_years ~= hazard2.orig_years
        fprintf(['Warning: orig years are not equal: ' int2str(hazard.orig_years) ' and ' int2str(hazard2.orig_years) '\n']);
    end
    
    if hazard.event_count ~= hazard2.event_count
        fprintf(['Warning: event counts are not equal: ' int2str(hazard.event_count) ' and ' int2str(hazard2.event_count) '\n']);
    end
    
    hazard.lon = [hazard.lon hazard2.lon];
    hazard.lat = [hazard.lat hazard2.lat];
    no_cen     = size(hazard.lon,2);
    hazard.centroid_ID = 1:no_cen;
    hazard.intensity = [hazard.intensity hazard2.intensity];
    if isfield(hazard,'fraction'),hazard.fraction=[hazard.fraction hazard2.fraction];end
    
end % strcmpi(merge_direction,'centroids')

if strcmpi(merge_direction,'events')
    
    if length(hazard.lon) ~= length(hazard2.lon)
        fprintf(['Warning: centroids count differs: ' int2str(length(hazard.lon)) ' and ' int2str(length(hazard2.lon)) '\n']);
    end
    
    hazard.comment=[hazard.comment 'merged with ' hazard2.comment];
    
    hazard.intensity=[hazard.intensity;hazard2.intensity];
    if isfield(hazard,'fraction'),hazard.fraction=[hazard.fraction;hazard2.fraction];end
    
    hazard.frequency = [hazard.frequency hazard2.frequency];
    hazard.orig_event_flag = [hazard.orig_event_flag hazard2.orig_event_flag];
    hazard.yyyy = [hazard.yyyy hazard2.yyyy];
    hazard.mm = [hazard.mm hazard2.mm];
    hazard.dd = [hazard.dd hazard2.dd];
    
    hazard.orig_years=max(hazard.yyyy)-min(hazard.yyyy)+1;
    
    hazard.event_count=size(hazard.intensity,1);
    hazard.event_ID=1:hazard.event_count;
    hazard.orig_event_count=sum(hazard.orig_event_flag);
    
    fprintf('hazard.frequency re-defined based on hazard.yyyy\n');
    hazard.frequency=ones(1,hazard.event_count)/hazard.orig_years;
    
    if isfield(hazard,'orig_yearset')
        fprintf('combining hazard.orig_yearset by just appending\n');
        hazard.orig_yearset=[hazard.orig_yearset hazard2.orig_yearset];
    end

end % strcmpi(merge_direction,'events')

if strcmpi(merge_direction,'both')
    fprintf('NOT IMPLEMENTED YET\n');
end % strcmpi(merge_direction,'both')

end % climada_hazard_merge