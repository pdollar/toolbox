% Display a point cloud animation
%
% USAGE
%  playAnimation( A, [fps], [loop], [N] )
%
% INPUTS
%  I       - Nx3xT or Nx2xT array (N=num points, T=num frames)
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
% DATESTAMP
%  17-May-2007
%
% See also

% Piotr's Image&Video Toolbox      Version 1.03
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function playAnimation( A, fps, loop, N )

if( nargin<2 || isempty(fps)); fps = 100; end
if( nargin<3 || isempty(loop)); loop = 1; end
if( nargin<4 || isempty(N)); useConn = 0; else useConn = 1; end

if( iscell(A) ); error('cell arrays not supported.'); end;
if( ~ismember(ndims(A),[2 3]) ); error('unsupported dimension of A'); end

siz=size(A); nframes=siz(3); nDim=siz(1); nPoint=siz(2);

% Determine the boundaries of the data
bound=minmax(reshape(A,nDim,[]));
maxB=max(bound(:,2)-bound(:,1))/2;
bound=mean(bound,2); bound=[bound-maxB bound+maxB]; % make axes equal
bound=reshape(bound',1,[]);

% If 3D data points are given
h=gcf; figure(h); % bring to focus
set( gcf, 'KeyPressFcn', { @interface } );
set(gcf,'Renderer','opengl');
doReturn=0;

conn=[]; hLine=0; hPoint=0;
initializeCloud();

% play the animation several times
for nplayed = 1 : abs(loop)
  if( loop<0 && mod(nplayed,2)==1 )
    order = nframes:-1:1;
  else
    order = 1:nframes;
  end

  % Play the animation once
  for i=order
    tic; try geth=get(h); catch return; end
    if doReturn; return; end

    updateCloud(i);

    % Display the image
    title(sprintf('frame %d of %d',i,nframes));
    axis(bound); drawnow;
    if(fps>0); pause(1/fps - toc); else pause(eps); end
  end
end

%%%%%%%%%%
  function initializeCloud()
    % Initialize the point cloud
    if useConn
      conn = cell(1,nPoint); coord=cell(1,3);
      for ii = 1 : nPoint
        conn{ii}(:,2) = N{i}'; conn{ii}(:,1) = ii;
      end
      conn = cell2mat(conn');

      if nDim==3
        for ii=1:3; coord{ii}=[A(ii,conn(:,1),1),A(ii,conn(:,2),1)]'; end
        hLine=line(coord{1},coord{2},coord{3},'Color',[0.4,0.4,1],...
          'Marker','.');
      else
        for ii=1:2; coord{ii}=[A(ii,conn(:,1),1),A(ii,conn(:,2),1)]'; end
        hLine=line(coord{1},coord{2},'Color',[0.4,0.4,1],...
          'Marker','.');
      end
    else
      if nDim==3
        hPoint=plot3(A(1,:,1),A(2,:,1),A(3,:,1),'Color',[0.4,0.4,1],...
          'Marker','.','LineStyle','none');
      else
        hPoint=plot(A(1,:,1),A(2,:,1),'Color',[0.4,0.4,1],...
          'Marker','.','LineStyle','none');
      end
    end
  end

%%%%%%%%%%
  function updateCloud(ii)
    if useConn
      if nDim==3
        for j = 1 : length( hLine )
          set(hLine(j),'XData',A(1,conn(j,1:2),ii),'YData',...
            A(2,conn(j,1:2),ii),'ZData',A(3,conn(j,1:2),ii));
        end
      else
        
      end
    else
      if nDim==3
        set(hPoint,'XData',A(1,:,i),'YData',A(2,:,i),'ZData',A(3,:,i));
      else
        set(hPoint,'XData',A(1,:,i),'YData',A(2,:,i));
      end
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
        case 'q',
          doReturn=1;
      end
    end
  end
end

