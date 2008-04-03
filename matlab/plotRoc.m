% Function for display of rocs (receiver operator characteristic curves).
%
% Displays nice clearly visible curves. Consistent usage ensures uniform
% look for rocs. The input D should have n rows, each of which is of the
% form [false-positive rate true-positive rate]. D is generated, for
% example, by scanning a detection threshold over n values from 0 (so first
% entry in D is [1 1]) to 1 (so last entry is [0 0]).
%
% USAGE
%  h = plotRoc( D, prm )
%
% INPUTS
%  D    - [nx2] n data points along roc (falsePos/truePos)
%  prm  - [] param struct
%   .color    ['g'] color for curve
%   .lineSt   ['-'] linestyle (see LineSpec)
%   .lineWd   [4] curve width
%   .logx     [0] use logarithmic scale for x-axis
%   .logy     [0] use logarithmic scale for y-axis
%   .marker   [''] marker type (see LineSpec)
%   .mrkrSiz  [12] marker size
%   .nMarker  [5] number of markers (regularly spaced) to display
%   .lims     [0 1 0 1] axes limits
%   .smooth   [0] if T compute lower envelop of roc to smooth staircase
%
% OUTPUTS
%  h    - plot handle for use in legend only
%
% EXAMPLE
%  k=2; x=0:.0001:1; data1 = [1-x; (1-x.^k).^(1/k)]';
%  k=3; x=0:.0001:1; data2 = [1-x; (1-x.^k).^(1/k)]';
%  hs(1)=plotRoc(data1,struct('color','g','marker','s'));
%  hs(2)=plotRoc(data2,struct('color','b','lineSt','--'));
%  legend( hs, {'roc1','roc2'} ); xlabel('fp'); ylabel('fn');
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

function h = plotRoc( D, prm )

% get params
dfs = {'color','g', 'lineSt','-', 'lineWd',4, 'logx',0, 'logy',0, ...
  'marker','', 'mrkrSiz',12, 'nMarker',5, 'lims',[], 'smooth',0 };
prm=getPrmDflt(prm, dfs); color=prm.color; marker=prm.marker;
lims=prm.lims; logx=prm.logx; logy=prm.logy;
if( isempty(lims) ); lims=[logx*1e-5 1 logy*1e-5 1]; end

% flip to plot miss rate, optionally 'nicefy' roc
D(:,2)=max(eps,1-D(:,2))+.001;
if(prm.smooth); D=smoothRoc( D ); end;

% separately plot: (1) h for legend only, (2) curves, (3) a few markers
hold on; axis(lims);
prmMrkr = {'MarkerSize',prm.mrkrSiz,'MarkerFaceColor',color};
prmPlot = {'Color',color, 'LineWidth',prm.lineWd };
h = plot( 2, 0, [prm.lineSt marker], prmMrkr{:}, prmPlot{:} );
plot( D(:,1), D(:,2), prm.lineSt, prmPlot{:} );
if(~isempty(marker))
  DQ = quantizeRocData( D, prm.nMarker, logx, lims );
  plot( DQ(:,1), DQ(:,2), marker,'Color',color,prmMrkr{:} );
end

% set log axes
if( logx==1 )
  ticks=10.^(-8:0);
  set(gca,'XScale','log','XTick',ticks);
end
if( logy==1 )
  ticks=[.001 .002 .005 .01 .02 .05 .1 .2 .5 1];
  set(gca,'YScale','log','YTick',ticks);
end
if( logx==1 || logy==1 )
  set(gca,'XMinorGrid','off','XMinorTic','off');
  set(gca,'YMinorGrid','off','YMinorTic','off');
end

end

function DQ = quantizeRocData( D, nPnts, logx, lims )
if( logx==1 )
  locs = logspace(log10(lims(1)),log10(lims(2)),nPnts);
else
  locs = linspace(lims(1),lims(2),nPnts);
end
DQ = [locs' ones(length(locs),1)];

loc=1;
for i=length(locs):-1:1
  fpCur = DQ(i,1);
  while( loc<size(D,1) && D(loc,1)>=fpCur )
    loc = loc+1;
  end
  dN=D(loc,:); if(loc==1); dP=D(loc,:); else dP=D(loc-1,:); end
  distP=dP(1)-fpCur; distN=fpCur-dN(1); r=distN/(distP+distN);
  DQ(i,2) = r*dP(2) + (1-r)*dN(2);
end
end

function D1 = smoothRoc( D )
D1 = zeros(size(D));
n = size(D,1); cnt=0;
for i=1:n
  isAnkle = (i==1) || (i==n);
  if( ~isAnkle )
    dP=D1(cnt,:); dC=D(i,:); dN=D(i+1,:);
    isAnkle = (dC(1)~=dP(1)) && (dC(2)~=dN(2));
  end
  if(isAnkle); cnt=cnt+1; D1(cnt,:)=D(i,:); end
end
D1=D1(1:cnt,:);
end
