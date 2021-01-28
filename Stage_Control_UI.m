%Load library and connect to stage

loadlibrary('C:\Program Files\Mad City Labs\MicroDrive\MicroDrive.dll','C:\Program Files\Mad City Labs\MicroDrive\MicroDrive.h');

handle = calllib('MicroDrive','MCL_InitHandleOrGetExisting');

if handle == 0
    fprintf('Cannot connect to stage\n')
end

%libfunctions('MicroDrive') %Use to verify that you are using the correct library functions

%Buid GUI

fig = uifigure('Name','Stage Control');

%Map buttons to movement speed
bg = uibuttongroup(fig,'Position',[230 10 125 85]);
tb1 = uibutton(bg,'push','Position',[10 8 100 22],'Text','Extra Fine','FontSize',10,'ButtonPushedFcn', @(tb1,event) ButtonVel(0.1,0.01)); % 0.1 mm/sec, 0.01 mm step
tb2 = uibutton(bg,'push','Position',[10 33 100 22],'Text','Fine','FontSize',10,'ButtonPushedFcn',  @(tb2,event) ButtonVel(0.5,0.05)); % 0.5 mm/sec, 0.05 mm step
tb3 = uibutton(bg,'push','Position',[10 56 100 22],'Text','Coarse','FontSize',10,'ButtonPushedFcn',  @(tb3,event) ButtonVel(1,0.1)); % 1 mm/sec, 0.1 mm step

%Map buttons to axis and movement direction
btn = uibutton(fig,'push','Position',[330, 200, 80, 50],'Text','>','FontSize',30,'ButtonPushedFcn', @(btn,event) ButtonPushed(2,1,handle));
btn2 = uibutton(fig,'push','Position',[170, 200, 80, 50],'Text','<','FontSize',30,'ButtonPushedFcn', @(btn2,event)  ButtonPushed(2,-1,handle));
btn3 = uibutton(fig,'push','Position',[250, 260, 80, 50],'Text','^','FontSize',35,'ButtonPushedFcn', @(btn3,event)  ButtonPushed(1,1,handle));
btn4 = uibutton(fig,'push','Position',[250, 140, 80, 50],'Text','v','FontSize',30,'ButtonPushedFcn', @(btn4,event)  ButtonPushed(1,-1,handle));

%Quit button 
btn5 = uibutton(fig,'push','Position',[190, 380, 200, 30],'Text','Quit','FontSize',20,'ButtonPushedFcn', @(btn5,event) ReleaseButtonPushed(fig));

%Functions called upon button pressing

function ButtonVel(velocity,step)

setappdata(0,'velocity',velocity) %Pass data between UI elements
setappdata(0,'step',step)

end

function ButtonPushed(axis,direction,handle)

step = getappdata(0,'step');
velocity = getappdata(0,'velocity');

if isempty(step) == 1 %If step size and velocity are not defined, use conservative settings
    step = 0.01;
end

if isempty(velocity) == 1
    velocity = 0.1;
end

active_mov = calllib('MicroDrive','MCL_MicroDriveMoveStatus',1,handle); %Check if stage is moving

if active_mov == 0

    [~,x_pos_1,y_pos_1,~] = calllib('MicroDrive','MCL_MicroDriveReadEncoders',1,1,0,handle); %read encoders
    calllib('MicroDrive','MCL_MicroDriveMoveProfile',axis,velocity,direction*step,0,handle); %axis: X=1,Y=2,Z=3; velocity in mm/sec; distance in mm; rounding; handle
    calllib('MicroDrive','MCL_MicroDriveWait',handle); %waits until stage is moved
    [~,x_pos_2,y_pos_2,~] = calllib('MicroDrive','MCL_MicroDriveReadEncoders',1,1,0,handle); %read encoders again

    x_translocation = x_pos_1-x_pos_2;
    y_translocation = y_pos_1-y_pos_2;

    fprintf(sprintf('Stage moved %f mm in x and %f mm in y axis with a velocity of %.2f mm/sec\n',x_translocation,y_translocation,velocity))
    %Mostly useful for debugging

elseif active_mov == 1

    fprintf('wait until stage stops moving\n')

end

end

function ReleaseButtonPushed(fig)

calllib('MicroDrive','MCL_ReleaseAllHandles') %Release stage control
unloadlibrary MicroDrive
clear handle

fprintf('Released control of the stage\n')
close(fig)

end
