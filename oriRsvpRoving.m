function oriRsvpRoving(varargin)
% Static/moving gratings/Gabors with interleaved direction/TF/SF/size/position/orientation/etc.
% Explicitly designed for anaesthetised work = no fixation, no rewards.
%
% Created from oriRsvpWeights
%


% parse optional arguments...
p = inputParser();
p.KeepUnmatched = true;
p.addParameter('subject', 'test', @(x) ischar(x));
p.addParameter('debug',false,@(x) validateattributes(x,{'logical'},{'scalar','nonempty'}));
p.addParameter('saveEveryN',100);
p.addParameter('nrRepeats',10); % number of repeats of each unique stimulus
p.addParameter('tITI',0.25); %inter sequence interval [s]
%p.addParameter('tPreStat',0.5);
p.addParameter('tMove',5000); %duration of 1 sequence???
%p.addParameter('tPostStat',0.25);
p.addParameter('mask','circle');
% converted from list
p.addParameter('X',0);
p.addParameter('Y',0);
%specific for gabor
p.addParameter('sigma',3);
p.addParameter('contrast',1);
p.addParameter('frequency',1); %te

% parameters for rsvp
p.addParameter('onFrames',5);%number of frames per presentation
p.addParameter('offFrames',2);%number of frames per presentation

%% list
p.addParameter('phase1List',0:90:270);
p.addParameter('ori1List',0:15:165);%0:30:330);

%% weight
p.addParameter('weights',ones(12,1));%nCols defines #conditions

%% options
p.addParameter('phaseRandomise',false);
p.addParameter('screenDistance',85);

p.parse(varargin{:});

args = p.Results;
nrConds = 1;%size(args.weights,2);

import neurostim.*
commandwindow;

c = marmolab.rigcfg('debug',args.debug,'subject',args.subject, ...
    'screenDistance',args.screenDistance, p.Unmatched);


%% log git hash
if ~args.debug
    hash = marmolab.getGitHash(strrep(fileparts(mfilename('fullpath')),'+tuning',''));
    c.githash('marmolab-stimuli.git') = hash;
end

    % c.trialDuration = '@gabor.off'; % milliseconds
    %c.trialDuration = '@gabor.stopTime'; % milliseconds. WHY WOULD THIS BE BAD? CHECK SLACK
    c.trialDuration = args.tMove+20; % milliseconds
    %c.iti = args.tITI;

%% stimuli
    stimName = 'patch';
    g = neurostim.stimuli.gabor(c,stimName); % neurostim.stimuli.gabor
    
    % define maximum texture size based on mask type

    g.width = 2*max(args.sigma);
    g.height = g.width;
    g.mask = upper(args.mask);
    
    % TIMING (ms)
    % plugins.jitter(c, {0, 0})
    g.on = 0;%args.tPreBlank; % visible from when?
    %g.duration = args.tMove;
    
    %duration of a single trial? what is difference to c.trialduration??
    % g.duration = args.tPreStat + args.tMove + args.tPostStat;
    %23/5/21  commented out
    g.phaseSpeed = 0;
    g.X = args.X;
    g.Y = args.Y;
    g.sigma = args.sigma;
    g.contrast = args.contrast;
    g.frequency = args.frequency;
    
     
    %% RSVP stimuli (from sogDemo.m)
    % We want to show a rapid stream of gratings. Use the factorial class to
    % define these "conditions" in the stream.
    stream = design('oneOR');           % Define a factorial with one factor
    stream.randomization = 'RANDOMWITHOUTREPLACEMENT'; % Randomize
    
    %% Diode Flasher 25/5/21
    %make offColor transparent so that disabled flasher will not interfere
    %with enabled flasher
    %addDiodeFlasher(g,'offColor',[0 0 0 0]);
    
    stream.fac1.patch.orientation = args.ori1List;%0:30:359; % Assign orientations
    stream.fac2.patch.phase = args.phase1List;
    %if there are >1 fac, the experiment never ends ... likely a bug
    %stream.weights = repmat(args.weights(:,ii), 1, length(args.phase1List)); %user input
    
    
    % Tell the stimulus that it should run this stream (in every trial). 5 frames on 2 frames off.
    g.addRSVP(stream,'duration',args.onFrames*1000/c.screen.frameRate,...
        'isi',args.offFrames*1000/c.screen.frameRate);
    
 % end


% %% make sure gaborXX and gaborYY are not presented at the same time
% myDesign = design('multiORs');
% for ii = 1:nrConds
%     theseValues = logical(ones(1,nrConds));
%     theseValues(ii) = false;
%     myDesign.fac1.(sprintf('gabor%d',ii)).disabled = theseValues;
% end

%% specify a block of trials
% blk = block('myBlock', myDesign);
blk = block('myBlock', stream);
blk.nrRepeats = args.nrRepeats;

%% now run the experiment...
c.subject = args.subject;
c.paradigm = mfilename;
%c.saveEveryN = args.saveEveryN; % (default 10).

% ListenChar(2);
% c.order('gabor','displayPP');
%c.order('gabor','mcc'); %DS commented out 23/5
%c.order('gabor2','gabor1'); %order should not matter 
c.run(blk); % run the paradigm
% ListenChar(0);

end
