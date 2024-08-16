function sogRoving(subject, varargin)
%% 
% Stream of Gratings Example
% 
% Shows how a single stimulus ( a grating in this case) can be shown as a 
% rapid visual stream (RSVP) with one or more of its properties changing within a
% trial. 
%
% The experiment starts with a red dot, click with a mouse to fixate, then
% the stream of gratings will show.
% 
% created from sogDemo

%% PARAMETER DEFINITIONS

if ~exist('subject','var')
    error('No subject name provided. Type ''help facecal'' for usage information.');
end

validateattributes(subject,{'char'},{'nonempty'},'','subject',1);
% parse optional arguments...
p = inputParser();
p.KeepUnmatched = true;
p.addParameter('subject', 'test', @(x) ischar(x));
p.addParameter('debug',false,@(x) validateattributes(x,{'logical'},{'scalar','nonempty'}));
% trial
p.addParameter('tDur',5000);%number of 1 sequence [ms]
p.addParameter('nRepPerCond',3,@(x) validateattributes(x,{'numeric'},{'scalar','nonempty'}));  % number of repeats of each condition
% parameters for rsvp
p.addParameter('onFrames',5);%number of frames per presentation
p.addParameter('offFrames',2);%number of frames per presentation
p.addParameter('ori1List',0:15:165);%0:30:330);
p.parse(subject,varargin{:});
args = p.Results;

%% fixed parameters
radius_init = 2;%initial fixation radius[deg] value from OcuFol and cueSaccade
fixationDeadline = 5000; %[ms]
fixDuration = 300; % [ms] minimum duration of fixation to initiate patch stimuli
iti = 1000; %[ms] inter trial interval
frequency = 0.5; %spatial frequency in cycles per visual angle in degree (not pixel) %Kapoor 2022

%% Prerequisites. 
import neurostim.*


%% Setup CIC and the stimuli.
c = marmolab.rigcfg('debug',args.debug, p.Unmatched); % set to false to save githash at start of each experiment!
c.paradigm = 'sogRoving';
c.addProperty('tDur',args.tDur); %duration of one sequence in ms
c.addProperty('fixDuration', fixDuration);
c.trialDuration = '@fixbhv.startTime.FIXATING+cic.tDur';
c.screen.color.background = [0 0 0]; 
c.iti = iti;

% Create a Gabor stimulus to adadot. 
g=stimuli.gabor(c,'patch');           
g.color             = [0.5 0.5 0.5]; %TOBE FIXED
g.contrast          = 0.25; %TOBE FIXED
g.Y                 = 0; 
g.X                 = 0;
g.sigma             = 3;                       
g.phaseSpeed        = 0;
%g.orientation       = 15; 
g.mask              ='CIRCLE';
g.frequency         = frequency;
g.on                =  '@fixbhv.startTime.FIXATING +cic.fixDuration'; % Start showing fixDuration [ms] after the subject starts fixating (See 'fixation' object below).

% We want to show a rapid stream of gratings. Use the factorial class to
% define these "conditions" in the stream.
stream =design('ori');           % Define a factorial with one factor
stream.fac1.patch.orientation = args.ori1List; % Assign orientations
stream.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
g.addRSVP(stream,'duration', args.onFrames*1000/c.screen.frameRate, ...
    'isi', args.offFrames*1000/c.screen.frameRate); % Tell the stimulus that it should run this stream (in every trial). 5 frames on 2 frames off.

% Alternatively, you may want to stream gratings with both orientation and
% contrast varied.
% stream =design('ovc');           % Define a factorial with two fa0ctors
% stream.fac1.grating.orientation = 0:30:359; % Assign orientations
% stream.fac2.grating.contrast = [0 0.25 0.5 1]; % Contrasts including 0
% stream.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
% g.addRSVP(stream,'log',true,'duration',5*1000/c.screen.frameRate,'isi',15*1000/c.screen.frameRate); % Tell the stimulus that it should run this stream (in every trial). 5 frames on 2 frames off.

%% This is all you need for an rsvp stream. The rest is just to make it into a full experiment.

% fixation point at trial start
f = stimuli.fixation(c,'fixstim');       % Add a fixation point stimulus
f.color             = [1 1 1];
f.shape             = 'CIRC';           % Shape of the fixation point
f.size              = 0.25;
f.X                 = 0;
f.Y                 = 0;
f.on                = 0;                % On from the start of the trial
f.duration = '@fixbhv.startTime.fixating+cic.fixDuration'; % Show spot briefly after fixation acquired



%% Behavioral control

%Make sure there is an eye tracker (or at least a virtual one)
if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

fix = behaviors.fixate(c,'fixbhv');
fix.addProperty('radius_init',radius_init);
fix.from            = fixationDeadline;                 % If fixation has not been achieved at this time, move to the next trial
fix.to              = '@patch.stopTime';   % Require fixation until testGabor has been shown.
fix.X               = 0;%'@fixstim.X';
fix.Y               = 0;%'@fixstim.Y';
fix.tolerance       = radius_init;


%% Define conditions and blocks
% We will show the stream of gratings with different contrasts in each
% trial.
% d=design('contrast');           % Define a factorial with one factor
% d.fac1.grating.contrast = 0.1:0.2:1; % From 10 to 100% contrast
% d.randomization = 'RANDOMWITHOUTREPLACEMENT';

% Or (if the stream already varies contrast and orientation, we vary
% nothing across trials).
d=design('dummy');           % Define a factorial with one factor
% Nothing to vary here but we need at least one condition
d.conditions(1).patch.X = 0; % Dummy
blck=block('block',d);                  % Define a block based on this factorial
blck.nrRepeats  = args.nRepPerCond;                        % Each condition is repeated this many times 

%% Run the experiment   
c.cursor = 'arrow';
% Now tell CIC how we want to run these blocks 
c.run(blck);
 