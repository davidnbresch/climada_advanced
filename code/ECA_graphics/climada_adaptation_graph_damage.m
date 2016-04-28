
function  fig = climada_adaptation_graph_damage(ECA_adaptation, case_i, digits)

global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('ECA_adaptation' ,'var'), ECA_adaptation  = []; end
if ~exist('case_i'         ,'var'), case_i          = []; end
if ~exist('digits'         ,'var'), digits          = []; end

if isempty(case_i)         , case_i = 1 ; end
if isempty(digits)         , digits = 6 ; end


%% case i
case_index = case_i;
ECA_name   = ECA_adaptation.ECA_case_study{case_i(1)};

% list_cases = unique(ECA_adaptation.ECA_case_study);
% ECA_name   = list_cases{case_i};
% case_index = strcmp(ECA_adaptation.ECA_case_study, ECA_name);

ex_flag = 0;
if strcmp(ECA_name,'Example')
    ex_flag = 1;
end

bn_flag = 0;
% if any(strcmp(ECA_name,{'Florida, US' 'Gulf Coast, US'}))
%     bn_flag = 1;
% else
%     bn_flag = 0;
% end

% shorten measures name, lea, 20150220
ECA_adaptation.Measure{46} = 'Rain water harvesting';
Measure           = ECA_adaptation.Measure(case_index);
Averted_Loss_2030 = ECA_adaptation.Averted_Loss_2030(case_index);
CostBenefit       = ECA_adaptation.CostBenefit(case_index);
BenefitCost       = 1./CostBenefit;
BenefitCost(1)    = 20; % for nicer figure, lea, 20150220
BenefitCost(isinf(BenefitCost)) = 0;
no_measures       = length(Measure);

% sort according to CostBenefit and cumulate
[sort_BenefitCost, sort_index] = sort(BenefitCost,'descend');
% sort_CostBenefit  = [sort_CostBenefit; 0];
% sort_index        = [sort_index; no_measures];
% % cum_benefit       = cumsum(Averted_Loss_2030(sort_index));
cum_benefit       = [0; cumsum(Averted_Loss_2030(sort_index))];


%----------
% figure
%----------
%%
fig        = climada_figuresize(0.6,1.1);% fig        = climada_figuresize(0.57,0.7);
fontsize_  = 17; % fontsize_  = 8;
fontsize_2 = fontsize_ - 3;
stretch    = 0.2; % stretch    = 0.3;

color_adaptation = [143	188	143]/256;
color_residual   = [220  20  60]/255; % residual risk  [205 0	0]/255;   % residual risk
color_     = [color_adaptation;...% cost-effective measures
              193 205 205 ;...    % non-cost-effective measures
              color_residual];    % residual risk %	 
color_(1,:) = brighten(color_(1,:),0.1); 
color_(1,:) = color_adaptation;

color_1 = color_adaptation;
% color_1 = [  0 197 205]/255; % light blue
% color_1 = brighten(color_1,0.5);

color_(2,:)= [255 127   0]/255;% orange        
c_index    = ones(no_measures,1);
c_index(sort_BenefitCost <1) = 2;
c_index(sort_BenefitCost==0) = 3;

m_cost_eff = sum(c_index <2)+1;
a_cost_eff = cum_benefit(m_cost_eff)/max(cum_benefit);
a_non_cost = (cum_benefit(end-1)-cum_benefit(m_cost_eff))/max(cum_benefit);
a_residual = abs(diff(cum_benefit([end end-1])))/max(cum_benefit);

color_text = brighten(color_,-0.7); 
color_text(1,:) = [  0 100  0]/255;
% color_text(2,:) = [139  26 26]/255;
color_text(2,:) = color_residual;
color_text(3,:) = color_residual;

if ex_flag
    ymax_limit = 10;
else
    ymax_limit = 20;
end

