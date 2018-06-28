function example_action

% change this path if you install the VOC code elsewhere
addpath([cd '/VOCcode']);

% initialize VOC options
VOCinit;

% train and test classifier for each action
for i=2:VOCopts.nactions % skip "other"
    cls=VOCopts.actions{i};
    classifier=train(VOCopts,cls);                           % train classifier
    test(VOCopts,cls,classifier);                            % test classifier
    [recall,prec,ap]=VOCevalaction(VOCopts,'comp9',cls,true);   % compute and display PR
    
    if i<VOCopts.nclasses
        fprintf('press any key to continue with next class...\n');
        drawnow;
        pause;
    end
end

% train classifier
function classifier = train(VOCopts,cls)

% load training set for class
[imgids,objids,classifier.gt]=textread(sprintf(VOCopts.action.clsimgsetpath,cls,VOCopts.trainset),'%s %d %d');

% extract features for each person
classifier.FD=zeros(0,length(imgids));
tic;
for i=1:length(imgids)
    % display progress
    if toc>1
        fprintf('%s: train: %d/%d\n',cls,i,length(imgids));
        drawnow;
        tic;
    end
    
    rec=PASreadrecord(sprintf(VOCopts.annopath,imgids{i}));
    obj=rec.objects(objids(i));

    fd=extractfd(VOCopts,obj);    
    classifier.FD(1:length(fd),i)=fd;
end

% run classifier on test images
function test(VOCopts,cls,classifier)

% load test set ('val' for development kit)
[imgids,objids,gt]=textread(sprintf(VOCopts.action.clsimgsetpath,cls,VOCopts.testset),'%s %d %d');

% create results file
fid=fopen(sprintf(VOCopts.action.respath,'comp9',cls),'w');

% classify each person
tic;
for i=1:length(imgids)
    % display progress
    if toc>1
        fprintf('%s: test: %d/%d\n',cls,i,length(imgids));
        drawnow;
        tic;
    end
    
    rec=PASreadrecord(sprintf(VOCopts.annopath,imgids{i}));
    obj=rec.objects(objids(i));

    fd=extractfd(VOCopts,obj);

    % compute confidence of positive classification
    c=classify(VOCopts,classifier,fd);
    
    % write to results file
    fprintf(fid,'%s %d %f\n',imgids{i},objids(i),c);
end

% close results file
fclose(fid);

% trivial feature extractor: bounding box aspect ratio
function fd = extractfd(VOCopts,obj)

w=obj.bndbox.xmax-obj.bndbox.xmin+1;
h=obj.bndbox.ymax-obj.bndbox.ymin+1;
fd=w/h;

% trivial classifier: compute ratio of L2 distance betweeen
% nearest positive (class) feature vector and nearest negative (non-class)
% feature vector
function c = classify(VOCopts,classifier,fd)

d=sum(fd.*fd,1)+sum(classifier.FD.*classifier.FD,1)-2*fd'*classifier.FD;
dp=min(d(classifier.gt>0));
dn=min(d(classifier.gt<0));
c=dn/(dp+eps);
