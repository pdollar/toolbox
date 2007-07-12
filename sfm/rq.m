function [R,Q]=rq(A)
% Reference: HZ2, p579

[Q,R] = qr(A(end:-1:1,end:-1:1)');
Q = Q(end:-1:1,end:-1:1)';
R = R(end:-1:1,end:-1:1)';

if det(Q)<0; R = -R; Q = -Q; end
