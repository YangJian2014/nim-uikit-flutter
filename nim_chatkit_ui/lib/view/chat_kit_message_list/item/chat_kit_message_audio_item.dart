// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:nim_core/nim_core.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../chat_kit_client.dart';
import '../../../media/audio_player.dart';

class ChatKitMessageAudioItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageAudioItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageAudioState();
}

class ChatKitMessageAudioState extends State<ChatKitMessageAudioItem>
    with RouteAware {
  final List<String> toAniList = [
    'images/ic_sound_to_1.svg',
    'images/ic_sound_to_2.svg',
    'images/ic_sound_to_3.svg'
  ];

  final List<String> fromAniList = [
    'images/ic_sound_from_1.svg',
    'images/ic_sound_from_2.svg',
    'images/ic_sound_from_3.svg'
  ];

  StreamSubscription? _phoneStateSub;

  int aniIndex = 2;

  Timer? _timer;

  bool isPlaying = false;

  double _getWidth(NIMMessage message) {
    int dur = _getAudioLen(message);
    double baseLen = 77.0;
    double maxLen = 265.0;
    if (dur <= 2) {
      return baseLen;
    } else {
      return min(maxLen, baseLen + (dur - 2) * 8);
    }
  }

  int _getAudioLen(NIMMessage message) {
    NIMAudioAttachment attachment =
        message.messageAttachment as NIMAudioAttachment;
    int len = attachment.duration == null ? 0 : attachment.duration!;
    return (len / 1000).truncate();
  }

  Widget _getAudioUI(NIMMessage message) {
    if (message.messageDirection == NIMMessageDirection.outgoing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${_getAudioLen(message)}s',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          SvgPicture.asset(
            isPlaying ? toAniList[aniIndex] : toAniList[2],
            package: kPackage,
            width: 28,
            height: 28,
            color: Colors.black,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SvgPicture.asset(
            isPlaying ? fromAniList[aniIndex] : fromAniList[2],
            package: kPackage,
            width: 28,
            height: 28,
          ),
          Text(
            '${_getAudioLen(message)}s',
            style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
          ),
        ],
      );
    }
  }

  void _startAudioPlay(NIMMessage message) {
    isPlaying = true;
    _timer?.cancel();
    var attachment = message.messageAttachment as NIMAudioAttachment;
    if (attachment.path != null) {
      _playAudio(attachment.path!, attachment.duration!);
    } else {
      NimCore.instance.messageService
          .downloadAttachment(message: message, thumb: false)
          .then((value) {
        if (value.isSuccess) {
          _playAudio(attachment.path!, attachment.duration!);
        } else {
          isPlaying = false;
        }
      });
    }
  }

  void _playAudio(String path, int duration) async {
    if (isPlaying == false) {
      return;
    }
    _handlePhoneCall();
    ChatAudioPlayer.instance
        .play(widget.message.uuid!, DeviceFileSource(path),
            stopAction: _stopPlayAni)
        .then((value) {
      if (value) {
        _startPlayAni(duration);
      } else {
        isPlaying = false;
      }
    });
  }

  void _stopAudioPlay() {
    ChatAudioPlayer.instance.stop(widget.message.uuid!);
    _stopPlayAni();
  }

  void _startPlayAni(int duration) {
    if (isPlaying == false) {
      _stopAudioPlay();
      return;
    }
    isPlaying = true;
    if (mounted) {
      setState(() {});
    }

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (aniIndex >= 2) {
          aniIndex = 0;
        } else {
          aniIndex++;
        }
      });
      if (200 * timer.tick >= duration) {
        _stopAudioPlay();
      }
    });
  }

  void _stopPlayAni() {
    _timer?.cancel();
    if (isPlaying && mounted) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  //监听权限
  Future<bool?> _requestPermission() async {
    var status = await Permission.phone.request();

    switch (status) {
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.permanentlyDenied:
        return false;
      case PermissionStatus.granted:
        return true;
      default:
        return true;
    }
  }

  //处理来电话播放器停止播放的操作
  void _handlePhoneCall() async {
    _phoneStateSub?.cancel();
    bool havePermission = true;
    if (Platform.isAndroid) {
      havePermission = await _requestPermission() ?? true;
    }
    if (havePermission) {
      // _phoneStateSub = PhoneState.phoneStateStream.listen((event) {
      //   if (event != null &&
      //       ChatAudioPlayer.instance.isPlaying(widget.message.uuid!)) {
      //     _stopAudioPlay();
      //   }
      // });
    }
  }

  @override
  void initState() {
    super.initState();
    ChatAudioPlayer.instance
        .getCurrentPosition(widget.message.uuid!)
        .then((value) {
      //如果消息未播放完成则恢复动画
      if (value != null) {
        var attachment = widget.message.messageAttachment as NIMAudioAttachment;
        var durLast = attachment.duration! - value.inMilliseconds;
        _startPlayAni(durLast);
      }
    });
    Future.delayed(Duration.zero, () {
      IMKitRouter.instance.routeObserver
          .subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void didPushNext() {
    //打开其他页面之前停止播放
    super.didPushNext();
    _stopAudioPlay();
    _timer?.cancel();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    _phoneStateSub?.cancel();
  }

  bool _isSelf() {
    return (widget.message.messageDirection == NIMMessageDirection.outgoing);
  }

  //  获取本地消息语音转换成文字
  bool _getMessageToVoiceStatus(NIMMessage? chatMessage) {
    if (chatMessage == null) {
      return false;
    }
    if (chatMessage.messageAttachment == null) {
      return false;
    }

    try {
      // 做一下保护，防止以后增加字段覆盖本地逻辑
      if (chatMessage.localExtension == null) {
        return false;
      } else {
        var localExtension = chatMessage.localExtension;
        return localExtension?['toVoice'] ?? false;
      }
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<String?> _getVoiceText() async {
    NIMResult<String> result = await NimCore.instance.messageService
        .voiceToText(message: widget.message);
    return result.data;
  }

  Widget _getTranstedView() {
    return SizedBox(
      width: 230, //_getWidth(widget.message),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.0),
        padding: const EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
        child: Column(
          children: [
            _getAudioUI(widget.message),
            Divider(
              color: _isSelf() ? Colors.grey.shade100 : Colors.grey.shade400,
            ),
            FutureBuilder<String?>(
              future: _getVoiceText(),
              builder: (context, snapshot) {
                return Text(snapshot.data == null ? '' : snapshot.data!,
                    style: TextStyle(
                        color: _isSelf() ? Colors.white : Colors.black));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSrcView() {
    return SizedBox(
      width: _getWidth(widget.message),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.0),
        padding: const EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
        child: Column(
          children: [
            _getAudioUI(widget.message),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (isPlaying) {
            _stopAudioPlay();
          } else {
            _startAudioPlay(widget.message);
          }
        },
        child: _getMessageToVoiceStatus(widget.message)
            ? _getTranstedView()
            : _getSrcView());
  }
}
