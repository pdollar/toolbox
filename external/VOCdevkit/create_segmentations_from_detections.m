% Creates segmentation results from detection results. 
% CREATE_SEGMENTATIONS_FROM_DETECTIONS(ID) creates segmentations from 
% the detection results with identifier ID e.g. 'comp3'. All detections
% will be used, no matter what their confidence level. Detections are
% ranked by increasing confidence, so more confident detections occlude
% less confident detections.
%
% CREATE_SEGMENTATIONS_FROM_DETECTIONS(ID, CONFIDENCE) as above, but only 
% detections above the specified confidence will be used.  
function create_segmentations_from_detections(id,confidence)

if nargin<2
    confidence = -inf;
end

% change this path if you install the VOC code elsewhere
addpath([cd '/VOCcode']);

% initialize VOC options
VOCinit; 

% load detection results 

n=0;
for clsnum = 1:VOCopts.nclasses
    % display progress
    fprintf('class %d/%d: load detections\n',clsnum,VOCopts.nclasses);
    drawnow;
        
    resultsfile = sprintf(VOCopts.detrespath,id,VOCopts.classes{clsnum});
    if ~exist(resultsfile,'file')
        error('Could not find detection results file to use to create segmentations (%s not found)',resultsfile);
    end
    [ids,confs,xmin,ymin,xmax,ymax]=textread(resultsfile,'%s %f %f %f %f %f');    
    t=[ids num2cell(ones(numel(ids),1)*clsnum) num2cell(confs) num2cell([xmin ymin xmax ymax],2)];
    dets(n+(1:numel(ids)))=cell2struct(t,{'id' 'clsnum' 'conf' 'bbox'},2);
    n=n+numel(ids);
end

% Write out the segmentations

segid=sprintf('comp%d',sscanf(id,'comp%d')+2);

resultsdir = sprintf(VOCopts.seg.clsresdir,segid,VOCopts.testset);
resultsdirinst = sprintf(VOCopts.seg.instresdir,segid,VOCopts.testset);

if ~exist(resultsdir,'dir')
    mkdir(resultsdir);
end

if ~exist(resultsdirinst,'dir')
    mkdir(resultsdirinst);
end

% load test set

imgids=textread(sprintf(VOCopts.seg.imgsetpath,VOCopts.testset),'%s');

cmap = VOClabelcolormap(255);
detids={dets.id};
tic;
for j=1:numel(imgids)
    % display progress
    if toc>1
        fprintf('make segmentation: %d/%d\n',j,numel(imgids));
        drawnow;
        tic;
    end
    imname = imgids{j};

    classlabelfile = sprintf(VOCopts.seg.clsrespath,segid,VOCopts.testset,imname);
    instlabelfile = sprintf(VOCopts.seg.instrespath,segid,VOCopts.testset,imname);

    imgfile = sprintf(VOCopts.imgpath,imname);
    imginfo = imfinfo(imgfile);

    vdets=dets(strmatch(imname,detids,'exact'));
    
    [instim,classim]= convert_dets_to_image(imginfo.Width, imginfo.Height,vdets,confidence);
    imwrite(instim,cmap,instlabelfile);
    imwrite(classim,cmap,classlabelfile);    
    
% Copy in ground truth - uncomment to copy ground truth segmentations in
% for comparison
%    gtlabelfile = [VOCopts.root '/Segmentations(class)/' imname '.png'];
%    gtclasslabelfile = sprintf('%s/%d_gt.png',resultsdir,imnums(j));        
%    copyfile(gtlabelfile,gtclasslabelfile);
end

% Converts a set of detected bounding boxes into an instance-labelled image
% and a class-labelled image
function [instim,classim]=convert_dets_to_image(W,H,dets,confidence)

instim = uint8(zeros([H W]));
classim = uint8(zeros([H W])); 
[sc,si]=sort([dets.conf]);
si(sc<confidence)=[];
for j=si
    detinfo = dets(j);
    bbox = round(detinfo.bbox); 
    % restrict to fit within image
    bbox([1 3]) = min(max(bbox([1 3]),1),W);
    bbox([2 4]) = min(max(bbox([2 4]),1),H);      
    instim(bbox(2):bbox(4),bbox(1):bbox(3)) = j;
    classim(bbox(2):bbox(4),bbox(1):bbox(3)) = detinfo.clsnum;      
end


