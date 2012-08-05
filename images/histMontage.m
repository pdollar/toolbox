function histMontage( HS, mm, nn )
% Used to display multiple 1D histograms.
%
% USAGE
%  histMontage( HS, mm, nn )
%
% INPUTS
%  HS  - HS(i,j) is the jth bin in the ith histogram
%  mm  - [] #images/row (if [] then calculated based on nn)
%  nn  - [] #images/col (if [] then calculated based on mm)
%
% OUTPUTS
%
% EXAMPLE
%  h = histc2( randn(2000,1), 20 )'; clf; histMontage([h; h]);
%
% See also HISTC, HISTC2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

[nhist, nbins] = size(HS);
if( nhist>100 || nhist*nbins>10000 )
  error('Too much histogram data to display!');  end;

% get layout of images (mm=#images/row, nn=#images/col)
if (nargin<3 || isempty(mm) || isempty(nn))
  if (nargin==1 || (nargin==2 && isempty(mm)) || (nargin==3 && ...
      isempty(mm) && isempty(nn)) )
    nn = round(sqrt(nhist));
    mm = ceil( nhist / nn );
  elseif (isempty(mm))
    mm = ceil( nhist / nn );
  else
    nn = ceil( nhist / mm );
  end;
end;

% plot each histogram
clf;
for q=1:nhist
  if( nhist>1 ); subplot( mm, nn, q ); end;
  bar( HS(q,:), 1 ); shading('flat');
  ylim( [0,1] );   set( gca, 'YTick', [] );
  xlim( [.5, nbins+.5] );  set( gca, 'XTick', [] );
end;
