function w = tpsRandom( LnInv, bendE )
% Obtain a random warp with the same bending energy as the original.
%
% USAGE
%  w = tpsRandom( LnInv, bendE )
%
% INPUTS
%  LnInv  - [see tpsGetWarp] bookstein warping parameters
%  bendE  - amount of bening energy for random warp to have
%
% OUTPUTS
%  w      - nonlinear component of warp for use in tpsInterpolate
%
% EXAMPLE
%
% See also TPSGETWARP
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

n = size(LnInv,1);
u = rand(n-3,1) - .5;
u = u / norm(u);
u = [u; 0; 0; 0];

% get U, sig, sigInv, requires some fanangling
[U,sig] = eig(LnInv);
U = real(U); sig=real(sig);
sig( abs(sig)<.000001)=0;
%sigInv = sig;
%sigInv(abs(sig)>.000001) = 1./sigInv(abs(sig)>.000001);

% get w (and v?)
%v = sqrt(bendE)* U * sqrt(sigInv) * u;
w = sqrt(bendE)* U * sqrt(sig) * u;

% % should be eye(N) with 3 0's
% sqrt(sigInv) * U' * LnInv * U * sqrt(sigInv)
% % should be equal
% v' * LnInv * v, bendE
