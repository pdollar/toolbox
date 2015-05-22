# Use the C++ Wrapper for ACF Detector

We will illustrate how to use the simple C++ wrapper for the ACF detector.

###Compile

See http://blogs.mathworks.com/loren/2011/02/03/creating-c-shared-libraries-and-dlls/ for how to compile the cpp files.

The sample `main.cpp` contains the simple detection function that runs the detector on a sample image. You can easily modify it to fit for detecting more images. 

```sh
  mwArray I("test.png");
  mwArray detectorFileName("../models/AcfInriaDetector.mat");
  mwArray fileName("output.txt");
  mwArray bbs;
  acfDetect(1, bbs, I, detectorFileName, fileName); 
  cout << bbs << endl;
```

Please note that here I modify the original `acfDetect.m` to provide more flexibility. The followings are the code added by me.

```
if(isempty(detectorFileName) || ~exist(detectorFileName)), bbs = 1; return; end
t = load(detectorFileName); detector = t.detector;
```

###Run

To deploy the binary file to the group of machines, you do not need to install the heavy-weighted MATLAB. But you need to install the **MATLAB Compiler Runtime** at http://www.mathworks.com/products/compiler/mcr/index.html. We recommend you choose the version corresponding to your compiled files.

After installing the **MATLAB Compiler Runtime**, you need to add its paths to the environments of the system. You can add the following snippets to your `.bashrc` or `.zshrc`. The variable `MCR_ROOT` specifies the directory where you install the **MATLAB Compiler Runtime**.

```sh
export $MCR_ROOT=/home/szy/MCR
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MCR_ROOT/v84/runtime/glnxa64:$MCR_ROOT/v84/bin/glnxa64:$MCR_ROOT/v84/sys/os/glnxa64:$MCR_ROOT/v84/sys/opengl/lib/glnxa64
export XAPPLRESDIR=$MCR_ROOT/v84/X11/app-defaults
```

Then you can just execute the binary file and make the great object detection algorithm to be able to used in C++. 
