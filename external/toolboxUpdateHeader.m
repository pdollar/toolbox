% Update the headers of all the files.
%
% Must start in /toolbox base directory
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

% Piotr's Image&Video Toolbox      Version 2.02
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Liscensed under the Lesser GPL [see external/lgpl.txt]

function toolboxUpdateHeader

headerL1def = '%% Piotr''s Image&Video Toolbox      Version 2.02\n';
header=[...
  '%% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]\n' ...
  '%% Please email me if you find bugs, or have suggestions or questions!\n' ...
  '%% Licensed under the Lesser GPL [see external/lgpl.txt]\n\n'];

% must start in /toolbox base directory  - cd( 'c:/code/toolbox' );
dirs={ 'classify', 'classify/private', 'filters', 'images', ...
     'images/private', 'matlab', 'external' };

% update the headers
for i=1:length(dirs)
  mfiles = dir([ dirs{i}, '/*.m' ]);
  disp( ['--------------------------------->' dirs{i}] );
  for j=1:length(mfiles);
    fname = [dirs{i} '/' mfiles(j).name];
    disp( fname );
    [success,headerL1] = removeHeader(fname);
    if(success); 
      if(any(strfind(headerL1,'NEW'))); headerL1=headerL1def; end;
      insertHeader( fname, headerL1, header );
    else
      warning( ['skipping ' fname] ); %#ok<WNTAG>
    end;
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Removes toolbox data after main comment in an .m file.
%  ~ischar(fileLn{ind})          % true if fgetl returns eof (-1)
%  isempty(strtrim(fileLn{ind})) % true if line is all whitespace
function [success, headerL1] = removeHeader( fname )

fid = fopen( fname, 'rt' );
fileLn = cell(10000,1);  ind=0;
success=1;  headerL1=[];

% Read first part of the comments - up to and including first empty line
while( 1 )
  ind=ind+1;  fileLn{ind} = fgetl(fid);
  if( ~ischar(fileLn{ind}) || isempty(strtrim(fileLn{ind}))); break; end
end
if( fileLn{ind}==-1 ); ind=ind-1; end;

% Skip the second part of the comments
frst = true;
while( 1 )
  fileLnTmp = fgetl(fid);
  if( ~ischar(fileLnTmp) || isempty(strtrim(fileLnTmp))); break; end
  if( frst && ~any(strfind(fileLnTmp,'Piotr')) ); success=0; return; end;
  if( frst ); headerL1=['%' fileLnTmp '\n']; frst=0; end;
end

% Read the rest
while( 1 )
  ind=ind+1;  fileLn{ind} = fgetl(fid);
  if( ~ischar(fileLn{ind})); ind=ind-1; break; end
end

% Write the file
fclose(fid); fid = fopen( fname, 'wt' );
for i=1:ind; fprintf( fid, '%s\n', fileLn{i} ); end
fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inserts toolbox data after main comment in an .m file.
% Does not affect files with no body (such as Contents.m)
function insertHeader( fname, headerL1, header )

fidIn = fopen( fname, 'rt' );
fidOut = fopen( [fname '2'] , 'wt' );

firstComment = true;
while( 1 )
  tline = fgetl(fidIn);
  if( ~ischar(tline) ); break; end;
  fprintf( fidOut, '%s\n', tline );
  if( isempty(strtrim(tline)) && firstComment )
    firstComment = false;    
    fprintf( fidOut, headerL1 );
    fprintf( fidOut, header );
  end
end

fclose(fidIn); fclose(fidOut);
movefile( [fname '2'], fname, 'f' );


