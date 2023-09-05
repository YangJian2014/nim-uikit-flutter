// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:nim_conversationkit_ui/page/add_friend_page.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/message/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_conversationkit_ui/page/scan_page.dart';
import 'package:nim_core/nim_core.dart';
import 'package:utils/utils.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';

class ConversationPopMenuButton extends StatelessWidget {
  const ConversationPopMenuButton({Key? key}) : super(key: key);

  _onMenuSelected(BuildContext context, String value) async {
    Alog.i(tag: 'ConversationKit', content: "onMenuSelected: $value");
    switch (value) {
      case "scan":
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const ScanPage()));
        break;
      case "add_friend":
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddFriendPage()));
        break;
      case "create_group_team":
      case "create_advanced_team":
        if (!(await Connectivity().checkNetwork(context))) {
          return;
        }
        goToContactSelector(context, mostCount: 199, returnContact: true)
            .then((contacts) async {
          if (contacts is List<ContactInfo> && contacts.isNotEmpty) {
            Alog.d(
                tag: 'ConversationKit',
                content: '$value, select:${contacts.length}');
            var selectName =
                contacts.map((e) => e.user.nick ?? e.user.userId!).toList();

            var members = contacts.map((e) => e.user.userId!).toList();
            var response = await UtilsNetworkHelper.groupCreated(members);
            var rspData = response?.data;
            var code = rspData['code'] ?? -1;
            if (code != 0) {
              print('创建team失败, status=$code');
              return;
            }

            String tid = rspData['data']['tid'] ?? '';
            if (tid.isEmpty) {
              print('创建team失败, tid=$tid');
              return;
            }

            Map<String, String> map = {};
            map[RouterConstants.keyTeamCreatedTip] =
                S.of(context).createAdvancedTeamSuccess;
            getIt<MessageProvider>().sendTeamTipWithoutUnread(tid, map);

            // 入群无需被邀请者同意
            NIMTeamUpdateFieldRequest request = NIMTeamUpdateFieldRequest();
            request.setBeInviteMode(NIMTeamBeInviteModeEnum.noAuth);

            // 所有人都可以邀请
            request.setInviteMode(NIMTeamInviteModeEnum.all);

            final result = await NimCore.instance.teamService.updateTeamFields(
              tid,
              request,
            );
            Future.delayed(const Duration(milliseconds: 200), () {
              goToTeamChat(context, tid);
            });

            // getIt<TeamProvider>()
            //     .createTeam(
            //   contacts.map((e) => e.user.userId!).toList(),
            //   selectNames: selectName,
            //   isGroup: value == 'create_group_team',
            // )
            //     .then((teamResult) {
            //   if (teamResult != null && teamResult.team != null) {
            //     if (value == 'create_advanced_team') {
            //       Map<String, String> map = Map();
            //       map[RouterConstants.keyTeamCreatedTip] =
            //           S.of(context).createAdvancedTeamSuccess;
            //       getIt<MessageProvider>()
            //           .sendTeamTipWithoutUnread(teamResult.team!.id!, map);
            //     }
            //     Future.delayed(Duration(milliseconds: 500), () {
            //       goToTeamChat(context, teamResult.team!.id!);
            //     });
            //   }
            // });
          }
        });
        break;
    }
  }

  List _conversationMenu(BuildContext context) {
    return [
      {
        'image': 'images/icon_add_friend.svg',
        'name': S.of(context).addFriend,
        'value': 'add_friend'
      },
      // {
      //   'image': 'images/icon_create_group_team.svg',
      //   'name': S.of(context).createGroupTeam,
      //   'value': 'create_group_team'
      // },
      {
        'image': 'images/icon_create_advanced_team.svg',
        'name': S.of(context).createAdvancedTeam,
        'value': 'create_advanced_team'
      },
      {
        'image': 'images/icon_create_advanced_team.svg',
        'name': S.of(context).group_scan,
        'value': 'scan'
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) {
        return _conversationMenu(context)
            .map<PopupMenuItem<String>>(
              (item) => PopupMenuItem<String>(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      item['image'],
                      package: kPackage,
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      item['name'],
                      style: const TextStyle(
                          fontSize: 14, color: CommonColors.color_333333),
                    ),
                  ],
                ),
                value: item['value'],
              ),
            )
            .toList();
      },
      icon: Image.asset(
        'images/icon_titlebar_add_btn.png',
        // width: 48,
        // height: 58.5,
        package: 'nim_conversationkit_ui',
      ),
      padding: const EdgeInsets.all(0),
      offset: const Offset(0, 50),
      onSelected: (value) {
        _onMenuSelected(context, value);
      },
    );
  }
}
