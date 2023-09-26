// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_common_ui/widgets/search_page.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/user_info/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:utils/utils.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  TextEditingController inputController = TextEditingController();
  late String keyword;

  Future<List<NIMUser>?> searchUserInfo(List<String> accountList) async {
    if (!await haveConnectivity()) {
      return null;
    }
    return getIt<UserInfoProvider>().fetchUserInfo(accountList);
  }

  Future<List<NIMUser>?> fetchUserInfo(String keyword) async {
    if (!await haveConnectivity()) {
      return null;
    }
    var coinInfo = await UtilsNetworkHelper.queryUserInfo(keyword);
    var datas = coinInfo?.data;
    if (datas == null) {
      return null;
    }

    var currentData = datas['data']?['list'];
    if (currentData == null) {
      return null;
    }

    var accid = currentData[0]['accid'];
    if (accid == null) {
      return null;
    }

    if (!mounted) {
      return null;
    }
    Future<List<NIMUser>?> userInfo =
        getIt<UserInfoProvider>().fetchUserInfo([accid]);
    return userInfo;
  }

  _searchUserInfo() async {
    var text = inputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    List<NIMUser>? userList = await fetchUserInfo(text);
    if (userList == null || userList.isEmpty) {
      return;
    }

    var userInfo = userList.first;

    if (getIt<LoginService>().userInfo?.userId == userInfo.userId) {
      gotoMineInfoPage(context);
    } else {
      goToContactDetail(context, userInfo.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: CommonScaffoldHelper.getGradientBackground()),
        ),
        // leading: IconButton(
        //   icon: const Icon(
        //     Icons.arrow_back_ios_rounded,
        //     size: 26,
        //   ),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        // centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'images/icon_titlebar_back.png',
            width: 45,
            height: 30,
            package: 'nim_chatkit_ui',
            // fit:BoxFit.cover,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: false,
        title: Text(S.of(context).addFriend,
            style: TextStyle(color: Colors.black)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: TextField(
              controller: inputController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: Color(0xfff2f4f5),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none),
                isDense: true,
                hintText: S.of(context).addFriendSearchHint,
                hintStyle: const TextStyle(
                    color: CommonColors.color_a8adb6, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: CommonColors.color_a8adb6,
                  size: 30,
                ),
                suffixIcon: IconButton(
                  icon: SvgPicture.asset(
                    'images/ic_clear.svg',
                    package: 'netease_common_ui',
                  ),
                  onPressed: () {
                    inputController.clear();
                    setState(() {
                      // keyword = '';
                    });
                  },
                ),
              ),
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(
                  color: CommonColors.color_333333, fontSize: 14),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                // keyword = value;
                // if (!widget.buildOnComplete) {
                //   setState(() {});
                // }
              },
              onEditingComplete: _searchUserInfo,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24))),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        '搜索',
                        style:
                            const TextStyle(fontSize: 21, color: Colors.white),
                      ),
                    ),
                    onPressed: _searchUserInfo,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
