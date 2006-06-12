function demsvm2()
% DEMSVM2 - Demonstrate advanced Support Vector Machine features
% 
%   DEMSVM2 demonstrates the classification of a simple artificial data
%   set by a Support Vector Machine classifier. The features of the SVM
%   routines that make it useful for large data sets are shown.
%
%   See also
%   SVM, SVMTRAIN, SVMFWD, SVMKERNEL, DEMSVM2
%

% 
% Copyright (c) Anton Schwaighofer (2001)
% $Revision: 1.4 $ $Date: 2001/04/19 23:29:48 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

rand('seed', 1);
randn('seed', 1);

X = [2 7; 3 6; 2 2; 8 1; 6 4; 4 8; 9 5; 9 9; 9 4; 6 9; 7 4; 4 4];
Y = [ +1;  +1;  +1;  +1;  +1;  -1;  -1;  -1;  -1;  -1;  -1;  -1];
% define a simple artificial data set

x1ran = [0 10];
x2ran = [0 10];
% range for plotting the data set and the decision boundary

disp(' ');
disp('This demonstration illustrates the use of a Support Vector Machine');
disp('(SVM) for classification.');
disp(' ');
disp('This Matlab implementation has a few special features that make');
disp('its use on large data sets particularly efficient. We will in turn');
disp('demonstrate a few of theses features on small artifial data sets.');
disp(' ');
disp('Press any key to plot the data set');
pause

f1 = figure;
plotdata(X, Y, x1ran, x2ran);
title('Data from class +1 (squares) and class -1 (crosses)');

fprintf('\n\n\n\n');
fprintf('The data is plotted in figure %i, where\n', f1);
disp('  squares stand for points with label Yi = +1');
disp('  crosses stand for points with label Yi = -1');
disp(' ')
disp('Now we train a Support Vector Machine classifier on this data set,');
disp('we use the simple linear kernel.');
disp('Training the SVM involves solving a quadratic programming (QP)');
disp('problem that has as many variables as we have training points.');
disp('This may result in huge time and memory consumption during');
disp('training.');
disp('This SVM toolbox uses a special decomposition algorithm proposed');
disp('by Osuna, Freund and Girosi');
disp('(ftp://ftp.ai.mit.edu/pub/cbcl/nnsp97-svm.ps)');
disp('The QP problem is decomposed into smaller ones, the size of these');
disp('small QP problems is controlled by the parameter net.qpsize');
disp(' ');
disp('We demonstrate the decomposition algorithm by setting net.qpsize');
disp('to 6. In the SVM framework this means that we consider a set of');
disp('6 examples (the ''working set'') at once and try to find the ');
disp('separating hyperplane for this set of examples.');
disp(' ');
disp(' ');
disp('Press any key to start training')
pause
disp(' ');
disp('************');
disp(' ');

net = svm(size(X, 2), 'linear', [], 100);
net.qpsize = 6;
net = svmtrain(net, X, Y, [], 2);

disp(' ');
disp('************');
disp(' ');

f2 = figure;
plotboundary(net, x1ran, x2ran);
plotdata(X, Y, x1ran, x2ran);
plotsv(net, X, Y);
title(['SVM with linear kernel: decision boundary (black) plus Support' ...
       ' Vectors (red)']);

disp(' ');
fprintf('The resulting decision boundary is plotted in figure %i.\n', f2);
disp('The contour plotted in black separates class +1 from class -1');
disp('(this is the actual decision boundary)');
disp('The SVM has successfully found the set of Support Vectors without');
disp('ever having to work with the whole set of examples.');
disp(' ');
disp('The decomposition algorithm works in such a way that the size of');
disp('the small QP subproblems is independent of the number of Support');
disp('Vectors. Thus complex data sets with a few thousand Support');
disp('Vectors can be handled easily and efficiently by solving a series');
disp('of small QP problems of size net.qpsize.');
disp(' ');
disp('Furthermore, a linear approximation of the objective function is');
disp('used for selecting which examples to put into the working set for');
disp('the next QP subproblem. This is based on the approximation');
disp('proposed by Joachims, see');
disp('http://www-ai.cs.uni-dortmund.de/DOKUMENTE/joachims_99a.ps.gz');
disp('This approximation gives an excellent convergence behaviour.');
disp(' ');
disp('Usually it is not necessary to modify the default value');
disp('for net.qpsize');
disp(' ');
disp('Press any key to continue')
pause


