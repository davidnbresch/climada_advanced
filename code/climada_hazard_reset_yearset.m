function hazard = climada_hazard_reset_yearset(hazard,join_duplicate_years_only,verbose_mode)
% climada TC hazard event set generate new orig_yearset
% NAME:
%   climada_hazard_reset_yearset
% PURPOSE:
%   Reset hazard.orig_yearset and hazard.orig_years 
%
%   (a) for a changed (i.e. cropped) hazard set. climada_hazard_reset_yearset is required to make
%       the computation of YDS work. (See climada_EDS2YDS or
%       climada_tc_hazard_set.) and
%   (b) to get rid of duplicates in the field orig_yearset,
%       as these duplicates cause expected damage mismatches in climada_EDS2YDS
%   
%   Please note: The duplicates in orig_yearset come from a problem in the hazard generation
%   which is not fixed as of today (20180417). Until it is fixed, 
%   please use this function to reset the orig_yearset before computing damage.
%
% CALLING SEQUENCE:
%   hazard = climada_hazard_reset_yearset(hazard,join_duplicate_years_only,verbose_mode)
% EXAMPLE:
%  % Given: hazard and entity (encoded). We want to exclude centroids and events where there is either no intensity or no assets:   
%     centroidList = sort(unique(entity.assets.centroid_index));
%     [~,centroidIndex] = ismember(centroidList,hazard.centroid_ID);
%     centroidList(centroidIndex==0)=[];
%     centroidIndex(centroidIndex==0)=[];
%     
%     centroidsZero = max(hazard.intensity(:,centroidIndex),[],1)==0;
%     centroidList = centroidList(centroidsZero);
%     centroidsZero = ismember(entity.assets.centroid_index,centroidList);
% 
%     entity.assets.lon(centroidsZero)=[];
%     entity.assets.lat(centroidsZero)=[];
%     entity.assets.Value(centroidsZero)=[];
%     entity.assets.Value_unit(centroidsZero)=[];
%     entity.assets.Cover(centroidsZero)=[];
%     entity.assets.DamageFunID(centroidsZero)=[];
%     entity.assets.centroid_index(centroidsZero)=[];
%     entity.assets.Deductible(centroidsZero)=[];
%     entity.assets.Category_ID(centroidsZero)=[];
%     entity.assets.litpop(centroidsZero)=[];
%     entity.assets.Region_ID(centroidsZero)=[];
%     
%     hazard.lat=hazard.lat(centroidIndex);
%     hazard.lon=hazard.lon(centroidIndex);
%     hazard.centroid_ID=hazard.centroid_ID(centroidIndex);
%     hazard.distance2coast_km=hazard.distance2coast_km(centroidIndex);
%     hazard.intensity=hazard.intensity(:,centroidIndex);
%     hazard.fraction=hazard.fraction(:,centroidIndex);
%     
%     eventsNonZero = find(max(hazard.intensity,[],2)>0);
%     hazard.intensity=hazard.intensity(eventsNonZero,:);
%     hazard.fraction=hazard.fraction(eventsNonZero,:);  
%     hazard.event_ID=hazard.event_ID(eventsNonZero);  
%     hazard.mm=hazard.mm(eventsNonZero); 
%     hazard.dd=hazard.dd(eventsNonZero); 
%     hazard.yyyy=hazard.yyyy(eventsNonZero); 
%     hazard.datenum=hazard.datenum(eventsNonZero); 
%     hazard.category=hazard.category(eventsNonZero); 
%     hazard.orig_event_flag=hazard.orig_event_flag(eventsNonZero); 
%     hazard.name=hazard.name(eventsNonZero); 
%     hazard.frequency=hazard.frequency(eventsNonZero); 
%     hazard.orig_event_count = sum(hazard.orig_event_flag);
%     hazard.event_count = length(hazard.event_ID);
%     
%     centroid_ID_new = 1:numel(hazard.lat);
%     centroid_index_new = zeros(size(entity.assets.centroid_index));
%     for i=centroid_ID_new
%             centroid_index_new(entity.assets.centroid_index==hazard.centroid_ID(i))=centroid_ID_new(i);
%     end
%     entity.assets.centroid_index = centroid_index_new;
%     hazard.centroid_ID = centroid_ID_new;
%     entity.assets.filename = hazard.filename;
%
%     hazard = climada_hazard_reset_yearset(hazard,0,1);
% INPUTS:
%   hazard: hazard set (struct)
% OPTIONAL INPUT PARAMETERS:
%   join_duplicate_years_only: default=0: Evaluate part b of function only,
%       no full reset of orig_yearset
%   verbose_mode: default=1, 0: do not print anything to stdout
% OUTPUTS:
%   hazard: hazard set (struct) with updated orig_yearset
% MODIFICATION HISTORY:
% Samuel Eberenz, eberenz@posteo.eu, 20180329, initial
% Samuel Eberenz, eberenz@posteo.eu, 20180406, add functionality b 
% Samuel Eberenz, 20180417, added extra notes in description
% Samuel Eberenz, 20180503, improve verbose mode

