function sogRovingMinimal(subject, varargin)
%%
% rsvp of Gratings with roving design
%
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
p.addParameter('onFrames',30);%number of frames per presentation
p.addParameter('offFrames',12);%number of frames per presentation
p.addParameter('ori1List',0:30:150);
p.parse(subject,varargin{:});
args = p.Results;

%% fixed parameters
iti = 1000; %[ms] inter trial interval
frequency = 0.5; %spatial frequency in cycles per visual angle in degree (not pixel) %Kapoor 2022

%% Prerequisites.
import neurostim.*


%% Setup CIC and the stimuli.
c = myRig; 
c.addProperty('tDur',args.tDur); %duration of one sequence in ms
c.trialDuration = '@cic.tDur';
c.screen.color.background = [0 0 0];
c.iti = iti;

% Create a Gabor stimulus to adadot.
g=stimuli.gabor(c,'myStim');
g.color             = [0.5 0.5 0.5]; %TOBE FIXED
g.contrast          = 0.25; %TOBE FIXED
g.Y                 = 0;
g.X                 = 0;
g.sigma             = 3;
g.phaseSpeed        = 0;
g.mask              ='CIRCLE';
g.frequency         = frequency;
g.on                = 0; 
g.addProperty('ori1List', args.ori1List);

% Add a param to store how many times will we show the "current" orientation
% This value will be updated in the RSVP sampling function
g.addProperty('n_ori_repeats', 0);

% Add a param to store how many times have we already shown the current orientation
g.addProperty('n_ori_repeats_completed', 0);

stopLog(c.myStim.prms.n_ori_repeats);
stopLog(c.myStim.prms.n_ori_repeats_completed);

% define the sampling function
    function val = set_orientation(o)

        if o.n_ori_repeats_completed == o.n_ori_repeats
            o.n_ori_repeats = 5;%randi([5 10]); %5-10 successive presentations
            val = randsample(o.ori1List, 1); 
            o.n_ori_repeats_completed = 1;
        else
            val = o.orientation;
            o.n_ori_repeats_completed = o.n_ori_repeats_completed + 1;
        end

        disp(['set_orientation: ' num2str([o.n_ori_repeats o.n_ori_repeats_completed])]); %sanity check

    end


% We want to show a rapid rsvp of gratings. Use the factorial class to
% define these "conditions" in the rsvp.
rsvp =design('rsvp');           % Define a factorial with one factor
rsvp.fac1.myStim.contrast = [1]; %dummy factorization
rsvp.conditions(:).myStim.orientation =plugins.jitter(c,{g},'distribution',@set_orientation);
rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
g.addRSVP(rsvp,'duration', args.onFrames*1000/c.screen.frameRate, ...
    'isi', args.offFrames*1000/c.screen.frameRate); % Tell the stimulus that it should run this rsvp (in every trial). 5 frames on 2 frames off.


%% Define conditions and blocks

blck=block('block',rsvp);                  % Define a block based on this factorial
blck.nrRepeats  = args.nRepPerCond;                        % Each condition is repeated this many times

%% Run the experiment
% Now tell CIC how we want to run these blocks
c.run(blck);
end