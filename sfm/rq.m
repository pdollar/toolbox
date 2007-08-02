% Perform RQ decomposition
% 
% Returns an upper-triangular matrixR and an unitary matrix Q such that
% A=R*Q
%
% USAGE
%  [R,Q]=rq(A)
%
% INPUTS
%  A       - input matrix
%
% OUTPUTS
%  R       - upper-triangular matrix
%  Q       - unitary matrix
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [R,Q]=rq(A)
% Reference: HZ2, p579

[Q,R] = qr(A(end:-1:1,end:-1:1)');
Q = Q(end:-1:1,end:-1:1)';
R = R(end:-1:1,end:-1:1)';

if det(Q)<0; R = -R; Q = -Q; end
