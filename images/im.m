function im( I, range, extraInf )
% Function for displaying grayscale images.
%
% Handy function for showing a grayscale image with a colorbar and
% interactive pixel info tool.
%
% USAGE
%  im( I, [range], [extraInf] )
%
% INPUTS
%  I        - image in a valid format
%  range    - [] minval/maxval for imagesc
%  extraInf - [1] if 1 then a colorbar is shown as well as impixelinfo
%
% EXAMPLE
%  load clown; im( X )
%
% See also IMSHOW, IMVIEW, IMPIXELINFO, IMTOOL
%
% Piotr's Image&Video Toolbox      Version 2.02
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<1 || isempty(I)); I=0; end;
if( nargin<2 || isempty(range))
  imagesc(I);
else
  imagesc(I,range)
end
if( nargin<3 || isempty(extraInf)); extraInf=1; end;

colormap(gray);
title(inputname(1));
axis('image');

% info about image pixels - removed impixelinfo for 2007b
if( extraInf )
  %impixelinfo;
  colorbar;
else
  set(gca,'XTick',[]);
  set(gca,'YTick',[]);
end

% whitebg('black'); set(gcf,'color', [0 0 0]); %black background
% set(gcf,'menubar','none'); % no menu
