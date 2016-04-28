
function  fig = climada_waterfall_graph_special(ECA_studies, case_i, digits)
% waterfall figure, expected damage for specified return period for 
% - today,
% - increase from economic growth, 
% - increase from high climate change, total expected damage 2030
% for the three EDS quoted above
% NAME:
%   climada_waterfall_graph
% PURPOSE:
%   plot expected damage for specific return period
% CALLING SEQUENCE:
%   climada_waterfall_graph(EDS1, EDS2, EDS3, return_period,
%   check_printplot)
% EXAMPLE:
%   climada_waterfall_graph
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   EDS:            three event damage sets 
%                   - today
%                   - economic growth
%                   - cc combined with economic growth, future
%   return_period:  requested return period for according expected damage,or
%                   annual expted damage, prompted if not given
%   check_printplot:if set to 1, figure saved, default 0. 
% OUTPUTS:
%   waterfall graph
% MODIFICATION HISTORY:
% Lea Mueller, 20110622
% Martin Heynen, 20120329
% David N. Bresch, david.bresch@gmail.com, 20130316 EDS->EDS
%-

global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('ECA_studies'    ,'var'), ECA_studies     = []; end
if ~exist('case_i'         ,'var'), case_i          = []; end
if ~exist('digits'         ,'var'), digits          = []; end
if ~exist('return_period'  ,'var'), return_period   = []; end
if ~exist('check_printplot','var'), check_printplot = 0; end

if isempty(case_i)         , case_i = 1 ; end
if isempty(digits)         , digits = 6 ; end
if isempty(return_period)  , return_period = 9999 ; end


%% damage numbers
damage    = [];
damage(1) = ECA_studies.Today(case_i);
damage(2) = ECA_studies.Today(case_i) + ECA_studies.Economic_growth(case_i);
damage(3) = ECA_studies.Today(case_i) + ECA_studies.Economic_growth(case_i) + ECA_studies.Climate_change(case_i);
damage(4) = ECA_studies.Future_2030(case_i);

residual_loss = ECA_studies.Residual_loss(case_i);
ECA_name      = ECA_studies.ECA_name{case_i};

if digits ~= 0 
    damage        = damage*10^-digits;
    residual_loss = residual_loss*10^-digits;
end
dig           = digits;


%----------
% figure
%----------
fig        = climada_figuresize(0.5,0.25);
% fig        = climada_figuresize(0.57,0.7);
fontsize_  = 16; % fontsize_  = 8;
fontsize_2 = fontsize_ - 3;
stretch    = 0.45; % stretch    = 0.3;

% % green color scheme
% yellow - red color scheme (Swiss Re brochure)
color_     = [255 222 173;...  %today
              255 153  18;...   %eco 
              238 130  98;...   %clim
              205	0	0;...   %total risk
              120 120 120]/256;  %dotted line]/255;
% color_(1:4,:) = brighten(color_(1:4,:),0.3);      
color_adaptation = [143	188	143]/256;

% % yellow - red color scheme
% color_     = [255 215   0 ;...   %today
%               255 127   0 ;...   %eco 
%               238  64   0 ;...   %clim
%               205   0   0 ;...   %total risk
%               120 120 120]/256;  %dotted line]/255;
% color_(1:4,:) = brighten(color_(1:4,:),0.3);            
          
% color_     = [227 236 208;...   %today
%               194 214 154;...   %eco 
%               181 205  133;...  %clim
%               197 190 151;...   %total risk
%               120 120 120]/256; %dotted line]/255;
% color_(1:4,:) = brighten(color_(1:4,:),-0.5);  

damage_count = length(damage);
damage       = [0 damage]; 

hold on
area([damage_count-stretch damage_count+stretch], damage(4)*ones(1,2),'facecolor',color_(4,:),'edgecolor','none')
for i = 1:length(damage)-2
    h(i) = patch( [i-stretch i+stretch i+stretch i-stretch],...
                  [damage(i) damage(i) damage(i+1) damage(i+1)],...
                  color_(i,:),'edgecolor','none');
end
plot([1-stretch 4+stretch], [0 0],'-k')

%number of digits before the comma (>10) or behind the comma (<10)
damage_disp(1) = damage(2);
damage_disp(2) = damage(3)-damage(2);
damage_disp(3) = damage(4)-damage(3);
damage_disp(4) = damage(4);
    
