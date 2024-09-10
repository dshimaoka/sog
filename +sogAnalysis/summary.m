function summary(file)
%daily summary

% saveDir = ;

%% summary eye
figname_eye = [file(1:end-4), 'eye.png'];
d = sogAnalysis.sogRovingByTrial(file,'loadArgs',{'loadEye',true});
fig = showEyePos_cat(d);
screen2png(figname_eye, fig);


%% summary ephys
if ~isempty(d.spikes.spk)
    figname_ephys = [file(1:end-4), 'eye.png'];
end
