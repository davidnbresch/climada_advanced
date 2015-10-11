% climada_tc_event_damage_ens
% MODULE:
%   LOCAL
% NAME:
%   climada_tc_event_damage_ens
% PURPOSE:
%   Given a single track file, calculate the damage for a given country
%   Plus generate ensemble 'forecast' damage
%
%   run as a script in order to all access to all generated data
% CALLING SEQUENCE:
%   global_max_damage % a batch file
% EXAMPLE:
% INPUTS:
%   On first call, select single TC track file (see
%       climada_tc_read_unisys_track) and country name (from list)
%   On subsequent calls, same track file and country are used
%       (set track_filename='' and country_name='' to start over again)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20151009

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
n_tracks=100;

[tc_track,track_filename]=climada_tc_read_unisys_track(track_filename);

if isempty(country_name)
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
entity=climada_assets_encode(entity,centroids);

figure('Name','TC ensemble','Position',[199 55 1076 618],'Color',[1 1 1]);
subplot(1,2,1)
climada_entity_plot(entity,4)
% plot(tc_track.lon,tc_track.lat,'-r');axis equal; hold on
% climada_plot_world_borders(1,country_name,'',1)
plot(tc_track.lon,tc_track.lat,'-r')
for track_i=1:length(tc_tracks),plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b');end
plot(tc_tracks(1).lon,tc_tracks(1).lat,'-r','LineWidth',2); % orig track
axis off

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
%plot(damage(track_i),0,'xb');
%text(damage(track_i),0,'max ensemble damage','Rotation',90);
subplot(1,2,1);hold on;
plot(tc_tracks(track_i).lon,tc_tracks(track_i).lat,'-b','LineWidth',2); % max damage track

