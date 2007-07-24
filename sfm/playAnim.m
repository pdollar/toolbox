% Display a point cloud animation
%
% USAGE
%  playAnimation( A, [fps], [loop], [N] )
%
% INPUTS
%  I       - 3xNxT or 2xNxT array (N=num points, T=num frames)
%  fps     - [100] maximum number of frames to display per second
%            use fps==0 to introduce no pause and have the movie play as
%            fast as possible
%  loop    - [0] number of time to loop video (may be inf),
%            if neg plays video forward then backward then forward etc.
%  N       - [] cell array containing the connectivity neighbors
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function playAnim( anim, prm )

if nargin<2 || isempty(prm); prm=struct(); end
dfs = {'nCamera',-1,'fps',100, 'loop',1, 'N',[]};
prm = getPrmDflt( prm, dfs );
nCamera=prm.nCamera; fps=prm.fps; loop=prm.loop; N=prm.N;

A=anim.A3; cam=anim.cam;
siz=size(A); nframes=siz(3); nDim=siz(1);

% Determine the boundaries of the data
if nCamera<0; bound=minmax(reshape(A,nDim,[]));
else bound=minmax([reshape(A,nDim,[]), cam]);end
maxB=max(bound(:,2)-bound(:,1))/2;
bound=mean(bound,2); bound=[bound-maxB bound+maxB]; % make axes equal
bound=reshape(bound',1,[]);

% Define some initial variables
h=gcf; figure(h); % bring to focus
set( gcf, 'KeyPressFcn', { @interface } );
doReturn=0; doPause=0;

clf;
[hPoint, hCam]=initializeCloud( struct('cam',anim.cam,'nCamera',nCamera,...
  'c',[0.4,0.4,1],'N',N,'A',anim.A3,'bound',bound) );

% play the animation several times
for nplayed = 1 : abs(loop)
  if( loop<0 && mod(nplayed,2)==1 )
    order = nframes:-1:1;
  else
    order = 1:nframes;
  end

  % Play the animation once
  for i=order
    tic; try geth=get(h); catch return; end %#ok<NASGU>
    if doReturn; return; end

    hCam=updateCloud( struct('hPoint',hPoint,'hCam',hCam,'nCamera',...
      nCamera, 'i',i,'A',anim.A3,'cam',cam));

    while doPause
      pause(0.1);
    end
    
    % Display the image
    title(sprintf('frame %d of %d',i,nframes));
    axis(bound); drawnow;
    if(fps>0); pause(1/fps - toc); else pause(eps); end
  end
end

%%%%%%%%%%
  function interface( src, event )
    % Deal with a pressed key to change the view or quit the animation
    if ~isempty(event)
      switch event.Key
        case 'leftarrow',
          set( gca, 'View', get( gca, 'View' ) + [ 10 0 ] );
        case 'rightarrow',
          set( gca, 'View', get( gca, 'View' ) - [ 10 0 ] );
        case 'uparrow',
          set( gca, 'View', get( gca, 'View' ) - [ 0 10 ] );
        case 'downarrow',
          set( gca, 'View', get( gca, 'View' ) + [ 0 10 ] );
        case 'space',
          doPause=~doPause;
        case 'q',
          doReturn=1;
      end
    end
  end
end
