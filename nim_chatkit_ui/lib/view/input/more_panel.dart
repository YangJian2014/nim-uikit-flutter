// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:nim_chatkit_ui/view/page/location_map_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../../view_model/chat_view_model.dart';
import 'actions.dart';

class MorePanel extends StatefulWidget {
  const MorePanel({Key? key, this.moreActions, this.keepDefault = true})
      : super(key: key);

  final bool keepDefault;
  final List<ActionItem>? moreActions;

  @override
  State<StatefulWidget> createState() => _MorePanelState();
}

class _MorePanelState extends State<MorePanel> {
  static const int pageSize = 8;
  final ImagePicker _picker = ImagePicker();

  List<ActionItem> getActions() {
    if (widget.moreActions != null) {
      return [
        if (widget.keepDefault) ..._defaultMoreActions(),
        ...widget.moreActions!,
      ];
    }
    return _defaultMoreActions();
  }

  List<ActionItem> _defaultMoreActions() {
    var imageText = S.of(context).chatMessageBriefImage.replaceAll(r'[', '');
    imageText = imageText.replaceAll(r']', '');

    return [
      ActionItem(
          type: ActionConstants.shoot,
          icon: SvgPicture.asset(
            'images/ic_send_image.svg',
            package: kPackage,
          ),
          title: imageText,
          permissions: [Permission.camera],
          onTap: _pickImage),
      ActionItem(
          type: ActionConstants.shoot,
          icon: SvgPicture.asset(
            'images/ic_shoot.svg',
            package: kPackage,
          ),
          title: S.of(context).chatMessageMoreShoot,
          permissions: [Permission.camera],
          onTap: _onShootActionTap),
      ActionItem(
          type: ActionConstants.location,
          icon: SvgPicture.asset(
            'images/ic_location.svg',
            package: kPackage,
          ),
          title: S.of(context).chatMessageMoreLocation,
          permissions: [Permission.locationWhenInUse],
          onTap: _onLocationActionTap,
          deniedTip: S.of(context).locationDeniedTips),
      ActionItem(
          type: ActionConstants.file,
          icon: SvgPicture.asset(
            'images/ic_file.svg',
            package: kPackage,
          ),
          title: S.of(context).chatMessageMoreFile,
          onTap: _onFileActionTap),
    ];
  }

