file = 'Z:/Shared/MarmosetData/2024/08/30/test.sogRoving.183738.mat';
load(file,'c');

%below from nsLoad.m
  plg = 'patch1';%plgNames{ii};
  % prms = c.(plg).prms;
  % prmNames = fieldnames(prms); 
  prm = 'rsvpIsi';%prmNames{jj};
  
 [data,trial,trialTime,time,block,frame] = get(c.patch1.prms.rsvpIsi,'trial',1, 'matrixIfPossible',false);
 plot(trialTime, cell2mat(data));  xlabel('trialTime');ylabel('data');
  axis padded;
