% climada_tc_event_damage_ens
% MODULE:
%   LOCAL
% NAME:
%   climada_tc_event_damage_ens
% PURPOSE:
%   Given a single track file, calculate the damage for all countries
%   posibbly hit (i.e. at least one node within country boders)
%   
%   Plus generate ensemble 'forecast' damage
%
%   run as a script in order to allow access to all generated data
%
%   See also: weather.unisys.com/hurricane
% CALLING SEQUENCE:
%   global_max_damage % a batch file
% EXAMPLE:
% INPUTS:
%   Select the region and event from selection lists , the single TC track
%       file is downloaded from UNISYS and processed  
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20151009
% David N. Bresch, david.bresch@gmail.com, 20151018 automatic country detection

% init global variables
global climada_global
if ~climada_init_vars,return;end

if ~exist('track_filename','var'),track_filename = ''; end
if ~exist('country_name','var'),country_name = ''; end


% PARAMETERS
%
% for experimenting, you might set parameters here (otherwise asked at first call)
% track_filename = [climada_global.data_dir filesep 'tc_tracks' filesep '20071116_SIDR_track.dat'];
% country_name='Bangladesh';
%
% number of tracks (incl original one)
n_tracks=100; % 100 is far good enough
%
% UNISYS regions
UNISYS_regis{1}='atlantic';
UNISYS_regis{2}='e_pacific';
UNISYS_regis{3}='w_pacific';
UNISYS_regis{4}='s_pacific';
UNISYS_regis{5}='s_indian';
UNISYS_regis{6}='n_indian';
%
% UNISYS year (usually the actual one)
UNISYS_YEAR=datestr(today,'yyyy'); % e.g. '2015';

% prompt for the region
[selection,ok] = listdlg('PromptString','Select region:',...
    'ListString',UNISYS_regis,'SelectionMode','SINGLE');
pause(0.1)
if ok
    UNISYS_REGI=UNISYS_regis{selection};
end

% fetch the index of all events
url_str=['http://weather.unisys.com/hurricane/' UNISYS_REGI '/' UNISYS_YEAR '/index.php'];
fprintf('fetching %s\n',url_str);
index_str = urlread(url_str);
% kind of parse index_str to get names
UNISYS_names={};
for event_i=100:-1:1
    for black_red=1:2
        if black_red==1
            check_str=['<tr><td width="20" align="right" style="color:black;">' num2str(event_i) '</td><td width="250" style="color:black;">'];
        else
            check_str=['<tr><td width="20" align="right" style="color:red;">' num2str(event_i) '</td><td width="250" style="color:red;">'];
        end
        
        pos=strfind(index_str,check_str);
        if pos>0
            UNISYS_names{end+1}=index_str(pos+length(check_str):pos+length(check_str)+25);
        end
    end % black_red
end % event_i

[selection,ok] = listdlg('PromptString','Select event:',...
    'ListString',UNISYS_names,'SelectionMode','SINGLE');
pause(0.1)
if ok
    UNISYS_NAME=UNISYS_names{selection};
    % get rid of all clutter
    UNISYS_NAME=strrep(UNISYS_NAME,'Super ','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Tropical Depression','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Tropical Storm','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Typhoon-1','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Typhoon-2','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Typhoon-3','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Typhoon-4','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Typhoon-5','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Hurricane-1','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Hurricane-2','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Hurricane-3','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Hurricane-4','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Hurricane-5','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Cyclone-1','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Cyclone-2','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Cyclone-3','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Cyclone-4','');
    UNISYS_NAME=strrep(UNISYS_NAME,'Cyclone-5','');
    UNISYS_NAME=strrep(UNISYS_NAME,' ','');
    UNISYS_NAME=strrep(UNISYS_NAME,' ','');
else
    return
end

% fetch the tc track data from the internet
url_str=['http://weather.unisys.com/hurricane/' UNISYS_REGI '/' UNISYS_YEAR '/' UNISYS_NAME '/track.dat'];
fprintf('fetching %s\n',url_str);
track_data_str = urlread(url_str);
track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep  UNISYS_REGI '_' UNISYS_YEAR '_' UNISYS_NAME '.dat'];
fprintf('saving as %s\n',track_filename);
fid=fopen(track_filename,'w');
% write to single track file
fprintf(fid,'%s\r\n',track_data_str);
fclose(fid);

