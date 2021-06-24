%This code creates a simple experiment where 5 faces are shown randomly interspersed
%   with 5 images of houses. The participant pushes "4" if there is a face, "6" for an
%   object. EEG output is recorded. This type of experiment is expected to show a
%   negative component around 170 ms after image presentation. The component will be
%   significantly larger to faces vs. houses, typically around the right fusiform gyrus (N170).

function EEG_Experiment_Shell()
%SEGMENTING: each value in vector represents the trials in order. Those
%marked "1" are experimental face trials and "0" are house controls. DIN
%output is also recorded: 1 for face, 2 for house

%Screen('Preference', 'SkipSyncTests', 1);
EEG = false;        %False = skip EEG-specific code when debugging on personal computer
global biosemi;     %Some programmers hate global variables but tough
biosemi = true;     %Use EGI code if false, Biosemi if true CHANGE AS NEEDED
debugmode = false;  %If true, shortens trials considerably for debug purposes
Screen('Preference','SkipSyncTests', 1);

nStim = 5;          %5 images in each condition
nCond = 2;          %2 conditions * 5 images = 10 unique images
nReps = 10;         %10 images * 10 repetitions = 100 total images displayed
%100 images * (1.5+1 seconds) = 250 seconds total, or 4 minutes, 10 seconds

comp = computer;                             %Type of system
slash = '\';
if strcmp(comp,'PCWIN64') || strcmp(comp,'PCWIN32') || strcmp(comp,'PCWIN')   %Windows
    slash = '\';
    screennumber = 2;
elseif strcmp(comp,'MACI64')
    slash = '/';
    screennumber = 0;       %Assumed to be the Net Station computer
elseif strcmp(comp,'GLNXA64') || strcmp(comp,'GLNX32') || strcmp(comp,'GLNX86')
    disp('Untested in Linux')
    slash = '/';
else
    disp('Computer type undetermined.')
end

%Lines that have '#ok<UNRCH>' comments simply ignore the
% 'this statement (and possibly following ones) cannot be reached' errors
if debugmode; nReps = 1; end; %#ok<UNRCH>
nTrials = nStim * nCond * nReps;        %100 trials total
trials = [zeros(1,nStim),ones(1,nStim);1:nStim,1:nStim;]'; %Column of 1:5;1:5... column of 5 zeros;5 ones, sorted
trials = repmat(trials,nReps,1);        %2x100 list of trials
torder = randperm(nTrials);             %Random order. 'order' might be used by DSP System Toolbox found
% in some installs, best not to conflict
responses = zeros(nTrials,3);           %Cols: 1 = cond, 2 = img#, 3 = response (1=4,0=6) Preallocate for memory savings
TTL_pulse_dur = 0.005;                  %Delay between pulses

%Get participant data. You can use:
%inputdlg: popup box for inputting initials
%input: prompt in Command Window ( ,'s' formats as string)
prompt = {'Participant initials'};
defaults = {''};
part_data = inputdlg(prompt, 'Participant',1,defaults);
filename = sprintf('%s_facehouse',part_data{1}); % %s = initials, %d = age
%ALT: filename = input('Enter your initials:','s');
%Open Psychtoolbox window
[w,rect] = Screen('OpenWindow',1);  %0 = span monitors, 1 = primary monitor, 2 = secondary monitor

%Define shape and location of stimulus, timings, text, etc.
%May even want to make houses bigger than faces to match perceived size
xc = rect(3)/2; yc = rect(4)/2;     %Location of screen center
scaling = 1;                        %If you need to scale stimuli, 1 = actual size
xs = scaling * 400; ys = scaling * 400; %400x400 default size. Change 400 if different image set used,
%or scaling to scale. You can also load images and get size from matrix.
destrect = [xc-xs/2, yc-ys/2, xc+xs/2, yc+ys/2];    %400x400 rectangle centered on screen
stim_time = 1;                      %Show for 1 second
ISI = 1.5;                          %Blank for 1.5 seconds
bgcolor = [128 128 128];            %Gray background

%Background & text
Screen('FillRect',w,bgcolor,[0 0 rect(3) rect(4)]);     %Fill entire screen gray
txt = 'Press any key to start';
txtWidth = RectWidth(Screen('TextBounds',w,txt));

Screen('DrawText',w,txt,xc-txtWidth/2,yc,[0 0 0]);
Screen('Flip',w);                                       %Display background and text simultaneously
KbWait;                                                 %Wait for keyboard input (any key)

if EEG
    Initialize_EEG(); %#ok<UNRCH>
end
%breaks texture below?