fprintf('\n\n\n\n');
disp('We have just now trained a SVM with linear kernel. If the');
disp('resulting classifier makes too many errors on the training');
disp('set we might switch to a more powerful kernel function.');
disp('We will now switch to a RBF kernel.');
disp(' ');
disp('Training a SVM means finding the Support Vectors - the examples');
disp('that are on the boundary between the classes +1 and -1.');
disp('If we change the kernel function and start the training again');
disp('from scratch, we loose the previously obtained information on');
disp('the Support Vectors. If a set of examples are Support Vectors');
disp('when using a linear kernel, we may assume that at least a few');
disp('of theses examples will again be Support Vectors when using ');
disp('the RBF kernel.');
disp(' ');
disp('SVMTRAIN provides a way of incorporating this information since');
disp('it is possible to set a start value for the coefficients alpha.');
disp(' ');
disp('We will now start the training again, using the RBF kernel. We');
disp('will use the previously obtained alpha''s as the start values.');
disp(' ');
disp(' ');
disp('Press any key to start training')
pause
disp(' ');
disp('************');
disp(' ');

alpha0 = net.alpha;
net = svm(size(X, 2), 'rbf', [36], 100);
net.qpsize = 6;
net = svmtrain(net, X, Y, alpha0, 2);

disp(' ');
disp('************');
disp(' ');

f3 = figure;
plotboundary(net, x1ran, x2ran);
plotdata(X, Y, x1ran, x2ran);
plotsv(net, X, Y);
title(['SVM with RBF kernel, width 36: decision boundary (black) plus Support' ...
       ' Vectors (red)']);

fprintf('\n\n\n\n');
disp('It can be seen that the whole training is finished after fewer');
disp('iterations than before. It turned out that the set of Support');
disp('Vectors has indeed stayed the same when changing the kernel');
disp('function.');
disp(' ');
disp('This features is particularly useful for testing the results of ');
disp('different kernel functions on large data sets, for example');
disp('  net1 = svm(nin, ''RBF'', 0.5);');
disp('  net1 = svmtrain(net1, X, Y);');
disp('  net2 = svm(nin, ''RBF'', 0.4);');
disp('  net2 = svmtrain(net2, X, Y, net1.alpha);');
disp('  net3 = svm(nin, ''RBF'', 0.3);');
disp('  net3 = svmtrain(net3, X, Y, net2.alpha);');
disp(' ');
disp('Press any key continue');
pause


fprintf('\n\n\n\n');
disp('Another feature that is useful for use with imbalanced data sets');
disp('is to set different values for the upper bound C of the');
disp('coefficients alpha. In a mechanical analogy, these coefficients');
disp('can be viewed as forces ''pulling'' on the decision boundary. The');
disp('larger a coefficient alpha is, the larger is the force the');
disp('corresponding examples exerts on the decision surface. Thus the');
disp('upper bound C for the coefficients alpha is equivalent to an');
disp('upper bound for the force.');
disp(' ');
disp('If we now have an imbalanced data set with, say, 100 negative');
disp('examples and 5 positive examples, we may allow the positive');
disp('examples to exert a higher force on the decision boundary to');
disp('compensate for their under-representation.');
disp('We do this by setting different upper bounds C for the positive');
disp('and the negative examples. Such a technique has been proposed by');
disp('Veropoulos et.al. in the context of medical diagnosis, see');
disp('http://lara.enm.bris.ac.uk/cig/gzipped/ijcai_ss.ps.gz');
disp(' ');
disp('We will now show the effect of different bounds for positive and');
disp('negative examples on a simple data set. First we use an equal');
disp('upper bound C for the positive and negative examples.');
disp(' ');
disp('Press any key to show decision boundary')
pause

