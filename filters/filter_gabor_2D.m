% 2D Gabor filters.
%
% Creates a pair of Gabor filters (one odd one even) at the specified orientation.  
% For Thomas' ECCV98 filters, use sig=sqrt(2), lam=4.
%
% INPUTS
%   r       - final mask will be 2r+1 x 2r+1
%   sig     - standard deviation
%   lam     - elongation 
%   theta   - orientation
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   Feven   - even symmetric filter (-cosine masked with Gaussian)
%   Fodd    - even symmetric filter (-sine masked with Gaussian)
%
% EXAMPLE
%   [Feven,Fodd]=filter_gabor_2D(15,sqrt(2),4,45,1);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_GABOR_1D, FILTER_GAUSS_ND

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [Feven,Fodd]=filter_gabor_2D(r,sig,lam,theta,show)
    if( nargin<5 || isempty(show) ) show=0; end;
    
    % create even and odd pair (ppd version of Feven is the actual Gabor filter)
    % instead of using cos and sin, masks y.^2.
    [x,y]=meshgrid(-r:r,-r:r);
    %Feven = -cos(2*pi*y/4 ) .* exp(-(y.^2)/(sig^2)-(x.^2)/(lam^2*sig^2));
    Feven = (4*(y.^2)/(sig^4)-2/(sig^2)).*exp(-(y.^2)/(sig^2)-(x.^2)/(lam^2*sig^2));
    Fodd = imag(hilbert(Feven));
    
    % orient appropriately
    Feven=imrotate(Feven,theta,'bil','crop');
    Fodd=imrotate(Fodd,theta,'bil','crop');

    % Set mean to 0 (should already be 0)
    Feven=Feven-mean(Feven(:));
    Fodd=Fodd-mean(Fodd(:));

    % set L1norm to 0
    Feven=Feven/norm(Feven(:),1);
    Fodd=Fodd/norm(Fodd(:),1);
    
    
    % showlay
    if (show)
        figure(show);   filter_visualize_2D( Feven, 0 ); 
        figure(show+1); filter_visualize_2D( Fodd, 0 ); 
    end;
