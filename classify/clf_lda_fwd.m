% Apply the Linear Discriminant Analysis (LDA) classifier to data X.
%
% INPUTS
%   clf     - trained model
%   X       - nxp data array
% 
% OUTPUTS
%   Y       - nx1 vector of labels predicted according to the model
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also CLF_LDA, CLF_LDA_TRAIN

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function Y = clf_LDAfwd( clf, X )
    if( ~strcmp( clf.type, 'lda' ) ) error( ['incorrect type: ' clf.type] ); end;
    if( size(X,2)~= clf.p ) error( 'Incorrect data dimension' ); end;
    
    %%% get clf settings
    type = clf.clf_lda_type;
    prior = clf.prior;
    gmeans = clf.gmeans;
    gtype = clf.gtype;
    groups = clf.groups;
    ngroups = clf.ngroups;
    
    %%% calculate D matrix
    n = size(X,1);  D = repmat(NaN, n, ngroups);
    switch type
    case 1 % 'linear'
        % MVN relative log posterior density, by group, for each X
        R = clf.R;
        for k = 1:ngroups
            A = (X - repmat(gmeans(k,:), n, 1)) / R;
            D(:,k) = log(prior(k)) - .5*sum(A .* A, 2);
        end
    case {2,3} % 'quadratic' or 'mahalanobis'
        for k = 1:ngroups
            R=clf.RS{k};
            A = (X - repmat(gmeans(k,:), n, 1)) / R;
            switch type
            case 2 % 'quadratic'
                % MVN relative log posterior density, by group, for each X
                D(:,k) = log(prior(k)) - .5*(sum(A .* A, 2) + log(prod(diag(R))^2));
            case 3 % 'mahalanobis'
                % Negative squared Mahalanobis distance, by group, for each
                % X.  Prior probabilities are not used
                D(:,k) = -sum(A .* A, 2);
            end
        end
    end    
        
    %%% find nearest group to each observation in X data
    [tmp Y] = max(D, [], 2);

    %%% Convert back to original grouping variable
    if isnumeric(gtype)
        groups = str2num(char(groups));
        Y = groups(Y);
    elseif ischar(gtype)
        groups = char(groups);
        Y = groups(Y,:);
    else %if iscellstr(group)
        Y = groups(Y);
    end
    
