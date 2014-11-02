% Aggregate Channel Features Detector Overview.
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%% 1. Introduction. %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The detector portion of this toolbox implements the Aggregate Channel
% Features (ACF) object detection code. The ACF detector is a fast and
% effective sliding window detector (30 fps on a single core). It is an
% evolution of the Viola & Jones (VJ) detector but with an ~1000 fold
% decrease in false positives (at the same detection rate). ACF is best
% suited for quasi-rigid object detection (e.g. faces, pedestrians, cars).
%
% The detection code was written by Piotr Dollár with contributions by Ron
% Appel and Woonhyun Nam (with bug reports/suggestions from many others).
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%% 2. Papers. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The detector was introduced and described through the following papers:
%  [1] P. Dollár, Z. Tu, P. Perona and S. Belongie
%   "Integral Channel Features", BMVC 2009.
%  [2] P. Dollár, S. Belongie and P. Perona
%   "The Fastest Pedestrian Detector in the West," BMVC 2010.
%  [3] P. Dollár, R. Appel and W. Kienzle
%   "Crosstalk Cascades for Frame-Rate Pedestrian Detection," ECCV 2012.
%  [4] P. Dollár, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection," PAMI 2014.
%  [5] W. Nam, P. Dollár, and J.H. Han
%   "Local Decorrelation For Improved Pedestrian Detection," NIPS 2014.
% Please see: http://vision.ucsd.edu/~pdollar/research.html#ObjectDetection
%
% A short summary of the papers, organized by detector name:
%
% [1] "Integral Channel Features" [ICF] - Introduced channel features and
% modified the VJ framework to compute integral images (and Haar wavelets)
% over the channels. Substantially outperformed HOG and at faster speeds.
%
% [2] "Fastest Pedestrian Detector in the West" [FPDW] - We observed that
% features computed at one scale can be used to approximate features at
% nearby scales, increasing detector speed with little loss in accuracy.
%
% [3] "Crosstalk Cascades" - This work coupled cascade evaluation at nearby
% positions and scales to exploit correlations in detector responses at
% neighboring locations. Further increased speed of the ICF detector.
%
% [4] "Aggregate Channel Features" [ACF] - We found that single-scale
% square Haar wavelets were sufficient in the ICF framework. Thus instead
% of computing integral images and Haar wavelets, we simply smooth and
% downsample the channels and the features are now single pixel lookups in
% the "aggregated" channels.
%
% [5] "Locally Decorralated Channel Features" [LDCF] - Filtering the
% channel features with appropriate data-derived filters can remove local
% correlations from the channels. Given decorrelated features, boosted
% decision trees generalize much better giving a nice boost in accuracy.
%
% This code implements ACF [4] and LDCF [5]. It does not implement ICF [1]
% or FPDW [2] which are now obsolete and supplemented by ACF. Crosstalk
% cascades [3] are also not used as classifier evalution in ACF is very
% fast (no need to compute Haar wavelets). However, ACF does use the simple
% but highly effective "constant soft cascades" from [3].
%
% Please cite a subset of the above papers as appropriate if you end up
% using this code to support a publication. Thanks!
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%% 3. Setup. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% (A) Please install and setup the toolbox as described online:
%  http://vision.ucsd.edu/~pdollar/toolbox/doc/index.html
% You may need to recompile for your system, see toolboxCompile. Note:
% enabling OpenMP during compile will significantly speed training.
%
% (B) Important: to train the detectors and run the detection demos you
% need to install the Caltech Pedestrian Detection Benchmark available at:
%  http://www.vision.caltech.edu/Image_Datasets/CaltechPedestrians/
% In particular, make sure to download and install:
%  (B1) Matlab evaluation/labeling code version 3.2.1 or later
%  (B2) INRIA data (necessary for the INRIA demo)
%  (B3) Caltech-USA data (necessary for the Caltech demo)
% Please follow the instruction in the readme of the Caltech code. You only
% need to download the data and code and place appropriately, there is no
% need to look closely at the evaluation code. Initially running the demos
% (acfDemoInria and acfDemoCal) will convert the data from the Caltech data
% format to a format useable by ACF. If this step fails it means the
% Caltech code or data is not properly setup.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%% 4. Getting Started. %%%%%%%%%%%%%%%%%%%%%%%%
%
% After performing the setup, see acfDemoInria.m and acfDemoCal.m for demos
% and visualizations.
%
% For an overview of available functionality please see detector/Contents.m
% and channels/Contents.m. The various detector/acf*.m and channels/chns*.m
% functions are well documented and worth checking for additional details.
%
% Finally, a note about pre-trained models. The detector/models/ directory
% contains four pre-trained pedestrian models (ACF/LDCF on INRIA/Caltech).
% Running acfDemoInria/Cal.m with the ACF/LDCF flag toggled gives rise to
% these models (just delete the existing models to retrain from scratch).
% Note, however, that results will differ by up to +/-2% MR depending on
% operating system and random seed (see opts.seed), and the models here are
% not exactly equivalent to the models in the papers (due to evolution of
% the code). Small changes in MR should not be considered significant (nor
% should they be used as a basis for publishing). Whenever making a change
% I suggest training/testing the same model with multiple random seeds.
%
% Enjoy and I hope you find the detectors useful :)
