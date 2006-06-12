% Used to help visualize a 3D filter. 
%
% Dark lobes correspond to negative areas.  Surfaces shown are drawn at a percentage of
% the peak filter response detemined by frac.  
%
% INPUTS
%   F       - 3D filter to visualize
%   frac    - frac of max value of F at which to draw surfaces.
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_VISUALIZE_2D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function filter_visualize_3D( F, frac )
    if( nargin<2 || isempty(frac)) frac = .1; end; % 10% of peak

    %%% better visualization this way, t negative at left to positive at right
    F = flipdim( permute( F, [3, 1, 2] ), 1 ); 
    
    %%% approximate display as surface (may miss lots of lobes!!!)
    maxval = max(abs(F(:)));
    washeld = ishold; if (~washeld) hold('on'); end;
    p = patch(isosurface( F>frac*maxval, 0 ));
    set(p,'FaceColor',[.9 .9 .9],'EdgeColor','none'); % light gray lobes 
    p2 = patch(isosurface( F<-frac*maxval, 0 ));
    set(p2,'FaceColor',[.4 .4 .4],'EdgeColor','none'); % dark gray lobes

    %%% set view
    daspect([1 1 1]); view(3); axis tight; 
    camlight; lighting gouraud; set(gca,'Box','on');
    set(gca,'YTick',[]); set(gca,'XTick',[]); set(gca,'ZTick',[]);
    xlabel('y'); ylabel('t'); zlabel('x'); 
    if (~washeld) hold('off'); end;
    
    
