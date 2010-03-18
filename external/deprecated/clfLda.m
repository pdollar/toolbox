function clf = clfLda( p, type, prior )
% Create a Linear Discriminant Analysis (LDA) classifier.
%
% Same algorithm as matlab's function 'classify' (in the statistics
% toolbox).  Nice to have in form that actually stores a model that can be
% applied multiple times. For the meaning and usage of prior and type see
% classify.m 
%
% USAGE
%  clf = clfLda( p, [type], [prior] )
%
% INPUTS
%  p       - data dimension
%  type    - ['linear'] 'linear', 'quadratic', 'mahalanobis'
%  prior   - [] prior to use 
% 
% OUTPUTS
%  clf     - an LDA model ready to be trained (see clfLdaTrain)
%
% EXAMPLE
%
% See also NFOLDXVAL, CLASSIFY, CLFLDATRAIN, CLFLDAFWD
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<3 ); prior=[]; end

%%% get type
if( nargin < 2 || isempty(type) )
  type = 1; % 'linear'
elseif ischar(type)
  i = strmatch(lower(type), {'linear','quadratic','mahalanobis'});
  if( length(i)>1 );  
    error('Ambiguous value for TYPE:  %s.', type);
  elseif( isempty(i)); 
    error('Unknown value for TYPE:  %s.', type); 
  end;
  type = i;
else
  error('TYPE must be a string.'); 
end

%%% save clfLda parameters
clf.prior = prior;
clf.p = p;
clf.type = 'lda';
clf.clfLdaType = type;
clf.funTrain = @clfLdaTrain;
clf.funFwd = @clfLdaFwd;    
