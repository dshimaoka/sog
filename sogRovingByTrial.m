function sogRovingByTrial(subject, varargin)
%%
% rsvp of Gratings Example
%
% Shows how a single stimulus ( a grating in this case) can be shown as a
% rapid visual rsvp (RSVP) with one or more of its properties changing within a
% trial.
%
% The experiment starts with a red dot, click with a mouse to fixate, then
% the rsvp of gratings will show.
%
% created from sogDemo

% TODO: 
% control sequence 
% turn off logging
% impose fixation only in the 1st trial?
% shorten iti as much as possible

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

p.addParameter('nRep',3,@(x) validateattributes(x,{'numeric'},{'scalar','nonempty'}));  % number of sequences

% parameters for rsvp
p.addParameter('nSuccessivePresentations', [5 10]);
p.addParameter('onFrames',24);%number of frames per presentation
p.addParameter('offFrames',6);%number of frames per presentation
p.addParameter('dirList',0:15:165);%0:30:330);
p.addParameter('speed',11, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %[(visual angle in deg)/s]
p.addParameter('radius',15, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %aperture size [deg]

% parameters for reward
p.addParameter('rewardVolume',0.020,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','positive'})); % reward volume (ml)
p.addParameter('rewardRate',0.1,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','positive'})); % reward rate (ml/min)

p.parse(subject,varargin{:});
args = p.Results;

%% fixed parameters
% radius_init = 2;%initial fixation radius[deg] value from OcuFol and cueSaccade
% fixationDeadline = 5000; %[ms]
% fixDuration = 300; % [ms] minimum duration of fixation to initiate patch stimuli
%iti = 1000; %[ms] inter trial interval
frequency = 0.5; %spatial frequency in cycles per visual angle in degree (not pixel) %Kapoor 2022
redLuminance = 171/255; %Fraser ... Miller 2023

%% Prerequisites.
import neurostim.*
commandwindow;

%% Setup CIC and the stimuli.
c = marmolab.rigcfg('debug',args.debug, p.Unmatched); % set to false to save githash at start of each experiment!
c.paradigm = 'sogRoving';
c.addProperty('redLuminance', redLuminance);
c.trialDuration = '@patch.tDur'; %'@fixbhv.startTime.FIXATING+patch.tDur';
c.screen.color.background = [0 0 0];
tDur_cycle = (args.onFrames + args.offFrames)*1000/c.screen.frameRate; %one presentation cycle [ms]
c.iti = 0;%tDur_cycle;

if ~args.debug % log git hash
    hash = marmolab.getGitHash(fileparts(mfilename('fullpath')));
    c.githash('sog.git') = hash;
end

% Create a Gabor stimulus.
g=stimuli.gabor(c,'patch');
g.addProperty('tDur', 0); %duration of one successive presentations [ms]
g.addProperty('frameRate', c.screen.frameRate);
g.addProperty('direction',0);
g.addProperty('directionPolarity',0);
g.addProperty('speed',args.speed);

tDurChoices =  tDur_cycle*args.nSuccessivePresentations(1):tDur_cycle:tDur_cycle*args.nSuccessivePresentations(2);
g.tDur = plugins.jitter(c,num2cell(tDurChoices), 'distribution','1ofN');

g.color             = 0.5*[redLuminance 0 1 1]; 
g.contrast          = 1;
g.Y                 = 0;
g.X                 = 0;
g.width = 2*args.radius;
g.height = g.width;
g.sigma             = args.radius;
g.flickerMode = 'sinecontrast';%'none'; %none makes the phase difference between patches more apparent
g.flickerFrequency = 0;
g.phase = 0;
g.orientation = '@mod(patch.direction, 180) - 90';
g.directionPolarity = '@-2*fix(patch.direction/180) + 1'; 
g.phaseSpeed = '@360*patch.directionPolarity * patch.speed * patch.frequency /patch.frameRate'; %[deg/frame]
g.mask              = 'CIRCLE';
g.frequency         = frequency;
g.on                =  0;%'@fixbhv.startTime.FIXATING +cic.fixDuration'; % Start showing fixDuration [ms] after the subject starts fixating (See 'fixation' object below).


% define the sampling function
    function val = set_direction(dir_list)
          val = randsample(dir_list, 1);
    end


% We want to show a rapid rsvp of gratings. Use the factorial class to
% define these "conditions" in the rsvp.
rsvp =design('rsvp');           % Define a factorial with one factor
%rsvp.fac1.patch.orientation = args.ori1List; % OK
rsvp.fac1.patch.contrast = g.contrast; %dummy factorization
rsvp.conditions(:).patch.direction =plugins.jitter(c,{args.dirList},'distribution',@set_direction);
rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
g.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
    'isi', args.offFrames*1000/c.screen.frameRate); % Tell the stimulus that it should run this rsvp (in every trial). 5 frames on 2 frames off.


%% "fixate" for reward...
marmolab.behaviors.fixate(c,'fix');
c.fix.on = 0;
c.fix.from = '@fix.startTime.fixating';
c.fix.tolerance = args.radius; % radius (deg.)
c.fix.grace = Inf;

c.fix.failEndsTrial = false;
c.fix.successEndsTrial = false;

c.fix.verbose = false;

%% reward from marmolab-stimuli/+freeviewing/utimages.m
% p(reward) = (ml/min)/(s/min) /(frames/s) /(ml/reward) = reward/frame
%
% e.g., 0.1/60 /120 /0.020 = 6.9444e-04
c.fix.addProperty('rewardVolume',args.rewardVolume);
c.fix.addProperty('rewardRate',args.rewardRate);

c.fix.addProperty('pReward',NaN);
c.fix.pReward = args.rewardRate/60/c.screen.frameRate/args.rewardVolume;

if ~isempty(c.pluginsByClass('newera'))  
  % add liquid reward... newera syringe pump
  c.newera.add('volume',args.rewardVolume,'when','AFTERFRAME','repeat',true,'criterion','@fix.isFixating & binornd(1,fix.pReward)');
end

%% Turn off logging



%% This is all you need for an rsvp rsvp. The rest is just to make it into a full experiment.

% % fixation point at trial start
% f = stimuli.fixation(c,'fixstim');       % Add a fixation point stimulus
% f.color             = [1 1 1];
% f.shape             = 'CIRC';           % Shape of the fixation point
% f.size              = 0.25;
% f.X                 = 0;
% f.Y                 = 0;
% f.on                = 0;                % On from the start of the trial
% f.duration = '@fixbhv.startTime.fixating+cic.fixDuration'; % Show spot briefly after fixation acquired



%% Behavioral control

%Make sure there is an eye tracker (or at least a virtual one)
if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

% fix = behaviors.fixate(c,'fixbhv');
% fix.addProperty('radius_init',radius_init);
% fix.from            = fixationDeadline;                 % If fixation has not been achieved at this time, move to the next trial
% fix.to              = '@patch.stopTime';   % Require fixation until testGabor has been shown.
% fix.X               = 0; 
% fix.Y               = 0;
% fix.tolerance       = radius_init;


%% Define conditions and blocks
blck=block('block', rsvp);                  % Define a block based on this factorial
blck.nrRepeats  = args.nRep;                        % Each condition is repeated this many times

%% Run the experiment
%c.cursor = 'arrow';
% Now tell CIC how we want to run these blocks
c.run(blck);
end