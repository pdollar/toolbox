function varargout=pcaVisualize( U, mu, vars, X, index, ks, fname, show )
% Visualization of quality of approximation of X given principal comp.
%
% X can either represent a single element (a single image or video), or a
% set of elements. In the latter case, index controls which element of X to
% apply visualization to, if unspecified it is chosen randomly.
%
% USAGE
%  varargout=pcaVisualize(U, mu, vars, X, [index], [ks], [fname], [show])
%
% INPUTS
%  U           - returned by pca.m
%  mu          - returned by pca.m
%  vars        - returned by pca.m
%  X           - Set of images or videos, or a single image or video
%  index       - [] controls which element of X to aplply visualization to
%  ks          - [] ks values of k for pcaApply (ex. ks=[1 4 8 16])
%  fname       - [] if specified outputs avis
%  show        - [1] will display in figure(show) and figure(show+1)
%
% OUTPUTS
%  M           - [only if X is a movie] movie of xhats (see pcaapply)
%  MDiff       - [only if X is a movie] movie of difference images
%  MU          - [only if X is a movie] movie of eigenmovies
%
% EXAMPLE
%
% See also PCA, PCAAPPLY
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.30
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% sizes / dimensions
siz = size(X);  nd = ndims(X);  [D,r] = size(U);
if(D==prod(siz) && ~(nd==2 && siz(2)==1)); siz=[siz, 1]; nd=nd+1; end
n = siz(end);  siz1 = siz(1:end-1);  

% some error checking
if(prod(siz(1:end-1))~=D); error('incorrect size for X or U'); end
if( nargin<5 || isempty(index) ); index = randint2(1,1,[1 n]); end
if( index>n ); error(['index >' num2str(n)]); end
if( nargin<6 || isempty(ks) ); maxp=floor(log2(r)); ks=2.^(0:maxp); end
if( nargin<7 || isempty(fname)); fname = []; end
if( nargin<8 || isempty(show)); show = 1; end

%%% create xhats image of PCA reconstruction
ks = ks( ks<=r );
inds = {':'}; inds = inds(:,ones(1,nd-1));
x = double( X(inds{:},index) );
xhats = x;  diffs = []; errors = zeros(1,length(ks));
for k=1:length(ks)
  [ ~, xhat, errors(k) ] = pcaApply( x, U, mu, ks(k) );
  xhats = cat( nd, xhats, xhat );
  diffs = cat( nd, diffs, (xhat-x).^2 );
end

%%% calculate residual at each k for plot purposes
residuals = vars / sum(vars);
residuals = 1-cumsum(residuals);
residuals = [1; residuals(1:max(ks))];

%%% show decay image
figure(show); clf;
plot( 0:max(ks), residuals, 'r- .',  ks, errors, 'g- .' );
hold('on'); line( [0,max(ks)], [.1,.1] ); hold('off');
title('error of approximation vs number of eigenbases used');
legend('residuals','errors - actual');

%%% reshape U to have first dimensions same as x
k = min(100,r);  st=0;
Uim = reshape( U(:,1+st:k+st), [ siz1 k ]  );

%%% visualization
labels=cell(1,length(ks));
for k=1:length(ks); labels{k} = ['k=' num2str(ks(k))]; end
labels2=[{'orig'} labels];
if( nd==3 ) % images
  figure(show+1); clf;
  subplot(2,2,1); montage2( Uim ); title('principal components');
  subplot(2,2,2); im( mu ); title('mean');
  subplot(2,2,3); montage2( xhats, struct('labels',{labels2}) );
  title('various approximations of x');
  subplot(2,2,4); montage2( diffs, struct('labels',{labels}) );
  title('difference images');
  if (~isempty(fname))
    print( [fname '_eigenanalysis.jpg'], '-djpeg' );
  end

elseif( nd==4 ) % videos
  %%% create movies
  if( nargout>0 ); figureResized(.6,show+1); clf;
    M = playMovie( xhats, [], [], struct('labels',{labels2}) );
    varargout={M};
  end;
  if( nargout>1 ); figureResized(.6,show+1); clf;
    MDiff = playMovie( diffs );
    varargout{2} = MDiff;
  end;
  if( nargout>2 ); figureResized(.6,show+1); clf;
    MU = playMovie( Uim );
    varargout{3} = MU;
  end;

  %%% optionally record image and movie
  if (~isempty(fname))
    print( [fname '_decay.jpg'], '-djpeg' );
    compr = { 'Compresion', 'Cinepak' };
    if( nargout>0 ); movie2avi(M, [fname '.avi'], compr{:} ); end
    if( nargout>1 ); movie2avi(MDiff,[fname '_diff.avi'],compr{:} ); end;
    if( nargout>2 ); movie2avi(MU,'prineigenimages.avi',compr{:} ); end;
  end
end
