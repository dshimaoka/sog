function jitter2RSVP(varargin)
%%
% rsvp of Gratings with roving design
%
%
% created from sogDemo

%% PARAMETER DEFINITIONS
ori1List = 0:30:150;
nRepPerCond = 3;
onFrames = 30;
offFrames = 12;
frequency = 0.5; %spatial frequency in cycles per visual angle in degree (not pixel) %Kapoor 2022

%% Prerequisites.
import neurostim.*


%% Setup CIC and the stimuli.
c = myRig; 
c.subject = 'test';
c.trialDuration = 5000;
c.screen.color.background = [0 0 0];
c.iti = 1000;

% Create a Gabor stimulus to adadot.
g=stimuli.gabor(c,'myStim');
g.color             = [0.5 0.5 0.5];
g.contrast          = 0.25;
g.sigma             = 3;
g.mask              ='CIRCLE';
g.frequency         = frequency;
g.on                = 0; 
g.addProperty('ori1List', ori1List);


% define the sampling function
    function val = set_orientation(o)
        val = randsample(o.ori1List, 1);
        disp(['new orientation: ' num2str(val)]); %sanity check
    end

%% design specifying RSVP
rsvp =design('rsvp');           % Define a factorial with one factor
rsvp.fac1.myStim.contrast = [1]; %dummy factorization
rsvp.conditions(:).myStim.orientation =plugins.jitter(c,{g},'distribution',@set_orientation);
rsvp.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
g.addRSVP(rsvp,'duration', onFrames*1000/c.screen.frameRate, ...
    'isi', offFrames*1000/c.screen.frameRate); % Tell the stimulus that it should run this rsvp (in every trial). 5 frames on 2 frames off.


%% dummy design specifying presentations across trials
d=design('dummy');           % Define a factorial with one factor
d.conditions(1).myStim.X = 0; % Dummy
%d.nrTrials = nRepPerCond;

blck=block('block',d);                 % Define a block based on this factorial
blck.nrRepeats  = nRepPerCond;                        % Each condition is repeated this many times

%% Run the experiment
% Now tell CIC how we want to run these blocks
c.run(blck);
end
