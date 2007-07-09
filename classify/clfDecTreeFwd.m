% Apply the decision tree to data X.
%
% USAGE
%  Y = clfDecTreeFwd( clf, X )
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
% See also CLFDECTREE

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function Y = clfDecTreeFwd( clf, X )

if(~strcmp(clf.type,'dectree')); error( ['incor. type: ' clf.type] ); end;
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end;
T = clf.T;

[Y,d,cnames] = treeval( T, X );
Y = str2double( cnames ); % convert Y back to an int format
