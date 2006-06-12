% Calculate optical flow using Lucas & Kanade.  Fast, parallel code.
%
% Note that the window of integration can either be a hard square window of radius win_n
% or it can be a soft 'gaussian' window with sigma win_sig.  In general the soft window
% should be more accurate.
%
% INPUTS
%   I1, I2  - input images to calculate flow between
%   win_n   - window radius for hard window (should be [] if win_sig is provided)
%   win_sig - [optional] sigma for soft 'gauss' window (should be [] if win_n is provided)
%   sigma   - [optional] amount to smooth by (may be 0)
%   thr     - [optional] ABSOLUTE reliability threshold (min eigenvalue), [default: 3e-6]
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   Vx, Vy  - x,y components of optical flow [Vx>0 -> flow is right, Vy>0 -> flow is down]
%   reliab  - reliability of optical flow in given window (cornerness of window)  
%
% EXAMPLE
%   % create square + translated square (B) + rotated square (C)
%   A=zeros(50,50); A(16:35,16:35)=1;
%   B=zeros(50,50); B(17:36,17:36)=1;
%   C=imrotate(A,5,'bil','crop'); 
%   optflow_lucaskanade( A, B, [], 2, 2, 3e-6, 1 );
%   optflow_lucaskanade( A, C, [], 2, 2, 3e-6, 4 );
%   % compare on stored real images (of mice)
%   load optflow_data;
%   [Vx,Vy,reliab] = optflow_lucaskanade( I5A, I5B, [], 4, 1.2, 3e-6, 1 );
%   [Vx,Vy,reliab] = optflow_corr( I5A, I5B, 3, 5, 1.2, .01, 2 );
%   [Vx,Vy] = optflow_horn( I5A, I5B, 2, 3 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also OPTFLOW_HORN, OPTFLOW_CORR

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [Vx,Vy,reliab]=optflow_lucaskanade( I1, I2, win_n, win_sig, sigma, thr, show )
    if( nargin<4 || isempty(win_sig))  win_sig=[]; end;
    if( nargin<5 || isempty(sigma)) sigma=1; end;
    if( nargin<6 || isempty(thr))  thr=3e-6; end;
    if( nargin<7 || isempty(show)) show=0; end;
    
    %%% error check inputs
    if( ~isempty(win_n) && ~isempty(win_sig)) 
        error('Either win_n or win_sig should be empty!'); end;
    if( isempty(win_n) && isempty(win_sig)) 
        error('Either win_n or win_sig must be non-empty!'); end;
    if( ndims(I1)~=2 || ndims(I2)~=2 ) error('Only works for 2d input images.'); end
    if( any(size(I1)~=size(I2)) ) error('Input images must have same dimensions.'); end
    
    %%% convert to double in range [0,1]
    if( isa(I1,'uint8') )
        I1=double(I1)/255; I2=double(I2)/255;
    else
        if( ~isa(I1,'double')) 
            I1=double(I1); I2=double(I2); 
        end;
        if( abs(max([I1(:); I2(:)]))>1 ) 
            minval = min([I1(:); I2(:)]);  I1=I1-minval;  I2=I2-minval;  
            maxval = max([I1(:); I2(:)]);  I1=I1/maxval;  I2=I2/maxval;
        end;
    end;    

    %%% smooth images (using the 'smooth' flag causes this to be slow)
    I1 = gauss_smooth(I1,sigma,'same');
    I2 = gauss_smooth(I2,sigma,'same');

    %%% Compute components of outer product of gradient of frame 1
    [Gx,Gy]=gradient(I1);
    Gxx=Gx.^2;  Gxy=Gx.*Gy;   Gyy=Gy.^2;
    if( isempty(win_sig) )
        win_mask = ones(2*win_n+1); 
        win_mask = win_mask / sum(win_mask(:));
        Axx=conv2(Gxx,win_mask,'same');
        Axy=conv2(Gxy,win_mask,'same');
        Ayy=conv2(Gyy,win_mask,'same');
    else
        win_n = ceil(win_sig);
        Axx=gauss_smooth(Gxx,win_sig,'same',2);
        Axy=gauss_smooth(Gxy,win_sig,'same',2);
        Ayy=gauss_smooth(Gyy,win_sig,'same',2);
    end;
    
    %%% Find determinant, trace, and eigenvalues of A'A
    detA=Axx.*Ayy-Axy.^2;  
    trA=Axx+Ayy;
    V1=0.5*sqrt(trA.^2-4*detA);
    lambda0=0.5*trA+V1; lambda1=0.5*trA-V1; 

    %%% Compute inner product of gradient with time derivative
    It=I2-I1;    IxIt=-Gx.*It;   IyIt=-Gy.*It;
    if( isempty(win_sig) )
        ATbx=conv2(IxIt,win_mask,'same');
        ATby=conv2(IyIt,win_mask,'same');
    else
        ATbx=gauss_smooth(IxIt,win_sig,'same',2);
        ATby=gauss_smooth(IyIt,win_sig,'same',2);
    end;

    %%% Compute components of velocity vectors
    Vx=(1./(detA+eps)).*(Ayy.*ATbx-Axy.*ATby);
    Vy=(1./(detA+eps)).*(-Axy.*ATbx+Axx.*ATby);

    %%% Check for ill conditioned second moment matrices
    reliab = lambda1; 
    reliab([1:win_n end-win_n+1:end],:)=0;
    reliab(:,[1:win_n end-win_n+1:end])=0;
    Vx(reliab<thr) = 0;   Vy(reliab<thr) = 0;
    
    %%% show quiver plot on top of reliab
    if( show )
        figure(show); show=show+1;  clf; im( I1 );
        hold('on'); quiver( Vx, Vy, 0,'-b' ); hold('off');
        %figure(show); show=show+1;  clf; im( I2 );
        %figure(show); show=show+1;  clf; im( I1 );
        %figure(show); show=show+1;  clf; im( I2 );
        %figure(show); show=show+1;  clf; im( Vx );
        %figure(show); show=show+1;  clf; im( Vy );
        %reliab2=reliab; reliab2( reliab>thr ) = thr;  
        %figure(show); show=show+1;  clf; im( log(reliab2+eps) ); 
        %figure(show); show=show+1;  clf; im( reliab ); 
    end

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OLD LOOP VERSION OF ABOVE
% % %     %%% gradient of E wrt x,y, 
% % %     [gEy,gEx] = gradient( I1 );
% % %     Et = (I2 - I1);                       
% % %     reliab = zeros( size(I1)-2*n );
% % %     Vx = reliab; Vy = reliab;
% % %     
% % %     %%% loop over each window
% % %     for r= 1:size(I1,1)-2*n
% % %         for c=1:size(I1,2)-2*n
% % %             gEx_rc = gEx(r:r+2*n, c:c+2*n);  
% % %             gEy_rc = gEy(r:r+2*n, c:c+2*n); 
% % %             Et_rc = Et(r:r+2*n, c:c+2*n);
% % %             
% % %             A = [ gEx_rc(:), gEy_rc(:) ];
% % %             b = -Et_rc(:);
% % %             
% % %             AtA = A'*A; detAtA = AtA(1)*AtA(4)-AtA(2)*AtA(3);
% % %             if( detAtA < eps )
% % %                 v = [0 0];
% % %                 reliab(r,c)=0;
% % %             else
% % %                 invA = ([AtA(4) -AtA(2); -AtA(3) AtA(1)] / detAtA) * A';
% % %                 v = invA * b;
% % %                 lambdas = eig(A'*A);  
% % %                 reliab(r,c) = min(lambdas);  %abs(min(lambdas)/max(lambdas));
% % %             end
% % % 
% % %             % record results
% % %             Vx(r,c) = v(2);
% % %             Vy(r,c) = v(1);
% % %         end;
% % %     end;
% % %     reliab = reliab / max([reliab(:); eps]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
