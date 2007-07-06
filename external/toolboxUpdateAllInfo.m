% Update the headers of all the files.
%
% Must start in /toolbox base directory
%
% USAGE
%  toolboxUpdateAllInfo
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function toolboxUpdateAllInfo

insertInfo('Contents.m');

% must start in /toolbox base directory
dirTot={ 'classify/', 'classify/private', 'filters', 'images', ...
  'images/private', 'matlab' };

for i=1:length(dirTot)
  mfiles = dir([ dirTot{i}, '/*.m' ]);
  for j=1:length(mfiles);
    removeInfo(mfiles(j).name);
    insertInfo(mfiles(j).name);
  end
end

% Inserts toolbox data after main comment in an .m file.
% Does not affect files with no body (such as Contents.m)
function insertInfo( fname )

fid_in = fopen( fname, 'rt' ); fid_out = fopen( [fname '2'] , 'wt' );

first_comment = true;
while 1
  tline = fgetl(fid_in);
  if ~ischar(tline); break; end;
  fprintf( fid_out, '%s\n', tline );
  if( isempty(strtrim(tline)) && first_comment )
    first_comment = false;
    fprintf( fid_out, [...
      '%% Piotr''s Image&Video Toolbox      Version 1.03   \n' ...
      '%% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu \n' ...
      '%% Please email me if you find bugs, or have suggestions or questions! \n \n'] );
  end
end

fclose(fid_in); fclose(fid_out);
movefile( [fname '2'], fname );

% Removes toolbox data after main comment in an .m file.
function removeInfo( fname )

% Read the first part of the comments
fid = fopen( fname, 'rt' ); ind=0;
while 1
  ind = ind + 1;
  fileLine{ind} = fgetl(fid);
  if ~ischar(fileLine{ind}) || isempty(strtrim(fileLine{ind})); break; end
end

if ind>1; if strfind(fileLine{ind-1},'Piotr'); ind=ind-1; end; end

% Skip the second part of the comments
while 1
  fileLineTemp = fgetl(fid);
  if ~ischar(fileLineTemp) || isempty(strtrim(fileLineTemp)); break; end
end

% Read the rest
while 1
  ind = ind + 1;
  fileLine{ind} = fgetl(fid);
  if ~ischar(fileLine{ind}); break; end
end

% Write the file
fclose(fid); fid = fopen( fname, 'wt' );
for i=1:ind; fprintf( fid, '%s\n', fileLine{i} ); end
fclose(fid);
