function [h,miss] = plotRoc( D, varargin )
% Function for display of rocs (receiver operator characteristic curves).
%
% Display roc curves. Consistent usage ensures uniform look for rocs. The
% input D should have n rows, each of which is of the form:
%  D = [falsePosRate truePosRate]
% D is generated, for example, by scanning a detection threshold over n
% values from 0 (so first entry is [1 1]) to 1 (so last entry is [0 0]).
% Alternatively D can be a cell vector of rocs, in which case an average
% ROC will be shown with error bars. Plots missRate (which is just 1 minus
% the truePosRate) on the y-axis versus the falsePosRate on the x-axis.
%
% USAGE
%  [h,miss] = plotRoc( D, prm )
%
% INPUTS
%  D    - [nx2] n data points along roc [falsePosRate truePosRate]
%         typically ranges from [1 1] to [0 0] (or may be reversed)
%  prm  - [] param struct
%   .color    - ['g'] color for curve
%   .lineSt   - ['-'] linestyle (see LineSpec)
%   .lineWd   - [4] curve width
%   .logx     - [0] use logarithmic scale for x-axis
%   .logy     - [0] use logarithmic scale for y-axis
%   .marker   - [''] marker type (see LineSpec)
%   .mrkrSiz  - [12] marker size
%   .nMarker  - [5] number of markers (regularly spaced) to display
%   .lims     - [0 1 0 1] axes limits
%   .smooth   - [0] if T compute lower envelop of roc to smooth staircase
%   .fpTarget - [] return miss rates at given fp values (and draw lines)
%   .xLbl     - ['false positive rate'] label for x-axis
%   .yLbl     - ['miss rate'] label for y-axis
%
% OUTPUTS
%  h    - plot handle for use in legend only
%  miss - miss rates at fpTarget reference values (if fpTarget specified)
%
% EXAMPLE
%  k=2; x=0:.0001:1; data1 = [1-x; (1-x.^k).^(1/k)]';
%  k=3; x=0:.0001:1; data2 = [1-x; (1-x.^k).^(1/k)]';
%  hs(1)=plotRoc(data1,struct('color','g','marker','s'));
%  hs(2)=plotRoc(data2,struct('color','b','lineSt','--'));
%  legend( hs, {'roc1','roc2'} ); xlabel('fp'); ylabel('fn');
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.63
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% get params
[color lineSt lineWd logx logy marker mrkrSiz nMarker lims smooth ...
  fpTarget xLbl yLbl] = getPrmDflt( varargin, {'color' 'g' 'lineSt' '-' ...
  'lineWd' 4 'logx' 0 'logy' 0 'marker' '' 'mrkrSiz' 12 'nMarker' 5 ...
  'lims' [] 'smooth' 0 'fpTarget' [] 'xLbl' 'false positive rate' ...
  'yLbl' 'miss rate' } );
if( isempty(lims) ); lims=[logx*1e-5 1 logy*1e-5 1]; end

% ensure descending fp rate, change to miss rate, optionally 'nicefy' roc
if(~iscell(D)), D={D}; end; nD=length(D);
for j=1:nD, assert(size(D{j},2)==2); end
for j=1:nD, if(D{j}(1,2)<D{j}(end,2)), D{j}=flipud(D{j}); end; end
for j=1:nD, D{j}(:,2)=1-D{j}(:,2); assert(all(D{j}(:,2)>=0)); end
if(smooth), for j=1:nD, D{j}=smoothRoc(D{j}); end; end

% plot: (1) h for legend only, (2) roc curves, (3) markers, (4) error bars
hold on; axis(lims);
prmMrkr = {'MarkerSize',mrkrSiz,'MarkerFaceColor',color};
prmClr={'Color',color}; prmPlot = [prmClr,{'LineWidth',lineWd}];
h = plot( 2, 0, [lineSt marker], prmMrkr{:}, prmPlot{:} ); %(1)
if(nD==1), D1=D{1}; else D1=mean(quantizeRocs(D,100,logx,lims),3); end
plot( D1(:,1), D1(:,2), lineSt, prmPlot{:} ); %(2)
DQ = quantizeRocs( D, nMarker, logx, lims ); DQm=mean(DQ,3);
if(~isempty(marker))
  plot(DQm(:,1),DQm(:,2),marker,prmClr{:},prmMrkr{:} ); end %(3)
if(nD>1), DQs=std(squeeze(DQ(:,2,:)),0,2);
  errorbar(DQm(:,1),DQm(:,2),DQs,'.',prmClr{:}); end %(4)
xlabel(xLbl); ylabel(yLbl);

% plot line at given fp rate
m=length(fpTarget); miss=zeros(1,m);
if( m>0 )
  assert( min(D1(:,1))<=min(fpTarget) );
  for i=1:m, j=find(D1(:,1)<=fpTarget(i)); miss(i)=D1(j(1),2); end
  fp=min(fpTarget); plot([fp fp],lims(3:4),'Color',.7*[1 1 1]);
  fp=max(fpTarget); plot([fp fp],lims(3:4),'Color',.7*[1 1 1]);
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
if( logx==1 || logy==1 ), grid on;
  set(gca,'XMinorGrid','off','XMinorTic','off');
  set(gca,'YMinorGrid','off','YMinorTic','off');
end

end

function DQ = quantizeRocs( Ds, nPnts, logx, lims )
% estimate miss rate at each target fp rate
nD=length(Ds); DQ=zeros(nPnts,2,nD);
if(logx==1), fps=logspace(log10(lims(1)),log10(lims(2)),nPnts);
else fps=linspace(lims(1),lims(2),nPnts); end; fps=flipud(fps');
for j=1:nD, D=[Ds{j}; 0 1]; k=1; fp=D(k,1);
  for i=1:nPnts
    while( k<size(D,1) && fp>=fps(i) ), k=k+1; fp=D(k,1); end
    k0=max(k-1,1); fp0=D(k0,1); assert(fp0>=fp);
    if(fp0==fp), r=.5; else r=(fps(i)-fp)/(fp0-fp); end
    DQ(i,1,j)=fps(i); DQ(i,2,j)=r*D(k0,2)+(1-r)*D(k,2);
  end
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
