classdef sogRovingByTrial < marmodata.mdbase

    properties
        % stimulus
        patchDir; %direction of patch [deg]
        radius; %radius of patches in [deg]
        patchDirList; %list of stimulus directions
        patchSpeed; %stimulus speed [deg/s]
        tDur; %duration of a sequence of every trials [ms]
        patchStart; %onset times of patch in each trial [ms]
        patchStop; %offset times of patch in each trial [ms]
        onFrames;
        offFrames;
        frameRate;
        nSuccessivePresentations;
        patchFrequency;
       ctrl; %1: equiprobable. 0: roving 

        % reward
        rewardVol;
        rewardRate;
        pReward;
        rewardTimes; %time of reward in each trial

        % behavioural response
        probOddFixation;
        %oddFixationTime;
        %keyPressTime; %time when a key is perssed first time in a trial [ms]
        %reactionTime;
    end

    methods (Access = public)
        function d = sogRovingByTrial(varargin)
            d@marmodata.mdbase(varargin{:}); % base class constructor

            d.radius = getRadius(d); %radius of patches in [deg]
            d.patchDirList = getPatchDirList(d); %list of stimulus directions
            d.tDur = getTDur(d); %duration of a sequence [ms]
            d.patchStart = getPatchStart(d); %onset times of patch
            % d.patchStop = getPatchStop(d); %offset times of patch
            d.onFrames = getOnFrames(d);
            d.offFrames = getOffFrames(d);
            d.frameRate = getFrameRate(d);
            d.patchDir = getPatchDir(d); %direction of patch [deg]
            d.nSuccessivePresentations = getNSuccessivePresentations(d);
            d.patchSpeed = getPatchSpeed(d);
            d.patchFrequency = getPatchFrequency(d);
            d.ctrl = getCtrl(d);

            % % reward
            % d.rewardVol = getRewardVol(d);
            % d.rewardRate = getRewardRate(d);
            % d.pReward = getPReward(d);
            % d.rewardTimes = getRewardTimes(d);

            %% behaviour
            d.probOddFixation = getProbOddFixation(d);
            %d.keyPressTime = getKeyPressTime(d); %time of key press after trial onset
            %d.oddFixationTime = getOddFixationTime(d);
            %d.reactionTime = getReactionTime(d); %time of key press after odd fixation

        end

        function probOddFixation = getProbOddFixation(d)
            probOddFixation = d.meta.fixstim.probOddFixation('time',Inf).data;
        end

        function nSuccessivePresentations = getNSuccessivePresentations(d)
            nSuccessivePresentations = unique(d.meta.cic.nSuccessivePresentations('time',inf).data);
        end

        function radius = getRadius(d)
           radius =  unique(d.meta.patch1.sigma('time',inf).data);
        end

        function ctrl = getCtrl(d)
            ctrl = unique(d.meta.cic.ctrl('time',inf).data);
        end

        function tDur = getTDur(d)
            tDur = d.meta.cic.trialDuration('time',Inf).data;
        end
 
        function patchFrequency = getPatchFrequency(d)
            patchFrequency = unique(d.meta.patch1.frequency('time', Inf).data);
        end
 
        function patchSpeed = getPatchSpeed(d)
            patchSpeed = unique(d.meta.patch1.speed('time', Inf).data);
        end
        
        function keyPressTime = getKeyPressTime(d) %FIXME only 1st key press is returned
            %get time of key press from the onset of each trial [ms]

            t0 =  d.meta.cic.firstFrame('time',Inf);

            keyPressTime = cell(d.numTrials, 1);
            for itr = 1:d.numTrials
                % [time,trial,frame,keyTmp] = d.meta.keypress.keyIx('trial',itr);
                [time,trial,frame,keyTmp] = d.meta.cic.pressedKey('trial',itr);

                ignoreEntry = cellfun(@isempty, keyTmp);
                keepInd = find(~ignoreEntry);
                time = time(~ignoreEntry);
                trial = trial(~ignoreEntry);
                frame = frame(~ignoreEntry);
                key = keyTmp(~ignoreEntry);

                keyPressTime{itr} = 1e3*(time - t0(itr));
                if isempty( keyPressTime{itr})
                    keyPressTime{itr} = NaN;
                end
            end

        end

        function oddFixationTime = getOddFixationTime(d)

        [time, trial, frame, data] = d.meta.fixstim.color; 

        standard = cellfun(@(x)(x(1)==1), data);
        ignoreEvents = ((frame<0) + standard) > 0;
        time = time(~ignoreEvents);
        trial = trial(~ignoreEvents);

         oddFixationTime = cell(d.numTrials, 1);
         for itr = 1:d.numTrials
               t0 =  d.meta.cic.firstFrame('trial',itr);
               theseEvents = find(trial == itr);
               if ~isempty(time(theseEvents))
                   oddFixationTime{itr} = 1e3*(time(trial == itr) - t0);
               else 
                   oddFixationTime{itr} = NaN;
               end
        end
        
        end

        function [reactionTime, responseType] = getReactionTime(d)
         oddFixationTime = d.getOddFixationTime;
            keyPressTime = d.getKeyPressTime;

            oddFixationTime_all = [];
            keyPressTime_all = [];
            for itr = 1:d.numTrials
                t0 =  d.meta.cic.firstFrame('trial',itr);
                if ~isnan(oddFixationTime{itr})
                    oddFixationTime_all = [oddFixationTime_all oddFixationTime{itr}+1e3*t0];
                end
                if ~isnan(keyPressTime{itr})
                    keyPressTime_all = [keyPressTime_all keyPressTime{itr}+1e3*t0];
                end
            end

            reactionTime = zeros(numel(oddFixationTime_all),1);
            for ii = 1:numel(oddFixationTime_all)
              candidateEvents =  find(keyPressTime_all - oddFixationTime_all(ii) >0);
              [reactionTime(ii)] = min(keyPressTime_all(candidateEvents) - oddFixationTime_all(ii));
            end
            miss = find(reactionTime > 2000);
            hit = find(reactionTime < 2000);
            
            responseType = zeros(numel(oddFixationTime_all),1);
            responseType(hit) = 1;
            responseType(miss) = 0;
        end

        function frameRate = getFrameRate(d)
             test = d.meta.cic.screen.data(1);
             frameRate = test{1}.frameRate;
        end

        function onFrames = getOnFrames(d)
            onFrames = d.meta.cic.onFrames.data;
        end

        function offFrames = getOffFrames(d)
            offFrames = d.meta.cic.offFrames.data;
        end

        function patchDirList = getPatchDirList(d)
            patchDirList = d.meta.cic.dirList.data;
        end

        function patchDir = getPatchDir(d)
            %patch direction of every presentations of every trials

            tDur_cycle = (d.onFrames + d.offFrames)*1000/d.frameRate; %[ms]

            patchDir = cell(d.numTrials,1);
            for itr = 1:d.numTrials
                thisCond = d.condIds(itr);%d.meta.cic.condition('trial',itr).data

                %tDur =
                %d.meta.(sprintf('patch%d',thisCond)).tDur('time',inf,'trial',itr).data; %INCORRECT
                nSuccessivePresentations = round(d.tDur(itr) / tDur_cycle);

                if d.meta.cic.ctrl.data == 0
                     patchDir{itr} = d.patchDirList(thisCond) * ones(nSuccessivePresentations, 1);
                elseif d.meta.cic.ctrl.data == 1
                    [time,~,frame,data_tmp]  = d.meta.(sprintf('patch%d',thisCond)).direction('trial',itr);
                    okIdx = find(frame>=-1);

                    time = time(okIdx);
                    data_tmp = cell2mat(data_tmp);
                    data_tmp = data_tmp(okIdx);

                    mipi = median(diff(time));
                    
                    recorded = ones(nSuccessivePresentations,1);
                    for istim = 1:nSuccessivePresentations-1
                        try
                            if time(istim+1) - time(istim) > 1.2*mipi
                                recorded(istim+1) = 0;
                                time = [time(1:istim) time(istim)+mipi time(istim+1:end)];
                            end
                        catch err
                            recorded(istim+1) = 0;
                        end
                    end
                    data = nan(nSuccessivePresentations,1);
                    data(recorded==1) = data_tmp;
                    redundantIdx = find(recorded==0)-1;
                    data(recorded==0) = data(redundantIdx);
                    patchDir{itr} = data; %error when two successive stimuli are the same directions
                    %patchStart{itr} = time;
                end
            end
        end


        function patchStart = getPatchStart(d)
            %all patch start times from the start of each trial

            patchStart = cell(numel(d.numTrials), 1);
            for itr = 1:d.numTrials
                thisCond = d.condIds(itr);%d.meta.cic.condition('trial',itr).data

                t0 = d.meta.cic.firstFrame('time',Inf, 'trial',itr); %= d.meta.(sprintf('patch%d',thisCond)).startTime('trial',itr);

                [time,~,frame,data] = d.meta.(sprintf('patch%d',thisCond)).rsvpIsi('trial',itr);
                data = cell2mat(data);
                okIdx = find(data==0 & frame>=-1);

                patchStart{itr} = time(okIdx) - t0;
            end

        end
    end
end