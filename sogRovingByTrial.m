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
c.trialDuration = '@patch1.tDur'; %'@fixbhv.startTime.FIXATING+patch.tDur';
c.screen.color.background = [0 0 0];
tDur_cycle = (args.onFrames + args.offFrames)*1000/c.screen.frameRate; %one presentation cycle [ms]
c.iti = 0;%tDur_cycle;

if ~args.debug % log git hash
    hash = marmolab.getGitHash(fileparts(mfilename('fullpath')));
    c.githash('sog.git') = hash;
end

% Create a Gabor stimulus.
dirList = args.dirList;
nrConds = numel(args.dirList);
g = cell(nrConds,1);
for ii = 1:nrConds
    stimName = ['patch' num2str(ii)];
    g{ii} = neurostim.stimuli.gabor(c,stimName); % neurostim.stimuli.gabor
    thisDirection = dirList(ii);

    g{ii}.addProperty('tDur', 0); %duration of one successive presentations [ms]
    g{ii}.addProperty('frameRate', c.screen.frameRate);
    g{ii}.addProperty('direction',0);
    g{ii}.addProperty('directionPolarity',0);
    g{ii}.addProperty('speed',args.speed);

    tDurChoices =  tDur_cycle*args.nSuccessivePresentations(1):tDur_cycle:tDur_cycle*args.nSuccessivePresentations(2);
    g{ii}.tDur = plugins.jitter(c,num2cell(tDurChoices), 'distribution','1ofN');

    g{ii}.color             = 0.5*[redLuminance 0 1 1];
    g{ii}.contrast          = 1;
    g{ii}.Y                 = 0;
    g{ii}.X                 = 0;
    g{ii}.width = 2*args.radius;
    g{ii}.height = g{ii}.width;
    g{ii}.sigma             = args.radius;
    g{ii}.flickerMode = 'sinecontrast';%'none'; %none makes the phase difference between patches more apparent
    g{ii}.flickerFrequency = 0;
    g{ii}.phase = 0;
    g{ii}.orientation = mod(thisDirection, 180) - 90;
    g{ii}.directionPolarity = -2*fix(thisDirection/180) + 1;
    g{ii}.phaseSpeed = 360*g{ii}.directionPolarity * args.speed * frequency /g{ii}.frameRate; %[deg/frame]
    % g{ii}.orientation = '@mod(patch.direction, 180) - 90'; %NG
    % g{ii}.directionPolarity = '@-2*fix(patch.direction/180) + 1'; %NG
    % g{ii}.phaseSpeed = '@360*patch.directionPolarity * patch.speed * patch.frequency /patch.frameRate'; %[deg/frame]
    g{ii}.mask              = 'CIRCLE';
    g{ii}.frequency         = frequency;
    g{ii}.on                =  0;%'@fixbhv.startTime.FIXATING +cic.fixDuration'; % Start showing fixDuration [ms] after the subject starts fixating (See 'fixation' object below).


    % We want to show a rapid rsvp of gratings. Use the factorial class to
    % define these "conditions" in the rsvp.
    %rsvpName =  ['rsvp' num2str(ii)];
    rsvp =design('rsvp');           % Define a factorial with one factor
    rsvp.fac1.(sprintf('%s',stimName)).direction = thisDirection; % OK
    rsvp.fac1.(sprintf('%s',stimName)).contrast = g{ii}.contrast; %dummy factorization
    % rsvp.conditions(:).patch.direction =plugins.jitter(c,{args.dirList},'distribution',@set_direction);
    rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
    g{ii}.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
        'isi', args.offFrames*1000/c.screen.frameRate); % Tell the stimulus that it should run this rsvp (in every trial). 5 frames on 2 frames off.
end

%% equiprobable control condition
    g0 = neurostim.stimuli.gabor(c,'patch0'); % neurostim.stimuli.gabor
    thisDirection = dirList(ii);

    g0.addProperty('tDur', 0); %duration of one successive presentations [ms]
    g0.addProperty('frameRate', c.screen.frameRate);
    g0.addProperty('direction',0);
    g0.addProperty('directionPolarity',0);
    g0.addProperty('speed',args.speed);

    tDurChoices =  tDur_cycle*args.nSuccessivePresentations(1):tDur_cycle:tDur_cycle*args.nSuccessivePresentations(2);
    g0.tDur = plugins.jitter(c,num2cell(tDurChoices), 'distribution','1ofN');

    g0.color             = 0.5*[redLuminance 0 1 1];
    g0.contrast          = 1;
    g0.Y                 = 0;
    g0.X                 = 0;
    g0.width = 2*args.radius;
    g0.height = g0.width;
    g0.sigma             = args.radius;
    g0.flickerMode = 'sinecontrast';%'none'; %none makes the phase difference between patches more apparent
    g0.flickerFrequency = 0;
    g0.phase = 0;
    g0.orientation = '@mod(patch0.direction, 180) - 90'; %NG
    g0.directionPolarity = '@-2*fix(patch0.direction/180) + 1'; %NG
    g0.phaseSpeed = '@360*patch0.directionPolarity * patch0.speed * patch0.frequency /patch0.frameRate'; %[deg/frame]
    g0.mask              = 'CIRCLE';
    g0.frequency         = frequency;
    g0.on                =  0;

    rsvp =design('rsvp');           % Define a factorial with one factor
    rsvp.fac1.patch0.direction = args.dirList; % OK
    rsvp.fac1.patch0.contrast = g0.contrast; %dummy factorization
    rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
    g0.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
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





%% Behavioral control

%Make sure there is an eye tracker (or at least a virtual one)
if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

%% make sure gaborXX and gaborYY are not presented at the same time
myDesign = design('roving');
for ii = 1:nrConds
    theseValues = logical(ones(1,nrConds));
    theseValues(ii) = false;
    myDesign.fac1.(sprintf('patch%d',ii)).disabled = theseValues;
end

%% Define conditions and blocks
blck=block('block', myDesign);%rsvp);                  % Define a block based on this factorial
blck.nrRepeats  = args.nRep;                        % Each condition is repeated this many times

myDesign_ctrl = design('control');
myDesign_ctrl.fac1.patch0.contrast = 1; %fake

blck2 = block('control', myDesign_ctrl);
blck2.nrRepeats  = args.nRep*nrConds;

%% Run the experiment
%c.cursor = 'arrow';
% Now tell CIC how we want to run these blocks
c.run(blck, blck2);
end