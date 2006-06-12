% Difference of Gaussian (Dog) Filter.
%
% Adapted from code by Serge Belongie.  Takes a "difference of Gaussian" - all centered
% on the same point but with different values for sigma.  
%
% INPUTS
%   r       - Final filter will be 2*r+1 on each side
%   sig     - standard deviation of central Gaussian
%   order   - should be either 1 or 2
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   G       - final filter
%
% EXAMPLE
%   G = filter_DOG_2D( 6, 3, 1, 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_DOOG_2D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function G = filter_DOG_2D( r, sig, order, show )
    if( nargin<4 || isempty(show) ) show=0; end;

    N = 2*r+1;
    [x,y]=meshgrid(-r:r,-r:r);
    X=[x(:) y(:)];

    if (order==1)
        sigi=0.71*sig;  % these should have all been square-rooted
        sigo=1.14*sig;
        Ci=diag([sigi,sigi]);
        Co=diag([sigo,sigo]);

        Ga=normpdf2(X,[0 0]',Ci); Ga=reshape(Ga,N,N);
        Gb=normpdf2(X,[0 0]',Co); Gb=reshape(Gb,N,N);

        a=1; b=-1;
        G = a*Ga + b*Gb;
        
    elseif (order==2)
        sigi=0.62*sig;
        sigo=1.6*sig;
        C=diag([sig,sig]);
        Ci=diag([sigi,sigi]);
        Co=diag([sigo,sigo]);

        Ga=normpdf2(X,[0 0]',Ci); Ga=reshape(Ga,N,N);
        Gb=normpdf2(X,[0 0]',C);  Gb=reshape(Gb,N,N);
        Gc=normpdf2(X,[0 0]',Co); Gc=reshape(Gc,N,N);

        a=-1; b=2; c=-1;
        G = a*Ga + b*Gb + c*Gc;
        
    else
        error('order not supported');
    end

    % normalize
    G=G-mean(G(:));
    G=G/norm(G(:),1);

    % display
    if (show)
        figure(show); filter_visualize_2D( G, 0 );
    end
    


