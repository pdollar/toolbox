% View the similarities within an anim
%
% USAGE
%  viewAnimSimilarity( A, S, [N] )
%
% INPUTS
%  A       - 3xNxT or 2xNxT array (N=num points, T=num frames)
%  S       - TxT similarity matrix
%  N       - [] cell array containing the connectivity neighbors
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version 1.03
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function viewAnimSimilarity( anim, prm )

dfs = {'nCamera',-1,'N',[],'S','REQ'};
prm = getParamDefaults( prm, dfs );
nCamera=prm.nCamera; N=prm.N; S=prm.S; A=anim.A2; 

siz=size(A); nframes=siz(3); nDim=siz(1); nPoint=siz(2);

% Determine the boundaries of the data
if nCamera<0; bound=minmax(reshape(A,nDim,[]));
else bound=minmax([reshape(A,nDim,[]), cam]);end
maxB=max(bound(:,2)-bound(:,1))/2;
bound=mean(bound,2); bound=[bound-maxB bound+maxB]; % make axes equal
bound=reshape(bound',1,[]);

% Create the plots
figure(gcf); % bring to focus
h(1) = subplot( 'position', [ 0, 0, 0.3, 1 ] );
h(2) = subplot( 'position', [ 0.3, 0, 0.3, 1 ] );
h(3) = subplot( 'position', [ 0.6, 0, 0.4, 1 ] );
pos=get(gcf,'Position'); pos(1)=pos(1)-1.5*pos(3); pos(3)=3*pos(3);
set(gcf,'Position',pos);

% Show the similarity matrix
imshow( S, [] ); hold on;
marker1 = plot( 10, 1, 'r*' ); marker2 = plot( 1, 10, 'g*' );

% Define some initial variables
set( gcf, 'WindowButtonMotionFcn', { @interface } );
set( gcf, 'KeyPressFcn', { @interface } );

conn=[]; hLine=0; hPoint=0;

c=[ 1 0.4 0.4; 0.4 1 0.4 ];
for i=1:2
  axes(h(i));
  hPoint(i)=initializeCloud( struct('cam',anim.cam,'nCamera',nCamera,...
    'c',c(i,:),'N',N,'A',anim.A2,'bound',bound) );
end
axes(h(3));

%%%%%%%%%%
  function interface( src, event )
    % Deal with the mouse moving around
    if isempty(event)
      point = get( h(3), 'CurrentPoint' );
      x = round( point( 1, 1:2 ) );
      if any(x<=0) || any(x>size(S)); return; end

      % Deal with the markers
      set( marker1, 'XData', x(1), 'YData', 1 );
      set( marker2, 'XData', 1, 'YData', x(2) );
      % Deal with the 3D object
      for i=1:2
        updateCloud(struct('hPoint',hPoint(i),'hCam',[],'nCamera',-1,...
          'conn',conn,'i',x(i),'A',anim.A2,'cam',[]));
      end
    else
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
      end
      for i=1:2; set( h(i), 'View', get( h(i), 'View' ) + diffView ); end
    end
  end
end
