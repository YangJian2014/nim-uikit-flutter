// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(size) => "确定(${size})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "addFriend": MessageLookupByLibrary.simpleMessage("添加好友"),
        "addFriendSearchEmptyTips":
            MessageLookupByLibrary.simpleMessage("该用户不存在"),
        "addFriendSearchHint": MessageLookupByLibrary.simpleMessage("请输入账号"),
        "cancelStickTitle": MessageLookupByLibrary.simpleMessage("取消置顶"),
        "cancelTitle": MessageLookupByLibrary.simpleMessage("取消"),
        "chatMessageNonsupportType":
            MessageLookupByLibrary.simpleMessage("[当前版本暂不支持该消息体]"),
        "conversationEmpty": MessageLookupByLibrary.simpleMessage("暂无会话"),
        "conversationNetworkErrorTip":
            MessageLookupByLibrary.simpleMessage("当前网络不可用，请检查你当网络设置。"),
        "conversationTitle": MessageLookupByLibrary.simpleMessage("云信IM"),
        "createAdvancedTeam": MessageLookupByLibrary.simpleMessage("创建高级群"),
        "createAdvancedTeamSuccess":
            MessageLookupByLibrary.simpleMessage("成功创建高级群"),
        "createGroupTeam": MessageLookupByLibrary.simpleMessage("创建讨论组"),
        "deleteTitle": MessageLookupByLibrary.simpleMessage("删除"),
        "group_scan": MessageLookupByLibrary.simpleMessage("扫一扫"),
        "recentTitle": MessageLookupByLibrary.simpleMessage("最近聊天"),
        "search": MessageLookupByLibrary.simpleMessage("搜索"),
        "stickTitle": MessageLookupByLibrary.simpleMessage("置顶"),
        "sureCountTitle": m0,
        "sureTitle": MessageLookupByLibrary.simpleMessage("确定")
      };
}
