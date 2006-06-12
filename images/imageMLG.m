% Calculates maximum likelihood parameters of gaussian that gave rise to image G.
%
% Suppose G contains an image of a gaussian distribution.  One way to recover the
% parameters of the gaussian is to threshold the image, and then estimate the
% mean/covariance based on the coordinates of the thresholded points.  A better method is
% to do no thresholding and instead use all the coordinates, weighted by their value.
% This function does the latter, except in a very efficient manner since all computations
% are done in parallel over the entire image. 
%
% This function works over 2D or 3D images.  It makes most sense when G in fact contains
% an image of a single gaussian, but a result will be returned regardless.  All operations
% are performed on abs(G) in case it contains negative or complex values.
%
% symmFlag is an optional flag that if set to 1 then imageMLG recovers the maximum
% likelihood symmetric gaussian.  That is the variance in each direction is equal, and all
% covariance terms are 0.  If symmFlag is set to 2 and G is 3D, imageMLG recovers the ML
% guassian with equal variance in the 1st 2 dimensions (row and col) and all covariance
% terms equal to 0, but a possibly different variance in the 3rd (z or t) dimension.
%
% INPUTS
%   G           - image of a gaussian (weighted pixels)
%   symmFlag    - [optional] see above
%   show        - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   mu      - 2 or 3 element vector specifying the mean [row,col,z]
%   C       - 2x2 or 3x3 covariance matrix [row,col,z]
%   GR      - image of the recovered gaussian (faster if omitted)
%   logl    - log likelihood of G given the recovered gaussian (faster if omitted)
%
% EXAMPLE
%   % example 1 [2D]
%   R = rotation_matrix2D( pi/6 );  C=R'*[10^2 0; 0 20^2]*R;
%   G = filter_gauss_nD( [200, 300], [150,100], C, 0 );
%   [mu,C,GR,logl] = imageMLG( G, 0, 1 );
%   mask = mask_ellipse( size(G,1), size(G,2), mu, C ); 
%   figure(3); im(mask)
%   % example 2 [3D]
%   R = rotation_matrix3D( [1,1,0], pi/4 ); 
%   C = R'*[5^2 0 0; 0 2^2 0; 0 0 4^2]*R;
%   G = filter_gauss_nD( [50,50,50], [25,25,25], C, 0 );
%   [mu,C,GR,logl] = imageMLG( G, 0, 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also GAUSS2ELLIPSE, PLOT_GAUSSELLIPSES, MASK_ELLIPSE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function varargout = imageMLG( G, symmFlag, show )
    if( nargin<2 || isempty(symmFlag) ) symmFlag=0; end;
    if( nargin<3 || isempty(show) ) show=0; end;
    
    varargout = cell(1,max(nargout,2));
    nd = ndims(G);  G = abs(G);
    if( nd==2 )
        [varargout{:}] = imageMLG_2D( G, symmFlag, show );
    elseif( nd==3 )
        [varargout{:}] = imageMLG_3D( G, symmFlag, show );
    else
        error( 'Unsupported dimension for G.  G must be 2D or 3D.' );
    end

    
function [mu,C,GR,logl] = imageMLG_2D( G, symmFlag, show )

    % to be used throughout calculations
    [ grid_cols, grid_rows ] = meshgrid( 1:size(G,2), 1:size(G,1)  );
    sumG = sum(G(:)); if(sumG==0) sumG=1; end;
    
    % recover mean
    mu_col = (grid_cols .* G); mu_col = sum( mu_col(:) ) / sumG;
    mu_row = (grid_rows .* G); mu_row = sum( mu_row(:) ) / sumG;
    mu = [mu_row, mu_col];
    
    % recover sigma
    dist_cols = (grid_cols - mu_col); 
    dist_rows = (grid_rows - mu_row);
    if( symmFlag==0 )
        Ccc = (dist_cols .^ 2) .* G;   Ccc = sum(Ccc(:)) / sumG;
        Crr = (dist_rows .^ 2) .* G;   Crr = sum(Crr(:)) / sumG;
        Crc = (dist_cols .* dist_rows) .* G;   Crc = sum(Crc(:)) / sumG;
        C = [Crr Crc; Crc Ccc];
    elseif( symmFlag==1 )
        sigma_sq = (dist_cols.^2 + dist_rows.^2) .* G; 
        sigma_sq = 1/2 * sum(sigma_sq(:)) / sumG;
        C = sigma_sq*eye(2);
    else
        error(['Illegal value for symmFlag: ' num2str(symmFlag)])
    end

    % get the log likelihood of the data
    if (nargout>2)
        GR = filter_gauss_nD( size(G), mu, C );
        probs = GR; probs( probs<realmin ) = realmin;
        logl = G .* log( probs ); 
        logl = sum( logl(:) );
    end
        
    
    % plot ellipses
    if (show)
        figure(show); im(G);  
        hold('on'); plot_gaussellipses( mu, C, 2 ); hold('off');
        %[ crow, ccol, ra, rb, phi ] = gauss2ellipse( mu, C, 2 );
        %hold('on'); plot_ellipses(crow, ccol, ra, rb, phi, 'r' ); hold('off');
    end
    

function [mu,C,GR,logl] = imageMLG_3D( G, symmFlag, show )
    % to be used throughout calculations
    [ grid_cols, grid_rows, grid_zs ] = meshgrid( 1:size(G,2), 1:size(G,1), 1:size(G,3) );
    sumG = sum(G(:));
    
    % recover mean
    mu_col = (grid_cols .* G); mu_col = sum( mu_col(:) ) / sumG;
    mu_row = (grid_rows .* G); mu_row = sum( mu_row(:) ) / sumG;
    mu_z   = (grid_zs .* G);   mu_z = sum( mu_z(:) ) / sumG;    
    mu = [mu_row, mu_col, mu_z];
    
    % recover C
    dist_cols = (grid_cols - mu_col); 
    dist_rows = (grid_rows - mu_row);
    dist_zs = (grid_zs - mu_z);
    if( symmFlag==0 )
        dist_cols_G = dist_cols .* G; dist_rows_G = dist_rows .* G; 
        Ccc = dist_cols .* dist_cols_G;   Ccc = sum(Ccc(:));
        Crc = dist_rows .* dist_cols_G;   Crc = sum(Crc(:));
        Czc = dist_zs   .* dist_cols_G;   Czc = sum(Czc(:));
        Crr = dist_rows .* dist_rows_G;   Crr = sum(Crr(:));
        Czr = dist_zs   .* dist_rows_G;   Czr = sum(Czr(:));
        Czz = dist_zs   .* dist_zs .* G;  Czz = sum(Czz(:));
        C = [Crr Crc Czr; Crc Ccc Czc; Czr Czc Czz] / sumG;
    elseif( symmFlag==1 )
        sigma_sq = (dist_cols.^2 + dist_rows.^2 + dist_zs .^ 2) .* G;  
        sigma_sq = 1/3 * sum(sigma_sq(:));
        C = [sigma_sq 0 0; 0 sigma_sq 0; 0 0 sigma_sq] / sumG;
    elseif( symmFlag==2 )
        sigma_sq = (dist_cols.^2 + dist_rows.^2) .* G;  sigma_sq = 1/2 * sum(sigma_sq(:));
        tau_sq = (dist_zs .^ 2) .* G;  tau_sq = sum(tau_sq(:));
        C = [sigma_sq 0 0; 0 sigma_sq 0; 0 0 tau_sq] / sumG;
    else
        error(['Illegal value for symmFlag: ' num2str(symmFlag)])
    end
    
    % get the log likelihood of the data
    if (nargout>2 || (show))
        GR = filter_gauss_nD( size(G), mu, C );
        probs = GR; probs( probs<realmin ) = realmin;
        logl = G .* log( probs ); 
        logl = sum( logl(:) )
    end
    
    % plot G and GR
    if (show)
        figure(show); montage2(G,1);  
        figure(show+1); montage2(GR,1);  
    end
