// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

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

    var currentData = datas['data'];
    if (currentData == null) {
      return null;
    }

    var accid = currentData['accid'];
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

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      title: S.of(context).addFriend,
      searchHint: S.of(context).addFriendSearchHint,
      buildOnComplete: true,
      builder: (context, keyword) {
        if (keyword.isEmpty)
          return Container();
        else {
          return FutureBuilder<List<NIMUser>?>(
              future: fetchUserInfo(keyword),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Column(
                      children: [
                        const SizedBox(
                          height: 68,
                        ),
                        SvgPicture.asset(
                          'images/ic_search_empty.svg',
                          package: kPackage,
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Text(
                          S.of(context).addFriendSearchEmptyTips,
                          style:
                              TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                        )
                      ],
                    );
                  } else {
                    Future.delayed(Duration(milliseconds: 200), () {
                      if (getIt<LoginService>().userInfo?.userId ==
                          snapshot.data![0].userId) {
                        gotoMineInfoPage(context);
                      } else {
                        goToContactDetail(context, snapshot.data![0].userId!);
                      }
                    });
                  }
                }
                return Container();
              });
        }
      },
    );
  }
}
