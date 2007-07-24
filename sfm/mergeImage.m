function mergeImage( folderIn, folderOut )

folderIn='~/LDVM/input/';
tileSize=1000; sigma=5; nBand=10;

% read the given files and store their relative positions
d=dir([ folderIn '/*.mat' ]);
nIm=length(d);
boundXTot=zeros(nIm,2); boundYTot=zeros(nIm,2);
for n=1:nIm
  load([ folderIn d(n).name],'boundX','boundY');
  boundXTot(n,:)=boundX; boundYTot(n,:)=boundY;
end

g=bestGain();

% Create the different tiles of the big image
boundYTot=boundYTot-min(boundYTot(:))+1;
boundXTot=boundXTot-min(boundXTot(:))+1;

for y=1:ceil(max(boundYTot(:))/tileSize)
  for x=1:ceil(max(boundXTot(:))/tileSize)
    in=(boundXTot(:,1)>=((x-1)*tileSize+1)) & ...
      (boundXTot(:,2)<=x*tileSize) & (boundYTot(:,2)<=y*tileSize) & ...
      (boundYTot(:,1)>=((y-1)*tileSize+1));
    in=find(in);

    % Save the image
    ITot=bandBlend();
    minmax(ITot(:)')

    imwrite(uint8(ITot), [folderOut 'image-' int2str(y) '-' int2str(x)],...
      'png');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function g=bestGain()
    % Compute the best gain for each image. See help.pdf

    % fill Imean and N
    Imean=zeros(nIm); N=zeros(nIm);
    for i=1:nIm
      load([ folderIn d(i).name ], 'I');
      Ii=I; [yi xi]=find(~isnan(Ii));

      for j=i+1:nIm
        if (boundXTot(i,2)<boundXTot(j,1)) || ...
            (boundXTot(i,1)>boundXTot(j,2)) || ...
            (boundYTot(i,2)<boundYTot(j,1)) || ...
            (boundYTot(i,1)>boundYTot(j,2))
          continue % No overlap
        end
        load([ folderIn d(j).name ],'I');
        [yj xj]=find(~isnan(I));
        % Compute the pixels that overlap
        [indI,indJ]=ismember([yi-min(yi(:))+boundYTot(i,1) ...
          xi-min(xi(:))+boundXTot(i,1)],[yj-min(yj(:))+boundYTot(j,1) ...
          xj-min(xj(:))+boundXTot(j,1)],'rows');
        indJ=nonzeros(indJ);

        N(i,j)=sum(indI~=0); N(j,i)=N(i,j);
        Imean(i,j)=mean(Ii(sub2ind(size(Ii),yi(indI),xi(indI))));
        Imean(j,i)=mean(I(sub2ind(size(I),yj(indJ),xj(indJ))));
      end
    end

    % Compute the matrices used for the system in g
    sigmaN=10; sigmag=0.1;
    A=zeros(nIm); b=zeros(nIm,1);
    for i=1:nIm
      A(i,i)=nIm/sigmag^2;
      b(i)=nIm/sigmag^2;
      for j=i+1:nIm
        A(i,i)=A(i,i)+N(i,j)*(Imean(i,j)/sigmaN)^2;
        A(i,j)=-N(i,j)*Imean(i,j)*Imean(j,i)/sigmaN^2;
      end
    end
    g=A\b;

  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function ITot=bandBlend()
    num=0; denum=0;
    ISigPrev=cell(1,length(in)); WSigPrev=ISigPrev;
    ISig=ISigPrev; WSig=ISigPrev; ind=ISigPrev; WMax=ISigPrev;
    IPart=zeros(tileSize,tileSize,length(in)); WTot=IPart;
    for ii=1:length(in)
      load([ folderIn d(in(ii)).name],'I');

      % Crop and apply the gain, define W
      boundX=[(x-1)*tileSize+1 x*tileSize]-boundXTot(ii,1)+1;
      boundXMod=[max(boundX(1),1) min(boundX(2),size(I,2))];
      boundY=[(y-1)*tileSize+1 y*tileSize]-boundYTot(ii,1)+1;
      boundYMod=[max(boundY(1),1) min(boundY(2),size(I,1))];

      IPart((boundYMod(1):boundYMod(2))-boundY(1)+1, ...
        (boundXMod(1):boundXMod(2))-boundX(1)+1,ii)=...
        I(boundYMod(1):boundYMod(2),boundXMod(1):boundXMod(2))*g(ii);
      [X,Y]=meshgrid(1:size(I,2),1:size(I,1));
      W=(1-abs(X/(size(I,2)/2)-1)) .* (1-abs(Y/(size(I,1)/2)-1));

      WTot((boundYMod(1):boundYMod(2))-boundY(1)+1, ...
        (boundXMod(1):boundXMod(2))-boundX(1)+1,ii)=...
        W(boundYMod(1):boundYMod(2),boundXMod(1):boundXMod(2));

      ind{ii}=isnan(IPart(:,:,ii));
    end
    IPart(isnan(IPart))=0;
    % Define Wmax
    WTotMax=max(WTot,[],3);
    for ii=1:length(in); WMax{ii}=WTotMax==WTot(:,:,ii); end

    for ii=1:length(in)
      % Define the first band
      ISigPrev{ii}=gaussSmooth( IPart(:,:,ii), sigma, 'smooth');
      BSig=IPart(:,:,ii)-ISigPrev{ii};
      WSigPrev{ii}=gaussSmooth( double(WMax{ii}), sigma, 'smooth' );
      %BSig(ind{ii})=0; ISigPrev{ii}(ind{ii})=0; WSigPrev{ii}(ind{ii})=0;

      num=num+BSig.*WSigPrev{ii};
      denum=denum+WSigPrev{ii};
    end
    ITot=num./denum; ITot(isnan(ITot))=0;
    imshow(ITot,[]); drawnow;

    % do the following bands
    for k=2:nBand-1
      num=0; denum=0; sigmap=sqrt(2*k+1)*sigma;
      for ii=1:length(in)
        ISig{ii}=gaussSmooth( ISigPrev{ii}, sigmap, 'smooth' );
        BSig=ISigPrev{ii} - ISig{ii};
        WSig{ii}=gaussSmooth( WSigPrev{ii}, sigmap, 'smooth' );
        BSig(ind{ii})=0; ISig{ii}(ind{ii})=0; WSig{ii}(ind{ii})=0;

        num=num+BSig.*WSig{ii}; denum=denum+WSig{ii};
      end
      band=num./denum; band(isnan(band))=0;
      ITot=ITot+band;
      imshow(ITot,[]); drawnow;
      WSigPrev=WSig; ISigPrev=ISig;
    end
    % do the last band
    num=0; denum=0;
    for ii=1:length(in)
      num=num+ISigPrev{ii}.*WMax{ii}; denum=denum+WMax{ii};
    end
    band=num./denum; band(isnan(band))=0;
    imshow(band,[]); drawnow; pause
    ITot=ITot+band;

    imshow(ITot,[]); drawnow; pause
  end
end
