% Calculates the Euclidean distance between vectors [FAST].
%
% Assume X is an m-by-p matrix representing m points in p-dimensional space and Y is an
% n-by-p matrix representing another set of points in the same space. This function
% compute the m-by-n distance matrix D where D(i,j) is the SQUARED Euclidean distance
% between X(i,:) and Y(j,:).  Running time is O(m*n*p).
%
% If x is a single data point, here is a faster, inline version to use:
%   D = sum( (Y - ones(size(Y,1),1)*x).^2, 2 )';
%
% INPUTS
%   X   - m-by-p matrix of m p dimensional vectors 
%   Y   - n-by-p matrix of n p dimensional vectors 
%
% OUTPUTS
%   D   - m-by-n distance matrix
%
% EXAMPLE
%   X=[randn(100,5)]; Y=randn(40,5)+2;
%   D = dist_euclidean( [X; Y], [X; Y] ); im(D)
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also DIST_CHISQUARED, DIST_EMD

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function D = dist_euclidean( X, Y )
    if( ~isa(X,'double') || ~isa(Y,'double'))
        error( 'Inputs must be of type double'); end;
    m = size(X,1); n = size(Y,1);  
    Yt = Y';  
    XX = sum(X.*X,2);        
    YY = sum(Yt.*Yt,1);      
    D = XX(:,ones(1,n)) + YY(ones(1,m),:) - 2*X*Yt;
    
    
    

%%%% code from Charles Elkan with variables renamed
%    m = size(X,1); n = size(Y,1);
%    D = sum(X.^2, 2) * ones(1,n) + ones(m,1) * sum(Y.^2, 2)' - 2.*X*Y';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    
%%%% LOOP METHOD - SLOW
%     [m p] = size(X);  
%     [n p] = size(Y);
%     
%     D = zeros(m,n);
%     ones_m_1 = ones(m,1);
%     for i=1:n
%         y = Y(i,:);
%         d = X - y(ones_m_1,:);
%         D(:,i) = sum( d.*d, 2 );  
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% PARALLEL METHOD THAT IS SUPER SLOW (slower then loop)!
% % Code taken from "MATLAB array manipulation tips and tricks" by Peter J. Acklam
%     Xb = permute(X, [1 3 2]);  
%     Yb = permute(Y, [3 1 2]);
%     D = sum( (Xb(:,ones(1,n),:) - Yb(ones(1,m),:,:)).^2, 3);    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


%%%%% USELESS FOR EVEN VERY LARGE ARRAYS X=16000x1000!! and Y=100x1000
%     % call recursively to save memory
%     if( (m+n)*p > 10^5 && (m>1 || n>1))
%         if( m>n )
%             X1 = X(1:floor(end/2),:);
%             X2 = X((floor(end/2)+1):end,:);
%             D1 = dist_euclidean( X1, Y );
%             D2 = dist_euclidean( X2, Y );
%             D = cat( 1, D1, D2 );
%         else
%             Y1 = Y(1:floor(end/2),:);
%             Y2 = Y((floor(end/2)+1):end,:);
%             D1 = dist_euclidean( X, Y1 );
%             D2 = dist_euclidean( X, Y2 );
%             D = cat( 2, D1, D2 );
%         end
%         return;
%     end 
%        
