% Wrapper for ecoc that makes ecoc compatible with nfoldxval.
%
% Requires the SVM toolbox by Anton Schwaighofer.
%
% INPUTS
%   p               - data dimension
%   clfinit         - binary classifier init (see nfoldxval)
%   clfparams       - binary classifier parameters (see nfoldxval)
%   nclasses        - number of classes (currently only 3<=nclasses<=7 suppored)
%   use01targets    - see ecoc
%
% OUTPUTS
%   clf             - see ecoc
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also ECOC, NFOLDXVAL, CLF_ECOC_CODE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function clf = clf_ecoc(p,clfinit,clfparams,nclasses,use01targets)
    if( nclasses<3 || nclasses>7 )
        error( 'currently only works if 3<=nclasses<=7'); end;
    if( nargin<5 || isempty(use01targets)) use01targets=0; end;
    
    % create code (limited for now)
    [C,nbits] = clf_ecoc_code( nclasses );
    clf = ecoc(nclasses, nbits, C );
    clf.verbosity = 0; % don't diplay output

    % initialize and temporarily store binary learner
    clf.templearner = feval( clfinit, p, clfparams{:} );

    % ecoctrain2 is custom version of ecoctrain
    clf.fun_train = @clf_ecoctrain;
    clf.fun_fwd = @ecocfwd;
    
    
function clf = clf_ecoctrain( clf, varargin )
    clf = ecoctrain( clf, clf.templearner, varargin{:} );