  //点击位置按钮,跳转到地图页面
  _onLocationActionTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return LocationMapPage(needLocate: true);
    })).then((location) {
      if (location != null) {
        context.read<ChatViewModel>().sendLocationMessage(location);
      }
    });
  }

  _onFileActionTap(BuildContext context) async {
    final permissionList;
    if (Platform.isAndroid && await PlatformUtils.isAboveAndroidT()) {
      permissionList = [Permission.manageExternalStorage];
    } else {
      permissionList = [Permission.storage];
    }
    if (!(await PermissionsHelper.requestPermission(permissionList))) {
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    final platformFile = result?.files.single;
    if (platformFile?.path != null) {
      final overSize = 200;
      if (platformFile!.size > overSize * 1024 * 1024) {
        Fluttertoast.showToast(
            msg: S.of(context).chatMessageFileSizeOverLimit("$overSize"));
        return;
      }
      context
          .read<ChatViewModel>()
          .sendFileMessage(platformFile.path!, platformFile.name);
    } else {
      Alog.w(tag: 'MorePanel', content: 'file path is null.');
    }
  }

  _onShootActionTap(BuildContext context) async {
    final AssetEntity? resourceItem = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: const CameraPickerConfig(enableRecording: true),
    );

    if (resourceItem != null) {
      var fileItem = await resourceItem.file;
      switch (resourceItem.type) {
        case AssetType.image:
          if (fileItem != null) {
            int len = await fileItem.length();
            Alog.d(
                tag: 'ChatKit',
                moduleName: 'bottom input',
                content: 'pick image path:${fileItem.path}');
            context.read<ChatViewModel>().sendImageMessage(fileItem.path, len);
          }
          break;
        case AssetType.video:
          Alog.d(
              tag: 'ChatKit',
              moduleName: 'bottom input',
              content: 'pick video path:${fileItem?.path}');
          if (fileItem != null) {
            VideoPlayerController controller =
                VideoPlayerController.file(File(fileItem.path));
            controller.initialize().then((value) {
              context.read<ChatViewModel>().sendVideoMessage(
                  fileItem.path,
                  controller.value.duration.inMilliseconds,
                  controller.value.size.width.toInt(),
                  controller.value.size.height.toInt(),
                  resourceItem.id);
            });
          }
          break;
        default:
      }
    }
  }

  // _onShootActionTap(BuildContext context) {
  //   var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
  //   showBottomChoose<int>(
  //           context: context,
  //           actions: [
  //             CupertinoActionSheetAction(
  //               onPressed: () {
  //                 Navigator.pop(context, 1);
  //               },
  //               child: Text(
  //                 S.of(context).chatMessageTakePhoto,
  //                 style: style,
  //               ),
  //             ),
  //             CupertinoActionSheetAction(
  //               onPressed: () {
  //                 Navigator.pop(context, 2);
  //               },
  //               child: Text(
  //                 S.of(context).chatMessageTakeVideo,
  //                 style: style,
  //               ),
  //             ),
  //           ],
  //           showCancel: true)
  //       .then((value) {
  //     if (value == 1) {
  //       _onTakePhoto();
  //     } else if (value == 2) {
  //       _onTakeVideo();
  //     }
  //   });
  // }

  _onTakePhoto() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    Alog.i(
        tag: 'ChatKit',
        moduleName: 'more action',
        content: 'take photo path:${photo?.path}');
    if (photo != null) {
      int len = await photo.length();
      context.read<ChatViewModel>().sendImageMessage(photo.path, len);
    }
  }

  _onTakeVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    Alog.i(
        tag: 'ChatKit',
        moduleName: 'more action',
        content: 'take video path:${video?.path}');
    if (video != null) {
      VideoPlayerController controller =
          VideoPlayerController.file(File(video.path));
      controller.initialize().then((value) {
        context.read<ChatViewModel>().sendVideoMessage(
            video.path,
            controller.value.duration.inMilliseconds,
            controller.value.size.width.toInt(),
            controller.value.size.height.toInt(),
            video.name);
      });
    }
  }

  _pickImage(BuildContext context) async {
    final List<AssetEntity>? pickedFileList = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        // requestType: RequestType.image,
        // previewThumbnailSize: const ThumbnailSize.square(150),
        specialPickerType: SpecialPickerType.wechatMoment,
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
              Alog.d(
                  tag: 'ChatKit',
                  moduleName: 'bottom input',
                  content: 'pick image path:${fileItem.path}');
              context
                  .read<ChatViewModel>()
                  .sendImageMessage(fileItem.path, len);
            }
            break;
          case AssetType.video:
            Alog.d(
                tag: 'ChatKit',
                moduleName: 'bottom input',
                content: 'pick video path:${fileItem?.path}');
            if (fileItem != null) {
              VideoPlayerController controller =
                  VideoPlayerController.file(File(fileItem.path));
              controller.initialize().then((value) {
                context.read<ChatViewModel>().sendVideoMessage(
                    fileItem.path,
                    controller.value.duration.inMilliseconds,
                    controller.value.size.width.toInt(),
                    controller.value.size.height.toInt(),
                    resourceItem.id);
              });
            }
            break;
          default:
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ActionItem> moreActions = getActions();
    List<Widget> pages = [];
    int size = (moreActions.length / pageSize).ceil();
    for (int i = 0; i < size; ++i) {
      int start = i * pageSize;
      int end = start + pageSize > moreActions.length
          ? moreActions.length
          : start + pageSize;
      pages.add(MoreActionPage(actions: moreActions.sublist(start, end)));
    }
    return PageView(
      children: pages,
      allowImplicitScrolling: true,
    );
  }
}

class MoreActionPage extends StatelessWidget {
  const MoreActionPage({Key? key, required this.actions}) : super(key: key);

  final List<ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Wrap(
          spacing: (sw - 56 * 4 - 16 * 2) / 3,
          runSpacing: 16,
          children: actions.map((action) {
            return MoreItemAction(action: action);
          }).toList(),
        ),
      ),
    );
  }
}

class MoreItemAction extends StatelessWidget {
  const MoreItemAction({Key? key, required this.action}) : super(key: key);

  final ActionItem action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: action.permissions != null
              ? () {
                  PermissionsHelper.requestPermission(action.permissions!,
                          deniedTip: action.deniedTip)
                      .then((value) {
                    if (value && action.onTap != null) {
                      action.onTap!(context);
                    }
                  });
                }
              : () {
                  if (action.onTap != null) {
                    action.onTap!(context);
                  }
                },
          child: Container(
            height: 56,
            width: 56,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: action.icon,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          action.title ?? "",
          style:
              const TextStyle(fontSize: 12, color: CommonColors.color_666666),
        )
      ],
    );
  }
}
