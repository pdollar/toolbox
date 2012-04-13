function toolboxUpdateHeader
% Update the headers of all the files.
%
% USAGE
%  toolboxUpdateHeader
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.64
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

header={
  '% Piotr''s Image&Video Toolbox      Version 2.64'; ...
  '% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]'; ...
  '% Please email me if you find bugs, or have suggestions or questions!'; ...
  '% Licensed under the Lesser GPL [see external/lgpl.txt]'};

% must start in /toolbox base directory
cd(fileparts(mfilename('fullpath'))); cd('../');
dirs={ 'classify', 'classify/private', 'filters', 'images', ...
  'images/private', 'matlab', 'external' };

% update the headers
for i=1:length(dirs)
  mFiles = dir([ dirs{i}, '/*.m' ]);
  disp( ['--------------------------------->' dirs{i}] );
  for j=1:length(mFiles);
    fName = [dirs{i} '/' mFiles(j).name]; disp( fName );
    toolboxUpdateHeader1( fName, header );
  end
end

end

function toolboxUpdateHeader1( fName, header )
lines=readFile(fName); n=length(lines);

% find first part of first lines of header in file
loc = strfind(lines,header{1}(1:30));
for i=1:n, if(~isempty(loc{i})), break; end; end; loc=i;

% if not found nothing to do, ow assert nHeader lines exist
nHeader = length(header);
if(loc>n-nHeader+1), warning([fName ' no header']); return; end %#ok<WNTAG>
for i=1:nHeader; assert( strfind(lines{loc+i-1},header{i}(1:10))>0 ); end

% check if first lines changed, if so update; optionally update rest
if(any(strfind(lines{loc},'NEW'))); lines{loc}=header{1}; else return; end
if(1), for i=2:nHeader; lines{loc+i-1}=header{i}; end; end
assert(isempty(lines{loc-1}) || strcmp(lines{loc-1},'%'));
if(1), lines{loc-1} = '%'; end
writeFile( fName, lines );

end

function moveComment( fName ) %#ok<DEFNU>
lines=readFile(fName); n=length(lines);

% check first non-comment lines is "function ..." if not, we're done
for i=1:n; L=lines{i}; if(~isempty(L)&&L(1)~='%'), break; end; end
if(i==n || ~strcmp(lines{i}(1:8),'function')),
  warning([fName ' not a function']); return; %#ok<WNTAG>
end; if(i==1), return; end;

% Move main comment to appear after "function ..."
% This FAILS if func spans multiple lines (use mlint to find failures)!!!
if(~isempty(lines{i+1})), start=i+1; else start=i+2; end;
lines={lines{i} lines{[1:i-1 start:end]}}; lines=lines';
writeFile( fName, lines );

end

function lines = readFile( fName )
fid = fopen( fName, 'rt' ); assert(fid~=-1);
lines=cell(10000,1); n=0;
while( 1 )
  n=n+1; lines{n}=fgetl(fid);
  if( ~ischar(lines{n}) ), break; end
end
fclose(fid); n=n-1; lines=lines(1:n);
end

function writeFile( fName, lines )
fid = fopen( fName, 'wt' );
for i=1:length(lines); fprintf( fid, '%s\n', lines{i} ); end
fclose(fid);
end
