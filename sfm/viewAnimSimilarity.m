% View the similarities within an anim
%
% USAGE
%  viewAnimSimilarity( A, S, [N] )
%
% INPUTS
%  anim     - anim object
%  prm
%   .S      - TxT similarity matrix
%   .N      - [] cell array containing the connectivity neighbors
%   .nCam   - [-1] Number of cameras to display before and after the
%               current one (-1, don't display the current one)
%   .is3D   - [true] Show the 3D views
%
% OUTPUTS
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function viewAnimSimilarity( anim, prm )

dfs = {'nCam',-1,'N',[],'S','REQ','is3D',true};
prm = getPrmDflt( prm, dfs );
nCam=prm.nCam; N=prm.N; S=prm.S;

% Determine the boundaries of the data
boundTot{1}=minmax(reshape(anim.A2,2,[]));
boundTot{2}=minmax([reshape(anim.A3,3,[]), anim.cam]);
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

% Create the plots
figure(gcf); clf; % bring to focus
h(1) = subplot( 'position', [ 0, 0, 0.3, 0.95 ] ); 
h(2) = subplot( 'position', [ 0.3, 0, 0.3, 0.95 ] );
h(3) = subplot( 'position', [ 0.6, 0, 0.4, 0.95 ] );
pos=get(gcf,'Position'); pos(1)=pos(1)-1.5*pos(3); pos(3)=3*pos(3);
set(gcf,'Position',pos);

% Show the similarity matrix
imshow( S, [] ); hold on;
marker1 = plot( 10, 1, 'r*' ); marker2 = plot( 1, 10, 'b*' );

% Define some initial variables
set( gcf, 'WindowButtonMotionFcn', { @interface } );
set( gcf, 'KeyPressFcn', { @interface } );

conn=[]; hPoint=cell(1,2); hCam=hPoint; viewAng=hPoint;

c=[ 1 0.4 0.4; 0.4 0.4 1 ]; hTit=[0 0];
for i=1:2
  axes(h(i));
  [hPoint{i},hCam{i}]=initializeCloud( struct('nCam',nCam,...
    'c',c(i,:),'N',N,'A',A,'bound',bound,'t',anim.t,'R',anim.R) );
  viewAng{i}=get( h(i), 'View' ); hTit(i)=title('1');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function interface( src, event ) %#ok<INUSL>
    % Deal with the mouse moving around
    point = get( h(3), 'CurrentPoint' );
    x = round( point( 1, 1:2 ) );
    if any(x<=0) || any(x>size(S)); return; end

    % Deal with the markers
    set( marker1, 'XData', x(1), 'YData', 1 );
    set( marker2, 'XData', 1, 'YData', x(2) );

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
        case 'd',
          if size(A,1)==2;
            A=anim.A3; set(gcf,'Color',0.8*[1 1 1]);
            for j=1:2;
              axes(h(j)); axis(boundTot{2});
              set(hCam{j}(:),'Visible','on'); view(viewAng{j});
            end
          else A=anim.A2;
            set(gcf,'Color',[1 1 1]);
            for j=1:2
              axes(h(j)); axis(boundTot{1}); 
              set(hCam{j}(:),'Visible','off'); view(0,90);
            end
          end
      end
      if size(A,1)==3
        for j=1:2
          viewAng{j}=viewAng{j} + diffView; set( h(j), 'View', viewAng{j});
        end
      end
    end
    % Deal with the 3D object
    for j=1:2
      hCam{j}=updateCloud(struct('hPoint',hPoint{j},'hCam',hCam{j},...
        'nCam',nCam,'conn',conn,'i',x(j),'A',A,'t',anim.t,'R',anim.R));
      set(hTit(j),'String',['Frame ' int2str(x(j))]);
    end
  end
end
