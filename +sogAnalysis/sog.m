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
    end

    methods (Access = public)
        function d = sog(varargin)
            d@marmodata.mdbase(varargin{:}); % base class constructor

            d.patchDir = getPatchDir(d); %direction of patch [deg]
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
        end

        function tDur = getTDur(d)
            tDur = d.meta.cic.trialDuration('time',Inf).data;
        end

        function patchDir = getPatchDir(d) %FIXME
            patchDir = d.meta.patch.direction('time',Inf).data;
        end

    end
end