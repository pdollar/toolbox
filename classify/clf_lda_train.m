% Train a Linear Discriminant Analysis (LDA) classifier.
%
% INPUTS
%   clf     - model to be trained
%   X       - nxp data  array
%   Y       - nx1 array of labels (or cell array, see classify.m)
% 
% OUTPUTS
%   clf     - a trained clf_LDA model 
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also CLF_LDA, CLF_LDA_FWD

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function clf = clf_lda_train( clf, X, Y )
    if( ~strcmp( clf.type, 'lda' ) ) error( ['incorrect type: ' clf.type] ); end;
    if( size(X,2)~= clf.p ) error( 'Incorrect data dimension' ); end;
    %er = consist( clf, , X );  error(er);
    prior = clf.prior;  type = clf.clf_lda_type; 
    
    % grp2idx sorts a numeric grouping var ascending, and a string grouping
    % var by order of first occurrence
    [gindex,groups] = grp2idx(Y);  gtype = Y(1);
    ngroups = length(groups);
    gsize = hist(gindex,1:ngroups);
    [n,d] = size(X);
    
    %%% GET PRIOR ACCORDINGLY
    if isempty(prior)  
        % Default to a uniform prior
        prior = ones(1, ngroups) / ngroups;
    elseif ischar(prior) & ~isempty(strmatch(lower(prior), 'empirical'))
        % Estimate prior from relative Y sizes
        prior = gsize(:)' / sum(gsize);
    elseif isnumeric(prior)
        % Explicit prior
        if min(size(prior)) ~= 1 | max(size(prior)) ~= ngroups
            error('PRIOR must be a vector one element for each Y.');
        elseif any(prior < 0)
            error('PRIOR cannot contain negative values.'); end;
        prior = prior(:)' / sum(prior); % force a normalized row vector
    elseif isstruct(prior)
        [pgindex,pgroups] = grp2idx(prior.Y);
        ord = repmat(NaN,1,ngroups);
        for i = 1:ngroups
            j = strmatch(groups(i), pgroups(pgindex), 'exact');
            if ~isempty(j) ord(i) = j; end;
        end
        if any(isnan(ord)) 
            error('PRIOR.Y must contain all of the unique values in GROUP.'); end;
        prior = prior.prob(ord);
        if any(prior < 0)
            error('PRIOR.prob cannot contain negative values.'); end;
        prior = prior(:)' / sum(prior); % force a normalized row vector
    else
        error('PRIOR must be a a vector, a structure, or the string ''empirical''.');
    end


    %%% get means for each group
    gmeans = repmat(NaN, ngroups, d);
    for k = 1:ngroups
        gmeans(k,:) = mean(X(find(gindex == k),:),1);  end;


    %%% get R (or RS)
    switch type
    case 1 % 'linear'
        if n <= ngroups
            error('TRAINING must have more observs than the number of groups.'); end;
        
        % Pooled estimate of covariance
        [Q,R] = qr(X - gmeans(gindex,:), 0);
        R = R / sqrt(n - ngroups); % SigmaHat = R'*R
        s = svd(R);
        if any(s <= max(s) * eps(class(s))^(3/4))
            warning('The pooled cov matrix of TRAINING must be positive definite.'); end;
        clf.R = R;

    case {2,3} % 'quadratic' or 'mahalanobis'
        if any(gsize <= 1)
            error('Each Y in TRAINING must have at least two observations.'); end;
        
        for k = 1:ngroups
            % Stratified estimate of covariance
            [Q,R] = qr(X(find(gindex == k),:) - repmat(gmeans(k,:), gsize(k), 1), 0);
            R = R / sqrt(gsize(k) - 1); % SigmaHat = R'*R
            s = svd(R);
            if any(s <= max(s) * eps(class(s))^(3/4))
                error('The cov matrix of each Y in TRAINING must be pos definite.'); end;
            clf.RS{k}=R;
        end
    end 


    %%% store remaining clf variables
    clf.prior = prior;    
    clf.gmeans = gmeans;
    clf.gtype = gtype;
    clf.groups = groups;
    clf.ngroups = ngroups;
