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

dfs = {'hPoint','REQ','hCam',[],'nCamera',0,'conn',[],'i',1,'A','REQ',...
  'cam',[]};
prm = getPrmDflt( prm, dfs );
hPoint=prm.hPoint; hCam=prm.hCam; nCamera=prm.nCamera; conn=prm.conn;
i=prm.i; A=prm.A; cam=prm.cam;

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
    set(hPoint,'XData',A(1,:,i),'YData',A(2,:,i),'ZData',A(3,:,i));
  else set(hPoint,'XData',A(1,:,i),'YData',A(2,:,i)); end
end

% Update the cameras
if nCamera>=0
  inter=[i-nCamera:i-1,i+1:i+nCamera];
  inter((inter<1) | (inter>size(A,3)))=[];
  delete(hCam);
  hCam=plot3(cam(1,i),cam(2,i),cam(3,i),'Color','r',...
    'Marker','s','MarkerFaceColor','r','LineStyle','none');
  if nCamera>=1
    hCam(2)=plot3(cam(1,inter),cam(2,inter),cam(3,inter),'Color','b',...
      'Marker','s','LineStyle','none');
  end
end
