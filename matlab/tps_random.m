% Obtain a random warp with the same bending energy as the original.
%
% INPUTS
%   Ln_inv           - obtain from tps_getwarp (see Bookstein)
%   bend_energy     - amount of bening energy for random warp to have
%
% OUTPUTS
%   w               - nonlinear component of warp for use in tps_interpolate
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also TPS_GETWARP

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function w = tps_random( Ln_inv, bend_energy )
    n = size(Ln_inv,1);
    u = rand(n-3,1) - .5;
    u = u / norm(u);
    u = [u; 0; 0; 0];

    % get U, SIG, SIG_INV, requires some fanangling
    [U,SIG] = eig(Ln_inv); 
    U = real(U); SIG=real(SIG);
    SIG( find(abs(SIG)<.000001))=0;
    %SIG_INV = SIG; 
    %SIG_INV( find(abs(SIG)>.000001) ) = 1./SIG_INV( find(abs(SIG)>.000001) );

    % get w (and v?)
    %v = sqrt(bend_energy)* U * sqrt(SIG_INV) * u;
    w = sqrt(bend_energy)* U * sqrt(SIG) * u;
    
    %%% test to see if everything working as expected 
    return;
    sqrt(SIG_INV) * U' * Ln_inv * U * sqrt(SIG_INV) % should be eye(N) with 3 0's
    v' * Ln_inv * v, bend_energy  % should be equal
    
    
