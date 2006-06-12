% Create a Linear Discriminant Analysis (LDA) classifier.
%
% Same algorithm as matlab's function 'classify' (in the statistics toolbox).  Nice
% to have in form that actually stores a model that can be applied multiple times.
% 
% For the meaning and usage of prior and type see classify.m
%
% INPUTS
%   p       - data dimension
%   type    - [optional] 'linear', 'quadratic', 'mahalanobis' [see classify.m]
%   prior   - [optional] prior to use [see classify.m]
% 
% OUTPUTS
%   clf     - an clf_LDA model ready to be trained (see clf_lda_train)
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also NFOLDXVAL, CLASSIFY, CLF_LDA_TRAIN, CLF_LDA_FWD

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function clf = clf_lda( p, type, prior )
    if( nargin<3 ) prior = []; end;

    %%% get type
    if( nargin < 2 | isempty(type) )
        type = 1; % 'linear'
    elseif ischar(type)
        i = strmatch(lower(type), strvcat('linear','quadratic','mahalanobis'));
        if( length(i) > 1 )  error('Ambiguous value for TYPE:  %s.', type);
        elseif isempty(i) error('Unknown value for TYPE:  %s.', type); end;
        type = i;
    else error('TYPE must be a string.'); end;

    
    %%% save clf_lda parameters
    clf.prior = prior;
    clf.p = p;
    clf.type = 'lda';
    clf.clf_lda_type = type;
    clf.fun_train = @clf_lda_train;
    clf.fun_fwd = @clf_lda_fwd;    
