// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart' as Intl;
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/progress_ring.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:netease_corekit_im/services/team/team_provider.dart';
import 'package:nim_chatkit/message/message_reply_info.dart';
import 'package:nim_chatkit/message/message_revoke_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_audio_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_file_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_image_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_location_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_nonsupport_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_notify_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_tips_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_video_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/check_button.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_message_pop_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/page/chat_message_ack_page.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../../chat_kit_client.dart';
import '../../../view_model/chat_view_model.dart';
import 'chat_kit_message_text_item.dart';

typedef ChatMessageItemBuilder = Widget Function(NIMMessage message);

class ChatKitMessageBuilder {
  ChatMessageItemBuilder? textMessageBuilder;
  ChatMessageItemBuilder? audioMessageBuilder;
  ChatMessageItemBuilder? imageMessageBuilder;
  ChatMessageItemBuilder? videoMessageBuilder;
  ChatMessageItemBuilder? notifyMessageBuilder;
  ChatMessageItemBuilder? tipsMessageBuilder;
  ChatMessageItemBuilder? fileMessageBuilder;
  ChatMessageItemBuilder? locationMessageBuilder;
  Map<NIMMessageType, ChatMessageItemBuilder?>? extendBuilder;
}

class ChatKitMessageItem extends StatefulWidget {
  final ChatMessage chatMessage;

  final ChatMessage? lastMessage;

  final NIMTeam? teamInfo;

  final ChatKitMessageBuilder? messageBuilder;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final void Function(ChatMessage message)? onTapFailedMessage;

  final Function(String messageId) scrollToIndex;

  final PopMenuAction? popMenuAction;

  final bool showReadAck;

  final ChatUIConfig? chatUIConfig;

  final bool? isSelected;

  ChatKitMessageItem(
      {Key? key,
      required this.chatMessage,
      required this.lastMessage,
      this.messageBuilder,
      this.showReadAck = true,
      this.onTapAvatar,
      this.popMenuAction,
      this.onTapFailedMessage,
      required this.scrollToIndex,
      this.teamInfo,
      this.chatUIConfig,
      this.onMessageItemClick,
      this.onMessageItemLongClick,
      this.isSelected})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageItemState();
}

class ChatKitMessageItemState extends State<ChatKitMessageItem> {
  static const showTimeInterval = 5 * 60 * 1000;

  static const maxReceiptNum = 100;

  //重新编辑展示时间
  static const reeditTime = 2 * 60 * 1000;

  int _teamAck = 0;

  int _teamUnAck = 0;

  late UserAvatarInfo _userAvatarInfo = widget
      .chatMessage.nimMessage.fromAccount!
      .getCacheAvatar(widget.chatMessage.nimMessage.fromNickname ??
          widget.chatMessage.nimMessage.fromAccount!);

  MessageItemConfig _getMessageItemConfig(NIMMessage message) {
    if (message.messageType == NIMMessageType.image ||
        message.messageType == NIMMessageType.video ||
        message.messageType == NIMMessageType.location) {
      return MessageItemConfig(showMsgCommonBg: false);
    } else if (message.messageType == NIMMessageType.file) {
      return MessageItemConfig(
          showMsgCommonBg: false, showMsgLoadingState: false);
    }
    return MessageItemConfig();
  }

  _log(String text) {
    Alog.d(tag: 'ChatKit', moduleName: 'MessageItem', content: text);
  }

  // 修改选中状态
  _changeSelectStatus(NIMMessage? chatMessage, bool isSelected) async {
    if (chatMessage == null) {
      return;
    }
    if (chatMessage.messageAttachment == null) {
      return;
    }

    try {
      // 做一下保护，防止以后增加字段覆盖本地逻辑
      if (chatMessage.localExtension == null) {
        var localExtension = {'isSelected': isSelected};
        chatMessage.localExtension = localExtension;
      } else {
        var localExtension = chatMessage.localExtension;
        localExtension!['isSelected'] = isSelected;
        chatMessage.localExtension = localExtension;
      }

      await NimCore.instance.messageService
          .updateMessage(chatMessage)
          .then((value) {
        return value;
      });
    } catch (e) {
      print(e);
    }
  }

