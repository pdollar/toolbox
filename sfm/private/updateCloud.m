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
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function hCam=updateCloud( prm )

dfs = {'hPoint','REQ','hCam',[],'nCam',0,'conn',[],'i',1,'A','REQ',...
  't',[],'R',[]};
prm = getPrmDflt( prm, dfs );
hPoint=prm.hPoint; hCam=prm.hCam; nCam=prm.nCam; conn=prm.conn;
i=prm.i; A=prm.A; t=prm.t; R=prm.R;

nDim=size(A,1);

% Update the point cloud
if ~isempty(conn)
  if nDim==3
    for j = 1 : length( hLine )
      set(hLine(j),'XData',A(1,conn(j,1:2),i),'YData',...
        A(2,conn(j,1:2),i),'ZData',A(3,conn(j,1:2),i));
    end
  else
    for j = 1 : length( hLine )
      set(hLine(j),'XData',A(1,conn(j,1:2),i),'YData',...
        A(2,conn(j,1:2),i));
    end
  end
else
  if nDim==3
    set(hPoint(1),'XData',A(1,:,i),'YData',A(2,:,i),'ZData',A(3,:,i));
    set(hPoint(2),'XData',A(1,1,i),'YData',A(2,1,i),'ZData',A(3,1,i));
  else
    set(hPoint(1),'XData',A(1,:,i),'YData',A(2,:,i));
    set(hPoint(2),'XData',A(1,1,i),'YData',A(2,1,i));
  end
end

% Update the cameras
if nCam>=0
  XX=getCoord(t(:,i),R(:,:,i),1);
  for j=1:8
    set(hCam(1,j),'XData',XX{1}(:,j),'YData',XX{2}(:,j),'ZData',...
      XX{3}(:,j));
  end
  m=2;
  for l=[i-nCam:i-1,i+1:i+nCam]
    if l<1 || l>size(t,2); continue; end
    for j=1:8
      XX=getCoord(t(:,l),R(:,:,l),0.5);
      set(hCam(m,j),'XData',XX{1}(:,j),'YData',XX{2}(:,j),'ZData',...
        XX{3}(:,j));
    end
    m=m+1;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XX=getCoord(t,R,scale)

X=[-1 -1 0; 1 -1 0; 1 1 0; -1 1 0; 0 0 2]'*scale;
X(3,:)=X(3,:)+5; X=R'*(X-repmat(t,[1 5]));

XX=cell(1,3);
for k=1:3
  XX{k}=[X(k,1:2); X(k,2:3); X(k,3:4); X(k,[4 1]); X(k,[1 5]); ...
    X(k,[2 5]); X(k,[3 5]); X(k,[4 5])]';
end
