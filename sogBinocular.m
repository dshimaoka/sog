function sogBinocular(subject, varargin)
%%
% rsvp of Gratings Example
%
% Shows two superimposed RSVPs with direction property changing within a trial.
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
p.addParameter('nPresentations', 7, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %total number of presentations per trial
p.addParameter('onFrames',48);%number of frames per presentation
p.addParameter('offFrames',12);%number of frames per presentation
p.addParameter('dirList',[0:45:315 Inf]); %Inf = blank
p.addParameter('speed',11, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %[(visual angle in deg)/s]
p.addParameter('radius',15, @(x) validateattributes(x,{'numeric'},{'scalar','nonempty'})); %aperture size [deg]

% parameters for reward
p.addParameter('rewardVolume',0.020,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','positive'})); % reward volume (ml)
p.addParameter('rewardRate',0.1,@(x) validateattributes(x,{'numeric'},{'nonempty','scalar','positive'})); % reward rate (ml/min)


p.parse(subject,varargin{:});
args = p.Results;

%% fixed parameters
frequency = 0.5; %spatial frequency in cycles per visual angle in degree (not pixel) %Kapoor 2022
redLuminance = 128/255; %Fraser ... Miller 2023

%patch contour
contourWidth  = 10; %pixels? 

%total number of patches presented in a sequence
numPresentations = args.nRep * numel(args.dirList) * args.nPresentations;


%% Prerequisites.
import neurostim.*
commandwindow;

%% Setup CIC and the stimuli.
c = marmolab.rigcfg('debug',args.debug, p.Unmatched); % set to false to save githash at start of each experiment!
c.paradigm = 'sogBinocular';
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
c.addProperty('nPresentations', args.nPresentations);
c.addProperty('dirList', args.dirList);

if ~args.debug % log git hash
    hash = marmolab.getGitHash(fileparts(mfilename('fullpath')));
    c.githash('sog.git') = hash;
end
c.hardware.keyEcho = false;
c.hardware.maxPriorityPerTrial = false;

% Create a Gabor stimulus.
dirList = args.dirList;
nrConds = 2;

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

    g{ii}.tDur = tDur_cycle*args.nPresentations;

if ii == 1
    g{ii}.color             = 0.5*[redLuminance 0 0 1];
elseif ii == 2
    g{ii}.color             = 0.5*[0 0 1 1];
end
    g{ii}.contrast          = iff(isinf(sprintf('patch%d',ii).direction), 0, 1);
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
        g{ii}.orientation = '@mod(patch1.direction, 180) - 90';
        g{ii}.directionPolarity = '@-2*fix(patch1.direction/180) + 1';
        g{ii}.phaseSpeed = '@360*patch1.directionPolarity * patch1.speed * patch1.frequency /patch1.frameRate'; %[deg/frame]
    
    % We want to show a rapid rsvp of gratings. Use the factorial class to
    % define these "conditions" in the rsvp.
    rsvp =　design('rsvp');           % Define a factorial with one factor
    rsvp.fac1.(sprintf('%s',stimName)).direction = args.dirList; %use all directions
    
    rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
    g{ii}.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
        'isi', args.offFrames*1000/c.screen.frameRate,'log',true);

    c.(sprintf('patch%d',ii)).setChangesInTrial('rsvpIsi')
    stopLog(c.(sprintf('patch%d',ii)).prms.sigma); 
end



pc = stimuli.convPoly(c,'patchContour');    % Add a fixation stimulus object (named "fix") to the cic. It is born with default values for all parameters.
pc.filled = false;
pc.nSides = 32;
pc.radius = args.radius;
pc.linewidth= contourWidth;               %The seemingly local variable "f" is actually a handle to the stimulus in CIC, so can alter the internal stimulus by modifying "f".
pc.preCalc = false;
pc.color = [1 1 1];
pc.on = '@patch1.on';
rsvp =design('rsvp');           % Define a factorial with one factor
pc.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
        'isi', args.offFrames*1000/c.screen.frameRate); 



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
stopLog(c.cic.prms.onFrames);
stopLog(c.cic.prms.offFrames);


%% Behavioral control

%Make sure there is an eye tracker (or at least a virtual one)
if isempty(c.pluginsByClass('eyetracker'))
    e = neurostim.plugins.eyetracker(c);      %Eye tracker plugin not yet added, so use the virtual one. Mouse is used to control gaze position (click)
    e.useMouse = true;
end

%% make sure gaborXX and gaborYY are not presented at the same time
myDesign = design('myDesign');

%% Define conditions and blocks
blck=block('block', myDesign);                % Define a block based on this factorial
blck.nrRepeats  = args.nRep*numel(args.dirList);


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