if max(damage)>10 && digits ~= 0 
    N = -abs(floor(log10(max(damage)))-1);
    damage_disp = round(damage_disp*10^N)/10^N;
    N = 0;    
elseif digits == 0 
    N = 0;    
else
    %N = round(log10(max(damage_disp)));
    N = 1;
end


%damages above bars
strfmt = ['%2.' int2str(N) 'f'];
dED = 0.0;
% text(1, damage(2)                     , num2str(damage_disp(1),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);
text(1, damage(2)*0.7, num2str(damage_disp(1),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','normal','fontsize',fontsize_);
text(2-dED, damage(2)+ (damage(3)-damage(2))/2, ['+' num2str(damage_disp(2),strfmt)], 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','normal','fontsize',fontsize_);
text(3-dED, damage(3)+ (damage(4)-damage(3))/2, ['+' num2str(damage_disp(3),strfmt)], 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','normal','fontsize',fontsize_);
text(4, damage(4)                             , num2str(damage_disp(4),strfmt), 'color',color_(4,:) , 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','normal','fontsize',fontsize_);
% text(4, damage(4)                     , num2str(damage_disp(4),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);


% %damages above barsn -- int2str
% dED = 0.0;
% text(1, damage(2)                     , int2str(damage_disp(1)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);
% text(2-dED, damage(2)+ (damage(3)-damage(2))/2, int2str(damage_disp(2)), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
% text(3-dED, damage(3)+ (damage(4)-damage(3))/2, int2str(damage_disp(3)), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
% text(4, damage(4)                     , int2str(damage_disp(4)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);

%remove xlabEDS and ticks
set(gca,'xticklabel',[],'FontSize',10,'XTick',zeros(1,0),'layer','top');
set(gca,'yticklabel',[],'yTick',zeros(1,0),'color','w');

%axis range and ylabel
xlim([0.5 4.5])
ylim([0 damage(2)*4])
% ylim([0   max(damage)*1.25])
% ylabel(['damage amount \cdot 10^{', int2str(dig) '}'],'fontsize',fontsize_)
axis off

%arrow adaptation potential and residual loss
climada_arrow([4 damage(4)], [4 residual_loss], 'width',30,'Length',27,'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_adaptation);
% text (4, (residual_loss+max(damage))/2, ['+' int2str(adap_pot*100) '%'], 'color','k','HorizontalAlignment','center','VerticalAlignment','top','fontsize',fontsize_);
adap_pot = (residual_loss-damage(4))/damage(4);
text_height = -adap_pot*damage(4)*0.22+residual_loss;
text(4, text_height, [int2str(adap_pot*100) '%'], 'color','k','HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_+1,'fontweight','normal');


%title
if return_period == 9999
    %textstr = [ECA_name ': Annual Expected Damage (AED)'];
    textstr = ECA_name;
 else
    textstr = ['Expected damage with a return period of ' int2str(return_period) ' years'];
end
% textstr_TIV = sprintf('Total assets: %d, %d 10^%d USD', TIV_nr, digits);
text(1-stretch, max(damage)*1.30,textstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
% text(1-stretch, max(damage)*1.20,textstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
% text(1-stretch, max(damage)*1.15,textstr_TIV, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','normal','fontsize',fontsize_2);


% print(fig,'-dpdf',[climada_global.data_dir filesep textstr '.pdf'])


%%

% %xlabel
% text(1-stretch, damage(1)-max(damage)*0.02, {[num2str(climada_global.present_reference_year) ' today''s'];'expected damage'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
% text(2-stretch, damage(1)-max(damage)*0.02, {'Incremental increase';'from economic';'gowth; no climate';'change'},          'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
% text(3-stretch, damage(1)-max(damage)*0.02, {'Incremental increase';'from climate change'},                                 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
% text(4-stretch, damage(1)-max(damage)*0.02, {[num2str(climada_global.future_reference_year) ', total'];'expected damage'},    'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);

% %Legend
% L = legend(h,legend_str(index),'location','NorthOutside','fontsize',fontsize_2);
% set(L,'Box', 'off')

% if isempty(check_printplot)
%     choice = questdlg('print?','print');
%     switch choice
%     case 'Yes'
%         check_printplot = 1;
%     end
% end
% 
% 
% if check_printplot %(>=1)   
%     print(fig,'-dpdf',[climada_global.data_dir foldername])
%     %close
%     fprintf('saved 1 FIGURE in folder %s \n', foldername);
% end
%     
% return




