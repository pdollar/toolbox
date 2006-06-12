% Adds an ellipse to the current plot.
%
% INPUTS
%   crow    - the row location of the center of the ellipse
%   ccol    - the column location of the center of the ellipse
%   ra      - semi-major axis radius length (in pixels) of the ellipse
%   rb      - semi-minor axis radius length (in pixels) of the ellipse
%   phi     - rotation angle (in radians) of the semimajor axis from the x-axis
%   color   - [optional] color for ellipse
%   npoints - [optional] number of points used to draw each ellipse
%
% OUTPUT
%   h       - handle to ellipse
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% EXAMPLE
%   plot_ellipse( 3, 2, 1, 5, pi/6, 'g')

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function varargout = plot_ellipse( crow, ccol, ra, rb, phi, color, npoints )
    error(nargchk( 5, 7, nargin ));
    if( nargin<6 || isempty(color) ) color = 'b'; end;
    if( nargin<7 || isempty(npoints) ) npoints = 100; end;
    if( length(ra)~=length(rb)) error('length(ra)~=length(rb)'); end;
    if( length(ccol)~=length(crow)) error('length(ccol)~=length(crow)'); end;

    % plot ellipse (rotate a scaled circle):
    ts = linspace(-pi,pi,npoints+1);  cts = cos(ts); sts = sin(ts); 
    h = plot( ra*cts*cos(-phi) + rb*sts*sin(-phi) + ccol, ...
                rb*sts*cos(-phi) - ra*cts*sin(-phi) + crow, color );
     
    % plot center point
    washeld = ishold; if (~washeld) hold('on'); end;
    hc = plot( ccol, crow, 'k+' ); set( hc, 'Color', color );
    if (~washeld) hold('off'); end;
    
    if( nargout>0 ) varargout={h}; end
