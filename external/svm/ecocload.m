function net = ecocload(net, fname)
% ECOCLOAD - Load ECOC code matrix from collection
% 
%   NET = ECOCLOAD(NET)
%   A collection of ECOC codes can be downloaded from Thomas
%   G. Dietterich's homepage. This file, named 'ecoc-codes.tar.gz', is
%   assumed to reside in directory NET.CODEPATH. ECOCLOAD tries to
%   extract the code for the chosen number of bits and number of classes
%   from 'ecoc-codes.tar.gz'
%   NET = ECOCLOAD(NET, FNAME) tries loading the code from file
%   FNAME. The file must be plain ASCII, each line of the file contains
%   one row of the code matrix.
%
%   See also ECOC, ECOCTRAIN, ECOCFWD
%

% 
% Copyright (c) by Anton Schwaighofer (2001)
% $Revision: 1.2 $ $Date: 2002/01/07 17:59:45 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

error(nargchk(1, 2, nargin));
error(consist(net, 'ecoc'));

deletecode = 0;
if nargin<2,
  if isempty(findstr('~/', net.codepath)),
    archpath = net.codepath;
  else
    archpath = fullfile(getenv('HOME'), strrep(net.codepath, '~/', ''));
  end
  archname = fullfile(archpath, 'ecoc-codes.tar.gz');
  % Name of code file
  shortfname = sprintf('code%i-%i', net.nbits, net.nclasses);
  fullfname = fullfile(archpath, shortfname);
  if exist(shortfname)==2,
    % File exists in current directory: load it
    fname = shortfname;
  elseif exist(fullfname)==2,
    % Code file exists in archive directory
    fname = fullfname;
  else
    % Code file does not exist: extract from archive, load, delete file
    deletecode = 1;
    callstr = ['tar zxf ' archname ' ' shortfname];
    if net.verbosity>0, 
      fprintf('Extracting %s from archive %s\n', shortfname, archname);
    end
    status = unix(callstr);
    if (status~=0),
      error(sprintf('Unable to extract code file (calling %s)', ...
                    callstr));
    end
    % tar will extract into current directory
    fname = shortfname;
  end
end

% Open code file in text mode
if net.verbosity>0, 
  fprintf('Loading code from file %s\n', fname);
end
f = fopen(fname, 'rt');
if (f<0),
  error(sprintf('Unable to open file %s', fname));
end

i = 0;
while ~feof(f),
  s = fgetl(f);
  % try to read one row of the code matrix
  [data, count] = sscanf(s, '%f');
  if count==net.nbits,
    % read a full row: store in code matrix
    i = i+1;
    if i<=net.nclasses,
      net.code(i,:) = data;
    else
      error('Code file must not contain more than NET.NCLASSES lines of code');
    end
  elseif count==0,
    % no numbers read: try whether these are the lines with the Hamming
    % distance info
    [data, count] = sscanf(s, '; Maximum HD = %i, Minimum HD = %i');
    if count==2,
      net.HDmax = data(1);
      net.HDmin = data(2);
    end
    [data, count] = sscanf(s, '; Maximum row HD = %i, Minimum row HD = %i');
    if count==2,
      net.rowHDmax = data(1);
      net.rowHDmin = data(2);
    end
  else
    % Read some unpleasant number of data
    error('Invalid number of columns in the code file');
  end
end
if deletecode,
  delete(shortfname);
end
% Dietterichs codes are given as 0/1, we use -1/+1
if isempty(setdiff(unique(net.code(:)), [0 1])),
  net.code(net.code==0)=-1;
end
