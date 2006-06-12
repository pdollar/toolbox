% Creates multiple, slightly jittered versions of a video.
%
% Takes a video and creats multiple versions of the video with offsets in both space and
% time and rotations in space.  Basically, for each frame in the video calls jitter_image,
% and then also adds some temporal offsets. In all respects this it basically functions
% like jitter_image -- see that function for more information.
%
% Note: All temporal translations must have integer size.
%
% INPUTS
%   I           - BW input video (MxNxT) or videos (MxNxTxK), must have odd dimensions
%   nphis       - number of spatial rotations (must be odd)
%   maxphis     - max value for spatial rotation
%   ntrans      - number of spatial translations (must be odd)
%   maxtrans    - max value for spatial translations
%   nttrans     - number of temporal translations (must be odd)
%   maxttrans   - max value for temporal translations
%   jsiz        - [optional] Final size of each video in IJ 
%
% OUTPUTS
%   IS          - MxNxTxR or MxNxTxKxR set of videos where R=(ntrans*ntrans*nphis)
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also JITTER_IMAGE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IS = jitter_video( I, nphis, maxphi, ntrans, maxtrans, nttrans, maxttrans, jsiz )
    nd = ndims(I);  siz = size(I);
    
    % default param settings [some params dealt with by jitter_image]
    if( nargin<8 || isempty(jsiz)) jsiz = []; end;
    if( nphis==0 || nphis==1) maxphi=0; nphis = 1; end;
    if( ntrans==0 || ntrans==1) maxtrans=0; ntrans = 1; end;
    if( nttrans==0 || nttrans==1) maxttrans=0; nttrans = 1; end;
    if( isempty(jsiz)) jsiz=[siz(1:2)-2*maxtrans siz(3)-2*maxttrans]; end;
    ttrans = linspace( -maxttrans, maxttrans, nttrans );

    % basic error check
    if( nd~=3 && nd~= 4 || length(jsiz)~=3) 
        error('Only defined for 3 or 4 dimensional I'); end;
    if( ~all(mod(siz(1:3),2)==1))
        error('I must have odd dimensions'); end;
    if( ~all(mod(jsiz,2)==1)) 
        error('Jittered I must have odd dimensions'); end;    
    if( mod(nttrans,2)~=1 ) 
        error('must have odd number of temporal translations'); end;
    if( ~all(mod(ttrans,1)==0)) 
        error('All temporal translations must have integer size'); end;
    

    % now for each video jitter it
    jitter_params = {nphis, maxphi, ntrans, maxtrans, ttrans, jsiz};
    if( nd==3)
        IS = jitter_video1( I, jitter_params{:} );
    elseif( nd==4)
        IS = feval_arrays( I, @jitter_video1, jitter_params{:} ); 
        IS = permute( IS, [1 2 3 5 4] ); 
    end


    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function does the work
function IS = jitter_video1( I, nphis, maxphi, ntrans, maxtrans, ttrans, jsiz )
    nttrans = length( ttrans );

    % grow I in temporal direction
    siz = size(I);
    need_siz3 = jsiz(3) + 2*max(ttrans);
    delta3 = max( (need_siz3 - siz(3))/2, 0 );
    if( delta3>0 )  
        I = padarray(I,[0 0 delta3],'replicate','both'); 
        warning('jitter_video: Not enough video data - growing video.'); 
    end;
    delta3 = (size(I,3) - jsiz(3))/2;

    % jitter frames
    ISsp = jitter_image( I, nphis, maxphi, ntrans, maxtrans, jsiz(1:2) );

    % add temporal jitter to each spatially jittered version of I
    IS = repmat( ISsp(1), [jsiz, size(ISsp,4) * nttrans] );
    start3 = delta3+1;  end3 = size(I,3)-delta3;
    index = 1; 
    for i=1:size(ISsp,4)
        Isp = ISsp(:,:,:,i);
        for t_tran=ttrans
            I2 = Isp( :,:, (start3:end3)+t_tran );
            IS(:,:,:,index) = I2; index = index+1;
        end
    end
