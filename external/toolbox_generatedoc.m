% toolbox_generatedoc - Generate documentation.  Must run from directory toolbox. 

% Piotr's Image&Video Toolbox      Version 1.03
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

% The template frame-piotr is frame copied over, with a special start page
% (overview.html), and Contents.html given a link from every menu.  Also, after generating
% the documentation, removed links to */private from main doc/menu.html.
% (Currently script simply copies over menu.html that is fixed).

% After, make sure to update 1) date and 2) link to zip file in doc/Overview.html.
% Also history.txt get copied over


params = {'mfiles',{'classify','images','filters','matlab'}};
params = {params{:},'htmldir','doc','recursive','on','source','off'};
params = {params{:},'template','frame-piotr','index','menu','global','on'};
m2html(params{:});
copyfile('external\m2html\templates\menu-for-frame-piotr.html','doc/menu.html')
copyfile('external\history.txt','doc/history.txt')
