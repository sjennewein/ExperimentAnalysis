clear all;

addpath('C:\Users\stephan\Documents\FrenchyMatlab\functions\WinSpec\');
addpath('C:\Users\stephan\Documents\FrenchyMatlab\functions\Visualize\');

header = speread_header('C:\Users\stephan\Documents\data\Atoms_Macro_tof_40�s_651�W_90seq.SPE');
frame = speread_frame(header,1);
roiX = [125 300];
roiY = [125 300];
ShowROI(frame, roiX, roiY);