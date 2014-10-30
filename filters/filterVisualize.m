function filterVisualize( f, show, arg )
% Used to visualize a 1D/2D/3D filter.
%
% For 1d filters:
%  Marks local filter maxima with a green '+' and minima with a red '+'.
%  Also shows the fft response of the filter.
%
% For 2d filters:
%  Marks local filter maxima with a green '+' and minima with a red '+'.
%  Also shows the fft response of the filter.  Can optionally also plot a
%  scanline through either center row/column.
%
% For 3d filters:
%  Dark lobes correspond to negative areas.  Surfaces shown are drawn at a
%  percentage of the peak filter response detemined by frac.
%
% USAGE
%  filterVisualize( f, [show], [arg] )
%
% INPUTS
%  f         - filter to visualize
%  show      - [1] figure to use for display (0->uses current)
%  arg       - different meanding depending on dimension
%              d=1: [] not used
%              d=2: [''] 'row' OR 'col': display centeral row OR col line
%              d=3: [.1] frac of max value of f at which to draw surfaces
%
% OUTPUTS
%
% EXAMPLE
%  f=filterBinomial1d( 10, 0 ); filterVisualize( f, 1 ); %1d
%  f=filterDog2d( 15, 10, 1 ); filterVisualize( f, 2, 'row' ); %2d
%  f=filterDoog([51 51 99],[3 3 5],[1 2 3],0); filterVisualize(f,4,.1); %3d
%
% See also FILTERGAUSS, FBVISUALIZE
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 || isempty(show) ); show=1; end;
if( nargin<3 || isempty(arg) ); arg=[]; end;
nd = ndims(f); if(isvector(f)); nd=1; end;
if( show>0); figure( show ); clf; end;

switch nd
  case 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    r = (length(f)-1)/2;
    f( abs(f)<1e-10 ) = 0;

    % show original filter
    subplot(2,1,1); plot(-r:r, f);
    hold('on'); plot(0,0,'m+');
    h = line([-r,r],[0,0]); set(h,'color','green')
    xlim( [-r, r] );
    title(inputname(1));

    % plot local mins/maxs in f
    locMaxs = find(imregionalmax(f));
    locMins = find(imregionalmin(f));
    plot( locMaxs-r-1, f(locMaxs), 'g+');
    plot( locMins-r-1, f(locMins), 'r+');
    hold('off');

    % plot fft magnitude of f
    subplot(2,1,2);
    stem( (-r:r) / (2*r+1), abs( fftshift( fft( f ) )) );
    title('Fourier spectra');


  case 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    scanline=arg; if( isempty(scanline) ); scanline=''; end

    f( abs(f)<1e-10 ) = 0;

    % image of filter
    subplot(2,1,1); im(f);
    title(inputname(1));
    hold('on');

    % plot maxes and mins in f
    locMaxs = imregionalmax(f); locMaxs([1 end],[1 end])=0;
    [locMaxs1,locMaxs2] = find(locMaxs);
    plot( locMaxs2, locMaxs1, 'g+');
    locMins = imregionalmin(f); locMins([1 end],[1 end])=0;
    [locMins1,locMins2] = find(locMins);
    plot( locMins2, locMins1, 'r+');

    % show fft response
    subplot(2,1,2);
    FF = abs(fftshift(fft2(f)));
    im(FF); title('Fourier spectra');

    % optionally plot central row/col scanline
    if(strcmp(scanline,'row') || strcmp(scanline,'col'))
      if( strcmp(scanline,'row') )
        sc = f( round((size(f,1)-1)/2+1), : );
      else
        sc = f( :, round((size(f,2)-1)/2+1) );
      end
      figure(show+1);  plot( sc ); hold('on');  title(scanline);
      locMaxs = find(imregionalmax(sc));
      locMins = find(imregionalmin(sc));
      plot( locMaxs, sc(locMaxs), 'g+');
      plot( locMins, sc(locMins), 'r+');
      hold('off');
    end

  case 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    frac=arg; if( isempty(frac) ); frac = .1; end

    % better visualization this way, t left to right
    f = flipdim( permute( f, [3, 1, 2] ), 1 );

    % approximate display as surface (may miss lots of lobes!!!)
    maxval = max(abs(f(:)));
    washeld = ishold;  if(~washeld); hold('on'); end
    p = patch(isosurface( f>frac*maxval, 0 ));
    set(p,'FaceColor',[.9 .9 .9],'EdgeColor','none'); % light gray lobes
    p2 = patch(isosurface( f<-frac*maxval, 0 ));
    set(p2,'FaceColor',[.4 .4 .4],'EdgeColor','none'); % dark gray lobes

    % set view
    daspect([1 1 1]); view(3); axis tight;
    camlight; lighting gouraud; set(gca,'Box','on');
    set(gca,'YTick',[]); set(gca,'XTick',[]); set(gca,'ZTick',[]);
    xlabel('y'); ylabel('t'); zlabel('x');
    if(~washeld); hold('off'); end

  otherwise %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    error('f must be 1 2 or 3 dimensional');

end;
