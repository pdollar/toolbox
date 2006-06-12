% n-dimensional Gaussian filter. 
%
% Creates an image of a Gaussian with arbitrary covariance matrix. The point [x,y,z]
% refers to the x-th column and y-th row, at the t-th frame.  So for example mu should
% have the format [col,row,t].
%
% If mu==[], it is calculated to be the center of the image.  C can be a full nxn
% covariance matrix, or an nx1 vector of variance.  In the latter case C is calculated as
% C=diag(C).  If C=[]; then C=(dims/6).^2, ie it is transformed into a vector of variances
% such that along each dimension the variance is equal to (siz/6)^2.  
%
% INPUTS
%   dims    - n element vector of dimensions of final Gaussian
%   mu      - [optional] n element vector specifying the mean or []
%   C       - [optional] nxn covariance matrix, nx1 set of variances, or variance, or []
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   G   - image of the created Gaussian
%
% EXAMPLE
%   % 2D
%   sigma=3; G = filter_gauss_nD( 4*[sigma sigma] + 1, [], [sigma sigma].^2, 1 );
%   % 3D
%   R = rotation_matrix3D( [1,1,0], pi/4 ); 
%   C = R'*[10^2 0 0; 0 5^2 0; 0 0 16^2]*R;
%   G = filter_gauss_nD( [50,50,50], [25,25,25], C, 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_GAUSS_1D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function G = filter_gauss_nD( dims, mu, C, show )
    nd = length( dims );
    if( nargin<2 || isempty(mu)) mu=(dims+1)/2; end;
    if( nargin<3 || isempty(C)) C=(dims/6).^2; end;
    if( nargin<4 || isempty(show) || nd>3 ) show=0; end;
    
    if( size(C,1)==1 || size(C,2)==1 ) C=diag(C); end;
    if( length(mu)~=nd ) error('invalid mu'); end;
    if( any(size(C)~=nd)) error( 'invalid C'); end;
    
    % get vector of grid locations 
    if (nd==1)
        grid_vec = 1:dims(1);
    else
        for d=1:nd temp{d} = 1:dims(d); end;
        [ temp{:}] = ndgrid( temp{:} );
        grid_vec = zeros( nd, prod(dims) );
        for d=1:nd grid_vec( d, : ) = temp{d}(:)'; end
    end
    
    % evaluate the Gaussian at those points
    ps = normpdf2( grid_vec, mu, C );
    if( nd>1) G = reshape( ps, dims ); else G = ps; end;
    
    % optionally show
    if ( show )
        figure(show); clf; 
        if ( nd==1 )
            filter_visualize_1D( G );
        elseif( nd==2 )
            im(G); hold('on'); plot_gaussellipses( mu, C, 2 ); hold('off');
        elseif( nd==3 )
            if 1 montage2( G, 1 ); else filter_visualize_3D( G, .2 ); end
        end
    end
        