  //  获取本地消息选中状态
  bool _getMessageSelectStatus(NIMMessage? chatMessage) {
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
        return localExtension?['isSelected'] ?? false;
      }
    } catch (e) {
      print(e);
    }

    return false;
  }

  bool isSelf() {
    return widget.chatMessage.nimMessage.messageDirection ==
        NIMMessageDirection.outgoing;
  }

  ChatKitMessagePopMenu? _popMenu;

  bool isTeam() {
    return widget.chatMessage.nimMessage.sessionType == NIMSessionType.team;
  }

  bool _showMsgAck(ChatMessage message) {
    if (message.nimMessage.sessionType == NIMSessionType.p2p &&
        widget.chatUIConfig?.showP2pMessageStatus == false) {
      return false;
    }
    if (message.nimMessage.sessionType == NIMSessionType.team &&
        widget.chatUIConfig?.showTeamMessageStatus == false) {
      return false;
    }
    return message.nimMessage.messageAck &&
        (widget.teamInfo?.memberCount ?? 0) < maxReceiptNum;
  }

  int _getProcess(ChatMessage message) {
    if (widget.chatMessage.nimMessage.sessionType == NIMSessionType.p2p) {
      int receiptTime = context.watch<ChatViewModel>().receiptTime;
      if (receiptTime >= message.nimMessage.timestamp ||
          message.nimMessage.isRemoteRead == true) {
        return 1;
      } else {
        return 0;
      }
    }
    if (message.ackCount > 0) {
      _teamAck = message.ackCount;
    }
    return _teamAck;
  }

  int _getAllAck(ChatMessage message) {
    if (message.nimMessage.sessionType == NIMSessionType.p2p) {
      return 1;
    } else {
      if (message.ackCount > 0 || message.unAckCount > 0) {
        _teamAck = message.ackCount;
        _teamUnAck = message.unAckCount;
        _log('_getAllAck _teamUnAck:$_teamUnAck, _teamAck:$_teamAck');
      }
      return _teamAck + _teamUnAck;
    }
  }

  double getMaxWidth(isSelect) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return width - (isSelect ? 130 : 110);
  }

  bool showNickname() {
    return widget.chatMessage.nimMessage.sessionType == NIMSessionType.team &&
        !isSelf();
  }

  _onLongPress(BuildContext context) {
    _popMenu?.clean();
    _popMenu = null;
    _popMenu = ChatKitMessagePopMenu(widget.chatMessage, context,
        popMenuAction: widget.popMenuAction, chatUIConfig: widget.chatUIConfig);
    _popMenu!.show();
  }

  bool _showReeditText(RevokedMessageInfo? revokedMessageInfo) {
    var message = widget.chatMessage;
    return isSelf() &&
        message.nimMessage.messageType == NIMMessageType.text &&
        revokedMessageInfo != null &&
        DateTime.now().millisecondsSinceEpoch - message.nimMessage.timestamp <
            reeditTime;
  }

  Widget _buildRevokedMessage(ChatMessage message) {
    RevokedMessageInfo? revokedMessageInfo;
    if ((message.nimMessage.localExtension?[ChatMessage.keyRevokeMsgContent]
            is Map) &&
        (message.nimMessage.localExtension?[ChatMessage.keyRevokeMsgContent]
                    as Map?)
                ?.isNotEmpty ==
            true) {
      revokedMessageInfo = RevokedMessageInfo.fromMap((message.nimMessage
              .localExtension![ChatMessage.keyRevokeMsgContent] as Map)
          .cast<String, dynamic>());
    }
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of().chatMessageHaveBeenRevoked,
              style: TextStyle(fontSize: 16, color: '#333333'.toColor())),
          if (_showReeditText(revokedMessageInfo))
            InkWell(
              onTap: () {
                context.read<ChatViewModel>().reeditMessage =
                    revokedMessageInfo;
              },
              child: Text(S.of().chatMessageReedit,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: '#1861DF'.toColor())),
            )
        ],
      ),
    );
  }

  String? _getReplyMessageId(ChatMessage message) {
    var replyMessageInfoMap =
        message.nimMessage.remoteExtension?[ChatMessage.keyReplyMsgKey] as Map?;
    if (replyMessageInfoMap != null) {
      return ReplyMessageInfo.fromMap(
              replyMessageInfoMap.cast<String, dynamic>())
          .idClient;
    }
    return null;
  }

  bool _showReplyMessage(ChatMessage message) {
    return _getReplyMessageId(message)?.isNotEmpty == true;
  }

  Widget _buildMessageReply(ChatMessage message) {
    String? replyMsgId = _getReplyMessageId(message);
    return Container(
        padding: const EdgeInsets.only(left: 10, top: 5, right: 10),
        child: GestureDetector(
          child: FutureBuilder<String>(
            future: ChatMessageHelper.getReplayMessageText(context, replyMsgId!,
                message.nimMessage.sessionId!, message.nimMessage.sessionType!),
            builder: (context, snapshot) {
              return Text(
                '${S.of(context).chatMessageActionReply} | ${snapshot.data}',
                textWidthBasis: TextWidthBasis.parent,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 13, color: Color.fromARGB(255, 212, 212, 212)),
              );
            },
          ),
          onTap: () {
            widget.scrollToIndex(replyMsgId);
          },
        ));
  }

  Widget _buildMessage(ChatMessage message) {
    var messageItemBuilder = widget.messageBuilder;
    switch (message.nimMessage.messageType) {
      case NIMMessageType.text:
        if (messageItemBuilder?.textMessageBuilder != null) {
          return messageItemBuilder!.textMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageTextItem(
            text: message.nimMessage.content!,
            chatUIConfig: widget.chatUIConfig,
            isSelf: isSelf());
      case NIMMessageType.audio:
        if (messageItemBuilder?.audioMessageBuilder != null) {
          return messageItemBuilder!.audioMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageAudioItem(message: message.nimMessage);
      case NIMMessageType.image:
        if (messageItemBuilder?.imageMessageBuilder != null) {
          return messageItemBuilder!.imageMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageImageItem(message: message.nimMessage);
      case NIMMessageType.video:
        if (messageItemBuilder?.videoMessageBuilder != null) {
          return messageItemBuilder!.videoMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageVideoItem(message: message.nimMessage);
      case NIMMessageType.notification:
        //如果被过滤，则返回空Widget
        if (!_filterNotification(message.nimMessage)) {
          return Container();
        }
        if (messageItemBuilder?.notifyMessageBuilder != null) {
          return messageItemBuilder!.notifyMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageNotificationItem(message: message.nimMessage);
      case NIMMessageType.tip:
        if (messageItemBuilder?.tipsMessageBuilder != null) {
          return messageItemBuilder!.tipsMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageTipsItem(message: message.nimMessage);
      case NIMMessageType.file:
        if (messageItemBuilder?.fileMessageBuilder != null) {
          return messageItemBuilder!.fileMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageFileItem(message: message.nimMessage);

      case NIMMessageType.location:
        if (messageItemBuilder?.locationMessageBuilder != null) {
          return messageItemBuilder!.locationMessageBuilder!
              .call(message.nimMessage);
        }
        return ChatKitMessageLocationItem(message: message.nimMessage);
      default:
        if (messageItemBuilder?.extendBuilder != null) {
          if (messageItemBuilder
                  ?.extendBuilder![message.nimMessage.messageType] !=
              null) {
            return messageItemBuilder!.extendBuilder![
                message.nimMessage.messageType]!(message.nimMessage);
          }
        }
        return ChatKitMessageNonsupportItem();
    }
  }

  ///过滤消息
  ///返回结果为是否展示
  bool _filterNotification(NIMMessage message) {
    if (message.messageAttachment is NIMTeamNotificationAttachment) {
      NIMTeamNotificationAttachment attachment =
          message.messageAttachment as NIMTeamNotificationAttachment;
      if (attachment.type == NIMTeamNotificationTypes.transferOwner &&
          getIt<TeamProvider>().isGroupTeam(widget.teamInfo)) {
        return false;
      }
    }
    return true;
  }

  bool _showMessageStatus(ChatMessage message) {
    return message.nimMessage.status == NIMMessageStatus.sending ||
        message.nimMessage.status == NIMMessageStatus.fail ||
        message.nimMessage.sessionType == NIMSessionType.p2p ||
        message.nimMessage.isInBlackList ||
        message.nimMessage.messageAck;
  }

  void _onVisibleChange(VisibilityInfo info) {
    //可见并且未发送回执的时候发送回执
    if (info.visibleFraction > 0 &&
        !isSelf() &&
        widget.chatMessage.nimMessage.messageAck &&
        !widget.chatMessage.nimMessage.hasSendAck) {
      context.read<ChatViewModel>().sendTeamMessageReceipt(widget.chatMessage);
    }
  }

  Widget _getMessageStatus(ChatMessage message) {
    if (message.nimMessage.status == NIMMessageStatus.sending &&
        _getMessageItemConfig(message.nimMessage).showMsgLoadingState) {
      return SizedBox(
        child: CircularProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Colors.blue),
          strokeWidth: 2,
        ),
        width: 16,
        height: 16,
      );
    } else if (message.nimMessage.status == NIMMessageStatus.fail ||
        message.nimMessage.isInBlackList) {
      return GestureDetector(
        onTap: () {
          if (widget.onTapFailedMessage != null) {
            widget.onTapFailedMessage!(message);
          }
        },
        child: SvgPicture.asset('images/ic_failed.svg',
            package: kPackage, width: 16, height: 16),
      );
    } else if (_showMsgAck(message)) {
      return InkWell(
        onTap: () {
          _log('click $_teamUnAck');
          if (message.nimMessage.sessionType == NIMSessionType.team &&
              _teamUnAck != 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ChatMessageAckPage(message: message.nimMessage);
            }));
          }
        },
        child: ProgressRing(
          size: 16,
          progress: _getProcess(widget.chatMessage),
          max: _getAllAck(widget.chatMessage),
          startImage:
              SvgPicture.asset('images/ic_unread.svg', package: kPackage),
          finishImage:
              SvgPicture.asset('images/ic_read.svg', package: kPackage),
        ),
      );
    } else {
      return Container();
    }
  }

  Color? _getBgColor() {
    if (widget.chatMessage.getPinAccId() != null) {
      return widget.chatUIConfig?.signalBgColor ?? '#FFFBEA'.toColor();
    }
    return null;
  }

  //PIN消息时候展示
  Future<String> _getUserName(String accId) async {
    if (accId == getIt<LoginService>().userInfo!.userId) {
      return S.of(context).chatMessageYou;
    }
    if (widget.chatMessage.nimMessage.sessionType == NIMSessionType.team) {
      return getUserNickInTeam(widget.chatMessage.nimMessage.sessionId!, accId);
    } else {
      return accId.getUserName();
    }
  }

  //获取对方的用户信息
  Future<UserAvatarInfo> _getUserInfo(String accId) async {
    String name = (accId == getIt<LoginService>().userInfo!.userId)
        ? (S.of(context).chatMessageYou)
        : (await (isTeam()
            ? getUserNickInTeam(widget.chatMessage.nimMessage.sessionId!, accId)
            : accId.getUserName()));
    String? avatar = await accId.getAvatar();

    String? avatarName = await accId.getUserName(needAlias: false);
    _userAvatarInfo =
        UserAvatarInfo(name, avatar: avatar, avatarName: avatarName);
    return _userAvatarInfo;
  }

  bool _showTime(ChatMessage currentMessage, ChatMessage? lastMessage) {
    if (lastMessage == null) {
      return true;
    }
    var currentTime = currentMessage.nimMessage.timestamp == 0
        ? DateTime.now().millisecondsSinceEpoch
        : currentMessage.nimMessage.timestamp;
    if (currentTime - lastMessage.nimMessage.timestamp > showTimeInterval) {
      return true;
    }
    return false;
  }

  bool _hideAvatarMessage(ChatMessage message) {
    return message.nimMessage.messageType == NIMMessageType.notification ||
        message.nimMessage.messageType == NIMMessageType.tip;
  }

  String _timeFormat(int milliSecond) {
    var nowTime = DateTime.now();
    var messageTime = DateTime.fromMillisecondsSinceEpoch(milliSecond);
    if (nowTime.year != messageTime.year) {
      return Intl.DateFormat('yyyy-MM-dd HH:mm').format(messageTime);
    } else if (nowTime.day != messageTime.day) {
      return Intl.DateFormat('MM-dd HH:mm').format(messageTime);
    } else {
      return Intl.DateFormat('HH:mm').format(messageTime);
    }
  }

  BoxDecoration _getMessageDecoration() {
    if (isSelf() && widget.chatUIConfig?.selfMessageBg != null) {
      return widget.chatUIConfig!.selfMessageBg!;
    } else if (!isSelf() && widget.chatUIConfig?.receiveMessageBg != null) {
      return widget.chatUIConfig!.receiveMessageBg!;
    } else {
      Color color = isSelf() ? '#D6E5F6'.toColor() : '#E8EAED'.toColor();
      return BoxDecoration(
        color: !_getMessageItemConfig(widget.chatMessage.nimMessage)
                .showMsgCommonBg
            ? Colors.transparent
            : color,
        borderRadius: isSelf()
            ? const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8))
            : const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.chatMessage.nimMessage.sessionType == NIMSessionType.team &&
        widget.chatMessage.nimMessage.messageDirection ==
            NIMMessageDirection.outgoing) {
      ChatMessageRepo.fetchTeamMessageReceiptDetail(
              widget.chatMessage.nimMessage)
          .then((value) {
        if (mounted) {
          _log('mounted fetchTeamMessageReceiptDetail ${value?.toMap()}');
          setState(() {
            _teamAck = value?.ackAccountList?.length ?? 0;
            _teamUnAck = value?.unAckAccountList?.length ?? 0;
          });
        }
      });
    }
  }

  Widget _getPinText(String content, {TextStyle? style}) {
    return Text(
      content,
      textWidthBasis: TextWidthBasis.parent,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  String _getPintContent(String? userName) {
    return isTeam()
        ? S.of(context).chatMessagePinMessageForTeam(
              userName ?? '',
            )
        : S.of(context).chatMessagePinMessage(
              userName ?? '',
            );
  }

  bool _isPinContentTooLong(String content, {TextStyle? style}) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: content, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width > getMaxWidth(false);
  }

  @override
  void dispose() {
    _popMenu?.clean();
    _popMenu = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    var pinTextStyle = TextStyle(color: '#3EAF96'.toColor(), fontSize: 11);
    return VisibilityDetector(
      key: widget.key!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_showTime(widget.chatMessage, widget.lastMessage))
            Text(
              _timeFormat(widget.chatMessage.nimMessage.timestamp),
              style: TextStyle(
                  fontSize: widget.chatUIConfig?.timeTextSize ?? 12,
                  color: widget.chatUIConfig?.timeTextColor ??
                      '#B3B7BC'.toColor()),
            ),
          _hideAvatarMessage(widget.chatMessage)
              ? _buildMessage(widget.chatMessage)
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 10),
                  color: _getBgColor(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<UserAvatarInfo>(
                        future: _getUserInfo(
                            widget.chatMessage.nimMessage.fromAccount!),
                        builder: (context, snapshot) {
                          return Expanded(
                              child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isSelf()
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (widget.isSelected ?? false)
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: 15, left: 5, top: 8),
                                  child: Row(
                                    children: [
                                      CheckBoxButton(
                                        isChecked: _getMessageSelectStatus(
                                            widget.chatMessage.nimMessage),
                                        size: 22,
                                        onChanged: (bool status) {
                                          _changeSelectStatus(
                                              widget.chatMessage.nimMessage,
                                              status);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                              //对方头像
                              if (!isSelf())
                                InkWell(
                                  onTap: () {
                                    if (widget.onTapAvatar != null) {
                                      widget.onTapAvatar!(widget
                                          .chatMessage.nimMessage.fromAccount);
                                    }
                                  },
                                  child: Avatar(
                                    width: 36,
                                    height: 36,
                                    avatar: snapshot.data == null
                                        ? _userAvatarInfo.avatar
                                        : snapshot.data!.avatar,
                                    name: snapshot.data == null
                                        ? _userAvatarInfo.avatarName
                                        : snapshot.data!.avatarName,
                                    nameColor:
                                        widget.chatUIConfig?.userNickColor,
                                    fontSize:
                                        widget.chatUIConfig?.userNickTextSize,
                                    radius:
                                        widget.chatUIConfig?.avatarCornerRadius,
                                    bgCode: AvatarColor.avatarColor(
                                        content: widget.chatMessage.nimMessage
                                            .fromAccount),
                                  ),
                                ),
                              //消息
                              Container(
                                margin: isSelf()
                                    ? const EdgeInsets.only(right: 8)
                                    : const EdgeInsets.only(left: 8),
                                child: Column(
                                  crossAxisAlignment: isSelf()
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (showNickname())
                                      Container(
                                        width: screenWidth - 200,
                                        child: Text(
                                            snapshot.data?.name ??
                                                _userAvatarInfo.name,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color:
                                                    CommonColors.color_999999)),
                                      ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (isSelf() &&
                                            !widget.chatMessage.isRevoke &&
                                            _showMessageStatus(
                                                widget.chatMessage))
                                          _getMessageStatus(widget.chatMessage),
                                        Container(
                                          margin: EdgeInsets.only(
                                              left: isSelf() ? 8 : 0),
                                          decoration: _getMessageDecoration(),
                                          constraints: BoxConstraints(
                                              maxWidth: getMaxWidth(false)),
                                          child: Builder(
                                            builder: (context) {
                                              return GestureDetector(
                                                child: IgnorePointer(
                                                  ///todo ignoring for multiSelect
                                                  ignoring: false,
                                                  child: widget
                                                          .chatMessage.isRevoke
                                                      ? _buildRevokedMessage(
                                                          widget.chatMessage)
                                                      : Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (_showReplyMessage(
                                                                widget
                                                                    .chatMessage))
                                                              _buildMessageReply(
                                                                  widget
                                                                      .chatMessage),
                                                            _buildMessage(widget
                                                                .chatMessage)
                                                          ],
                                                        ),
                                                ),
                                                onTap:
                                                    widget.onMessageItemClick !=
                                                            null
                                                        ? () {
                                                            widget
                                                                .onMessageItemClick
                                                                ?.call(widget
                                                                    .chatMessage);
                                                          }
                                                        : null,
                                                onLongPress: () {
                                                  //long press
                                                  if (widget.onMessageItemLongClick ==
                                                          null ||
                                                      widget.onMessageItemLongClick!(
                                                              widget
                                                                  .chatMessage) !=
                                                          true) {
                                                    if (!widget
                                                        .chatMessage.isRevoke) {
                                                      _onLongPress(context);
                                                    }
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.chatMessage.getPinAccId() !=
                                        null)
                                      FutureBuilder<String>(
                                          future: _getUserName(widget
                                              .chatMessage
                                              .getPinAccId()!),
                                          builder: (context, snapshot) {
                                            return Container(
                                                constraints: BoxConstraints(
                                                    maxWidth:
                                                        getMaxWidth(false)),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment: isSelf()
                                                      ? MainAxisAlignment.end
                                                      : MainAxisAlignment.start,
                                                  children: [
                                                    SvgPicture.asset(
                                                        'images/ic_message_pin.svg',
                                                        package: kPackage),
                                                    (isSelf() &&
                                                            !_isPinContentTooLong(
                                                                _getPintContent(
                                                                    snapshot
                                                                        .data),
                                                                style:
                                                                    pinTextStyle))
                                                        ? _getPinText(
                                                            _getPintContent(
                                                                snapshot.data),
                                                            style: pinTextStyle)
                                                        : Expanded(
                                                            child: _getPinText(
                                                                _getPintContent(
                                                                    snapshot
                                                                        .data),
                                                                style:
                                                                    pinTextStyle))
                                                  ],
                                                ));
                                          })
                                  ],
                                ),
                              ),
                              if (isSelf())
                                InkWell(
                                  onTap: () {
                                    if (widget.onTapAvatar != null) {
                                      widget.onTapAvatar!(null, isSelf: true);
                                    }
                                  },
                                  child: Avatar(
                                    width: 36,
                                    height: 36,
                                    avatar:
                                        getIt<LoginService>().userInfo!.avatar,
                                    name: getIt<LoginService>().userInfo!.nick,
                                    nameColor:
                                        widget.chatUIConfig?.userNickColor,
                                    fontSize:
                                        widget.chatUIConfig?.userNickTextSize,
                                    radius:
                                        widget.chatUIConfig?.avatarCornerRadius,
                                    bgCode: AvatarColor.avatarColor(
                                        content: getIt<LoginService>()
                                            .userInfo!
                                            .userId),
                                  ),
                                )
                            ],
                          ));
                        },
                      )
                    ],
                  ),
                )
        ],
      ),
      onVisibilityChanged: _onVisibleChange,
    );
  }
}

class MessageItemConfig {
  // 是否展示消息发送loading状态
  bool showMsgLoadingState = true;

  // 是否展示消息通用背景
  bool showMsgCommonBg = true;

  MessageItemConfig(
      {this.showMsgLoadingState = true, this.showMsgCommonBg = true});
}
