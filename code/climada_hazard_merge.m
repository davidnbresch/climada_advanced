function hazard=climada_hazard_merge(hazard,hazard2,merge_direction,hazard_file)
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
%       same centroids (default)
%       ='both': add in both directions, i.e. just add centroids to
%       centroids and events to events, results in sparse matrix of the
%       form:    X 0
%                0 Y where X=hazard, Y=hazard2
%   hazard_file: if present, save to filename as specified. 
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
% David N. Bresch, david.bresch@gmail.com, 20171229, orig_yearset treated, too
% David N. Bresch, david.bresch@gmail.com, 20171230, frequency inferred
% David N. Bresch, david.bresch@gmail.com, 20180203, hazard_file
% David N. Bresch, david.bresch@gmail.com, 20180312, category, datenum and ID_no added in 'events'
% David N. Bresch, david.bresch@gmail.com, 20190311, name added in 'events'
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),return;end
if ~exist('hazard2','var'),return;end
if ~exist('merge_direction','var'),merge_direction='events';end
if ~exist('hazard_file','var'),hazard_file='';end

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
    hazard2=rmfield(hazard2,'intensity'); % free up memory ASAP
    if isfield(hazard,'fraction')
        hazard.fraction=[hazard.fraction hazard2.fraction];
        hazard2=rmfield(hazard2,'fraction'); % free up memory ASAP
    end

elseif strcmpi(merge_direction,'events')
    
    if length(hazard.lon) ~= length(hazard2.lon)
        fprintf(['Warning: centroids count differs: ' int2str(length(hazard.lon)) ' and ' int2str(length(hazard2.lon)) '\n']);
    end
    
    hazard.comment=[hazard.comment 'merged with ' hazard2.comment];
    
    hazard.intensity=[hazard.intensity;hazard2.intensity];
    hazard2=rmfield(hazard2,'intensity'); % free up memory ASAP
    
    if isfield(hazard,'fraction')
        hazard.fraction=[hazard.fraction;hazard2.fraction];
        hazard2=rmfield(hazard2,'fraction'); % free up memory ASAP
    end
    
    hazard.frequency = [hazard.frequency hazard2.frequency];
    hazard.orig_event_flag = [hazard.orig_event_flag hazard2.orig_event_flag];
    if isfield(hazard,'yyyy'),hazard.yyyy = [hazard.yyyy hazard2.yyyy];end
    if isfield(hazard,'mm'),  hazard.mm   = [hazard.mm hazard2.mm];end
    if isfield(hazard,'dd'),  hazard.dd   = [hazard.dd hazard2.dd];end
    
    if isfield(hazard,'orig_years'),hazard.orig_years=max(hazard.yyyy)-min(hazard.yyyy)+1;end
    
    hazard.event_count=size(hazard.intensity,1);
    hazard.event_ID=1:hazard.event_count;
    if isfield(hazard,'orig_event_flag'),hazard.orig_event_count=sum(hazard.orig_event_flag);end
    
    n_prob_events=hazard.event_count/hazard.orig_event_count-1;
    hazard.frequency = (hazard.frequency*0+1)/(hazard.orig_years*(1+n_prob_events));
    fprintf('WARNING: re-defining frequency based on orig_years (%i) and #prob. events (%i) --> 1/%i years\n',...
        hazard.orig_years,n_prob_events,ceil(1/hazard.frequency(1)));

    if isfield(hazard,'orig_yearset') && isfield(hazard2,'orig_yearset') 
        fprintf('combining hazard.orig_yearset by just appending\n');
        hazard.orig_yearset=[hazard.orig_yearset hazard2.orig_yearset];
    end
    
    if isfield(hazard,'category') && isfield(hazard2,'category') 
        hazard.category=[hazard.category hazard2.category];
    end
    
    if isfield(hazard,'datenum') && isfield(hazard2,'datenum')
        hazard.datenum=[hazard.datenum hazard2.datenum];
    end
    
    if isfield(hazard,'name') && isfield(hazard2,'name')
        hazard.name=[hazard.name hazard2.name];
    end
    
    if isfield(hazard,'ID_no') && isfield(hazard2,'ID_no')
        hazard.ID_no=[hazard.ID_no hazard2.ID_no];
    end
    
    if isfield(hazard,'t_elapsed_footprints') && isfield(hazard2,'t_elapsed_footprints')
        hazard.t_elapsed_footprints = hazard.t_elapsed_footprints+hazard2.t_elapsed_footprints;
    end

end % strcmpi(merge_direction,'events')

if strcmpi(merge_direction,'both')
    fprintf('NOT IMPLEMENTED YET, aborted\n');
    hazard=[];return % return empty
end % strcmpi(merge_direction,'both')

clear hazard2 % free up memory ASAP

if ~isempty(hazard_file)
    % complete path, if missing
    [fP,fN,fE]=fileparts(hazard_file);
    if isempty(fP),fP=climada_global.hazards_dir;end
    if isempty(fE),fE='.mat';end
    hazard.filename=[fP filesep fN fE];
    fprintf('> saving merged hazard as %s\n',hazard.filename);
    save(hazard.filename,'hazard',climada_global.save_file_version);
end

end % climada_hazard_merge