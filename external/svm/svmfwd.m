function [Y, Y1] = svmfwd(net, X)
% SVMFWD - Forward propagation through Support Vector Machine classifier
% 
%   Y = SVMFWD(NET, X)
%   For a data structure NET, the matrix of vectors X is input into the
%   Support Vector Machine described by NET and the matrix of outputs Y
%   is computed. NET must have non-empty fields NET.sv, NET.svcoeff and
%   NET.bias, these fields are set during training by SVMTRAIN.
%   X must contain one input vector per row. Y is a column vector with
%   one entry for each input vector in X. Y(i) is the SVM output for
%   input vector X(i,:), it is
%     +1, if X(i,:) is classified as belonging to class 1
%     -1, if X(i,:) is classified as belonging to class -1
%   [Y, Y1] = SVMFWD(NET, X) also gives the column vector Y1 containing
%   the SVM output before computing the sign. Y1(i) is equivalent to the
%   distance of point X(i,:) from the separating hyperplane.
%
%   See also
%   SVM, SVMTRAIN, SVMKERNEL
%

% 
% Copyright (c) Anton Schwaighofer (2001)
% $Revision: 1.2 $ $Date: 2002/01/07 19:53:06 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

% Check arguments for consistency
errstring = consist(net, 'svm', X);
if ~isempty(errstring);
  error(errstring);
end
[N d] = size(X);
if strcmp(net.kernel, 'linear'),
  if ~isfield(net, 'normalw') | ~all(size(net.normalw)==[1 d]),
    error('Structure NET does not contain a valid field ''normalw''');
  end
else
  if ~isfield(net, 'sv') | ((size(net.sv, 2)~=d) & ~isempty(net.sv)),
    error('Structure NET does not contain a valid field ''sv''');
  end
  nbSV = size(net.sv, 1);
  if nbSV~=size(net.svcoeff, 1),
    error('Structure NET does not contain a valid field ''svcoeff''');
  end
  if ~isfield(net, 'bias') | ~all(size(net.bias)==[1 1]),
    error('Structure NET does not contain a valid field ''bias''');
  end
end

if strcmp(net.kernel, 'linear'),
  Y1 = X*(net.normalw');
else
  chsize = net.chunksize;
  Y1 = zeros(N, 1);
  chunks1 = ceil(N/chsize);
  chunks2 = ceil(nbSV/chsize);
  for ch1 = 1:chunks1,
    ind1 = (1+(ch1-1)*chsize):min(N, ch1*chsize);
    for ch2 = 1:chunks2,
      ind2 = (1+(ch2-1)*chsize):min(nbSV, ch2*chsize);
      K12 = svmkernel(net, X(ind1, :), net.sv(ind2, :));
      Y1(ind1) = Y1(ind1)+K12*net.svcoeff(ind2);
    end
  end
end
Y1 = Y1+net.bias;
Y = sign(Y1);
Y(Y==0) = 1;