% get TC track (prompting for file to be selected)
[tc_track,track_filename]=climada_tc_read_unisys_track(track_filename);

% automatically detec country/ies
country_list={};
shapes=climada_shaperead(climada_global.map_border_file); % get country shapes
for shape_i = 1:length(shapes)
    in = inpolygon(tc_track.lon,tc_track.lat,shapes(shape_i).X,shapes(shape_i).Y);
    if sum(in)>0
        country_list{end+1}=shapes(shape_i).NAME;
    end
end % shape_i

if length(country_list)==0 % prompt for country, as no direct hit
    country_list{1}=climada_country_name('SINGLE'); % obtain country
end

for country_i=1:length(country_list)
    
    country_name=char(country_list{country_i});
    
    fprintf('*** processing %s:\n',country_name);
    
    if isempty(country_name) % usually not the case any more, but left in, in case one would like to use this
        [country_name,country_ISO3,shape_index]=climada_country_name('SINGLE'); % obtain country
    else
        [country_name,country_ISO3,shape_index]=climada_country_name(country_name); % just get ISO3
    end
    country_name=char(country_name);
    country_ISO3=char(country_ISO3);
    
    tc_tracks=climada_tc_random_walk(tc_track,n_tracks-1,0.1,pi/30); % /15
    
    % get entity and centroids
    entity=climada_entity_load([country_ISO3 '_' country_name '_entity']);
    centroids=climada_centroids_load([country_ISO3 '_' country_name '_centroids']);
    %entity=climada_assets_encode(entity,centroids);
    
    figure('Name',['TC ensemble ' country_name],'Position',[199 55 1076 618],'Color',[1 1 1]);
    subplot(1,2,1)
    climada_entity_plot(entity,4)
    % plot(tc_track.lon,tc_track.lat,'-r');axis equal; hold on
    % climada_plot_world_borders(1,country_name,'',1)
    plot(tc_track.lon,tc_track.lat,'-r')
    plot(tc_track.lon(logical(tc_track.forecast)),tc_track.lat(logical(tc_track.forecast)),'xr')
    
    for track_i=1:length(tc_tracks),plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b');end
    plot(tc_tracks(1).lon,tc_tracks(1).lat,'-r','LineWidth',2); % orig track
    axis off
    xlabel('red crosses: forecast timesteps, blue:ensemble members','FontSize',8);
    title(country_name,'FontSize',18,'FontWeight','normal');drawnow
    
    damage=zeros(1,length(tc_tracks)); % allocate
    
    for track_i=1:length(tc_tracks)
        hazard=climada_tc_hazard_set(tc_tracks(track_i),'NOSAVE',centroids);
        hazard.frequency=1;
        EDS(track_i)=climada_EDS_calc(entity,hazard);
        damage(track_i)=EDS(track_i).damage;
    end % track_i
    
    subplot(1,2,2)
    hist(damage); % plot
    [counts,centers]=hist(damage); % get info
    set(gca,'FontSize',18),xlabel('damage [USD]','FontSize',18),ylabel('event count','FontSize',18)
    hold on;plot(damage(1),0,'xr');
    ddamage=(max(damage)-min(damage))/(2*length(counts));
    text(damage(1)+ddamage,1,'damage','Rotation',90,'Color','red','FontSize',18);
    [max_damage,track_i] = max(damage);
    tc_track_name=lower(tc_track.name);
    title([[upper(tc_track_name(1)) tc_track_name(2:end)]  ' @ ' country_name],'FontSize',18,'FontWeight','normal');drawnow
    %plot(damage(track_i),0,'xb');
    %text(damage(track_i),0,'max ensemble damage','Rotation',90);
    subplot(1,2,1);hold on;
    plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b','LineWidth',2); % max damage track
    
end % country_i