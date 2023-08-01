// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(size) => "Sure(${size})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "addFriend": MessageLookupByLibrary.simpleMessage("add friends"),
        "addFriendSearchEmptyTips":
            MessageLookupByLibrary.simpleMessage("This user does not exist"),
        "addFriendSearchHint":
            MessageLookupByLibrary.simpleMessage("Please enter account"),
        "cancelStickTitle":
            MessageLookupByLibrary.simpleMessage("Cancel stick"),
        "cancelTitle": MessageLookupByLibrary.simpleMessage("Cancel"),
        "chatMessageNonsupportType":
            MessageLookupByLibrary.simpleMessage("[Nonsupport message type]"),
        "conversationEmpty": MessageLookupByLibrary.simpleMessage("no chat"),
        "conversationNetworkErrorTip": MessageLookupByLibrary.simpleMessage(
            "The current network is unavailable, please check your network settings."),
        "conversationTitle":
            MessageLookupByLibrary.simpleMessage("CommsEase IM"),
        "createAdvancedTeam":
            MessageLookupByLibrary.simpleMessage("create advanced team"),
        "createAdvancedTeamSuccess": MessageLookupByLibrary.simpleMessage(
            "create advanced team success"),
        "createGroupTeam":
            MessageLookupByLibrary.simpleMessage("create group team"),
        "deleteTitle": MessageLookupByLibrary.simpleMessage("Delete"),
        "group_scan": MessageLookupByLibrary.simpleMessage("Scan"),
        "recentTitle": MessageLookupByLibrary.simpleMessage("Recent chat"),
        "search": MessageLookupByLibrary.simpleMessage("search"),
        "stickTitle": MessageLookupByLibrary.simpleMessage("Stick"),
        "sureCountTitle": m0,
        "sureTitle": MessageLookupByLibrary.simpleMessage("Sure")
      };
}
