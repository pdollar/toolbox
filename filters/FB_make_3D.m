% Various 3D filterbanks (hardcoded).
%
% USAGE
%  FB = FB_make_3D( flag, [show] )
%
% INPUTS
%  flag    - controls type of filterbank to create
%            1: decent seperable steerable filterbank
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  FB      - filter bank
%
% EXAMPLE
%  FB = FB_make_3D( 1, 1 );

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function FB = FB_make_3D( flag, show )

if( nargin<2 || isempty(show) ); show=0; end;

switch flag
  case 1 % decent seperable steerable filterbank
    r = 25; dims=[2*r+1 2*r+1 2*r+1];
    sigs = [.5 1.5 3];
    derivs = [0 0 1; 0 1 0; 1 0 0; 0 0 2; 0 2 0; 2 0 0];
    cnt=1; nderivs = size(derivs,1);
    for s=1:length(sigs)
      for i=1:nderivs
        dG = filter_DooG_nD( dims, repmat(sigs(s),[1 3]), derivs(i,:), 0 );
        if(s==1 && i==1); FB=repmat(dG,[1 1 1 nderivs*length(sigs)]); end
        FB(:,:,:,cnt) = dG; cnt=cnt+1;
      end
    end

  otherwise
    error('none created.');
end

% display
FB_visualize( FB, show );
