% Script File: ShowFonts
% How choose a font, a size, a weight, and an angle.
close all
HA = 'HorizontalAlign';
fonts = {'Times-Roman' 'Helvetica' 'AvantGarde' 'Comic Sans MS' 'Palatino'...
'ZapfChancery' 'Courier' 'NewCenturySchlbk' 'Helvetica-Narrow'};
for k=1:length(fonts)
figure
axis([-20 100 -5 60])
axis off
hold on
fill([-20 100 100 -20 -20],[-5 -5 60 60 -5],'w')
plot([-20 100 100 -20 -20],[-5 -5 60 60 -5],'k','Linewidth',3)
v=38;
F = fonts{k};
text(45,55,F,'color','r','FontName',F,'FontSize',24,HA,'center')
text(10,47,'Plain','color','b','FontName',F,'FontSize',22,HA,'center')
text(45,47,'Bold','color','b','FontName',F,'Fontweight','bold','FontSize',22,HA,'center')
text(82,47,'Oblique','color','b','FontName',F,'FontAngle','oblique','FontSize',22,HA,'center')
for size=[22 18 14 12 11 10 9]
text(-12,v,int2str(size),'FontName',F,'FontSize',size,HA,'center')
text(10,v,'Matlab','FontName',F,'FontSize',size,HA,'center')
text(45,v,'Matlab','FontName',F,'FontSize',size,HA,'center','FontWeight','bold')
text(82,v,'Matlab','FontName',F,'FontSize',size,HA,'center','FontAngle','oblique')
v = v-6;
end
hold off
pause(1)
end

