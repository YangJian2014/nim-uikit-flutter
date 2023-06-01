// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/widgets/unread_message.dart';
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
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color:
          conversationInfo.isStickTop ? const Color(0xffededef) : Colors.white,
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
                height: 42,
                width: 42,
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
            left: 54,
            top: 10,
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
                  isSupportMessageType(conversationInfo.session.lastMessageType)
                      ? (conversationInfo.session.lastMessageContent ?? '')
                      : S.of(context).chatMessageNonsupportType,
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
                    fontSize: config.itemDateSize, color: config.itemDateColor),
              )),
          if (conversationInfo.mute)
            Positioned(
              right: 0,
              bottom: 10,
              child: SvgPicture.asset(
                'images/ic_mute.svg',
                package: kPackage,
              ),
            )
        ],
      ),
    );
  }
}
