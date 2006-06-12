% Clustering demo.
%
% Used to test different clustering algorithms on 2D and 3D mixture of gaussian data.
% Alter demo by edititing this file.
% 
% All input arguments are optional.
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [IDX, X, k_true, noisefrac_true, IDX_true ] = ...
                    democluster( X, k, noisefrac, IDX_true )

    %%% GENERATE DATA
    if( nargin<3 ) 
        if(1) % mixture of gaussians -- see demogendata
            k_true = 4; sep = 3; ecc = 3; noisefrac_true = 0.1;  
            npoints = 1000;  dim = 2;  % dim may be 2 or 3
            [X,IDX_true] = demogendata(npoints,0,k_true,dim,sep,ecc,noisefrac_true);  
        else
            % two parallel clusters - kmeans will fail
            k_true = 2;  dim = 2;  npoints = 200;  sep = 4;
            X = [([5 0; 0 .5] * randn(2,npoints) + sep/2)' ; ...
                    ([5 0; 0 .5] * randn(2,npoints) - sep/2)' ] / 5;
            IDX_true = [ones(1,npoints) 2*ones(1,npoints)];
            noisefrac_true=0;
        end; 
        noisefrac = noisefrac_true;  k = k_true;
    elseif( nargin<4 ) 
        IDX_true = []; 
    end;
        
    
    %%% kmeans and results
    switch 'meanshift'
        case 'kmeans2'
            params = {'replicates', 4, 'display', 1, 'outlierfrac', noisefrac};
            [IDX,C,sumd] = kmeans2( X, k, params{:} );  sum(sumd)
        case 'meanshift'
            %(X,radius,rate,maxiter,minCsize,blur)
            [IDX,C] = meanshift( X, .3, .2, 100 , 10, 0 );
    end

    
    %%% show data & clustering results
    figure(1); clf;
    subplot(2,2,1); plot_clusters( X, ones(1,size(X,1)) ); title('original points');
    if(~isempty(IDX_true))
        subplot(2,2,2); plot_clusters( X, IDX_true ); title('true clusters'); end;
    subplot(2,2,3); plot_clusters( X, IDX, C ); title('clustering result');
    %subplot(2,2,4); distmatrix_show( dist_euclidean(X,X), IDX );

    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_clusters( X, IDX, C )
% 
% calls visualize_data
% also displays cluster centers
function plot_clusters( X, IDX, C )
    if(nargin<3) C=[]; end;
    if( size(X,2)>3 ) error('unsupported dimension'); end;
    visualize_data( X, size(X,2), IDX );
    
    % plot cluster centers
    if( ~isempty(C) )
        IDX(IDX>12)=12;   c=1;  k=max(IDX);
        if( size(X,2)==2)
            for i=1:k  R{c}=C(i,1);  R{c+1}=C(i,2);  R{c+2}='x';  c=c+3;  end; 
            hold('on');  plot( R{:}, 'MarkerSize', 30 );  hold('off'); 
        elseif( size(X,2)==3 )
            for i=1:k R{c}=C(i,1);  R{c+1}=C(i,2);  R{c+2}=C(i,3); R{c+3}='x'; c=c+4; end; 
            hold('on'); plot3( R{:}, 'MarkerSize',30 );  hold('off'); 
        end
    end
