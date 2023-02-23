//
//  screen_capture_login_page.dart
//  zego_express_screen_capture
//
//  Created by Patrick Fu on 2020/10/25.
//  Copyright © 2020 Zego. All rights reserved.
//

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zego_express_screen_capture/config/zego_config.dart';
import 'package:zego_express_screen_capture/controller.dart';
import 'package:zego_express_screen_capture/ui/zego_ui_tool.dart';

import '../manager/screen_capture_manager.dart';

class ScreenCaptureLoginPage extends StatefulWidget {
  @override
  _ScreenCaptureLoginPageState createState() => _ScreenCaptureLoginPageState();
}

class _ScreenCaptureLoginPageState extends State<ScreenCaptureLoginPage> {
  final TextEditingController _roomIDEdController = new TextEditingController();
  final TextEditingController _streamIDEdController = TextEditingController();

  ScreenCaptureManager manager = ScreenCaptureManagerFactory.createManager();
  bool screenCaptureBtnClickable = true;
  GetStorage box = GetStorage();
  @override
  void initState() {
    super.initState();

    if (ZegoConfig.instance.roomID.isNotEmpty) {
      _roomIDEdController.text = ZegoConfig.instance.roomID;
    }
    if (ZegoConfig.instance.streamID.isNotEmpty) {
      _streamIDEdController.text = ZegoConfig.instance.streamID;
    }

    // Need to set app group ID and broadcast upload extension name first
    manager.setAppGroup(ZegoConfig.instance.appGroup);
    manager.setReplayKitExtensionName('BroadcastExtensionFlutter');
  }

  void syncConfig() {
    String roomID = controller.selectedCar.value;
    String streamID = controller.selectedCar.value;

    if (roomID.isEmpty || streamID.isEmpty) {
      ZegoUITool.showAlert(context, 'RoomID or StreamID cannot be empty');
      return;
    }

    ZegoConfig.instance.roomID = roomID;
    ZegoConfig.instance.streamID = streamID;
    ZegoConfig.instance.saveConfig();
  }

  void startScreenCapture() async {
    setState(() {
      screenCaptureBtnClickable = false;
    });

    syncConfig();

    // Set necessary params (just for iOS)
    await manager.setParamsForCreateEngine(
        ZegoConfig.instance.appID, ZegoConfig.instance.appSign, true);
    await manager.setParamsForVideoConfig(window.physicalSize.width.toInt(),
        window.physicalSize.height.toInt(), 15, 6000);
    await manager.setParamsForStartLive(
      controller.selectedCar.value,
      controller.selectedCar.value,
      controller.selectedCar.value,
      controller.selectedCar.value,
    );

    // Start screen capture
    await _initForegroundTask();

    await manager.startScreenCapture();
    setState(
      () {
        screenCaptureBtnClickable = true;
      },
    );
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  void stopScreenCapture() async {
    setState(() {
      screenCaptureBtnClickable = false;
    });

    await manager.stopScreenCapture();

    setState(() {
      screenCaptureBtnClickable = true;
    });
  }

  Controller controller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ekran Paylaşımı'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: ListView(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Yayın başlatılacak araç plakası"),
                  SizedBox(height: 10),
                  Text(
                    controller.selectedCar.value,
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Color(0xff0e88eb),
                ),
                width: 240.0,
                height: 60.0,
                child: CupertinoButton(
                  child: Text(
                    'Ekran Paylaşımını Başlat',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed:
                      screenCaptureBtnClickable ? startScreenCapture : null,
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Color(0xff0e88eb),
                ),
                width: 240.0,
                height: 60.0,
                child: CupertinoButton(
                  child: Text(
                    'Ekran Paylaşımını Durdur',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed:
                      screenCaptureBtnClickable ? stopScreenCapture : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
