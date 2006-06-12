% Various ways to make filterbanks.  See inside of this file for details.
%
% keep adding different filterbanks, don't alter old ones!
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB = FB_make_1D
    flag = 1;    

    if flag==1  % gabor filter bank for spatiotemporal stuff
        omegas = 1 ./ [3 4 5 7.5 11];
        sigmas =      [3 4 5 7.5 11];
        FB = mfb_gabor1D( 15, sigmas, omegas );
    end

    
    
        
function FB = mfb_gabor1D( r, sigmas, omegas )     
    counter=1;  
    for i=1:length(omegas)
        [feven,fodd]=filter_gabor_1D(r,sigmas(i),omegas(i));
        FB(counter,:)=feven;  counter=counter+1;
        FB(counter,:)=fodd;   counter=counter+1;
    end
    
    
    
%%%%%% Used to test filterbank response
% x=1:31; y=cos(2*pi*x* 1/5 ) + cos(2*pi*x* 1/7 ); y = y/max(y);
% resp = sum(repmat( y, 10,1 ).*FB, 2); stem(resp);
