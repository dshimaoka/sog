classdef sog < marmodata.mdbase

    properties
        % stimulus
        patchDir; %direction of patch [deg]
        radius; %radius of patches in [deg]
        patchDirList; %list of stimulus directions
        patchSpeed; %stimulus speed [deg/s]
        tDur; %duration of a sequence of every trials [ms]
        patchStart; %onset times of patch in each trial [ms]
        patchStop; %offset times of patch in each trial [ms]

        
        % reward
        rewardVol;
        rewardRate;
        pReward;
        rewardTimes; %time of reward in each trial

        % behavioural response
        %oddFixationTime;
        %keyPressTime; %time when a key is perssed first time in a trial [ms]
        %reactionTime;
    end

    methods (Access = public)
        function d = sog(varargin)
            d@marmodata.mdbase(varargin{:}); % base class constructor

            %d.patchDir = getPatchDir(d); %direction of patch [deg]
            % d.radius = getRadius(d); %radius of patches in [deg]
            % d.patchDirList = getPatchDirList(d); %list of stimulus directions
            % d.patchSpeed = getPatchSpeed(d); %stimulus speed [deg/s]
            d.tDur = getTDur(d); %duration of a sequence [ms]
            % d.patchStart = getPatchStart(d); %onset times of patch
            % d.patchStop = getPatchStop(d); %offset times of patch
            %
            % % reward
            % d.rewardVol = getRewardVol(d);
            % d.rewardRate = getRewardRate(d);
            % d.pReward = getPReward(d);
            % d.rewardTimes = getRewardTimes(d);

            %d.keyPressTime = getKeyPressTime(d);
            %d.oddFixationTime = getOddFixationTime(d);
            %d.reactionTime = getReactionTime(d);

        end

        function tDur = getTDur(d)
            tDur = d.meta.cic.trialDuration('time',Inf).data;
        end

        function patchDir = getPatchDir(d) %FIXME
            patchDir = d.meta.patch.direction('time',Inf).data;
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

    end
end