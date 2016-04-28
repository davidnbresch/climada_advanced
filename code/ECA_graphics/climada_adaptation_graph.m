
function  fig = climada_adaptation_graph(ECA_adaptation, case_i, digits)

global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('ECA_adaptation' ,'var'), ECA_adaptation  = []; end
if ~exist('case_i'         ,'var'), case_i          = []; end
if ~exist('digits'         ,'var'), digits          = []; end

if isempty(case_i)         , case_i = 1 ; end
if isempty(digits)         , digits = 6 ; end


%% case i
list_cases = unique(ECA_adaptation.ECA_case_study);
ECA_name   = list_cases{case_i};
case_index = strcmp(ECA_adaptation.ECA_case_study, ECA_name);

if any(strcmp(ECA_name,{'Florida, US' 'Gulf Coast, US' 'Hull, UK'}))
    bn_flag = 1;
else
    bn_flag = 0;
end

Measure           = ECA_adaptation.Measure(case_index);
Averted_Loss_2030 = ECA_adaptation.Averted_Loss_2030(case_index);
CostBenefit       = ECA_adaptation.CostBenefit(case_index);
BenefitCost       = 1./CostBenefit;
BenefitCost(isinf(BenefitCost)) = 0;
no_measures       = length(Measure);

% sort according to CostBenefit and cumulate
[sort_CostBenefit, sort_index] = sort(CostBenefit(CostBenefit>0));
sort_CostBenefit  = [sort_CostBenefit; 0];
sort_index        = [sort_index; no_measures];
% cum_benefit       = cumsum(Averted_Loss_2030(sort_index));
cum_benefit       = [0; cumsum(Averted_Loss_2030(sort_index))];


%----------
% figure
%----------
%%
fig        = climada_figuresize(0.6,1.1);% fig        = climada_figuresize(0.57,0.7);
fontsize_  = 18; % fontsize_  = 8;
fontsize_2 = fontsize_ - 3;
stretch    = 0.2; % stretch    = 0.3;

color_     = [  0 197 205 ;...   % cost-efficient measures
              193 205 205 ;...   % non-cost-efficient measures
              205   0   0 ]/255; % residual risk
% color_(2,:) = [255 215   0]/255; % yellow
color_(1,:)= brighten(color_(1,:),0.5); 
color_(2,:)= [255 127   0]/255;% orange
color_(3,:)= brighten(color_(3,:),-0.5);           
c_index    = ones(no_measures,1);
c_index(sort_CostBenefit >1) = 2;
c_index(sort_CostBenefit==0) = 3;

m_cost_eff = sum(c_index <2)+1;
a_cost_eff = cum_benefit(m_cost_eff)/max(cum_benefit);
a_non_cost = (cum_benefit(end-1)-cum_benefit(m_cost_eff))/max(cum_benefit);
a_residual = abs(diff(cum_benefit([end end-1])))/max(cum_benefit);

color_text = brighten(color_,-0.7);  
color_text(1,:) = [25 25 112 ]/255;
% color_text(1,:) = [ 0  104  139]/255;
% color_text(2,:) = [ 77  77   77]/255;
color_text(2,:) = [139  26   26]/255;
color_text(3,:) = [205   0    0]/255;

subaxis(1,1,1,'Mb',0.18)
stretch1 = max(CostBenefit)*1.1*0.028;
hold on
% plot measures
for m_i = sort_index'
    if m_i == no_measures %residual loss
