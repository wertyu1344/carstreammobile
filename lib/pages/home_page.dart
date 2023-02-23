import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:zego_express_screen_capture/firestore_services.dart';
import 'package:zego_express_screen_capture/pages/screen_capture_login_page.dart';

import '../config/zego_config.dart';
import '../controller.dart';
import '../ui/zego_ui_tool.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _appGroupEdController = TextEditingController();
  final TextEditingController _appIDEdController = TextEditingController();
  final TextEditingController _appSignEdController = TextEditingController();
  String deviceId;

  setup() async {
    deviceId = await PlatformDeviceId.getDeviceId;
  }

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ZegoConfig.instance.load().then((value) {
        if (ZegoConfig.instance.appGroup.isNotEmpty) {
          _appGroupEdController.text = ZegoConfig.instance.appGroup;
        }

        if (ZegoConfig.instance.appID > 0) {
          _appIDEdController.text = ZegoConfig.instance.appID.toString();
        }

        if (ZegoConfig.instance.appSign.isNotEmpty) {
          _appSignEdController.text = ZegoConfig.instance.appSign;
        }
      });
      setup();
    });

    super.initState();
  }

  final Stream<QuerySnapshot> _carsStream =
      FirebaseFirestore.instance.collection('cars').snapshots();
  Controller controller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$deviceId"),
      ),
      floatingActionButton: Obx(
        () => controller.selectedCar.value == ""
            ? SizedBox()
            : FloatingActionButton(
                child: Icon(Icons.start),
                onPressed: () {
                  onButtonPressed();
                },
              ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _carsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          List list = snapshot.data.docs;
          return ListView.builder(
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  list[index].data() as Map<String, dynamic>;
              return carTile(data["carPlate"], data["id"], data["isSelected"],
                  list, data["deviceId"]);
            },
            itemCount: list.length,
          );
        },
      ),
    );
  }

  void onButtonPressed() {
    String appGroup = _appGroupEdController.text.trim();
    String strAppID = "1647670150";
    String appSign =
        "ed521f0267d540a25da3965acd8a3862879ec65da7dceca224bc3fdd4bf5a3f0";

    if (strAppID.isEmpty || appSign.isEmpty) {
      ZegoUITool.showAlert(context, 'AppID or AppSign cannot be empty');
      return;
    }

    if (Platform.isIOS && appGroup.isEmpty) {
      ZegoUITool.showAlert(context, 'AppGroup cannot be empty');
      return;
    }

    int appID = int.tryParse(strAppID);
    if (appID == null) {
      ZegoUITool.showAlert(context, 'AppID is invalid, should be int');
      return;
    }

    ZegoConfig.instance.appGroup = appGroup;
    ZegoConfig.instance.appID = appID;
    ZegoConfig.instance.appSign = appSign;
    ZegoConfig.instance.saveConfig();

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return ScreenCaptureLoginPage();
    }));
  }

  Widget carTile(
      String carName, String carId, bool isSelected, List carList, deviceIdd) {
    deviceId == deviceIdd ? controller.selectedCar.value = carName : null;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () async {
          var id = await PlatformDeviceId.getDeviceId;

          print('Running on $id');
          if (!isSelected) {
            for (var i in carList) {
              if (i["deviceId"] == id) {
                await MyFirestoreServices().updateCar(i["id"], "", false);
              }
            }
            controller.selectedCar.value = carName;
            await MyFirestoreServices().updateCar(carId, id, true);
          }
          if (isSelected && controller.selectedCar.value == carName) {
            controller.selectedCar.value = "";
            await MyFirestoreServices().updateCar(carId, "", false);
          }
        },
        child: Container(
          height: 50,
          child: Center(
              child: Text(
            carName ?? "",
            style: TextStyle(color: Colors.white),
          )),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: deviceId == deviceIdd
                  ? Colors.green
                  : isSelected
                      ? Colors.red
                      : Colors.black),
        ),
      ),
    );
  }
}
