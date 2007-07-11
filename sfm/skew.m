function A=skew(a)

if numel(e)==3
  % returns the skew matrix of a vector
  % Reference: HZ2, p581, equation (A4.5)
  A=[0 -a(3) a(2); a(3) 0 -a(1); -a(2) a(1) 0];
  return
end

if all(size(e)==[3,3])
  % returns the vector that created the closest skew matrix
  A=0.5*[ a(3,2)-a(2,3); a(1,3)-a(3,1); a(2,1)-a(1,2)];
  return
end

error('Bad input dimensions. Input must be 1x3, 3x1 or 3x3');