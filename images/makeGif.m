function makeGif( M, fileName, prm )
% Writes a matlab movie to an animated GIF.
%
% USAGE
%  makeGif( M, fileName, prm )
%
% INPUTS
%  M          - Matlab movie
%  fileName   - file name of the output gif file
%  prm
%   .fps        - number of frames per second
%   .nColor     - number of indexes colors
%   .scale      - scale to resize the frames at
%   .loop       - number of times to repeat the movie (Inf possible)
%
% OUTPUTS
%
% EXAMPLE
%  load( 'images.mat' );
%  M = playMovie( video, [], 1 );
%  makeGif( M, 'mouse.gif', struct('scale',0.5) );
%
% See also PLAYMOVIE, MONTAGE2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

dfs = {'fps',30, 'nColor',256, 'scale',1, 'loop', 0};
prm = getPrmDflt( prm, dfs );
fps=prm.fps;  nColor=prm.nColor; scale=prm.scale; loop=prm.loop;

if scale~=1
  for i=1:length(M); M(i).cdata=imresize(M(i).cdata,scale, 'bicubic'); end
end  

if ndims(M(1).cdata)==3
  for i=1:length(M)
    [M(i).cdata,M(i).colormap] = rgb2ind(M(i).cdata, nColor);
  end
else
  for i=1:length(M)
    M(i).colormap = repmat(0:1/256:1,[3 1])';
  end
end

imwrite(M(1).cdata,M(1).colormap,fileName,'gif','LoopCount',loop);
for i=2:length(M)
  imwrite(M(i).cdata,M(i).colormap,fileName,'gif','DelayTime',1/fps,...
    'WriteMode','append');
end
