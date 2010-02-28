% Compiles all the private routines
%
% USAGE
%  toolboxCompile
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

disp('Compiling.......................................');
savepwd=pwd; cd(fileparts(mfilename('fullpath'))); cd('../');

% compile each file
for filePath={'classify/private/meanShift1.c', ...
  'images/private/assignToBins1.c', 'images/private/histc2c.c', ...
  'images/private/ktHistcRgb_c.c', 'images/private/ktComputeW_c.c', ...
  'images/private/nlfiltersep_max.c', ...
  'images/private/nlfiltersep_sum.c', 'images/private/imResample1.c', ...
  'images/private/hog1.cpp', { 'matlab/private/fibheap.cpp', ...
  'matlab/private/dijkstra1.cpp'} }
  if iscell(filePath{1}) filePath = filePath{1}; end
  [fileDir, fileName]=fileparts(filePath{1});
  switch computer
    case 'PCWIN',
      %windows
      opts = {'-outdir' fileDir};
    case {'GLNX86', 'GLNXA64'},
      % matlab linux
      opts = {'CXX=g++-4.1' 'CC=g++-4.1' 'LD=g++-4.1' '-l' ...
        'mwlapack' '-l' 'mwblas' '-outdir' fileDir};
    case {'i686-pc-linux-gnu', 'x86_64-pc-linux-gnu'},
      % octave linux
      opts = {'-o' [ fileDir '/' fileName '.mex' ]};
    end
  try
    mex( filePath{:}, opts{:} );
  catch
    fprintf(['C++ mex failed, likely due to lack of a C++ compiler.\n' ...
      'Run ''mex -setup'' to specify a C++ compiler if available.\n'...
      'Or, on LINUX specify a specific C++ explicitly (see opts above).\n']);
  end
end

cd(savepwd); disp('..................................Done Compiling');
