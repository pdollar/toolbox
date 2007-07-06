% Generate documentation, must run from dir toolbox.
%
% Prior to running, update a few things in the overview.html file in:
%   toolbox/external/m2html/templates/frame-piotr/overview.html
%   1) The version / date
%   2) Link to rar/zip file
%
% After running, remove links to Subsequent directories (*/private and
% */.svn from):
%  doc/classify/menu.html
%  doc/iamges/menu.html
%  doc/filters/menu.html
%  doc/matlab/menu.html
% 
% USAGE
%  toolbox_generatedoc
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

% run m2html
params = {'mfiles',{'classify','images','filters','matlab'}};
params = {params{:},'htmldir','doc','recursive','on','source','off'};
params = {params{:},'template','frame-piotr','index','menu','global','on'};
m2html(params{:});

% copy custom menu.html
copyfile('external\m2html\templates\menu-for-frame-piotr.html','doc/menu.html')

% copy history file
copyfile('external\history.txt','doc/history.txt')
