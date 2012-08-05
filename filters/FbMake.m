function FB = FbMake( dim, flag, show )
% Various 1D/2D/3D filterbanks (hardcoded).
%
% USAGE
%  FB = FbMake( dim, flag, [show] )
%
% INPUTS
%  dim     - dimension
%  flag    - controls type of filterbank to create
%          - if d==1
%            1: gabor filter bank for spatiotemporal stuff
%          - if d==2
%            1: filter bank from Serge Belongie
%            2: 1st/2nd order DooG filters.  Similar to Gabor filterbank.
%            3: similar to Laptev&Lindberg ICPR04
%            4: decent seperable steerable? filterbank
%            5: berkeley filterbank for textons papers
%            6: symmetric DOOG filters
%          - if d==3
%            1: decent seperable steerable filterbank
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%
% EXAMPLE
%  FB = FbMake( 2, 1, 1 ); 
%
% See also FBAPPLY2D
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(show) ); show=0; end

% create FB
switch dim
  case 1
    FB = FbMake1D( flag );
  case 2
    FB = FbMake2D( flag );
  case 3
    FB = FbMake3d( flag );
  otherwise
    error( 'dim must be 1 2 or 3');
end

% display
FbVisualize( FB, show );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FB = FbMake1D( flag )
switch flag
  case 1  %%% gabor filter bank for spatiotemporal stuff
    omegas = 1 ./ [3 4 5 7.5 11];
    sigmas =      [3 4 5 7.5 11];
    FB = FbMakegabor1D( 15, sigmas, omegas );

  otherwise
    error('none created.');
end

function FB = FbMakegabor1D( r, sigmas, omegas )
for i=1:length(omegas)
  [feven,fodd]=filterGabor1d(r,sigmas(i),omegas(i));
  if( i==1 ); FB=repmat(feven,[2*length(omegas) 1]); end
  FB(i*2-1,:)=feven; FB(i*2,:)=fodd;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FB = FbMake2D( flag )

switch flag
  case 1  %%% filter bank from Berkeley / Serge Belongie
    r=15;
    FB = FbMakegabor( r, 6, 3, 3, sqrt(2) );
    FB2 = FbMakeDOG( r, .6, 2.8, 4);
    FB = cat(3, FB, FB2);
    %FB = FB(:,:,1:2:36); %include only even symmetric filters
    %FB = FB(:,:,2:2:36); %include only odd symmetric filters

  case 2 %%% 1st/2nd order DooG filters.  Similar to Gabor filterbank.
    FB = FbMakeDooG( 15, 6, 3, 5, .5) ;

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
    FB2 = FbMakeDOG( r, .6, 2.8, 4);
    FB = cat(3, FB, FB2);

  case 5  %%% berkeley filterbank for textons papers
    FB = FbMakegabor( 7, 6, 1, 2, 2 );

  case 6  %%% symmetric DOOG filters
    FB = FbMakeDooGSym( 4, 2, [.5 1] );

  otherwise
    error('none created.');
end

function FB = FbMakegabor( r, nOrient, nScales, lambda, sigma )
% multi-scale even/odd gabor filters. Adapted from code by Serge Belongie.
cnt=1;
for m=1:nScales
  for n=1:nOrient
    [F1,F2]=filterGabor2d(r,sigma^m,lambda,180*(n-1)/nOrient);
    if(m==1 && n==1); FB=repmat(F1,[1 1 nScales*nOrient*2]); end
    FB(:,:,cnt)=F1;  cnt=cnt+1;   FB(:,:,cnt)=F2;  cnt=cnt+1;
  end
end

function FB = FbMakeDooGSym( r, nOrient, sigs )
% Adds symmetric DooG filters.  These are similar to gabor filters.
cnt=1; dims=[2*r+1 2*r+1];
for s=1:length(sigs)
  Fodd = -filterDoog( dims, [sigs(s) sigs(s)], [1 0], 0 );
  Feven = filterDoog( dims, [sigs(s) sigs(s)], [2 0], 0 );
  if(s==1); FB=repmat(Fodd,[1 1 length(sigs)*nOrient*2]); end
  for n=1:nOrient
    theta = 180*(n-1)/nOrient;
    FB(:,:,cnt) = imrotate( Feven, theta, 'bil', 'crop' );  cnt=cnt+1;
    FB(:,:,cnt) = imrotate( Fodd,  theta, 'bil', 'crop' );  cnt=cnt+1;
  end
end

function FB = FbMakeDooG( r, nOrient, nScales, lambda, sigma )
% 1st/2nd order DooG filters.  Similar to Gabor filterbank.
% Defaults: nOrient=6, nScales=3, lambda=5, sigma=.5,
cnt=1; dims=[2*r+1 2*r+1];
for m=1:nScales
  sigma = sigma * m^.7;
  Fodd = -filterDoog( dims, [sigma lambda*sigma^.6], [1,0], 0 );
  Feven = filterDoog( dims, [sigma lambda*sigma^.6], [2,0], 0 );
  if(m==1); FB=repmat(Fodd,[1 1 nScales*nOrient*2]); end
  for n=1:nOrient
    theta = 180*(n-1)/nOrient;
    FB(:,:,cnt) = imrotate( Feven, theta, 'bil', 'crop' );  cnt=cnt+1;
    FB(:,:,cnt) = imrotate( Fodd,  theta, 'bil', 'crop' );  cnt=cnt+1;
  end
end

function FB = FbMakeDOG( r, sigmaStr, sigmaEnd, n )
% adds a serires of difference of Gaussian filters.
sigs = sigmaStr:(sigmaEnd-sigmaStr)/(n-1):sigmaEnd;
for s=1:length(sigs)
  FB(:,:,s) = filterDog2d(r,sigs(s),2); %#ok<AGROW>
  if( s==1 ); FB=repmat(FB,[1 1 length(sigs)]); end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FB = FbMake3d( flag )

switch flag
  case 1 % decent seperable steerable filterbank
    r = 25; dims=[2*r+1 2*r+1 2*r+1];
    sigs = [.5 1.5 3];
    derivs = [0 0 1; 0 1 0; 1 0 0; 0 0 2; 0 2 0; 2 0 0];
    cnt=1; nderivs = size(derivs,1);
    for s=1:length(sigs)
      for i=1:nderivs
        dG = filterDoog( dims, repmat(sigs(s),[1 3]), derivs(i,:), 0 );
        if(s==1 && i==1); FB=repmat(dG,[1 1 1 nderivs*length(sigs)]); end
        FB(:,:,:,cnt) = dG; cnt=cnt+1;
      end
    end

  otherwise
    error('none created.');
end
