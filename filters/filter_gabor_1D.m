% 1D Gabor Filters.
%
% Creates a pair of 1D Gabor filters (even/odd).
%
% INPUTS
%   r       - final mask will be 2r+1 (good choice for r is r=2*sig)
%   sig     - standard deviation of Gaussian mask
%   omega   - frequency of underlying sine/cosine 
%             should range between 1/(2r+1) and r/(2r+1)~.5 
%             otherwise false frequencies form
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   feven   - even symmetric filter (-cosine masked with Gaussian)
%   fodd    - odd symmetric filter (-sine masked with Gaussian)
%
% EXAMPLE
%   tau = 5; filter_gabor_1D(2*tau,tau,1/tau,1);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_GABOR_2D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [feven,fodd] = filter_gabor_1D( r, sig, omega, show );
    r = ceil(r);
    if (omega<1/(2*r+1) || omega>r/(2*r+1)) 
        msg = ['omega =' num2str(omega) ' out of range; range = ['];
        msg = [msg num2str(1/(2*r+1)) ',' num2str(r/(2*r+1)) ']'];
        error(msg); 
    end;
    if( nargin<4 || isempty(show) ) show=0; end;
    
    % create even and odd pair (ppd version of F1 is the actual Gabor filter)
    x = -r:r;
    feven = -cos(2*pi*x*omega) .* exp( -(x.^2)/sig^2 );
    fodd = -sin(2*pi*x*omega) .* exp( -(x.^2)/sig^2 ); %imag(hilbert(feven));
 
    % normalize to mean==0, but only in locs that are nonzero
    inds = abs(feven)>.00001;  feven(inds) = feven(inds) - mean( feven(inds ) );
    inds = abs(fodd)>.00001;  fodd(inds) = fodd(inds) - mean( fodd(inds ) );
   
    % set L1norm to 0
    feven=feven/norm(feven(:),1);
    fodd=fodd/norm(fodd(:),1);

    % visualization
    if (show)
        figure(show); filter_visualize_1D( feven );
        title( ['even filter: sig = ' num2str(sig) ', omega = ' num2str(omega) ] );
        figure(show+1); filter_visualize_1D( fodd );
        title( ['odd filter: sig = ' num2str(sig) ', omega = ' num2str(omega) ] );
    end
