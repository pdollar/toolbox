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

function viewAnimSimilarity( A, S, N )

if( nargin<4 || isempty(N)); useConn = 0; else useConn = 1; end

if( iscell(A) ); error('cell arrays not supported.'); end;
if( ~ismember(ndims(A),[2 3]) ); error('unsupported dimension of A'); end

siz=size(A); nframes=siz(3); nDim=siz(1); nPoint=siz(2);

% Determine the boundaries of the data
bound=minmax(reshape(A,nDim,[]));
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
initializeCloud();

%%%%%%%%%%
  function initializeCloud()
    c=[ 1 0.4 0.4; 0.4 1 0.4 ];
    % Initialize the point cloud
    if useConn
      % define the connectivities
      conn = cell(1,nPoint); coord=cell(1,3);
      for i = 1 : nPoint
        conn{i}(:,2) = N{i}'; conn{i}(:,1) = i;
      end
      conn = cell2mat(conn');

      % Draw the points/lines
      for i=1:2
        axes(h(i));
        if nDim==3
          for ii=1:3; coord{ii}=[A(ii,conn(:,1),1),A(ii,conn(:,2),1)]'; end
          hLine(i)=line(coord{1},coord{2},coord{3},'Color',c(i,:),...
            'Marker','.');
        else
          for ii=1:2; coord{ii}=[A(ii,conn(:,1),1),A(ii,conn(:,2),1)]'; end
          hLine(i)=line(coord{1},coord{2},'Color',c(i,:),'Marker','.');
        end
        title(sprintf('frame %d of %d',1,nframes)); axis(bound);
      end
    else
      % Draw the points/lines
      for i=1:2
        axes(h(i));
        if nDim==3          
          hPoint(i)=plot3(A(1,:,1),A(2,:,1),A(3,:,1),'Color',c(i,:), ...
            'Marker','.','LineStyle','none');
        else
          hPoint(i)=plot(A(1,:,1),A(2,:,1),'Color',c(i,:), ...
            'Marker','.','LineStyle','none');
        end
        title(sprintf('frame %d of %d',1,nframes)); axis(bound); 
      end
    end
    axes(h(3));
  end

%%%%%%%%%%
  function updateCloud(x)
    if useConn
      for i=1:2
        if nDim==3
          for j = 1 : length( hLine )
            set(hLine(j),'XData',A(1,conn(j,1:2),ii),'YData',...
              A(2,conn(j,1:2),ii),'ZData',A(3,conn(j,1:2),ii));
          end
        else
          for j = 1 : length( hLine )
            set(hLine(j),'XData',A(1,conn(j,1:2),ii),'YData',...
              A(2,conn(j,1:2),ii),'ZData',A(3,conn(j,1:2),ii));
          end
        end
      end
    else
      for i=1:2
        %axes(h(i)); title(sprintf('frame %d of %d',x(i),nframes));
        if nDim==3
          set(hPoint(i),'XData',A(1,:,x(i)),'YData',A(2,:,x(i)),...
            'ZData',A(3,:,x(i)));
        else
          set(hPoint(i),'XData',A(1,:,x(i)),'YData',A(2,:,x(i)));
        end
      end
    end
  end

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
      updateCloud(x);
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
