clear all;

addpath('..\functions\WinSpec\');
addpath('..\functions\fitting\');
addpath('..\functions\Visualize\');
addpath('..\functions\Igor\');

header = speread_header('C:\Users\stephan\Documents\data\Atoms_Macro_tof_40µs_651µW_90seq.SPE');
frame = speread_frame(header,1);
backgroundROI = ones(400,400);
backgroundROI(126:299,126:299) = NaN(174,174);

