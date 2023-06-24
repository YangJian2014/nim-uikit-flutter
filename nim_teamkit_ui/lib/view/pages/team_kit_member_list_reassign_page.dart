// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.


import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nim_teamkit_ui/view_model/team_setting_view_model.dart';
import '../../l10n/S.dart';

class TeamKitMemberListReassignPage extends StatefulWidget {
  final String tId;

  const TeamKitMemberListReassignPage({Key? key, required this.tId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitMemberListReassignPageState();
}

class TeamKitMemberListReassignPageState
    extends State<TeamKitMemberListReassignPage> {
  String? filterStr;

  void _onFilterChange(String text, BuildContext context) {
    context.read<TeamSettingViewModel>().filterByText(text);
  }

  OutlineInputBorder _border() =>
      const OutlineInputBorder(
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

  // Future<TeamSettingViewModel> getViewModel() async{
  //   Completer<TeamSettingViewModel> completer = Completer<TeamSettingViewModel>();
  //   var viewModel = TeamSettingViewModel();
  //   final prefs = await SharedPreferences.getInstance();
  //   final String userId = prefs.getString('account') ?? "";
  //   viewModel.requestTeamMembersV2(widget.tId,userId);
  //   completer.complete(TeamSettingViewModel());
  //   return completer.future;
  // }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context){
        var viewModel = TeamSettingViewModel();
        () async{
          final prefs = await SharedPreferences.getInstance();
          final String userId = prefs.getString('account') ?? "";
          viewModel.requestTeamMembersV2(widget.tId,userId);
        }();
        return viewModel;
      },
      builder: (context, child) {
        var memberList = context
            .watch<TeamSettingViewModel>()
            .filterList;
        return Scaffold(
          appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(S.of(context).team_member_reassign_title,
                  style: TextStyle(color: '#333333'.toColor(), fontSize: 16)),
              backgroundColor: Colors.white,
              iconTheme: Theme
                  .of(context)
                  .primaryIconTheme
                  .copyWith(color: Colors.grey),
              elevation: 0,
              centerTitle: true),
          body: Container(
            padding: const EdgeInsets.all(20),
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
                    child: ListView.separated(
                        itemCount: memberList?.length ?? 0,
                        separatorBuilder: (BuildContext context, int index) =>
                        const Divider(
                            height: 1.0,
                            color: Color.fromARGB(255, 236, 235, 233)),
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
    return InkWell(
        onTap: () {
          showCommonDialog(
              context: context,
              title: '温馨提示',
              content: '确定将群转让给 ${widget.teamMember.userInfo!.userId!} ？',
              navigateContent: '取消',
              positiveContent: '确定')
              .then((value) async {
            if (value == true) {
              var response = await UtilsNetworkHelper.groupTransform({
                "tid": widget.teamMember.teamInfo.id ?? "",
                "newowner": widget.teamMember.userInfo!.userId ?? "",
                "leave": "2",
              });
              var rspData = response?.data;
              var code = rspData['code'] ?? -1;
              if (code != 0) {
                print('群转让失败, status=$code');
                return;
              } else {
                print('群转让成功');
                Navigator.pop(context);
                Navigator.pop(context);
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Avatar(
                radius: 5,
                width: 42,
                height: 42,
                avatar: widget.teamMember.getAvatar(),
                name: widget.teamMember.getName(),
                bgCode: AvatarColor.avatarColor(
                    content: widget.teamMember.teamInfo.account),
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
      );
      // return Slidable(
      //     endActionPane: ActionPane(
      //       motion: const ScrollMotion(),
      //       children: [
      //         SlidableAction(
      //           onPressed: (context) async {
      //             var team = (await NimCore.instance.teamService
      //                 .queryTeam(widget.teamMember.teamInfo.id ?? ''))
      //                 .data;
      //             if (team == null) {
      //               return;
      //             }
      //             if (team.creator != getIt<LoginService>().userInfo?.userId) {
      //               Fluttertoast.showToast(
      //                   msg: '您不是管理员，无删除成员权限。',
      //                   toastLength: Toast.LENGTH_SHORT,
      //                   gravity: ToastGravity.CENTER,
      //                   timeInSecForIosWeb: 2,
      //                   backgroundColor: Color.fromARGB(255, 25, 23, 23),
      //                   textColor: Colors.white,
      //                   fontSize: 16.0);
      //               return;
      //             }
      //
      //             showCommonDialog(
      //                 context: context,
      //                 title: '温馨提示',
      //                 content:
      //                 '确定将群转让给 ${widget.teamMember.userInfo!.userId!} ？',
      //                 navigateContent: '取消',
      //                 positiveContent: '确定')
      //                 .then((value) async {
      //               if (value ?? false) {
      //                 // // teamId表示群ID，account表示被踢出的成员帐号
      //                 //
      //                 // // String tid = widget.teamMember.teamInfo.id ?? '';
      //                 // // List<String> members = [
      //                 // //   widget.teamMember.userInfo!.userId!
      //                 // // ];
      //                 // // var response = await NetworkHelper.groupKick(
      //                 // //     {'members': members}, tid);
      //                 // // var rspData = response?.data;
      //                 // // var code = rspData['code'] ?? -1;
      //                 // // print(rspData);
      //                 //
      //                 // final result =
      //                 //     await NimCore.instance.teamService.removeMembers(
      //                 //   widget.teamMember.teamInfo.id ?? '',
      //                 //   [widget.teamMember.userInfo!.userId!],
      //                 // );
      //                 //
      //                 // setState(() {});
      //               }
      //             });
      //           },
      //           backgroundColor: Color.fromARGB(255, 126, 130, 144),
      //           foregroundColor: Colors.white,
      //           label: '转让',
      //         )
      //       ],
      //     ),
      //     child: InkWell(
      //       onTap: () {
      //         if (getIt<LoginService>().userInfo?.userId ==
      //             widget.teamMember.userInfo?.userId) {
      //           gotoMineInfoPage(context);
      //         } else {
      //           goToContactDetail(context, widget.teamMember.userInfo!.userId!);
      //         }
      //       },
      //       child: Container(
      //         padding: const EdgeInsets.symmetric(vertical: 10),
      //         child: Row(
      //           children: [
      //             Avatar(
      //               radius: 5,
      //               width: 42,
      //               height: 42,
      //               avatar: widget.teamMember.getAvatar(),
      //               name: widget.teamMember.getName(),
      //               bgCode: AvatarColor.avatarColor(
      //                   content: widget.teamMember.teamInfo.account),
      //             ),
      //             const Padding(padding: EdgeInsets.symmetric(horizontal: 7)),
      //             Expanded(
      //               child: Text(
      //                 widget.teamMember.getName(),
      //                 maxLines: 1,
      //                 overflow: TextOverflow.ellipsis,
      //                 style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
      //               ),
      //             )
      //           ],
      //         ),
      //       ),
      //     ));
    }
  }