%         b = cum_benefit(m_i:m_i+1);
%         area([b(1) interp1([0 1],b,0.5), b(2), interp1([0 1],b,0.5), b(1)],...
%              [0 0 0 1 0],...
%              'FaceColor',color_(c_index(m_i),:),'EdgeColor','w'); %red
         plot(cum_benefit(end),0,'d','color',color_(c_index(m_i),:),'markerfacecolor',color_(c_index(m_i),:),'markersize',10)
         plot(cum_benefit(end-1),0,'d','color','k','markerfacecolor',color_(c_index(m_i-1),:),'markersize',10)
         if bn_flag == 1
             tcr_str = sprintf('Total climate risk\n%.0f bn USD',cum_benefit(end));
         else
             tcr_str = sprintf('Total climate risk\n%.0f mn USD',cum_benefit(end));
         end
         if a_residual > 0.15
            text(cum_benefit(end)*0.93,stretch1,tcr_str,...
                                  'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_,'color',color_text(3,:))
         else
             text(cum_benefit(end)*1.05,stretch1,tcr_str,...
                                  'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_-4,'color',color_text(3,:))
         end
    else
        h(m_i) = area(cum_benefit(m_i:m_i+1),...
                     [sort_CostBenefit(m_i), sort_CostBenefit(m_i)],...
                     'FaceColor',color_(c_index(m_i),:) ,'EdgeColor','w');
    end
end
plot(cum_benefit(m_cost_eff),0,'d','color','k','markerfacecolor',color_(c_index(m_cost_eff-1),:),'markersize',10);
plot([0 cum_benefit(end)],[1 1],':k')

% names of measures
for m_i = 1:no_measures-1
    text(mean(cum_benefit([m_i m_i+1])),stretch1,...
         Measure{m_i}, 'Rotation',90,'FontSize',fontsize_2-2, 'color', color_text(c_index(m_i),:),'FontName','Helvetica-Narrow');
end

set(subaxis(1),'FontSize',fontsize_+2,'layer','top');
% xlabel('Averted and residual loss 2030')
% ylabel('Cost/Benefit Ratio (CBR)')

if m_cost_eff<= length(h)
    l = legend(h([m_cost_eff-1 m_cost_eff]),'Cost-efficient measures','Non-cost-efficient','location','ne');
else
    l = legend(h([m_cost_eff-1]),'Cost-efficient measures','location','ne');
end
legend('boxoff')
set(l,'fontsize',fontsize_-2)

%% arrow adaptation potential and residual loss
s_ = 0.1;
y_ = -max([max(CostBenefit) 1.3])*1.2*0.12; % y_ = -0.9;

% climada_arrow([cum_benefit(end) y_], [cum_benefit(end-1)+s_/2 y_],...
%                                                     'width',25+7,'Length',20+5, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(3,:));
if cum_benefit(end)>cum_benefit(m_cost_eff)
    climada_arrow([cum_benefit(end) y_*1.0], [cum_benefit(m_cost_eff)+s_/2 y_*1.0],...
                                                        'width',25+10,'Length',20+7, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(3,:));
end
if cum_benefit(end-1)>cum_benefit(m_cost_eff)
    climada_arrow([cum_benefit(m_cost_eff)+s_*3 y_], [cum_benefit(end-1)-s_/2 y_], ...
                                                    'width',13,'Length',13, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(2,:));
end
climada_arrow([0 y_], [cum_benefit(m_cost_eff) y_],'width',25,'Length',20, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(1,:));

% text in arrows
if a_cost_eff > 0.3
    text(cum_benefit(m_cost_eff)/2                     ,y_,'Cost-efficient adaptation','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2,'fontweight','bold');
elseif a_cost_eff > 0.15
    text(cum_benefit(m_cost_eff)/2                     ,y_,'Cost-efficient adaptation','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-4,'fontweight','bold');
end
if a_non_cost > 0.15
    text((cum_benefit(m_cost_eff)+cum_benefit(end-1))/2,y_,'Non-cost-efficient'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2,'fontweight','bold');
elseif a_non_cost > 0.07
    text((cum_benefit(m_cost_eff)+cum_benefit(end-1))/2,y_,'Non-cost-efficient'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-4,'fontweight','bold');
end
if a_residual > 0.15
    text(mean(cum_benefit([end end-1]))                ,y_,'Residual loss 2030'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2,'fontweight','bold');
elseif a_residual > 0.07
    text(mean(cum_benefit([end end-1]))                ,y_,'Residual loss 2030'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-4,'fontweight','bold');
end

ylim([0 max([max(CostBenefit) 1.3])*1.1])
xlim([0 max(cum_benefit)*1.03])
y_tick = get(subaxis(1),'ytick');
y_tick_2 = linspace(1,round((max(y_tick)-1)/3)*3+1,4);
if length(unique(y_tick_2)) < 2
    y_tick_2 = y_tick;
end
set(subaxis(1),'ytick',y_tick_2)
box off

%title
% stretch = 0.2;
ylabelstr = 'Cost/Benefit Ratio (CBR)';
text(0.8-stretch, max([max(CostBenefit) 1.3])*1.18,ylabelstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_+2);%'FontWeight','bold',
textstr = ECA_name;
% text(1-stretch, max(CostBenefit)*1.5,textstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_+3);

print(fig,'-dpdf',[climada_global.data_dir filesep textstr '_adaptation.pdf'])



