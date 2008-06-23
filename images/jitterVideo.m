function IS = jitterVideo( I, nphis, maxphi, ntrans, maxtrans, ...
  nttrans, maxttrans, jsiz )
% Creates multiple, slightly jittered versions of a video.
%
% Takes a video and creats multiple versions of the video with offsets in
% both space and time and rotations in space.  Basically, for each frame in
% the video calls jitterImage, and then also adds some temporal offsets.
% In all respects this it basically functions like jitterImage -- see that
% function for more information.
%
% Note: All temporal translations must have integer size.
%
% USAGE
%  IS = jitterVideo( I, nphis, maxphi, ntrans, maxtrans, ...
%                            nttrans, maxttrans, [jsiz] )
%
% INPUTS
%  I           - BW video (MxNxT) or videos (MxNxTxK), must have odd dims
%  nphis       - number of spatial rotations (must be odd)
%  maxphis     - max value for spatial rotation
%  ntrans      - number of spatial translations (must be odd)
%  maxtrans    - max value for spatial translations
%  nttrans     - number of temporal translations (must be odd)
%  maxttrans   - max value for temporal translations
%  jsiz        - [] Final size of each video in IJ
%
% OUTPUTS
%  IS          - MxNxTxR or MxNxTxKxR set of vids, R=(ntrans*ntrans*nphis)
%
% EXAMPLE
%
% See also JITTERIMAGE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

nd = ndims(I);  siz = size(I);

% default param settings [some params dealt with by jitterImage]
if( nargin<8 || isempty(jsiz)); jsiz = []; end;
if( nphis==0 || nphis==1); maxphi=0; nphis = 1; end;
if( ntrans==0 || ntrans==1); maxtrans=0; ntrans = 1; end;
if( nttrans==0 || nttrans==1); maxttrans=0; nttrans = 1; end;
if( isempty(jsiz)); jsiz=[siz(1:2)-2*maxtrans siz(3)-2*maxttrans]; end;
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
jitterPrms = {nphis, maxphi, ntrans, maxtrans, ttrans, jsiz};
if( nd==3)
  IS = jitterVideo1( I, jitterPrms{:} );
elseif( nd==4)
  IS = fevalArrays( I, @jitterVideo1, jitterPrms{:} );
  IS = permute( IS, [1 2 3 5 4] );
end
