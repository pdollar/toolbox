% Various 2D filterbanks (hardcoded).
%
% USAGE
%  FB = FB_make_2D( flag, [show] )
%
% INPUTS
%  flag    - controls type of filterbank to create
%            1: filter bank from Serge Belongie
%            2: 1st/2nd order DooG filters.  Similar to Gabor filterbank.
%            3: similar to Laptev&Lindberg ICPR04
%            4: decent seperable steerable? filterbank
%            5: berkeley filterbank for textons papers
%            6: symmetric DOOG filters
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  FB      - filter bank
%
% EXAMPLE
%  FB = FB_make_2D( 1, 1 );
%
% See Also

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function FB = FB_make_2D( flag, show )

if( nargin<2 || isempty(show) ); show=0; end

switch flag
  case 1  %%% filter bank from Berkeley / Serge Belongie
    r=15;
    FB = FB_make_gabor( r, 6, 3, 3, sqrt(2) );
    FB2 = FB_make_DOG( r, .6, 2.8, 4);
    FB = cat(3, FB, FB2);
    %FB = FB(:,:,1:2:36); %include only even symmetric filters
    %FB = FB(:,:,2:2:36); %include only odd symmetric filters

  case 2 %%% 1st/2nd order DooG filters.  Similar to Gabor filterbank.
    FB = FB_make_DooG( 15, 6, 3, 5, .5) ;

  case 3 %%% similar to Laptev&Lindberg ICPR04
    % Wierd filterbank of Gaussian derivatives at various scales
    % Higher order filters probably not useful.
    r = 9;   dims=[2*r+1 2*r+1];
    sigs = [.5 1 1.5 3]; % sigs = [1,1.5,2];

    derivs = [];
    %derivs = [ derivs; 0 0 ]; % 0th order
    %derivs = [ derivs; 1 0; 0 1 ]; % first order
    %derivs = [ derivs; 2 0; 0 2; 1 1 ]; % 2nd order
    %derivs = [ derivs; 3 0; 0 3; 1 2; 2 1 ]; % 3rd order
    %derivs = [ derivs; 4 0; 0 4; 1 3; 3 1; 2 2 ]; % 4th order
    derivs = [ derivs; 0 1; 0 2; 0 3; 0 4; 0 5]; % 0n order
    derivs = [ derivs; 1 0; 2 0; 3 0; 4 0; 5 0]; % n0 order
    cnt=1;  nderivs = size(derivs,1);
    for s=1:length(sigs)
      for i=1:nderivs
        dG = filterDoog( dims, [sigs(s) sigs(s)], derivs(i,:), 0 );
        if(s==1 && i==1); FB=repmat(dG,[1 1 length(sigs)*nderivs]); end
        FB(:,:,cnt) = dG; cnt=cnt+1;
        %dG = filterDoog( dims, [sigs(s)*3 sigs(s)], derivs(i,:), 0 );
        %FB(:,:,cnt) = dG; cnt=cnt+1;
        %dG = filterDoog( dims, [sigs(s) sigs(s)*3], derivs(i,:), 0 );
        %FB(:,:,cnt) = dG; cnt=cnt+1;
      end
    end

  case 4 % decent seperable steerable? filterbank
    r = 9;   dims=[2*r+1 2*r+1];
    sigs = [.5 1.5 3];
    derivs = [1 0; 0 1; 2 0; 0 2];
    cnt=1;  nderivs = size(derivs,1);
    for s=1:length(sigs)
      for i=1:nderivs
        dG = filterDoog( dims, [sigs(s) sigs(s)], derivs(i,:), 0 );
        if(s==1 && i==1); FB=repmat(dG,[1 1 length(sigs)*nderivs]); end
        FB(:,:,cnt) = dG; cnt=cnt+1;
      end
    end
    FB2 = FB_make_DOG( r, .6, 2.8, 4);
    FB = cat(3, FB, FB2);

  case 5  %%% berkeley filterbank for textons papers
    FB = FB_make_gabor( 7, 6, 1, 2, 2 );

  case 6  %%% symmetric DOOG filters
    FB = FB_make_DooG_sym( 4, 2, [.5 1] );

  otherwise
    error('none created.');
end

% display
FB_visualize( FB, show );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% multi-scale even/odd gabor filters. Adapted from code by Serge Belongie.
function FB = FB_make_gabor( r, num_ori, num_scales, lambda, sigma )
cnt=1;
for m=1:num_scales
  for n=1:num_ori
    [F1,F2]=filter_gabor_2D(r,sigma^m,lambda,180*(n-1)/num_ori);
    if(m==1 && n==1); FB=repmat(F1,[1 1 num_scales*num_ori*2]); end
    FB(:,:,cnt)=F1;  cnt=cnt+1;   FB(:,:,cnt)=F2;  cnt=cnt+1;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adds symmetric DooG filters.  These are similar to gabor filters.
function FB = FB_make_DooG_sym( r, num_ori, sigs )
cnt=1; dims=[2*r+1 2*r+1];
for s=1:length(sigs)
  Fodd = -filterDoog( dims, [sigs(s) sigs(s)], [1 0], 0 );
  Feven = filterDoog( dims, [sigs(s) sigs(s)], [2 0], 0 );
  if(s==1); FB=repmat(Fodd,[1 1 length(sigs)*num_ori*2]); end
  for n=1:num_ori
    theta = 180*(n-1)/num_ori;
    FB(:,:,cnt) = imrotate( Feven, theta, 'bil', 'crop' );  cnt=cnt+1;
    FB(:,:,cnt) = imrotate( Fodd,  theta, 'bil', 'crop' );  cnt=cnt+1;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1st/2nd order DooG filters.  Similar to Gabor filterbank.
% Defaults: num_ori=6, num_scales=3, lambda=5, sigma=.5,
function FB = FB_make_DooG( r, num_ori, num_scales, lambda, sigma )
cnt=1; dims=[2*r+1 2*r+1];
for m=1:num_scales
  sigma = sigma * m^.7;
  Fodd = -filterDoog( dims, [sigma lambda*sigma^.6], [1,0], 0 );
  Feven = filterDoog( dims, [sigma lambda*sigma^.6], [2,0], 0 );
  if(m==1); FB=repmat(Fodd,[1 1 num_scales*num_ori*2]); end
  for n=1:num_ori
    theta = 180*(n-1)/num_ori;
    FB(:,:,cnt) = imrotate( Feven, theta, 'bil', 'crop' );  cnt=cnt+1;
    FB(:,:,cnt) = imrotate( Fodd,  theta, 'bil', 'crop' );  cnt=cnt+1;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adds a serires of difference of Gaussian filters.
function FB = FB_make_DOG( r, sigma_st, sigma_end, n )
sigs = sigma_st:(sigma_end-sigma_st)/(n-1):sigma_end;
for s=1:length(sigs)
  FB(:,:,s) = filter_DOG_2D(r,sigs(s),2);
  if( s==1 ); FB=repmat(FB,[1 1 length(sigs)]); end
end
