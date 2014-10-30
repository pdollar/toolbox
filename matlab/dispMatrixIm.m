function dispMatrixIm( M, varargin )
% Display a Matrix with non-negative entries in image form.
%
% USAGE
%  dispMatrixIm( M, [varargin] )
%
% INPUTS
%  M          - [m x n] arbitrary matrix with non-negative entries
%  varargin   - additional params (struct or name/value pairs)
%   .fStr       - ['%1.2f'] format for each element
%   .invert     - [0] if 1 display large values as dark
%   .show0      - [1] if false don't display values exactly equal to 0
%   .maxM       - [] maximum possible value im M (defines display range)
%   .maxLen     - [inf] maximum number of chars to display per element
%   .pvPairs    - [{'FontSize',20}] parameter / value list for text.m
%   .cmap       - ['gray'] colormap for matrix (see doc colormap)
%
% OUTPUTS
%
% EXAMPLE
%  figure(1); dispMatrixIm(round(rand(5)*100),'fStr','%d','maxM',100)
%  figure(2); dispMatrixIm(rand(3,5),'fStr','%0.3f','invert',1)
%  imLabel({'a','b','c'},'left',0,{'FontSize',20});
%  imLabel({'1','2','3','4','5'},'bottom',0,{'FontSize',20});
%
% See also imLabel, confMatrixShow
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.62
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get default parameters
dfs={'fStr','%1.2f','invert',0,'show0',1,'maxM',[],...
  'maxLen','inf','pvPairs',{'FontSize',20},'cmap','gray'};
[fStr,invert,show0,maxM,maxLen,pvPairs,cmap]=getPrmDflt(varargin,dfs,1);
if( any(M(:)<0) ); error( 'M must have non-negative entries' ); end
% optionally invert M for display
[m,n]=size(M); maxM=max([maxM; M(:)]);
M1=M; if(invert), M1=maxM-M1; end
% display M as image
clf; imagesc(M1,[0,maxM]); colormap(cmap);
set(gca,'XTick',[]); set(gca,'YTick',[]);
% now write text of actual confusion value
txtAlign={'VerticalAlignment','middle','HorizontalAlignment','center'};
for i=1:m
  for j=1:n
    if(M(i,j)==0 && ~show0), continue; end; s=sprintf(fStr,M(i,j));
    if(length(s)>1 && all(s(1:2)=='0.')), s=s(2:end); end
    s=s(1:min(end,maxLen)); if(M1(i,j)>maxM/2), col='k'; else col='w'; end
    text(j,i,s,'col',col,txtAlign{:},pvPairs{:});
  end
end
end
