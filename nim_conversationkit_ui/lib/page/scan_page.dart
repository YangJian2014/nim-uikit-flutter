// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:flutter/material.dart';
// import 'package:nim_conversationkit_ui/page/network_helper.dart';
import 'package:recognition_qrcode/recognition_qrcode.dart' as qrCode;
import 'package:utils/utils.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = true;
  String _scanData = '';

  _pickImage() async {
    setState(() {
      _isScanning = false;
      _scanData = '';
    });

    final List<AssetEntity>? pickedFileList = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.image,
        // previewThumbnailSize: const ThumbnailSize.square(150),
        // specialPickerType: SpecialPickerType.wechatMoment,
      ),
    );

    // final List<XFile>? pickedFileList = await _picker.pickMultiImage();
    if (pickedFileList != null) {
      for (AssetEntity resourceItem in pickedFileList) {
        var fileItem = await resourceItem.file;

        switch (resourceItem.type) {
          case AssetType.image:
            if (fileItem != null) {
              int len = await fileItem.length();
              UtilsNetworkHelper.showLoading();

              qrCode.RecognitionQrcode.recognition(fileItem.path)
                  .then((result) {
                UtilsNetworkHelper.hideLoading();
                String rawValue = result['value'] ?? '';

                print("recognition: $result");

                // String rawValue = result ?? '';
                if (rawValue.isEmpty) {
                  UtilsNetworkHelper.utilShowToast('二维码内容为空');
                  setState(() {
                    _isScanning = true;
                    _scanData = '';
                  });
                  return;
                }

                _processValue(rawValue);
                setState(() {
                  _isScanning = false;
                  _scanData = rawValue;
                });
              });
              // _viewModel.sendImageMessage(fileItem.path, len);
            }
            break;

          default:
        }
      }
    } else {
      setState(() {
        _isScanning = true;
        _scanData = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('扫一扫'), // S.of(context).group_scan
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              child: const Icon(
                Icons.image_outlined,
                size: 30,
              ),
              onTap: () {
                _pickImage();
              },
            ),
          )
        ],
      ),
      body: _isScanning
          ? Padding(
              padding: const EdgeInsets.all(30),
              child: _getScanView(),
            )
          : Center(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('扫描结果：$_scanData')),
            ),
    );
  }

  Widget _getScanView() {
    return MobileScanner(
      fit: BoxFit.contain,
      controller: MobileScannerController(
          // facing: CameraFacing.back,
          // torchEnabled: false,
          // returnImage: true,
          ),
      onDetect: (barCode, mobileScannerArguments) {
        debugPrint('Barcode found! ${barCode.rawValue}');
        String rawValue = barCode.rawValue ?? '';
        if (rawValue.isEmpty) {
          UtilsNetworkHelper.utilShowToast('二维码内容为空');
          return;
        }

        _processValue(rawValue);

        // final List<Barcode> barcodes = capture.barcodes;
        // final Uint8List? image = capture.image;
        // for (final barcode in barcodes) {
        //   debugPrint('Barcode found! ${barcode.rawValue}');
        // }
        // if (image != null) {
        //   showDialog(
        //     context: context,
        //     builder: (context) => Image(image: MemoryImage(image)),
        //   );
        //   Future.delayed(const Duration(seconds: 5), () {
        //     Navigator.pop(context);
        //   });
        // }
      },
    );
  }

  _processValue(String rawValue) {
    try {
      var object = jsonDecode(rawValue);
      if (object != null) {
        String dataString = object['data'] ?? '';

        String type = object['type'] ?? '';
        if (type == 'team') {
          setState(() {
            _isScanning = false;
            _scanData = dataString;
          });

          // 申请入群
          showCommonDialog(
                  context: context,
                  title: '温馨提示',
                  content: '申请加入群号为：$dataString 的群聊？',
                  navigateContent: '取消',
                  positiveContent: '确认')
              .then((value) {
            if (value ?? false) {
              _addToGroup(dataString);
            } else {
              setState(() {
                _isScanning = true;
                _scanData = '';
              });
            }
          });
        } else if (type == 'person') {
          setState(() {
            _isScanning = false;
            _scanData = dataString;
          });

          // 加好友
          showCommonDialog(
                  context: context,
                  title: '温馨提示',
                  content: '申请添加 $dataString 为好友？',
                  navigateContent: '取消',
                  positiveContent: '确认')
              .then((value) {
            if (value ?? false) {
              _addPerson(dataString);
            } else {
              setState(() {
                _isScanning = true;
                _scanData = '';
              });
            }
          });
        }
      }
    } catch (e) {
      UtilsNetworkHelper.utilShowToast('二维码格式不正确:$rawValue');
    }
  }

  // 申请入群
  _addToGroup(String tid) async {
    Map<String, String> userParams = {'tid': tid};
    var response = await UtilsNetworkHelper.groupQRInveted(userParams);
    var rspData = response?.data;
    var code = rspData['code'] ?? -1;
    UtilsNetworkHelper.utilShowToast('${rspData['msg'] ?? ''}');

    if (!mounted) {
      return;
    }

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  // 添加好友
  _addPerson(String userId) async {
    LoginService _loginService = getIt<LoginService>();
    String nickName = _loginService.userInfo?.nick ?? '';

    Map<String, String> userParams = {
      'faccid': userId,
      'msg': '我是$nickName申请添加好友'
    };
    var response = await UtilsNetworkHelper.friendAdd(userParams);
    var rspData = response?.data;
    var code = rspData['code'] ?? -1;
    UtilsNetworkHelper.utilShowToast('${rspData['msg'] ?? ''}');

    if (!mounted) {
      return;
    }

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }
}
