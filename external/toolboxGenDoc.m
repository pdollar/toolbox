% Generate documentation, must run from dir toolbox.
%
% Requires external/m2html to be in path.
%
% Prior to running, update a few things in the overview.html file in:
%   toolbox/external/m2html/templates/frame-piotr/overview.html
%   1) The version / date
%   2) Link to rar/zip file
% 
% USAGE
%  toolboxGenDoc
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
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% run m2html
params = {'mfiles',{'classify','images','filters','matlab'}};
params = {params{:},'htmldir','doc','recursive','on','source','off'};
params = {params{:},'template','frame-piotr','index','menu','global','on'};
m2html(params{:});

% copy custom menu.html
copyfile('external\m2html\templates\menu-for-frame-piotr.html','doc/menu.html')

% copy history file
copyfile('external\history.txt','doc/history.txt')

% remove links to .svn and private in the menu.html files
d = { './doc' };
while ~isempty(d)
  dTmp = dir(d{1});
  for i = 1 : length(dTmp)
    name = dTmp(i).name;
    if strcmp( name,'.') || strcmp( name,'..'); continue; end
    if dTmp(i).isdir; d{end+1} = [ d{1} '/' name ]; continue; end %#ok<AGROW>
    if ~strcmp( name,'menu.html'); continue; end
    fid = fopen( [ d{1} '/' name ], 'r' ); c = fread(fid, '*char')'; fclose( fid );
    c = regexprep( c, '<li>([^<]*[<]?[^<]*)\.svn([^<]*[<]?[^<]*)</li>', '');
    c = regexprep( c, '<li>([^<]*[<]?[^<]*)private([^<]*[<]?[^<]*)</li>', '');
    fid = fopen( [ d{1} '/' name ], 'w' ); fwrite( fid, c ); fclose( fid );
  end
  d(1) = [];
end

% remove /private directories
rmdir('doc/classify/private','s')
rmdir('doc/images/private','s')

