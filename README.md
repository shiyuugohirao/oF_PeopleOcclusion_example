

# oF_PeopleOcclusion_example

PeopleOcclusion with openFrameworks.

<div align="center">
<img src="img/img00.png" alt="" width=15% height=15% align="left">
<img src="img/img01.png" alt="" width=15% height=15% align="left">
<img src="img/img02.png" alt="" width=15% height=15% align="left">
<img src="img/img03.png" alt="" width=15% height=15% align="left">
</div>
<br clear="left">



### Dependencies

- openFrameworks0.11.0 for iOS
- Xcode11.3 ~
- iPhone[A12/A12X Bionic].  (tested on my iPhoneXS)
- ofxAddons
  - ofxARKit
  - ofxOpenCv
  - ofxCv

### how to

- General > DeploymentInfo > Target  iOS13 +

- Signing&Capabilities

- add `Privacy - Camera Usage Description` in `ofxiOS-Info.plist` 

- addons>ofxARKit>src>lib>Shaders.metal   change Type to `MetalShaderSource` and check `TargetMembership`



簡単に記事を書きました。 → [oF_ofxARKitでPeopleOcclusion](https://shugohirao.com/blog/705)