X = [2 7; 3 6; 6 3; 8 1; 6 4; 4 8; 9 5; 9 9; 9 4; 6 9; 7 4; 4 4; 4 6; ...
     3 3];
Y = [ +1;  +1;  -1;  +1;  +1;  -1;  -1;  -1;  -1;  -1;  -1;  -1;  -1; ...
      +1];

net = svm(size(X, 2), 'rbf', [128]);
net.c = 100;
net = svmtrain(net, X, Y);

f6 = figure;
plotboundary(net, x1ran, x2ran);
plotdata(X, Y, x1ran, x2ran);
plotsv(net, X, Y);
title(['Decision boundary from SVM with upper bound C=100 for' ...
       ' positive and negative examples']);

fprintf('\n\n\n\n');
disp('Now we use an upper bound of C=10 for the positive examples and');
disp('C=100 for the negative examples.');

disp(' ');
disp('Press any key to show decision boundary')
pause

net = svm(size(X, 2), 'rbf', [128]);
net.c = [50 100];
net = svmtrain(net, X, Y);

f7 = figure;
plotboundary(net, x1ran, x2ran);
plotdata(X, Y, x1ran, x2ran);
plotsv(net, X, Y);
title(['Decision boundary from SVM with upper bound C=10 for' ...
       ' positive examples (squares) and C=100 for negatives' ...
       ' (crosses)']);


fprintf('\n\n\n\n');
disp('It can be seen clearly that the SVM now makes fewer errors on the');
disp('negative examples, since errors on negative examples have a');
disp('''penalty'' of C=100 associated with it, whereas errors on');
disp('positive examples only have a penalty of C=10. The decision');
disp('boundary has moved such that example 12 is the only one that is');
disp('not correctly classified.');
disp('(Recall that the actual decision boundary that separates the');
disp('positive from the negative examples is plotted in black, the');
disp('contour lines plotted in blue and green are the lines of');
disp('distance +1 and -1 from the decision boundary. All examples that');
disp('are in the margin (between the +1 and -1 lines) are seen as');
disp('misclassifications.)');

fprintf('\n\n\n\n');
disp('Press any key to end the demo')
pause

delete(f1);
delete(f2);
delete(f3);
delete(f6);
delete(f7);



function plotdata(X, Y, x1ran, x2ran)
% PLOTDATA - Plot 2D data set
% 

hold on;
ind = find(Y>0);
plot(X(ind,1), X(ind,2), 'ks');
ind = find(Y<0);
plot(X(ind,1), X(ind,2), 'kx');
text(X(:,1)+.2,X(:,2), int2str([1:length(Y)]'));
axis([x1ran x2ran]);
axis xy;


function plotsv(net, X, Y)
% PLOTSV - Plot Support Vectors
% 

hold on;
ind = find(Y(net.svind)>0);
plot(X(net.svind(ind),1),X(net.svind(ind),2),'rs');
ind = find(Y(net.svind)<0);
plot(X(net.svind(ind),1),X(net.svind(ind),2),'rx');


function [x11, x22, x1x2out] = plotboundary(net, x1ran, x2ran)
% PLOTBOUNDARY - Plot SVM decision boundary on range X1RAN and X2RAN
% 

hold on;
nbpoints = 100;
x1 = x1ran(1):(x1ran(2)-x1ran(1))/nbpoints:x1ran(2);
x2 = x2ran(1):(x2ran(2)-x2ran(1))/nbpoints:x2ran(2);
[x11, x22] = meshgrid(x1, x2);
[dummy, x1x2out] = svmfwd(net, [x11(:),x22(:)]);
x1x2out = reshape(x1x2out, [length(x1) length(x2)]);
contour(x11, x22, x1x2out, [-0.99 -0.99], 'b-');
contour(x11, x22, x1x2out, [0 0], 'k-');
contour(x11, x22, x1x2out, [0.99 0.99], 'g-');

