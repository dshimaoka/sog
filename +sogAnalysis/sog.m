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
        keyPressTime; %time when a key is perssed first time in a trial [ms]
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
                [time,trial,frame,keyTmp] = d.meta.keypress.keyIx('trial',itr);

                key = cell2mat(keyTmp);
                ignoreTrial = isnan(key);
                keepInd = find(~ignoreTrial);
                time = time(~ignoreTrial);
                trial = trial(~ignoreTrial);
                frame = frame(~ignoreTrial);
                key = key(~ignoreTrial);

                keyPressTime{itr} = 1e3*(time - t0(itr));
                if isempty( keyPressTime{itr})
                    keyPressTime{itr} = NaN;
                end
            end

        end
    end
end