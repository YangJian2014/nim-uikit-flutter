// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_chatkit_ui/chat_setting_page.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_common_ui/widgets/no_network_tip.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:utils/utils.dart';

import 'chat_kit_client.dart';
import 'l10n/S.dart';
import 'media/audio_player.dart';
import 'view/input/bottom_input_field.dart';

class ChatPage extends StatefulWidget {
  final String sessionId;

  final NIMSessionType sessionType;

  final NIMMessage? anchor;

  final PopMenuAction? customPopActions;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  ChatPage(
      {Key? key,
      required this.sessionId,
      required this.sessionType,
      this.anchor,
      this.customPopActions,
      this.onTapAvatar,
      this.chatUIConfig,
      this.messageBuilder,
      this.onMessageItemClick,
      this.onMessageItemLongClick})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatPageState();
}

class ChatPageState extends BaseState<ChatPage> {
  late AutoScrollController autoController;
  final GlobalKey<dynamic> _inputField = GlobalKey();

  Timer? _typingTimer;

  int _remainTime = 5;

  StreamSubscription? _teamDismissSub;

  void _setTyping(BuildContext context) {
    _typingTimer?.cancel();
    _remainTime = 5;
    _typingTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (_remainTime <= 0) {
        _remainTime = 5;
        _typingTimer?.cancel();
        context.read<ChatViewModel>().resetTyping();
      } else {
        _remainTime--;
      }
    });
  }

  void defaultAvatarTap(String? userId, {bool isSelf = false}) {
    if (isSelf) {
      gotoMineInfoPage(context);
    } else {
      goToContactDetail(context, userId!);
    }
  }

  @override
  void initState() {
    super.initState();
    autoController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
    //初始化语音播放器
    ChatAudioPlayer.instance.initAudioPlayer();
    //高德定位初始化
    if (ChatKitClient.instance.aMapAndroidKey?.isNotEmpty == true &&
        ChatKitClient.instance.aMapIOSKey?.isNotEmpty == true) {
      //由于个人信息保护法的实施，请务必确保调用SDK任何接口前先调用更新隐私合规updatePrivacyShow、updatePrivacyAgree两个接口
      AMapFlutterLocation.updatePrivacyAgree(true);
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.setApiKey(ChatKitClient.instance.aMapAndroidKey!,
          ChatKitClient.instance.aMapIOSKey!);
    }
    ChatKitClient.instance.registerRevokedMessage();
    if (widget.sessionType == NIMSessionType.team) {
      _teamDismissSub =
          NimCore.instance.messageService.onMessage.listen((event) {
        for (var msg in event) {
          if (_isTeamDisMessageNotify(msg)) {
            _showTeamDismissDialog();
            break;
          }
        }
      });
    }
  }

  bool _isTeamDisMessageNotify(NIMMessage msg) {
    if (msg.sessionId == widget.sessionId &&
        msg.messageType == NIMMessageType.notification) {
      NIMTeamNotificationAttachment attachment =
          msg.messageAttachment as NIMTeamNotificationAttachment;
      if (attachment.type == NIMTeamNotificationTypes.dismissTeam &&
          msg.fromAccount != getIt<LoginService>().userInfo?.userId) {
        return true;
      }
    }
    return false;
  }

  void _showTeamDismissDialog() {
    showCommonDialog(
            context: GlobalKey().currentContext ?? context,
            title: S.of().chatTeamBeRemovedTitle,
            content: S.of().chatTeamBeRemovedContent,
            showNavigate: false)
        .then((value) {
      if (value == true) {
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    });
  }

  @override
  void onAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
    super.onAppLifecycleState(state);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    ChatAudioPlayer.instance.release();
    _teamDismissSub?.cancel();
    super.dispose();
  }

  Future<UserAvatarInfo> _getUserInfo(String accId) async {
    String name = await (accId.getUserName());
    String? avatar = await accId.getAvatar();
    return UserAvatarInfo(name, avatar: avatar);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) =>
            ChatViewModel(widget.sessionId, widget.sessionType),
        builder: (context, wg) {
          String title;
          if (context.watch<ChatViewModel>().isTyping) {
            _setTyping(context);
            title = S.of(context).chatIsTyping;
          } else {
            title = context.watch<ChatViewModel>().chatTitle;
          }
          var hasNetwork = context.watch<ChatViewModel>().hasNetWork;
          var viewModel = context.watch<ChatViewModel>();
          var userId = viewModel.contactInfo?.user.userId;
          return Scaffold(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              appBar: AppBar(
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                      gradient: CommonScaffoldHelper.getGradientBackground()),
                ),
                leading: IconButton(
                  icon: Image.asset(
                    'images/icon_titlebar_back.png',
                    width: 10,
                    height: 17.5,
                    package: 'nim_chatkit_ui',
                    // fit:BoxFit.cover,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                centerTitle: false,
                title:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FutureBuilder<UserAvatarInfo>(
                    future: _getUserInfo(userId ?? ''),
                    builder: (context, snapshot) {
                      return Avatar(
                        width: 30,
                        height: 30,
                        avatar:
                            snapshot.data == null ? '' : snapshot.data!.avatar,
                        name: snapshot.data == null ? '' : snapshot.data!.name,
                        // nameColor: widget.chatUIConfig?.userNickColor,
                        // fontSize: widget.chatUIConfig?.userNickTextSize,
                        radius: 5,
                        bgCode: AvatarColor.avatarColor(content: userId ?? ''),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
                // title: Text(
                //   title,
                //   style: const TextStyle(
                //       fontSize: 20,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.white),
                // ),
                // elevation: 0.5,
                actions: [
                  IconButton(
                      onPressed: () {
                        if (widget.sessionType == NIMSessionType.p2p) {
                          ContactInfo? info =
                              context.read<ChatViewModel>().contactInfo;
                          if (info != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ChatSettingPage(info)));
                          }
                        } else if (widget.sessionType == NIMSessionType.team) {
                          Navigator.pushNamed(
                              context, RouterConstants.PATH_TEAM_SETTING_PAGE,
                              arguments: {'teamId': widget.sessionId});
                        }
                      },
                      icon: Image.asset(
                        'images/icon_titlebar_setting.png',
                        width: 17.5,
                        height: 4,
                        package: 'nim_chatkit_ui',
                        // fit:BoxFit.cover,
                      ))
                ],
              ),
              body: Column(
                children: [
                  CommonScaffoldHelper.getScaffoldBodyWidget(
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!hasNetwork) const NoNetWorkTip(),
                              Expanded(
                                child: Listener(
                                  onPointerMove: (event) {
                                    _inputField.currentState.hideAllPanel();
                                  },
                                  child: ChatKitMessageList(
                                    scrollController: autoController,
                                    popMenuAction: widget.customPopActions ??
                                        widget
                                            .chatUIConfig
                                            ?.messageClickListener
                                            ?.customPopActions,
                                    anchor: widget.anchor,
                                    messageBuilder: widget.messageBuilder ??
                                        widget.chatUIConfig?.messageBuilder ??
                                        ChatKitClient.instance.chatUIConfig
                                            .messageBuilder,
                                    onTapAvatar: (String? userId,
                                        {bool isSelf = false}) {
                                      if (widget.onTapAvatar != null &&
                                          widget.onTapAvatar!(userId,
                                              isSelf: isSelf)) {
                                        return true;
                                      }
                                      if (widget
                                                  .chatUIConfig
                                                  ?.messageClickListener
                                                  ?.onTapAvatar !=
                                              null &&
                                          widget
                                                  .chatUIConfig!
                                                  .messageClickListener!
                                                  .onTapAvatar!(userId,
                                              isSelf: isSelf)) {
                                        return true;
                                      }
                                      defaultAvatarTap(userId, isSelf: isSelf);
                                      return true;
                                    },
                                    chatUIConfig: widget.chatUIConfig ??
                                        ChatKitClient.instance.chatUIConfig,
                                    teamInfo:
                                        context.watch<ChatViewModel>().teamInfo,
                                    onMessageItemClick:
                                        widget.onMessageItemClick ??
                                            widget
                                                .chatUIConfig
                                                ?.messageClickListener
                                                ?.onMessageItemClick,
                                    onMessageItemLongClick:
                                        widget.onMessageItemLongClick ??
                                            widget
                                                .chatUIConfig
                                                ?.messageClickListener
                                                ?.onMessageItemLongClick,
                                  ),
                                ),
                              ),
                              BottomInputField(
                                scrollController: autoController,
                                sessionType: widget.sessionType,
                                hint: S.of(context).chatMessageSendHint(title),
                                chatUIConfig: widget.chatUIConfig ??
                                    ChatKitClient.instance.chatUIConfig,
                                key: _inputField,
                              )
                            ],
                          ),
                        ],
                      ),
                      context)
                ],
              ));
        });
  }
}
