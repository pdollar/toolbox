% Use to see how much image information is preserved in filter outputs.
%
% Reconstructs the orginal image from filter outputs. Does this independenly for each
% pixel, and then just combines the pixel info.  Note that each patch is 0 mean, since no
% mean information is captured by the filter outputs.  Alter flag below to either attempt
% to reconstruct the entire image of just a patch (interactively specified).  Other flags
% can also be changed, see file.
%
% INPUTS
%   I       - original image
%   FB      - FB to apply and do reconstruction with
%
% OUTPUTS
%   I2  - recovered image
%
% EXAMPLE
%   load trees; X=imresize(X,.5);
%   load FB_DoG.mat;
%   I2 = FB_reconstruct_2D( X, FB );
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I2 = FB_reconstruct_2D( I, FB )
    FB_mrows = size(FB,1); FB_ncols = size(FB,2);
    FB_mradius = (FB_mrows-1)/2;  FB_nradius = (FB_ncols-1)/2;
    [mrows,ncols] = size(I);
    
    % add mean vector to filterbank (helps for visualization to have mean)
    if( 0 ) FB = cat(3, FB, ones([FB_mrows FB_ncols])/FB_mrows/FB_ncols ); end
    
    % get FB responses
    IFR = FB_apply_2D( I, FB, 'same' );  
    IFR_str = squeeze( sum( sum( abs(IFR), 1 ), 2) );

    % Reshape FB.  Each row of F will be taken from 1 of the filters in FB.  
    % reshape takes elements out of FB columnwise, starting with the first
    % filter and so on, creating a matrix where each column represents a 
    % filter response.  We tranpose this.  The fliplr  is important because 
    % when conv was done, the REVERSED version (fliplr and flipud) of each 
    % filter was passed.  Once each filter is string strung out we just need 
    % to do 1 fliplr to perfectly reverse the whole thing.
    F = reshape( FB, FB_mrows*FB_ncols, [] ); F=F'; F=fliplr(F);
    
    % invert filter bank
    Finv = pinv(F); 
    
    if 1  %%% recover entire image  
        if 1 % reconstruct filter
            w = filter_binomial_1D( 1 );
            w = w * w';
        else
            w = [0 0 0; 0 1 0; 0 0 0];
        end

        I2 = zeros( size(IFR,1)+2, size(IFR,2)+2 );
        index_r = (FB_mrows+1)/2;  index_c = (FB_ncols+1)/2;
        for r=1:size(IFR,1) for c=1:size(IFR,2)
            % recover the vector at this point
            filter_resp_vec = squeeze( IFR(r,c,:) );
            I_win_recovered_vec = Finv * filter_resp_vec;
            I_win_recovered = reshape( I_win_recovered_vec, FB_mrows, FB_ncols );

            % update overall image
            Idelta = w .* I_win_recovered( index_r-1:index_r+1, index_c-1:index_c+1 );
            I2(r:r+2,c:c+2) = I2( r:r+2,c:c+2 ) + Idelta;
        end; end;
        I2 = arraycrop2dims( I2, size(I2)-2 );

        % display
        figure; 
        subplot(2,2,1); montage2( IFR, 1 );   
        subplot(2,2,2); montage2( FB, 1 );  
        subplot(2,2,3); im( I ); 
        subplot(2,2,4); im( I2 ); 
        %IFR_str
        
    else  %%% recover a specific patch
        
        % get a specific r,c
        figure(1); im(I); 
        [c,r] = ginput(1); r=round(r); c=round(c); 
        hold('on'); plot( c, r, '+r' ); hold('off');
        
        % recover a given window patch
        filter_resp_vec = squeeze( IFR(r,c,:) );
        I_win_recovered_vec = Finv * filter_resp_vec;
        I_win_recovered = reshape( I_win_recovered_vec, FB_mrows, FB_ncols );
        
        % get the TRUE image window around given point (for comparison only)
        I_win = I( max(1,r-FB_mradius):min(r+FB_mradius,mrows), max(1,c-FB_mradius):min(c+FB_mradius,ncols ));
        I_win_vec = reshape( I_win, [], 1 );

        % show the TRUE window vs the recovered window
        figure(2); im( I_win );
        hold('on'); plot( FB_mradius+1, FB_nradius+1, '+r' ); hold('off');
        figure(3); im( I_win_recovered);
        hold('on'); plot( FB_mradius+1, FB_nradius+1, '+r' ); hold('off');
        
        I2 = [];
    end