if ~exist('hazard','var'),error('no hazard provided.');end
if ~exist('join_duplicate_years_only','var'),join_duplicate_years_only=0;end
if ~exist('verbose_mode','var'),verbose_mode=1;end

%% (a) full reset
% (a alone does not solve the duplicate issue, this requires b)
if ~join_duplicate_years_only
    hazard = rmfield(hazard,'orig_yearset');

    t0       = clock;
    n_events = length(hazard.yyyy);
    if verbose_mode
        fprintf('yearset: processing %i events\n',n_events);
        climada_progress2stdout; % init, see terminate below
    end

    year_i=1; % init
    active_year=hazard.yyyy(year_i); % first year
    event_index=[];event_count=0; % init

    for event_i=1:n_events

        if hazard.yyyy(event_i)==active_year
            if hazard.orig_event_flag(event_i)
                % same year, add if original track
                event_count=event_count+1;
                event_index=[event_index event_i];
            end
        else
            % new year, save last year
            hazard.orig_yearset(year_i).yyyy=active_year;
            hazard.orig_yearset(year_i).event_count=event_count;
            hazard.orig_yearset(year_i).event_index=event_index;
            year_i=year_i+1;
            % reset for next year
            active_year=hazard.yyyy(event_i);
            if hazard.orig_event_flag(event_i)
                % same year, add if original track
                event_count=1;
                event_index=event_i;
            end
        end

        if verbose_mode,climada_progress2stdout(event_i,n_events,100,'tracks');end % update

    end % track_i

    %%
    if verbose_mode,climada_progress2stdout(0);end % terminate

    % save last year
    hazard.orig_yearset(year_i).yyyy=active_year;
    hazard.orig_yearset(year_i).event_count=event_count;
    hazard.orig_yearset(year_i).event_index=event_index;

    t_elapsed = etime(clock,t0);
    msgstr    = sprintf('generating yearset took %3.2f sec',t_elapsed);
    if verbose_mode,fprintf('%s\n',msgstr);end

    min_year   = hazard.yyyy(1);
    max_year   = hazard.yyyy(end); % start time of track, as we otherwise might count one year too much
    hazard.orig_years = max_year - min_year+1;
end % ~join_duplicate_years_only
%% (b) get rid of duplicates in orig_yearset
yyyy_unique = sort(unique([hazard.orig_yearset.yyyy]));
if length(yyyy_unique)~=length([hazard.orig_yearset.yyyy]) ||...
        ~min(yyyy_unique==[hazard.orig_yearset.yyyy])
    if ~verbose_mode, disp(length(yyyy_unique));end
    for orig_year_i = 1:length(yyyy_unique)    
        orig_yearset_new(orig_year_i).yyyy = yyyy_unique(orig_year_i);
        orig_yearset_new(orig_year_i).event_count=sum([hazard.orig_yearset([hazard.orig_yearset.yyyy]==yyyy_unique(orig_year_i)).event_count]);
        orig_yearset_new(orig_year_i).event_index=sort([hazard.orig_yearset([hazard.orig_yearset.yyyy]==yyyy_unique(orig_year_i)).event_index]);
    end
    hazard.orig_yearset = orig_yearset_new;
    clear orig_yearset_new yyyy_unique orig_year_i
end
end

