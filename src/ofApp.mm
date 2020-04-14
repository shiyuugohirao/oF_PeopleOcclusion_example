#include "ofApp.h"

using namespace ofxARKit::common;

//--------------------------------------------------------------
ofApp :: ofApp (ARSession * session){
    //    ARBodyTrackingConfiguration *configuration = [ARBodyTrackingConfiguration new];
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    //auto mode = ARFrameSemanticPersonSegmentation;
    auto mode = ARFrameSemanticPersonSegmentationWithDepth;
    bool b = [ARWorldTrackingConfiguration supportsFrameSemantics:mode];
    if(b) configuration.frameSemantics = mode;
    else ofLogWarning()<<"Not support for "<<mode;

    [session runWithConfiguration:configuration];

    this->session = session;
}
ofApp::ofApp(){}
ofApp :: ~ofApp () {}

//--------------------------------------------------------------
void ofApp::setup() {

    int fontSize = 8;
    if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice()) fontSize *= 2;
    font.load("fonts/mono0755.ttf", fontSize);

    processor = ARProcessor::create(session);
    processor->setup();

    //--- Width:1125 / Height:2436 in iPhoneXS
    WIDTH = ofGetWidth();
    HEIGHT = ofGetHeight();

    camFbo.allocate(WIDTH, HEIGHT);
    stencilFbo.allocate(WIDTH, HEIGHT);
    segmentationFbo.allocate(WIDTH, HEIGHT);
    segmentationFbo.getTexture().setAlphaMask(stencilFbo.getTexture());

    finder.setFindHoles(true);

    cout<<"--- setup! ---"<<endl;
}

//--------------------------------------------------------------
void ofApp::update(){

    processor->update();

    //--- Camera ---//
    camFbo.begin();
    ofClear(0);
    processor->draw();
    camFbo.end();

    /*--- update Segmentation ---*/
    ofPixels pix;
    if(!cvtSegmentationToPix(pix)) return;

    //--- convert to Mat
    segMat = ofxCv::toCv(pix);
    scale = 2.0;    // scalize segMat. the bigger, the finer and the heavier.
    blurSize = 4;   // blur edge. the bigger, the fuzzier.
    updateSegmentation(segMat, scale, blurSize);


    //--- StencilBuffer ---//
    stencilFbo.begin();
    ofClear(0);
    ofTranslate(WIDTH*.5, HEIGHT*.5);
    ofRotateDeg(90);
    ofScale(2436.0/256.0/scale);
    ofTranslate(-segMat.cols*.5, -segMat.rows*.5);
    ofSetColor(255);
    ofxCv::drawMat(segMat, 0, 0);
    stencilFbo.end();

    //--- Segmentation ---//
    segmentationFbo.begin();
    ofClear(0);
    ofScale(1, -1);
    ofTranslate(0,-HEIGHT);
    camFbo.draw(0,0);
    segmentationFbo.end();
}

//--------------------------------------------------------------
void ofApp::draw() {
    ofBackground(0);
    ofSetColor(255);

    //--- Camera ---//
    if(toggles[0]){
        ofPushMatrix();
        ofScale(1, -1); // draw upside-down
        camFbo.draw(0,-HEIGHT);
        ofPopMatrix();
    }

    //--- Outlines ---//
    if(toggles[1]){
        ofPushMatrix();
        ofTranslate(WIDTH*.5, HEIGHT*.5);
        ofRotateDeg(90);
        ofScale(2436.0/256.0/scale);
        ofTranslate(-segMat.cols*.5, -segMat.rows*.5);
        for(auto p:finder.getPolylines()) p.draw();
        ofPopMatrix();
    }

    //--- StencilBuffer ---//
    if(toggles[2]) stencilFbo.draw(0,0);

    //--- Segmentation ---//
    if(toggles[3]) segmentationFbo.draw(0,0);


    // ========== DEBUG STUFF ============= //
    ofTranslate(0,100);
    processor->debugInfo.drawDebugInformation(font);
}

//--------------------------------------------------------------
bool ofApp::cvtSegmentationToPix(ofPixels &pix){
    auto buf = session.currentFrame.segmentationBuffer;
    auto mat = getMatFromImageBuffer(buf);

    if(mat.empty()) return false;

//    //--- GRAY - just simple (no alpha)
//    pix.allocate(mat.cols, mat.rows, OF_PIXELS_GRAY);
//    for(int i=0; i<mat.total(); i++){
//        pix[i] = mat.data[i];
//    }
    //--- RGBA
    int ch = mat.channels();
    pix.allocate(mat.cols, mat.rows, OF_PIXELS_RGBA);
    for(int i=0; i<mat.total(); i++){
        pix[i*ch+0] = mat.data[i];
        pix[i*ch+1] = mat.data[i];
        pix[i*ch+2] = mat.data[i];
        pix[i*ch+3] = mat.data[i];
    }
    return true;
}
//--------------------------------------------------------------
void ofApp::updateSegmentation(cv::Mat &segMat, float scale, int blurSize){
    if(segMat.empty()){
        ofLogWarning()<<"segMat is empty...";
        return;
    }
    cv::Mat res;
    int w = segMat.cols;
    int h = segMat.rows;

    //--- Resize
    cv::resize(segMat, segMat, cv::Size(w*scale, h*scale),0,0,cv::INTER_LINEAR_EXACT);

    //--- Blur
    ofxCv::GaussianBlur(segMat, blurSize);

    //--- Contour
    finder.findContours(segMat);
}

//--------------------------------------------------------------
cv::Mat ofApp::getMatFromImageBuffer(CVImageBufferRef buffer) {
    cv::Mat mat ;
    CVPixelBufferLockBaseAddress(buffer, 0);
    void *address = CVPixelBufferGetBaseAddress(buffer);
    int width = (int) CVPixelBufferGetWidth(buffer);
    int height = (int) CVPixelBufferGetHeight(buffer);
    mat = cv::Mat(height, width, CV_8UC4, address, 0);
    //ofxCv::convertColor(mat, mat, CV_BGRA2BGR);
    //cv::cvtColor(mat, mat, CV_BGRA2RGBA);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return mat;
}

//--------------------------------------------------------------
void ofApp::exit() {

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch){
    glm::vec2 pos = {touch.x, touch.y};
    glm::vec2 center = glm::vec2(WIDTH*.5, HEIGHT*.5);
    if(pos.y<center.y){
        if(pos.x<center.x)  toggles[0] =! toggles[0];
        else                toggles[1] =! toggles[1];
    }else{
        if(pos.x<center.x)  toggles[2] =! toggles[2];
        else                toggles[3] =! toggles[3];
    }
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    processor->deviceOrientationChanged(newOrientation);
}
