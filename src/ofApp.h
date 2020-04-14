#pragma once

#include "ofxiOS.h"
#include <ARKit/ARKit.h>
#include "ofxARKit.h"
#include "ofxOpenCv.h"
#include "ofxCv.h"

class ofApp : public ofxiOSApp {
private:
    int WIDTH, HEIGHT;

    // ====== AR STUFF ======== //
    ARSession * session;
    ARRef processor;
    cv::Mat segMat;

    ofFbo camFbo, segmentationFbo, stencilFbo;
    ofxCv::ContourFinder finder;

    ofTrueTypeFont font;
    ofParameter<int> blurSize;
    ofParameter<float> scale;
    ofParameter<bool> toggles[4];

protected:
    bool cvtSegmentationToPix(ofPixels &pix);
    void updateSegmentation(cv::Mat &segMat, float scale, int blurSize);
    cv::Mat getMatFromImageBuffer(CVImageBufferRef buffer);

public:

    ofApp (ARSession * session);
    ofApp();
    ~ofApp ();

    void setup();
    void update();
    void draw();
    void exit();
    void touchDown(ofTouchEventArgs &touch);
    void deviceOrientationChanged(int newOrientation);

};



