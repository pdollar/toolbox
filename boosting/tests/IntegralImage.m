classdef IntegralImage < handle

  properties ( GetAccess=public, SetAccess=private )
    roiLf; roiTp; roiRt; roiBt;   % current region of interest (ROI)
    roiMu; roiSig; roiSigInv;     % ROI properties
    mRows; nCols;                 % image width/height
  end

  properties %( GetAccess=private, SetAccess=private )
    II, sqII; % integral image and square integral image
  end

  methods
    function obj = IntegralImage()
      obj=clear(obj);
    end

    function obj = clear(obj)
      obj.II=[]; obj.sqII=[]; obj.mRows=0; obj.nCols=0;
      obj.roiLf=0; obj.roiTp=0; obj.roiRt=0; obj.roiBt=0;
      obj.roiMu=0; obj.roiSig=1; obj.roiSigInv=1;
    end

    function prep = prepared(obj)
      prep = ~isempty(obj.II);
    end

    function obj = prepare( obj, I )
      %%% CALL C CODE?
      %[m n]=size(I); obj.mRows=m; obj.nCols=n;
      %obj.II=zeros(m+1,n+1); obj.sqII=obj.II;
      %obj.II(2:end,2:end)=cumsum(cumsum(I),2);
      %obj.sqII(2:end,2:end)=cumsum(cumsum(I.*I),2);
      %%% C CODE
      [obj.mRows,obj.nCols]=size(I);
      [obj.II,obj.sqII]=integralImagePrepare(I);
    end

    function o = setRoi( o, lf, tp, rt, bt )
      if( o.roiLf==lf && o.roiTp==tp && o.roiRt==rt && o.roiBt==bt )
        return;
      end
      o.roiLf	= 0; o.roiTp = 0;
      areaInv = 1.0/double((rt-lf+1)*(bt-tp+1));
      m1 = o.rectSum(lf, tp, rt, bt) * areaInv;
      m2 = o.rectSumSq(lf, tp, rt, bt) * areaInv;
      o.roiMu = m1;
      o.roiSig = sqrt(max(m2 - m1 * m1, 0.0)) + .000001;
      o.roiSigInv	= 1.0/o.roiSig;
      o.roiLf=lf;  o.roiTp=tp;  o.roiRt=rt; o.roiBt=bt;
    end

    function [lf tp rt bt] = getRoi( obj )
      lf=obj.roiLf; tp=obj.roiTp; rt=obj.roiRt; bt=obj.roiBt;
    end

    function s = rectSum( obj, lf, tp, rt, bt )
      %%% CALL C CODE?
      lf=lf+obj.roiLf; rt=rt+obj.roiLf+1;
      tp=tp+obj.roiTp; bt=bt+obj.roiTp+1;
      s = obj.II(tp,lf) + obj.II(bt,rt) ...
        - obj.II(tp,rt) - obj.II(bt,lf);
    end

    function s = rectSumSq( obj, lf, tp, rt, bt )
      %%% CALL C CODE?
      lf=lf+obj.roiLf; rt=rt+obj.roiLf+1;
      tp=tp+obj.roiTp; bt=bt+obj.roiTp+1;
      s = obj.sqII(tp,lf) + obj.sqII(bt,rt) ...
        - obj.sqII(tp,rt) - obj.sqII(bt,lf);
    end
  end
end
