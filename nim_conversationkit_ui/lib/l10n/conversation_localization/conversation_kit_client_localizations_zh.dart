// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.



import 'conversation_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ConversationKitClientLocalizationsZh extends ConversationKitClientLocalizations {
  ConversationKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get conversationTitle => '云信IM';

  @override
  String get createAdvancedTeamSuccess => '成功创建高级群';

  @override
  String get stickTitle => '置顶';

  @override
  String get cancelStickTitle => '取消置顶';

  @override
  String get deleteTitle => '删除';

  @override
  String get recentTitle => '最近聊天';

  @override
  String get cancelTitle => '取消';

  @override
  String get sureTitle => '确定';

  @override
  String sureCountTitle(int size) {
    return '确定($size)';
  }

  @override
  String get conversationNetworkErrorTip => '当前网络不可用，请检查你当网络设置。';

  @override
  String get addFriend => '添加好友';

  @override
  String get addFriendSearchHint => '请输入账号';

  @override
  String get addFriendSearchEmptyTips => '该用户不存在';

  @override
  String get createGroupTeam => '创建讨论组';

  @override
  String get createAdvancedTeam => '创建高级群';

  @override
  String get chatMessageNonsupportType => '[当前版本暂不支持该消息体]';

  @override
  String get conversationEmpty => '暂无会话';

  @override
  String get group_scan => '扫一扫';

  @override
  String get search => '搜索';
}
