//
//  screen_capture_manager_impl_android.dart
//  zego-express-example-screen-capture-flutter
//
//  Created by Patrick Fu on 2020/10/27.
//  Copyright © 2020 Zego. All rights reserved.
//

import 'package:media_projection_creator/media_projection_creator.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_screen_capture/manager/screen_capture_manager.dart';

/// Private implementation
class ScreenCaptureManagerImplAndroid extends ScreenCaptureManager {
  int appID;
  String appSign;
  String roomID;
  String userID;
  String userName;
  String streamID;

  int videoWidth;
  int videoHeight;
  int videoFPS;
  int videoBitrateKBPS;

  @override
  Future<bool> startScreenCapture() async {
    int errorCode = await MediaProjectionCreator.createMediaProjection();
    if (errorCode != MediaProjectionCreator.ERROR_CODE_SUCCEED) {
      print('Can not get screen capture permission');
      return false;
    }

    ZegoEngineProfile profile =
        ZegoEngineProfile(appID, ZegoScenario.Default, appSign: appSign);
    await ZegoExpressEngine.createEngineWithProfile(profile);

    /// Developers need to write native Android code to access native ZegoExpressEngine
    await ZegoExpressEngine.instance.enableCustomVideoCapture(true,
        config:
            ZegoCustomVideoCaptureConfig(ZegoVideoBufferType.SurfaceTexture));
    await ZegoExpressEngine.instance.setVideoConfig(ZegoVideoConfig(
        videoWidth,
        videoHeight,
        videoWidth,
        videoHeight,
        videoFPS,
        videoBitrateKBPS,
        ZegoVideoCodecID.Default));
    await ZegoExpressEngine.instance
        .loginRoom(roomID, ZegoUser(userID, userName));
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
    return true;
  }

  @override
  Future<bool> stopScreenCapture() async {
    await ZegoExpressEngine.instance.stopPublishingStream();
    await ZegoExpressEngine.instance.logoutRoom(roomID);
    await ZegoExpressEngine.destroyEngine();

    await MediaProjectionCreator.destroyMediaProjection();
    return true;
  }

  @override
  Future<void> setParamsForCreateEngine(
      int appID, String appSign, bool onlyCaptureVideo) async {
    this.appID = appID;
    this.appSign = appSign;
  }

  @override
  Future<void> setParamsForStartLive(
      String roomID, String userID, String userName, String streamID) async {
    this.roomID = roomID;
    this.userID = userID;
    this.userName = userName;
    this.streamID = streamID;
  }

  @override
  Future<void> setParamsForVideoConfig(int videoWidth, int videoHeight,
      int videoFPS, int videoBitrateKBPS) async {
    this.videoWidth = videoWidth;
    this.videoHeight = videoHeight;
    this.videoFPS = videoFPS;
    this.videoBitrateKBPS = videoBitrateKBPS;
  }
}
