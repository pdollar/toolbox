% Obtain a random warp with the same bending energy as the original.
%
% USAGE
%  w = tps_random( LnInv, bendE )
%
% INPUTS
%  warp   - [see tps_getwarp] bookstein warping parameters
%  bendE  - amount of bening energy for random warp to have
%
% OUTPUTS
%  w      - nonlinear component of warp for use in tps_interpolate
%
% DATESTAMP
%  15-Jan-2007  11:00am
%
% See also TPS_GETWARP

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function w = tps_random( LnInv, bendE )
  n = size(LnInv,1);
  u = rand(n-3,1) - .5;
  u = u / norm(u);
  u = [u; 0; 0; 0];

  % get U, SIG, SIG_INV, requires some fanangling
  [U,SIG] = eig(LnInv); 
  U = real(U); SIG=real(SIG);
  SIG( abs(SIG)<.000001)=0;
  %SIG_INV = SIG; 
  %SIG_INV(abs(SIG)>.000001) = 1./SIG_INV(abs(SIG)>.000001);

  % get w (and v?)
  %v = sqrt(bendE)* U * sqrt(SIG_INV) * u;
  w = sqrt(bendE)* U * sqrt(SIG) * u;

%   % should be eye(N) with 3 0's
%   sqrt(SIG_INV) * U' * LnInv * U * sqrt(SIG_INV) 
%   % should be equal
%   v' * LnInv * v, bendE  
    
    
