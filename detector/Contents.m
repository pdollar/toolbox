% DETECTOR
% See also
%
% Fast detector code is based on the papers:
%  [1] P. Dollár, Z. Tu, P. Perona and S. Belongie
%   "Integral Channel Features", BMVC 2009.
%  [2] P. Dollár, S. Belongie and P. Perona
%   "The Fastest Pedestrian Detector in the West," BMVC 2010.
%  [3] P. Dollár, R. Appel and W. Kienzle
%   "Crosstalk Cascades for Frame-Rate Pedestrian Detection," ECCV 2012.
%  [4] P. Dollár, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection", PAMI 2014.
% Please cite a subset of the above papers if you end up using the code.
% The PAMI 2014 paper has the most thorough and up to date descriptions.
% Code written and maintained by Piotr Dollar and Ron Appel.
%
% Aggregate channel features object detector:
%   acfDemoCal   - Demo for aggregate channel features object detector on Caltech dataset.
%   acfDemoInria - Demo for aggregate channel features object detector on Inria dataset.
%   acfDetect    - Run aggregate channel features object detector on given image(s).
%   acfModify    - Modify aggregate channel features object detector.
%   acfTest      - Test aggregate channel features object detector given ground truth.
%   acfTrain     - Train aggregate channel features object detector.
% 
% Object bounding box utilities and labeling tools:
%   bbApply      - Functions for manipulating bounding boxes (bb).
%   bbGt         - Bounding box (bb) annotations struct, evaluation and sampling routines.
%   bbLabeler    - Bounding box or ellipse labeler for static images.
%   bbNms        - Bounding box (bb) non-maximal suppression (nms).
