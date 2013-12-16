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
% Piotr's Image&Video Toolbox      Version 3.25
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

header={
  '% Piotr''s Image&Video Toolbox      Version 3.25'; ...
  '% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]'; ...
  '% Please email me if you find bugs, or have suggestions or questions!'; ...
  '% Licensed under the Simplified BSD License [see external/bsd.txt]'};

% must start in /toolbox base directory
cd(fileparts(mfilename('fullpath'))); cd('../');
dirs={ 'channels', 'classify', 'classify/private', 'detector', ...
  'filters', 'images', 'images/private', 'matlab', 'external', 'videos' };

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
if(~any(strfind(lines{loc},'NEW'))); return; end
lines{loc+1}(13:16)=header{2}(13:16);
for i=[1 3:nHeader]; lines{loc+i-1}=header{i}; end
assert(isempty(lines{loc-1}) || strcmp(lines{loc-1},'%'));
lines{loc-1} = '%'; writeFile( fName, lines );

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
