

%% WATERFALL GRAPH

% set modul data directory
% dir
% modul_data_dir = [fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];
% xlsfile   = 'C:\TEMP\climada_test_environment\climada_additional\ECA_graphics\data\ECA_risk_analysis.xls';
% modul_data_dir = [fileparts(climada_global.root_dir) filesep 'climada_modules' filesep 'advanced' filesep 'data'];
xlsfile     = [climada_global.modules_dir filesep 'advanced' filesep 'data' filesep 'ECA_risk_analysis.xls'];
ECA_studies = climada_read_risk_analysis(xlsfile,'million_USD');

no_cases    = length(ECA_studies.Today);
digits      = zeros(no_cases,1);
digits(1:3) = 3;
digits(8)   = 3;

close all
for case_i = [1:10 17] %1:length(ECA_studies.Today)
    fig(case_i) = climada_waterfall_graph_special(ECA_studies, case_i, digits(case_i));
end

% close all
% Tanzania special case
case_i = 6;
fig(case_i) = climada_waterfall_graph_special_tanzania(ECA_studies, case_i, digits(case_i));


% close all
% New York special case
case_i = 3;
fig(case_i) = climada_waterfall_graph_special_NY(ECA_studies, case_i, digits(case_i));



%% ADAPTATION COST CURVE
% xlsfile        = 'C:\TEMP\climada_test_environment\climada_additional\ECA_graphics\data\ECA_risk_analysis.xls';
xlsfile        = [climada_global.modules_dir filesep 'advanced' filesep 'data' filesep 'ECA_risk_analysis.xls'];
ECA_adaptation = climada_read_risk_analysis(xlsfile,'adaptation');

%% Example
% list_cases = unique(ECA_adaptation.ECA_case_study);
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Example'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);


%% Hull
% list_cases = unique(ECA_adaptation.ECA_case_study);
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Hull, UK'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% China
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'North & Northeast China'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% US Gulf Coast
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Gulf Coast, US'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% India
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Maharasthra, India'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
% fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);
fig = climada_adaptation_graph_damage(ECA_adaptation, case_i);


%% Tanzania
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Tanzania'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% Jamaica
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Jamaica'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% Mopti, Mali
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Mopti region, Mali'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% Samoa
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Samoa'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% Guyana
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Georgetown, Guyana'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);

%% Florida
case_i = find(strcmp(ECA_adaptation.ECA_case_study,'Florida, US'));
close all
% fig = climada_adaptation_graph(ECA_adaptation, case_i);
fig = climada_adaptation_graph_upsidedown(ECA_adaptation, case_i);


%% Florida
% list_cases = unique(ECA_adaptation.ECA_case_study);
% case_i = find(strcmp(list_cases,'Florida, US'));
% close all
% fig = climada_adaptation_graph_new(ECA_adaptation, case_i);
% 
% list_cases = unique(ECA_adaptation.ECA_case_study);
% case_i = find(strcmp(list_cases,'Georgetown, Guyana'));
% close all
% fig = climada_adaptation_graph_new(ECA_adaptation, case_i);
% 
% list_cases = unique(ECA_adaptation.ECA_case_study);
% case_i = find(strcmp(list_cases,'Samoa'));
% close all
% fig = climada_adaptation_graph_new(ECA_adaptation, case_i);











