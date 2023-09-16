// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/widgets/unread_message.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_conversationkit/model/conversation_info.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_conversationkit_ui/l10n/S.dart';

bool isSupportMessageType(NIMMessageType? type) {
  return type == NIMMessageType.text ||
      type == NIMMessageType.audio ||
      type == NIMMessageType.image ||
      type == NIMMessageType.video ||
      type == NIMMessageType.notification ||
      type == NIMMessageType.tip ||
      type == NIMMessageType.file ||
      type == NIMMessageType.custom ||
      type == NIMMessageType.location;
}

class ConversationItem extends StatelessWidget {
  const ConversationItem(
      {Key? key,
      required this.conversationInfo,
      required this.config,
      required this.index})
      : super(key: key);

  final ConversationInfo conversationInfo;
  final ConversationItemConfig config;
  final int index;

  bool _isRedPacketContent() {
    var content = conversationInfo.session.lastMessageContent ?? '';
    if (conversationInfo.session.lastMessageType != null) {
      if (conversationInfo.session.lastMessageType != NIMMessageType.custom) {
        return false;
      }

      var attachMsg = conversationInfo.session.lastMessageAttachment?.toMap();
      if (attachMsg == null) {
        return false;
      }
      var customMsgType = attachMsg['msg_type'];

      // 非红包消息
      if (customMsgType != 1) {
        return false;
      }
    }

    return true;
  }

  String _getLastContent(BuildContext context) {
    if (!isSupportMessageType(conversationInfo.session.lastMessageType)) {
      return S.of(context).chatMessageNonsupportType;
    }

    var content = conversationInfo.session.lastMessageContent ?? '';
    if (conversationInfo.session.lastMessageType != null) {
      if (_isRedPacketContent()) {
        String type = '收到';
        LoginService _loginService = getIt<LoginService>();
        if (_loginService.userInfo?.userId ==
            conversationInfo.session.senderAccount) {
          type = '发送了';
        }

        return '你$type一个红包';
      }
      if (conversationInfo.session.lastMessageType != NIMMessageType.tip) {
        return content;
      }
    }
    try {
      var obj = jsonDecode(content);
      if (obj == null) {
        return content;
      }
      var from = obj['content'];
      if (from != null) {
        return '$from';
      }
    } catch (e) {
      return content;
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    String? avatar;
    String? name;
    String? avatarName;
    if (conversationInfo.session.sessionType == NIMSessionType.p2p) {
      avatar = conversationInfo.getAvatar();
      name = conversationInfo.getName();
      avatarName = conversationInfo.getName(needAlias: false);
    } else if (conversationInfo.session.sessionType == NIMSessionType.team ||
        conversationInfo.session.sessionType == NIMSessionType.superTeam) {
      avatar = conversationInfo.team?.icon;
      name = conversationInfo.team?.name;
      avatarName = name;
    }
    return Column(
      children: [
        Divider(
          height: 1,
          indent: 15,
          endIndent: 15,
          color: Color.fromARGB(255, 221, 212, 212),
        ),
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          color: /*conversationInfo.isStickTop
              ? const Color(0xffededef)
              : Colors.white*/
              Colors.transparent,
          alignment: Alignment.centerLeft,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  child: Avatar(
                    avatar: avatar,
                    name: avatarName,
                    height: 50,
                    width: 50,
                    radius: config.avatarCornerRadius,
                  ),
                  onTap: () {
                    if (config.avatarClick != null &&
                        config.avatarClick!(conversationInfo, index)) {
                      return;
                    }
                  },
                  onLongPress: () {
                    if (config.avatarLongClick != null &&
                        config.avatarLongClick!(conversationInfo, index)) {
                      return;
                    }
                  },
                ),
              ),
              if (!conversationInfo.mute)
                Positioned(
                    top: 7,
                    left: 27,
                    child: UnreadMessage(
                      count: conversationInfo.session.unreadCount ?? 0,
                    )),
              Positioned(
                left: 60,
                top: 14,
                right: conversationInfo.mute ? 20 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 70),
                      child: Text(
                        name ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: config.itemTitleSize,
                            color: config.itemTitleColor),
                      ),
                    ),
                    Text(
                      _getLastContent(context),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: config.itemContentSize,
                          color: config.itemContentColor),
                    ),
                  ],
                ),
              ),
              Positioned(
                  right: 0,
                  top: 17,
                  child: Text(
                    conversationInfo.session.lastMessageTime!.formatDateTime(),
                    style: TextStyle(
                        fontSize: config.itemDateSize,
                        color: config.itemDateColor),
                  )),
              if (conversationInfo.mute)
                Positioned(
                  right: 0,
                  bottom: 10,
                  child: SvgPicture.asset(
                    'images/ic_mute.svg',
                    package: kPackage,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
