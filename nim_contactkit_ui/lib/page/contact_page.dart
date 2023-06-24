// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/contact_kit_contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:utils/utils.dart';

import '../l10n/S.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key, this.config}) : super(key: key);

  final ContactUIConfig? config;

  @override
  State<StatefulWidget> createState() => _ContactState();
}

class _ContactState extends State<ContactPage> {
  ContactUIConfig get uiConfig =>
      widget.config ?? ContactKitClient.instance.contactUIConfig;

  ContactTitleBarConfig get _titleBarConfig => uiConfig.contactTitleBarConfig;

  late String keyword;

  @override
  void initState() {
    super.initState();
    keyword = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _titleBarConfig.showTitleBar
          ? AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: CommonScaffoldHelper.getGradientBackground()),
        ),
        title: Text(
          _titleBarConfig.title ?? S.of(context).contactTitle,
          style: const TextStyle(
              fontSize: 20,
              /*color: _titleBarConfig.titleColor,*/
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: _titleBarConfig.centerTitle,
        elevation: 0,
        bottom: CommonScaffoldHelper.getScaffoldAppBarBottomWidget(
            onChanged: (String value) {
              keyword = value;
              setState(() {});
            }, onPressed: () {
          // goto add friend page
          goAddFriendPage(context);
        }),
      )
          : null,
      body: Column(
        children: [
          keyword.isNotEmpty
              ? CommonScaffoldHelper.getScaffoldBodyWidget(
              CommonScaffoldHelper.buildSearchList(context, keyword),
              context)
              : CommonScaffoldHelper.getScaffoldBodyWidget(
              ContactKitContactPage(
                config: uiConfig,
              ),
              context)
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
