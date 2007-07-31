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
dfs = {'nCam',-1,'fps',20, 'loop',1, 'N',[],'is3D',true};
prm = getPrmDflt( prm, dfs );
nCam=prm.nCam; fps=prm.fps; loop=prm.loop; N=prm.N;

% Determine the boundaries of the data
boundTot{1}=minmax(reshape(anim.A2,2,[]));
boundTot{2}=minmax([reshape(anim.A3,3,[]), anim.cam]);
minmax([anim.cam])
boundTot{2}
for i=1:2
  maxB=max(boundTot{i}(:,2)-boundTot{i}(:,1))/2;
  % make axes equal
  boundTot{i}=mean(boundTot{i},2); boundTot{i}=[boundTot{i}-maxB ...
    boundTot{i}+maxB];
  boundTot{i}=reshape(boundTot{i}',1,[]);
end

if prm.is3D; bound=boundTot{2}; A=anim.A3;
else bound=boundTot{1}; A=anim.A2;
end

% Define some initial variables
h=gcf; figure(h); % bring to focus
set( gcf, 'KeyPressFcn', { @interface } );
doReturn=0; doPause=0; nFrames=size(A,3);

clf; [hPoint, hCam]=initializeCloud( struct('nCam',nCam,...
  'c',[0.4,0.4,1],'N',N,'A',A,'bound',bound,'t',anim.t,'R',anim.R) );
viewAng=get( gca, 'View' );

% play the animation several times
for nplayed = 1 : abs(loop)
  if( loop<0 && mod(nplayed,2)==1 )
    order = nframes:-1:1;
  else
    order = 1:nFrames;
  end

  % Play the animation once
  for i=order
    tic; try geth=get(h); catch return; end %#ok<NASGU>
    if doReturn; return; end

    hCam=updateCloud( struct('hPoint',hPoint,'hCam',hCam,'nCam',...
      nCam, 'i',i,'N',N,'A',A,'t',anim.t,'R',anim.R));

    while doPause; pause(0.1); end

    % Display the image
    title(sprintf('frame %d of %d',i,nFrames));
    axis(bound); drawnow;
    if(fps>0); pause(1/fps - toc); else pause(eps); end
  end
end

%%%%%%%%%%
  function interface( src, event ) %#ok<INUSL>
    % Deal with a pressed key to change the view or quit the animation
    if ~isempty(event)
      % Deal with a pressed key to change the view or quit the animation
      diffView=[0 0];
      switch event.Key
        case 'leftarrow',
          diffView = [ 10 0 ];
        case 'rightarrow',
          diffView = [ -10 0];
        case 'uparrow',
          diffView = [ 0 -10];
        case 'downarrow',
          diffView = [ 0 10 ];
        case 'space',
          doPause=~doPause;
        case 'q',
          doReturn=1;
        case 'd',
          if size(A,1)==2;
            A=anim.A3; set(gcf,'Color',0.8*[1 1 1]); axis(boundTot{2});
            set(hCam(:),'Visible','on'); view(viewAng);
          else A=anim.A2; set(gcf,'Color',[1 1 1]);
            axis(boundTot{1}); set(hCam(:),'Visible','off'); view(0,90);
          end
      end
      if size(A,1)==3
        viewAng=viewAng + diffView; set( gca, 'View', viewAng);
      end
    end
  end
end