subaxis(1,1,1,'Mb',0.18)
stretch1 = max([BenefitCost; ymax_limit])*1.1*0.028;
hold on
% plot measures
for m_i = sort_index'
    if m_i == no_measures %residual damage
         plot(cum_benefit(end),0,'d','color',color_(c_index(m_i),:),'markerfacecolor',color_(c_index(m_i),:),'markersize',10)
         plot(cum_benefit(end-1),0,'d','color','w','markerfacecolor',color_(c_index(m_i-1),:),'markersize',10)
         if ex_flag
             tcr_str = sprintf('Total climate risk');
         else
             if bn_flag == 1
                 tcr_str = sprintf('Total climate risk\n%.0f bn USD',cum_benefit(end));
             else
                 tcr_str = sprintf('Total climate risk\n%.0f mn USD',cum_benefit(end));
             end
         end
         if a_residual > 0.05
             text(cum_benefit(end)*0.99,ymax_limit/13+stretch1,tcr_str,...
                                  'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_-2,'color',color_text(3,:))
         %else
         %    text(cum_benefit(end)*0.99,1+stretch1,tcr_str,...
         %                         'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_-2,'color',color_text(3,:))
         end
    else
        if sort_BenefitCost(m_i)<0.3
            if sort_BenefitCost(m_i)<0.1
                h(m_i) = area(cum_benefit(m_i:m_i+1),...
                              [0.2, 0.2],...
                               'FaceColor',color_(c_index(m_i),:) ,'EdgeColor','w', 'LineWidth',1);
            else
                h(m_i) = area(cum_benefit(m_i:m_i+1),...
                              [sort_BenefitCost(m_i), sort_BenefitCost(m_i)],...
                               'FaceColor',color_(c_index(m_i),:) ,'EdgeColor','w', 'LineWidth',1);
            end
        else
            h(m_i) = area(cum_benefit(m_i:m_i+1),...
                          [sort_BenefitCost(m_i), sort_BenefitCost(m_i)],...
                           'FaceColor',color_(c_index(m_i),:) ,'EdgeColor','w', 'LineWidth',2);
        end
    end
end
% plot(cum_benefit(m_cost_eff),0,'d','color','k','markerfacecolor',color_(c_index(m_cost_eff-1),:),'markersize',10);
plot(cum_benefit(m_cost_eff),0,'d','color','w','markerfacecolor',color_1,'markersize',10);
plot([0 cum_benefit(end)],[1 1],'--k')

% names of measures
if ~ex_flag
    for m_i = 1:no_measures-1
        %text(mean(cum_benefit([m_i m_i+1])),1+stretch1,...
        %     Measure{m_i}, 'Rotation',90,'FontSize',fontsize_2+2, 'color', color_text(c_index(m_i),:),'FontName','Helvetica-Narrow');
        text(mean(cum_benefit([m_i m_i+1])),max([BenefitCost; ymax_limit])-1.5,...
             Measure{m_i}, 'Rotation',90,'FontSize',fontsize_2+3, 'color', color_text(c_index(m_i),:),'FontName','Helvetica-Narrow',...
             'HorizontalAlignment','right');               
    end
end

set(subaxis(1),'FontSize',fontsize_+2,'layer','top');

if m_cost_eff<= length(h)
    l = legend(h([m_cost_eff-1 m_cost_eff]),'Cost-effective measures','Non-cost-effective','location','ne');
else
    l = legend(h([m_cost_eff-1]),'Cost-effective measures','location','ne');
end
legend('boxoff')
set(l,'fontsize',fontsize_-2)

%% arrow adaptation potential and residual damage
ylim([0 max([max([BenefitCost; ymax_limit]) 1.3])*1.1])
xlim([0 max(cum_benefit)*1.03])
s_ = ymax_limit/200; % 0.1;
y_ = -max([BenefitCost; ymax_limit])*0.173; % y_ = -0.9;


% climada_arrow([cum_benefit(end) y_], [cum_benefit(end-1)+s_/2 y_],...
%                                                     'width',25+7,'Length',20+5, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(3,:));
if cum_benefit(end)>cum_benefit(m_cost_eff)
    climada_arrow([cum_benefit(end) y_*1.0], [cum_benefit(m_cost_eff)+s_/2 y_*1.0],...
                                                    'width',25,'Length',20, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(3,:));
end
if cum_benefit(end-1)>cum_benefit(m_cost_eff)
    climada_arrow([cum_benefit(m_cost_eff)+s_*3 y_], [cum_benefit(end-1)-s_/2 y_], ...
                                                    'width',15,'Length',13, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_(2,:));
end
climada_arrow([0 y_], [cum_benefit(m_cost_eff) y_],'width',25,'Length',20, 'BaseAngle',90, 'TipAngle', 130,'EdgeColor','none', 'FaceColor',color_1);%color_(1,:));

% text in arrows
if a_cost_eff >ymax_limit/80 %> 0.25
    text(cum_benefit(m_cost_eff)/2                     ,y_,'Cost-effective adaptation','color','k','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2,'fontweight','bold');
elseif a_cost_eff >ymax_limit/133 %> 0.15
    text(cum_benefit(m_cost_eff)/2                     ,y_,'Cost-effective adaptation','color','k','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-2,'fontweight','bold');
end
if a_non_cost >ymax_limit/133 %> 0.15
    text((cum_benefit(m_cost_eff)+cum_benefit(end-1))/2,y_,'Non-cost-effective'       ,'color','k','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2,'fontweight','bold');
elseif a_non_cost >ymax_limit/82 %> 0.11
    text((cum_benefit(m_cost_eff)+cum_benefit(end-1))/2,y_,'Non-cost-effective'       ,'color','k','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-5,'fontweight','bold');
end
if a_residual >ymax_limit/133 %> 0.15
    text(mean(cum_benefit([end end-1]))                ,y_,'Residual damage 2030'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-2,'fontweight','bold');
    %text(mean(cum_benefit([end end-1]))                ,y_,'Residual damage 2030'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-2,'fontweight','bold');
elseif a_residual >ymax_limit/285 %> 0.07
    text(mean(cum_benefit([end end-1]))                ,y_,'Residual damage 2030'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-8,'fontweight','bold');
    %text(mean(cum_benefit([end end-1]))                ,y_,'Residual damage 2030'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_2-6,'fontweight','bold');
end

ylim([0 max([max([BenefitCost; ymax_limit]) 1.3])*1.1])
xlim([0 max(cum_benefit)*1.03])
y_tick = get(subaxis(1),'ytick');
y_tick_2 = linspace(1,round((max(y_tick)-1)/3)*3+1,4);
if length(unique(y_tick_2)) < 2
    y_tick_2 = y_tick;
end
set(subaxis(1),'ytick',y_tick_2)
if ex_flag
    x_tick = get(subaxis(1),'xtick');
    set(subaxis(1),'xtick',x_tick(1:2:end))
end
box off

%title
ylabelstr = 'Reduced damage per USD invested (USD)';
text(max(cum_benefit)*0.01, max([BenefitCost; ymax_limit])*1.18,ylabelstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_+1,'FontAngle','italic');%'FontWeight','bold',
textstr = ECA_name;
% text(0.8-stretch, max(BenefitCost)*1.5,textstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_+3);

if ~ex_flag
    if bn_flag == 1
        xstr = 'Averted damage (bn USD)';
    else
        xstr = 'Averted damage (mn USD)';
    end
else
    xstr = 'Averted damage (mn USD)';
end
text(max(cum_benefit)*1.00, -max([BenefitCost; ymax_limit])*0.075, xstr, 'color','k','HorizontalAlignment','right','VerticalAlignment','top','fontsize',fontsize_+1,'FontAngle','italic');%'FontWeight','bold',


%print
print(fig,'-dpdf',[climada_global.data_dir filesep textstr '_adaptation_upsidedown.pdf'])



