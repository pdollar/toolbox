% Various 1D filterbanks (hardcoded).
%
% USAGE
%  FB = FB_make_1D( flag, [show] )
%
% INPUTS
%  flag    - controls type of filterbank to create
%            1: gabor filter bank for spatiotemporal stuff
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%
% EXAMPLE
%  FB = FB_make_1D( 1, 1 );

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB = FB_make_1D( flag, show )

if( nargin<2 || isempty(show) ); show=0; end;

switch flag
case 1  %%% gabor filter bank for spatiotemporal stuff
  omegas = 1 ./ [3 4 5 7.5 11];
  sigmas =      [3 4 5 7.5 11];
  FB = FB_make_gabor1D( 15, sigmas, omegas );
  
otherwise
  error('none created.');
end

% display
FB_visualize( FB, show );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FB = FB_make_gabor1D( r, sigmas, omegas )     
for i=1:length(omegas)
  [feven,fodd]=filter_gabor_1D(r,sigmas(i),omegas(i));
  if( i==1 ); FB=repmat(feven,[2*length(omegas) 1]); end;
  FB(i*2-1,:)=feven; FB(i*2,:)=fodd;
end

        