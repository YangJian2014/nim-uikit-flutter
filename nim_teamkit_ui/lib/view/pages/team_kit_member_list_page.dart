// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:utils/utils.dart';

import '../../l10n/S.dart';
import '../../view_model/team_setting_view_model.dart';

class TeamKitMemberListPage extends StatefulWidget {
  final String tId;

  const TeamKitMemberListPage({Key? key, required this.tId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitMemberListPageState();
}

class TeamKitMemberListPageState extends State<TeamKitMemberListPage> {
  String? filterStr;

  void _onFilterChange(String text, BuildContext context) {
    context.read<TeamSettingViewModel>().filterByText(text);
  }

  OutlineInputBorder _border() => const OutlineInputBorder(
        gapPadding: 0,
        borderSide: BorderSide(
          color: Colors.transparent,
        ),
      );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        var viewModel = TeamSettingViewModel();
        viewModel.requestTeamMembers(widget.tId);
        viewModel.addTeamSubscribe();
        return viewModel;
      },
      builder: (context, child) {
        var memberList = context.watch<TeamSettingViewModel>().filterList;
        return Scaffold(
          appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(S.of(context).teamMemberTitle,
                  style: TextStyle(color: '#333333'.toColor(), fontSize: 16)),
              backgroundColor: Colors.white,
              iconTheme: Theme.of(context)
                  .primaryIconTheme
                  .copyWith(color: Colors.grey),
              elevation: 0,
              centerTitle: true),
          body: Container(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  // controller: queryTextController,
                  onChanged: (text) {
                    _onFilterChange(text, context);
                  },
                  decoration: InputDecoration(
                      fillColor: '#F2F4F5'.toColor(),
                      filled: true,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      border: _border(),
                      enabledBorder: _border(),
                      focusedBorder: _border(),
                      hintText: S.of(context).teamSearchFriend,
                      hintStyle:
                          TextStyle(fontSize: 14, color: '#A6ADB6'.toColor()),
                      prefixIcon: const Icon(Icons.search)),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: memberList?.length ?? 0,
                        itemBuilder: (context, index) {
                          var user = memberList?[index];
                          return TeamMemberListItem(teamMember: user!);
                        }))
              ],
            ),
          ),
        );
      },
    );
  }
}

class TeamMemberListItem extends StatefulWidget {
  final UserInfoWithTeam teamMember;

  const TeamMemberListItem({Key? key, required this.teamMember})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamMemberListItemState();
}

class TeamMemberListItemState extends State<TeamMemberListItem> {
  @override
  Widget build(BuildContext context) {
    return Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                var team = (await NimCore.instance.teamService
                        .queryTeam(widget.teamMember.teamInfo.id ?? ''))
                    .data;
                if (team == null) {
                  return;
                }
                if (team.creator != getIt<LoginService>().userInfo?.userId) {
                  Fluttertoast.showToast(
                      msg: '您不是管理员，无删除成员权限。',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 2,
                      backgroundColor: const Color.fromARGB(255, 25, 23, 23),
                      textColor: Colors.white,
                      fontSize: 16.0);
                  return;
                }

                showCommonDialog(
                        context: context,
                        title: '温馨提示',
                        content:
                            '确定将 ${widget.teamMember.userInfo!.userId!} 移出群聊？',
                        navigateContent: '取消',
                        positiveContent: '确定')
                    .then((value) async {
                  if (value ?? false) {
                    // teamId表示群ID，account表示被踢出的成员帐号

                    String tid = widget.teamMember.teamInfo.id ?? '';
                    List<String> members = [
                      widget.teamMember.userInfo!.userId!
                    ];
                    var response = await UtilsNetworkHelper.groupKick(
                        {'members': members}, tid);
                    var rspData = response?.data;
                    if (rspData != null) {
                      var code = rspData['code'] ?? -1;
                      if (code == 0) {
                        print('踢人成功');
                        setState(() {});
                        return;
                      }
                    }
                    print('踢人失败, rspData=$rspData');
                  }
                });
              },
              backgroundColor: const Color.fromARGB(255, 126, 130, 144),
              foregroundColor: Colors.white,
              label: '移出群聊',
            )
          ],
        ),
        child: InkWell(
          onTap: () {
            if (getIt<LoginService>().userInfo?.userId ==
                widget.teamMember.userInfo?.userId) {
              gotoMineInfoPage(context);
            } else {
              goToContactDetail(context, widget.teamMember.userInfo!.userId!);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Avatar(
                  width: 42,
                  height: 42,
                  avatar: widget.teamMember.getAvatar(),
                  name: widget.teamMember
                      .getName(needAlias: false, needTeamNick: false),
                  bgCode: AvatarColor.avatarColor(
                      content: widget.teamMember.teamInfo.account),
                  radius: 4,
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 7)),
                Expanded(
                  child: Text(
                    widget.teamMember.getName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
