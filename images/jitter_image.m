% Creates multiple, slightly jittered versions of an image.
%
% Takes an image I, and generates a number of images that are copies of the original image
% with slight translation and rotation applied.  The original image also appears in the
% final set.  
%
% The parameter jsiz controls the size of the cropped images.  If jsiz gives a size that's
% substantially smaller than I then all data in the the final set will come from I.
% However, if this is not the case then I may need to be padded first.  The way this is
% done is with padarray with the 'replicate' method.  If jsiz is not specified, it is set
% to be the size of the original image. A warning appears if the image needs to be grown. 
% 
% Rotations and translations are specified by giving a range and a maximum value for each.
% For example, if maxphi=10 and nphis=5, then the actual rotations applied are [-10 -5 0 5
% 10]. Uses: linspace( -maxphi, maxphi, nphis ); Likewise if maxtrans=3 and ntrans=3 then
% the translations are [-3 0 3]. Each translation is applied in the x direction as well as
% the y direction.  Each combination of rotation, translation in x, and translation in y
% is used (for example phi=5, transx=-3, transy=0), so the total number of images
% generated is R=ntrans*ntrans*nphis).  This function works faster if all of the 
% translation end up being integer valued.
%
% If the input image is actually a MxNxK stack of images then applies op to each image in
% stack and returns an MxNxKxR where R=(ntrans*ntrans*nphis) set of images. 
%
% INPUTS
%   I           - BW input image (MxN) or images (MxNxK), must have odd dimensions
%   nphis       - number of rotations
%   maxphis     - max value for rotation
%   ntrans      - number of translations 
%   maxtrans    - max value for translation
%   jsiz        - [optional] Final size of each image in IJ 
%   reflectflag - [optional] if true then also adds reflection of each image
%   scales      - [optional] nscalesx2 array of vert/horiz scalings
%
% OUTPUTS
%   IJ          - MxNxR or MxNxKxR set of images where R=(ntrans*ntrans*nphis*nscales)
% 
% EXAMPLE
%   load trees; I = ind2gray(X,map); I = imresize(I,[41 41]); clear X caption map
%   % creates 7^2*2 images of slight translations with reflection (but no rotation) 
%   IJ = jitter_image( I, 0, 0, 7, 3, [35 35], 1 ); montage2(IJ,1,1)
%   % creates 5 images of slight rotations (no translations)
%   IJ = jitter_image( I, 5, 25, 0, 0, size(I) ); montage2(IJ,1,1)
%   % creates 45 images of both rotation and slight translations
%   % alternatively use (maxtrans=3) OR (nphis=5)
%   IJ = jitter_image( I, 5, 10, 3, 2 ); montage2(IJ,1,1)
%   % additionally create multiple scaled versions
%   IJ = jitter_image( I, 1, 0, 1, 0, [], [], [1 1; 2 1; 1 2; 2 2] ); montage2(IJ,1)
%
% DATESTAMP
%   27-Feb-2005  2:00pm
%
% See also JITTER_VIDEO

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IJ = jitter_image( I, nphis, maxphi, ntrans, maxtrans, jsiz, reflectflag, scales )
    %% NOTE: CODE HAS BECOME REALLY MESSY :-(

    %%% Eigenanalysis of IJ can be informative:
    %   I = double(I);
    %   IJ = jitter_image( I, 111, 10, 0, 0 );
    %   IJ = jitter_image( I, 11, 10, 11, 3 ); %slow
    %   [ U, mu, variances ] = pca( IJ );
    %   ks = 0:min(11,size(U,2));   % should need about 4
    %   pca_visualize( U, mu, variances, IJ, [], ks );

    nd = ndims(I);  siz = size(I);

    % basic error checking and default parameter settings
    if( nargin<6 || isempty(jsiz)) jsiz = []; end;
    if( nargin<7 || isempty(reflectflag)) reflectflag = 0; end;
    if( nargin<8 || isempty(scales)) scales = [1 1]; end;
    if( nphis==0 || nphis==1) maxphi=0; nphis = 1; end;
    if( ntrans==0 || ntrans==1) maxtrans=0; ntrans = 1; end;
    if( isempty(jsiz)) jsiz=siz(1:2); end;
    if( nd~=2 && nd~=3 || length(jsiz)~=2)
        error('Only defined for 2 or 3 dimensional I'); end;

    % build trans / phis 
    trans = linspace( -maxtrans, maxtrans, ntrans );
    ntrans = length(trans);
    trans = trans( ones(1,ntrans), : );
    trans_x = trans(:)'; trans_y = trans'; trans_y = trans_y(:)';
    trans = [ trans_x; trans_y ];
    ntrans = size(trans,2);
    phis = linspace( -maxphi, maxphi, nphis );
    phis = phis / 180 * pi;

    
    % I must be big enough to support given ops.  So grow I if necessary.
    need_siz = jsiz + 2*max(trans(1,:)); % size needed for translation
    if( nphis>1 ) need_siz = sqrt(2)*need_siz+1; end; % size needed for rotation
    if( size(scales,1)>1 ) % size needed for scaling
        need_siz = [need_siz(1)*max(scales(:,1)) need_siz(2)*max(scales(:,2))]; end;
    need_siz = ceil(need_siz); if( ndims(I)==3 ) need_siz = [need_siz siz(3)]; end;
    deltas_grow = ceil( max( (need_siz - size(I))/2, 0 ) );
    if( any(deltas_grow>0) ) 
       I = padarray(I,deltas_grow,'replicate','both');
       warning(['jitter_image: Not enough image data - growing image need size:' ...
                int2str(need_siz) ' have size: ' int2str(siz(1:2))]); 
    end;
    
    % now for each image jitter it!
    if( nd==2)     
        IJ = jitter_image1( I, jsiz, phis, trans, scales, reflectflag );
    elseif( nd==3)
        IJ = feval_arrays( I, @jitter_image1, jsiz, phis, trans, scales, reflectflag );
        IJ = reshape( IJ, size(IJ,1), size(IJ,2), [] );
    else
        error('Only defined for 2 or 3 dimensional I');
    end;
  
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function does the work for SCALE
function IJ = jitter_image1( I, jsiz, phis, trans, scales, reflectflag )
    method = 'linear'; 
    nscales = size(scales,1); 
    if( nscales==1 ) % if just 1 scaling
        if( ~all(scales==1) )
            S = [scales(1,1) 0; 0 scales(1,2)]; 
            H = [S [0;0]; 0 0 1];    
            I = apply_homography( I, H, method, 'crop' );
        end;
        IJ = jitter_image2( I, jsiz, phis, trans );
    else % multiple scales
        IJ = repmat( I(1), [size(I) nscales] );
        for i=1:nscales 
            S = [scales(i,1) 0; 0 scales(i,2)]; 
            H = [S [0;0]; 0 0 1];    
            J = apply_homography( I, H, method, 'crop' );
            IJ(:,:,i) = J;
        end;
        IJ = feval_arrays( IJ, @jitter_image2, jsiz, phis, trans );
        IJ = reshape( IJ, size(IJ,1), size(IJ,2), [] );
    end

    %% add reflection if reflectflag
    if( reflectflag ) IJ = cat( 3, IJ, flipdim( IJ, 2 ) ); end;

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function does the work for ROT/TRANS
function IJ = jitter_image2( I, jsiz, phis, trans )
    method = 'linear';
    ntrans = size(trans,2); nphis = length(phis); nops = ntrans*nphis;
    siz = size(I);   deltas = (siz - jsiz)/2;

    %%% get each of the transformations.  
    index = 1;
    if( all(mod(trans,1))==0) % all integer translations [optimized for speed]
        startr = floor(deltas(1)+1); endr = floor(siz(1)-deltas(1));
        startc = floor(deltas(2)+1); endc = floor(siz(2)-deltas(2));
        IJ = repmat( I(1), [jsiz(1), jsiz(2), nops] );
        for phi=phis
            if( phi==0) IR = I; else
                R = rotation_matrix2D( phi );
                H = [R [0;0]; 0 0 1];    
                IR = apply_homography( I, H, method, 'crop' );            
            end
            
            for tran=1:ntrans
                I2 = IR( (startr:endr)-trans(1,tran), (startc:endc)-trans(2,tran) );
                IJ(:,:,index) = I2; index = index+1;
            end
        end
    else % arbitrary translations
        IJ = repmat( I(1), [siz(1), siz(2), nops] );
        for phi=phis
            R = rotation_matrix2D( phi );
            for tran=1:ntrans
                H = [R trans(:,tran); 0 0 1];    
                I2 = apply_homography( I, H, method, 'crop' );
                IJ(:,:,index) = I2; index = index+1;
            end
        end
        IJ = arraycrop2dims( IJ, [jsiz, nops] );    
    end
