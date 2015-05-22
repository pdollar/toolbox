#include "libacf.h"
#include <iostream>

using namespace std;

int main(int argc, char* argv[]) {
  // Initialize the MATLAB Compiler Runtime global state
  if (!mclInitializeApplication(NULL, 0)) {
    cerr << "Could not initialize the application properly."
         << std::endl;
    return -1;
  }
  // Initialize the ACF library
  if (!libacfInitialize()) {
    std::cerr << "Could not initialize the library properly."
              << std::endl;
    return -1;
  }
  
  mwArray I("test.png");
  mwArray detectorFileName("../models/AcfInriaDetector.mat");
  mwArray fileName("output.txt");
  mwArray bbs;
  acfDetect(1, bbs, I, detectorFileName, fileName); 
  cout << bbs << endl;
}
