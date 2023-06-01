// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_helper.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:nim_core/nim_core.dart';

class ChatKitMessageNotificationItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageNotificationItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageNotificationState();
}

class ChatKitMessageNotificationState
    extends State<ChatKitMessageNotificationItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 8),
      child: FutureBuilder<String>(
        future: NotifyHelper.getNotificationText(widget.message),
        builder: (context, snap) {
          return Text(
            snap.data ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: '#999999'.toColor()),
          );
        },
      ),
    );
  }
}
