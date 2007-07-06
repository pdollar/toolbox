% Apply the decision tree to data X.
%
% USAGE
%  Y = clf_dectree_fwd( clf, X )
%
% INPUTS
%  clf     - trained model
%  X       - nxp data array
%
% OUTPUTS
%  Y       - nx1 vector of labels predicted according to the clf
%
% EXAMPLE
%
% See also CLF_DECTREE

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function Y = clf_dectree_fwd( clf, X )

if(~strcmp(clf.type,'dectree')); error( ['incor. type: ' clf.type] ); end;
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end;
T = clf.T;

[Y,d,cnames] = treeval( T, X );
Y = str2double( cnames ); % convert Y back to an int format