for i=torder
    responded = false;      %Allow key input again if key previously pushed
    if trials(i,1) == 1
        switch trials(i,2)
            case 1
                pict = imread('face1.jpg');
            case 2
                pict = imread('face2.jpg');
            case 3
                pict = imread('face3.jpg');
            case 4
                pict = imread('face4.jpg');
            case 5
                pict = imread('face5.jpg');
            otherwise
                disp('Invalid face')
        end
        if EEG; trigout = 1 ; end %#ok<UNRCH>      %Trigger index to output
    else
        switch trials(i,2)
            case 1
                pict = imread('house1.jpg');    %Ideally, use PNG, BMP, etc. instead
            case 2
                pict = imread('house2.jpg');
            case 3
                pict = imread('house3.jpg');
            case 4
                pict = imread('house4.jpg');
            case 5
                pict = imread('house5.jpg');
            otherwise
                disp('Invalid house')
        end
        if EEG; trigout = 2; end %#ok<UNRCH>      %Trigger index to output
    end
    
    tex = Screen('MakeTexture',w,pict);
    Screen('DrawTexture',w,tex,[],destrect);  %[] = sourceRect
    Screen('Flip',w);               %Show backbuffer with face/house image
    if EEG
        %Mark EVERY trial with a 3, also send 1 if face, 2 if house
        if biosemi %#ok<UNRCH>
            outputSingleScan(s,dec2binvec(3,8));
            %Binary number of length 8, can also just type in as below:
            %Binary 3 = 1 1 0 0 0 0 0 0
            outputSingleScan(s, [0 0 0 0 0 0 0 0])      %Turn off trigger
            outputSingleScan(s,dec2binvec(trigout,8));
            %Binary 1 = 1 0 0 0 0 0 0 0
            %Binary 2 = 0 1 0 0 0 0 0 0
            outputSingleScan(s, [0 0 0 0 0 0 0 0])      %Turn off trigger
        else
            DaqDOut(trigDevice,0,3);
            WaitSecs(TTL_pulse_dur);
            DaqDOut(trigDevice,0,0);                    %Turn off trigger
            DaqDOut(trigDevice,0,trigout);
            WaitSecs(TTL_pulse_dur);
            DaqDOut(trigDevice,0,0); %#ok<UNRCH>        %Turn off trigger
        end
    end
    if ~responded                   %Allow only 1 response/image presentation
        [keyIsDown,~,keyCode] = KbCheck;    %Get keyboard input
        if keyIsDown
            if KbName(keyCode) == '4'     %4 on keypad, on number row it's '4$'
                disp('4')
                responses(i,3) = keyCode; %For now = 100 = 4key, 102 = 6key
                responded = true;
            elseif KbName(keyCode) == '6'
                disp('6')
                responses(i,3) = keyCode;
                responded = true;
            else
                disp('Invalid key')
            end
        end
        WaitSecs(stim_time);
        Screen('FillRect',w,bgcolor,[0 0 rect(3) rect(4)]);   %Fill entire screen gray
        Screen('Flip',w);               %Show backbuffer with background
        WaitSecs(ISI);
        %Record responses. It might be more efficient to prefill the first two
        %columns, but this way is easier to see.
        responses(i,1) = trials(i,1);
        responses(i,2) = trials(i,2);
        %responses(i,3) = is above
    end     %Individual response
end         %For loop/experimental display
save(filename);             %Will save entire workspace. You may want to request fewer variables for simplicity.
% For analysis, 'trials' and 'torder' are important
if EEG
    Close_EEG()
else
    Screen('Close',w);
    close all
end
%ShowCursor;

end

function  Initialize_EEG()
%Netstation initial communication parameters, experiment-generic
global biosemi
if biosemi
    s = daq.createSession('ni');
    ch = addDigitalChannel(s,'Dev1','Port1/Line0:7','OutputOnly');
else
    NS_host = '169.254.180.49';     %IP address for EEG computer
    NS_port = 55513;   sca
    %Default port
    %NS_synclimit = 0.9; % the maximum allowed difference in milliseconds between PTB and NetStation computer clocks (.m default is 2.5)
    
    %Windows: you should download the 'libusb' library at: http://libusb.org/wiki/windows_backend
    
    %Detect and initialize the DAQ for ttl pulses
    d=PsychHID('Devices');
    numDevices=length(d);
    trigDevice=[];
    dev=1;
    while isempty(trigDevice)
        if d(dev).vendorID==2523 && d(dev).productID==130 %if this is the first trigger device
            trigDevice=dev;
            %if you DO have the USB to the TTL pulse trigger attached
            disp('Found the trigger.');
        elseif dev==numDevices
            %if you do NOT have the USB to the TTL pulse trigger attached
            disp('Warning: trigger not found.');
            disp('Check out the USB devices by typing d=PsychHID(''Devices'').');
            break;
        end
        dev=dev+1;
    end
end

%trigDevice=4; %if this doesn't work, try 4
%Set port B to output, then make sure it's off
DaqDConfigPort(trigDevice,0,0);
DaqDOut(trigDevice,0,0);
TTL_pulse_dur = 0.005; % duration of TTL pulse to account for ahardware lag

% Connect to the recording computer and start recording
NetStation('Connect', NS_host, NS_port)
NetStation('StartRecording');           %Same as clicking the record button in Net Station

% Sync the screen flips for timing purposes
%sync_time = Screen('Flip',w,[],2);
end

function Close_EEG()
% Make sure to stop recording and disconnect from the recording computer
global biosemi
if biosemi
    Screen('CloseAll');
    clear all
    close all
else
    NetStation('StopRecording');
    NetStation('Disconnect');
    Screen('Close',w);
    close all
end
end