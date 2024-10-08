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

%% checkout my neurostim branch
sogDirectory = fileparts(mfilename('fullpath'));
nsDirectory = strrep(sogDirectory,'sog','neurostim');
originalHash = marmolab.getGitHash(nsDirectory);
cd(nsDirectory);
[~, cmdOutput] = system(sprintf('git show-ref superposition-binocular'));
myHash = cmdOutput(1:40); %myHash = '141539c45b2263844e1e72ed9a4677b3cd19159f';
system(sprintf('git checkout %s', myHash));
cd(sogDirectory);

%% PARAMETER DEFINITIONS
if ~exist('subject','var')
    error('No subject name provided. Type ''help facecal'' for usage information.');
end

validateattributes(subject,{'char'},{'nonempty'},'','subject',1);

% parse optional arguments...
p = inputParser();
p.KeepUnmatched = true;
p.addRequired('subject',@(x) validateattributes(x,{'char'},{'nonempty'}));
p.addParameter('debug',false,@(x) validateattributes(x,{'logical'},{'scalar','nonempty'}));

p.addParameter('nRep',14,@(x) validateattributes(x,{'numeric'},{'scalar','nonempty'}));  % number of sequences

% parameters for rsvp
p.addParameter('nPresentationsRange', [4 11]);
p.addParameter('onFrames',48);%number of frames per presentation
p.addParameter('offFrames',12);%number of frames per presentation
p.addParameter('dirList',0:45:315);
p.addParameter('speed',11, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %[(visual angle in deg)/s]
p.addParameter('radius',15, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %aperture size [deg]
p.addParameter('ctrl',1, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); 

% parameters for reward
p.addParameter('rewardVolume',0.020,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','positive'})); % reward volume (ml)
p.addParameter('rewardRate',0.1,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','positive'})); % reward rate (ml/min)

% parameters for oddball fixations
p.addParameter('fixOn',false,@(x) validateattributes(x,{'logical'},{'scalar','nonempty'})); %whether to present a fixation point [logical]
p.addParameter('probOddFixation', 0.02, @(x) validateattributes(x,{'numeric'},{'nonempty','scalar'})); %probability of dim fixation point  [0-1]

p.parse(subject,varargin{:});
args = p.Results;

%% fixed parameters
% radius_init = 2;%initial fixation radius[deg] value from OcuFol and cueSaccade
% fixationDeadline = 5000; %[ms]
% fixDuration = 300; % [ms] minimum duration of fixation to initiate patch stimuli
%iti = 1000; %[ms] inter trial interval
frequency = 0.5; %spatial frequency in cycles per visual angle in degree (not pixel) %Kapoor 2022
redLuminance = 171/255; %Fraser ... Miller 2023
colorFixation = [.5 1];

%total number of patches presented in a sequence
numPresentations = args.nRep * numel(args.dirList) * mean(args.nPresentationsRange);
probCtrlFixation = 1 - args.probOddFixation;
weightFixation = [round(numPresentations * args.probOddFixation) round(numPresentations * probCtrlFixation)];


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
c.iti = 0;
c.saveEveryN = Inf; 
% expected duration of one sequence
tDur_sequence = numPresentations * (tDur_cycle + c.iti) * 1e-3;
disp(['Expected duration [s]: ' num2str(tDur_sequence)]);
c.addProperty('onFrames', args.onFrames);
c.addProperty('offFrames', args.offFrames);
c.addProperty('ctrl', args.ctrl);
c.addProperty('nPresentationsRange', args.nPresentationsRange);
c.addProperty('dirList', args.dirList);
c.addProperty('fixOn', args.fixOn);
c.addProperty('pressedKey',[]);
c.addScript('KEYBOARD',@logKeyPress, 'space')
function logKeyPress(o, key)
    %disp('a key was pressed');
    % log the key press
    o.cic.pressedKey = key;
    % reset
    o.cic.pressedKey = [];
end

if ~args.debug % log git hash
    hash = marmolab.getGitHash(fileparts(mfilename('fullpath')));
    c.githash('sog.git') = hash;
end
c.hardware.keyEcho = false;
c.hardware.maxPriorityPerTrial = false;

% Create a Gabor stimulus.
dirList = args.dirList;
ctrl = args.ctrl;
if ctrl
    nrConds = 1;
else
    nrConds = numel(args.dirList);
end

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

    tDurChoices =  tDur_cycle*args.nPresentationsRange(1):tDur_cycle:tDur_cycle*args.nPresentationsRange(2);
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
    g{ii}.mask              = 'CIRCLE';
    g{ii}.frequency         = frequency;
    g{ii}.on                =  0;
    if ctrl
        g{ii}.orientation = '@mod(patch1.direction, 180) - 90';
        g{ii}.directionPolarity = '@-2*fix(patch1.direction/180) + 1';
        g{ii}.phaseSpeed = '@360*patch1.directionPolarity * patch1.speed * patch1.frequency /patch1.frameRate'; %[deg/frame]
    else
        g{ii}.orientation = mod(thisDirection, 180) - 90;
        g{ii}.directionPolarity = -2*fix(thisDirection/180) + 1;
        g{ii}.phaseSpeed = 360*g{ii}.directionPolarity * args.speed * frequency /g{ii}.frameRate; %[deg/frame]
    end

    % We want to show a rapid rsvp of gratings. Use the factorial class to
    % define these "conditions" in the rsvp.
    rsvp =design('rsvp');           % Define a factorial with one factor
    if ctrl
         rsvp.fac1.(sprintf('%s',stimName)).direction = args.dirList; %use all directions
    else
        rsvp.fac1.(sprintf('%s',stimName)).direction = thisDirection; %use only one direction
    end
    
    rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
    g{ii}.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
        'isi', args.offFrames*1000/c.screen.frameRate,'log',true); % Tell the stimulus that it should run this rsvp (in every trial). 5 frames on 2 frames off.

    c.(sprintf('patch%d',ii)).setChangesInTrial('rsvpIsi')
    stopLog(c.(sprintf('patch%d',ii)).prms.sigma); %still recording?

    %c.(sprintf('patch%d',ii)).addProperty('dout',false); % DOUT state
    %c.addScript('BeforeFrame',@(x) dout(x.(sprintf('patch%d',ii)))); % check/set DOUT state before each frame
end

pc = stimuli.arc(c,'patchContour');    % Add a fixation stimulus object (named "fix") to the cic. It is born with default values for all parameters.
pc.linewidth= 1;               %The seemingly local variable "f" is actually a handle to the stimulus in CIC, so can alter the internal stimulus by modifying "f".
pc.arcAngle = 360;
pc.outerRad = args.radius+pc.linewidth;
pc.color = [1 1 1];
pc.on = '@patch1.on';
rsvp =design('rsvp');           % Define a factorial with one factor
pc.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
        'isi', args.offFrames*1000/c.screen.frameRate); 

%% Fixation dot
if args.fixOn
    f = stimuli.fixation(c,'fixstim');    % Add a fixation stimulus object (named "fix") to the cic. It is born with default values for all parameters.
    f.shape = 'CIRC';               %The seemingly local variable "f" is actually a handle to the stimulus in CIC, so can alter the internal stimulus by modifying "f".
    f.size = 0.5; % units?
    f.addProperty('probOddFixation', args.probOddFixation);
    f.addProperty('colorFixation', colorFixation);
    f.addProperty('weightFixation', weightFixation);
    f.on='@patch1.on';                         % What time should the stimulus come on? (all times are in ms)
    f.X = 0;
    f.Y = 0;
    rsvp =design('rsvp');           % Define a factorial with one factor
    rsvp.fac1.fixstim.color = colorFixation;
    rsvp.weights = weightFixation;
    f.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
        'isi', args.offFrames*1000/c.screen.frameRate);
    c.fixstim.setChangesInTrial('color');
    stopLog(c.fixstim.prms.rsvpIsi);
    stopLog(c.fixstim.prms.disabled);
    stopLog(c.fixstim.prms.startTime);
    stopLog(c.fixstim.prms.stopTime);
end


 %% "fixate" for reward...
marmolab.behaviors.fixate(c,'fixbhv');
c.fixbhv.on = 0;
c.fixbhv.from = '@fixbhv.startTime.fixating';
c.fixbhv.tolerance = args.radius; % radius (deg.)
c.fixbhv.grace = Inf;
c.fixbhv.failEndsTrial = false;
c.fixbhv.successEndsTrial = false;
c.fixbhv.verbose = false;

%% reward from marmolab-stimuli/+freeviewing/utimages.m
% p(reward) = (ml/min)/(s/min) /(frames/s) /(ml/reward) = reward/frame
%
% e.g., 0.1/60 /120 /0.020 = 6.9444e-04
c.fixbhv.addProperty('rewardVolume',args.rewardVolume);
c.fixbhv.addProperty('rewardRate',args.rewardRate);
c.fixbhv.addProperty('pReward',NaN);
c.fixbhv.pReward = args.rewardRate/60/c.screen.frameRate/args.rewardVolume;

if ~isempty(c.pluginsByClass('newera'))
    % add liquid reward... newera syringe pump
    c.newera.add('volume',args.rewardVolume,'when','AFTERFRAME','repeat',true,'criterion','@fixbhv.isFixating & binornd(1,fixbhv.pReward)');
end


%% Turn off logging
stopLog(c.fixbhv.prms.event);
stopLog(c.fixbhv.prms.invert);
stopLog(c.fixbhv.prms.allowBlinks);
stopLog(c.patchContour.prms.rsvpIsi);
stopLog(c.patchContour.prms.disabled);
stopLog(c.patchContour.prms.filled);
stopLog(c.patchContour.prms.startTime);
stopLog(c.patchContour.prms.stopTime);
% stopLog(c.cic.prms.condition);%THIS IS NECESSARY for mdbase construction
stopLog(c.cic.prms.ctrl);
stopLog(c.cic.prms.fixOn);
stopLog(c.cic.prms.onFrames);
stopLog(c.cic.prms.offFrames);
stopLog(c.cic.prms.nPresentationsRange);


%% Behavioral control

%Make sure there is an eye tracker (or at least a virtual one)
if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

%% make sure gaborXX and gaborYY are not presented at the same time
myDesign = design('roving'); %RENAME
for ii = 1:nrConds
    theseValues = logical(ones(1,nrConds));
    theseValues(ii) = false;
    myDesign.fac1.(sprintf('patch%d',ii)).disabled = theseValues;
end

%% Define conditions and blocks
blck=block('block', myDesign);                % Define a block based on this factorial
if ctrl
    blck.nrRepeats  = args.nRep*numel(args.dirList);
else
    blck.nrRepeats  = args.nRep;                        % Each condition is repeated this many times
end


%% Run the experiment
% Now tell CIC how we want to run these blocks
c.subject = args.subject;

% load and set eye tracker calibration matrix...
c.eye.clbMatrix = marmolab.loadCal(c.subject);

c.run(blck);

%% return to original neurostim branch
cd(nsDirectory);
system(sprintf('git checkout %s', originalHash));
cd(sogDirectory);

end

%% from marmolab-stimuli/+cuesaccade/opto.m
function ix = dout(o)
  % o        - flash stimulus object

  loc_on = o.flags.on;
  
  if o.dout == loc_on, return; end
  
  if loc_on
      % DOUT high (LED on?)
      Datapixx('SetDoutValues',2); Datapixx('RegWrRd');
  else
      % DOUT low (LED off?)
      Datapixx('SetDoutValues',0); Datapixx('RegWrRd');
  end
  
  o.dout = loc_on;
end

function ip = doff(o)
    %(LED off?)
      Datapixx('SetDoutValues',0); Datapixx('RegWrRd');
end


%% to check ITI:
%0.2982 default/c.hardware.keyEcho = false;
%0.0413 c.hardware.maxPriorityPerTrial = false;

% [time,trial,frame,data]=d.meta.patch1.rsvpIsi;
% 
%  iti = [];
%  for itrial = 1:d.numTrials-1
%      iti(itrial)  =   min(time(trial==itrial+1)) - max(time(trial==itrial));
%  end
%  disp(mean(iti))