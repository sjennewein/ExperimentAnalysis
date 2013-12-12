function display(speobj)
%DISPLAY Displays the SPEFILE object
%   Package name:     SPEFILE
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   See also SPEFILE, SPEFILE/CLOSE.

%% LICENSE
% Copyright (c) 2008-2013 Alexander Nikitin
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
% 3. The name of the author may not be used to endorse or promote products
%    derived from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
% IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
% NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
% THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
% THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%% Version history
%   2013-08-01 - release version
%   2012-08-02 - alpha version

%% CODE
disp('')
disp('Automatically updated parameters:');
auto.xdim = speobj.xdim;
auto.ydim = speobj.ydim;
auto.NumFrames = speobj.NumFrames;
auto.CurrentState = speobj.CurrentState;
disp(auto)
disp('Fixed parameters:');
fixed.header = speobj.header;
fixed.vardata = speobj.vardata;
if isfield(speobj,'structdecl')
    fixed.structdecl = speobj.structdecl;
end;
fixed.filepath = speobj.filepath;
fixed.DATA_OFFSET = speobj.DATA_OFFSET;
fixed.DATATYPE_SIZE = speobj.DATATYPE_SIZE;
fixed.DATATYPE_STR = speobj.DATATYPE_STR;
fixed.DATAORDER = speobj.DATAORDER;
disp(fixed)
