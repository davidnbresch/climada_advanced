%function res=manila_test(param1,param2)
% climada template
% MODULE:
%   adavanced
% NAME:
%   manila_test
% PURPOSE:
%   check Manila for tropical cyclones
%
% CALLING SEQUENCE:
%   manila_test
% EXAMPLE:
%   manila_test
% INPUTS:
%   param1:
%       > promted for if not given
%   OPTION param1: a structure with the fields...
%       this way, parameters can be passed on a fields, see below
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20181130, initial
%-

res=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('param1','var'),param1=[];end % OR:
if ~exist('param1','var'),param1=struct;end % in case we want to pass all parameters as structure
if ~exist('param2','var'),param2=[];end

% locate the module's (or this code's) data folder (usually  a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
FontSize=12;

% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given
if isempty(param2),param2=2;end
%

% generate the asset base on 10km resolution
entity_filename=[climada_global.entities_dir filesep 'PHL_Philippines_10x10.mat'];
if exist(entity_filename,'file')
    entity=climada_entity_load(entity_filename);
else
    entity=climada_entity_country('PHL');
end

% load the globsal TC hazard set
hazard_hist = climada_hazard_load('GLB_0360as_TC_hist');
hazard      = climada_hazard_load('GLB_0360as_TC');

entity=climada_assets_encode(entity,hazard_hist);
EDS    = climada_EDS_calc(entity,hazard_hist,'hist');
EDS(2) = climada_EDS_calc(entity,hazard,'prob');

% define area around Manila
px=[120 120 121 121 120];py=[14 15 15 14 14];
figure;climada_entity_plot(entity,1)
hold on;plot(px,py,'-k');
ip=climada_inpolygon(entity.assets.lon,entity.assets.lat,px,py);
plot(entity.assets.lon(ip),entity.assets.lat(ip),'xg')

Value=entity.assets.Value;
entity.assets.Value=entity.assets.Value*0;
entity.assets.Value(ip)=Value(ip);

EDS(3)=climada_EDS_calc(entity,hazard_hist,'hist Manila');
figure;climada_EDS_DFC(EDS);xlim([0 100])

manila_damage_pos=find(EDS(3).damage);
[x,max_pos]=max(EDS(3).damage);
figure;climada_hazard_plot(hazard_hist,max_pos);xlim([100 150]);ylim([0 30])
children_handle=get(gcf,'Children');
set(children_handle(1),'FontSize',FontSize)
set(children_handle(2),'FontSize',FontSize)
saveas(gcf,[climada_global.results_dir filesep 'Manila_max_hazard'],'png');

yyyy   = hazard_hist.yyyy(manila_damage_pos);
damage = EDS(3).damage(manila_damage_pos);

[yyyy_unique,b,c]=unique(yyyy);
yyyy_damage=yyyy_unique*0; % allocate
for i=1:length(c)
    yyyy_damage(c(i))=damage(i);
end %i

figure;bar_handle=bar(yyyy_unique,yyyy_damage);set(gcf,'Color',[1 1 1])
title('simulated damage to Manila region')
axis_handle=get(bar_handle,'Parent');
set(axis_handle,'XMinorTick','on');
children_handle=get(gcf,'Children');
set(children_handle(1),'FontSize',FontSize)
saveas(gcf,[climada_global.results_dir filesep 'Manila_simulated_damage'],'png');

csv_fid=fopen([climada_global.results_dir filesep 'Manila_simulated_damage.csv'],'w');
csv_header='year,damage in USD';
csv_header=strrep(csv_header,',',climada_global.csv_delimiter);
csv_format='%4.4i,%g\n';
csv_format=strrep(csv_format,',',climada_global.csv_delimiter);
fprintf(csv_fid,'%s\n',csv_header);
for i=1:length(yyyy_unique)
    fprintf(csv_fid,csv_format,yyyy_unique(i),yyyy_damage(i));
end %i
 fclose(csv_fid);