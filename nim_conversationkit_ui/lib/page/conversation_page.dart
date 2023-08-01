// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_list.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_pop_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/widgets/no_network_tip.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_searchkit/model/friend_search_info.dart';
import 'package:nim_searchkit/model/hit_type.dart';
import 'package:nim_searchkit/model/search_info.dart';
import 'package:nim_searchkit/model/team_search_info.dart';
import 'package:nim_searchkit/repo/search_repo.dart';
import 'package:nim_searchkit/repo/text_search.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../view_model/conversation_view_model.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({Key? key, this.config, this.onUnreadCountChanged})
      : super(key: key);

  final ValueChanged<int>? onUnreadCountChanged;
  final ConversationUIConfig? config;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends BaseState<ConversationPage> {
  late ConversationTitleBarConfig _titleBarConfig;

  late String keyword;

  ConversationUIConfig get uiConfig =>
      widget.config ?? ConversationKitClient.instance.conversationUIConfig;

  OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(style: BorderStyle.none));

  @override
  void initState() {
    super.initState();
    _titleBarConfig = uiConfig.titleBarConfig;
    keyword = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: getScaffoldAppBarWidget(),
      body: ChangeNotifierProvider(
        create: (context) => ConversationViewModel(widget.onUnreadCountChanged,
            uiConfig.itemConfig.conversationComparator),
        builder: (context, child) {
          var hasNetwork = context.watch<ConversationViewModel>().hasNetWork;
          return Column(
            children: [
              if (!hasNetwork) const NoNetWorkTip(),
              keyword.isNotEmpty
                  ? getScaffoldBodyWidget(buildSearchList(context, keyword))
                  : getScaffoldBodyWidget(ConversationList(
                config: uiConfig.itemConfig,
                onUnreadCountChanged: widget.onUnreadCountChanged,
              ))
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget? getScaffoldAppBarWidget() {
    return _titleBarConfig.showTitleBar
        ?
    /*PreferredSize(
              child: AppBar(
                  backgroundColor: _titleBarConfig.backgroundColor,
                  centerTitle: _titleBarConfig.centerTitle,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_titleBarConfig.showTitleBarLeftIcon)
                        _titleBarConfig.titleBarLeftIcon ??
                            SvgPicture.asset(
                              'images/ic_yunxin.svg',
                              width: 32,
                              height: 32,
                              package: 'nim_conversationkit_ui',
                            ),
                      if (_titleBarConfig.showTitleBarLeftIcon)
                        const SizedBox(
                          width: 12,
                        ),
                      Text(
                        _titleBarConfig.titleBarTitle ??
                            S.of(context).conversation_title,
                        style: TextStyle(
                            fontSize: 20,
                            color: _titleBarConfig.titleBarTitleColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  elevation: 0.3,
                  actions: [
                    if (_titleBarConfig.showTitleBarRight2Icon)
                      _titleBarConfig.titleBarRight2Icon ??
                          IconButton(
                            onPressed: () {
                              goGlobalSearchPage(context);
                            },
                            icon: SvgPicture.asset(
                              'images/ic_search.svg',
                              width: 26,
                              height: 26,
                              package: 'nim_conversationkit_ui',
                            ),
                          ),
                    if (_titleBarConfig.showTitleBarRightIcon)
                      _titleBarConfig.titleBarRightIcon ??
                          ConversationPopMenuButton()
                  ],
                  bottom: getAppBarBottomWidget()),
              preferredSize: Size.fromHeight(300))*/
    AppBar(
        backgroundColor: _titleBarConfig.backgroundColor,
        centerTitle: _titleBarConfig.centerTitle,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: getGradientBackground()),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_titleBarConfig.showTitleBarLeftIcon)
              _titleBarConfig.titleBarLeftIcon ??
                  SvgPicture.asset(
                    'images/ic_yunxin.svg',
                    width: 32,
                    height: 32,
                    package: 'nim_conversationkit_ui',
                  ),
            if (_titleBarConfig.showTitleBarLeftIcon)
              const SizedBox(
                width: 12,
              ),
            Text(
              _titleBarConfig.titleBarTitle ??
                  S.of(context).conversationTitle,
              style: TextStyle(
                  fontSize: 20,
                  color: _titleBarConfig.titleBarTitleColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0.0,
        // actions: [
        // if (_titleBarConfig.showTitleBarRight2Icon)
        //   _titleBarConfig.titleBarRight2Icon ??
        //       IconButton(
        //         onPressed: () {
        //           goGlobalSearchPage(context);
        //         },
        //         icon: SvgPicture.asset(
        //           'images/ic_search.svg',
        //           width: 26,
        //           height: 26,
        //           package: 'nim_conversationkit_ui',
        //         ),
        //       ),
        // if (_titleBarConfig.showTitleBarRightIcon)
        //   _titleBarConfig.titleBarRightIcon ??
        //       ConversationPopMenuButton()
        // ],
        bottom: getScaffoldAppBarBottomWidget())
        : null;
  }

  PreferredSizeWidget getScaffoldAppBarBottomWidget() {
    /**
     * 功能6 给appbar的bottom设置背景色，如果appbar的bottom也是appbar，尝试通过flexibleSpace对这个做appbar的bottom
     * 的appbar设置背景可能因为冲突而不生效，所以此处把appbar的bottom实现换成自定义PreferredSizeWidget
     * 在这里是自定义PreferredSize
     */
    return PreferredSize(
      child: Container(
        // color: _titleBarConfig.backgroundColor,
        // centerTitle: _titleBarConfig.centerTitle,
        decoration: BoxDecoration(gradient: getGradientBackground()),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SvgPicture.asset(
              //   'images/ic_search.svg',
              //   width: 26,
              //   height: 26,
              //   package: 'nim_conversationkit_ui',
              // )
              // Text("data"),
              /**
               * 1.（功能1：设置Image.asset的宽高）直接使用Image.asset设置width、height可以用
               */
              // Image.asset(
              //     'images/icon_titlebar_search_btn.png',
              //     width: 20,
              //     height: 20,
              //     package: 'nim_conversationkit_ui',
              //     // fit:BoxFit.cover
              // )
              /**
               * 2.（功能1：设置Image.asset的宽高）
               * 如果作为TextField的prefixIcon的话，直接使用Image
               * .asset设置width、height不可用，必须设置prefixIconConstraints来设置宽高，为什么？？
               *
               * 这里同时也涉及到（功能2：设置TextField的宽高）使用ConstrainedBox和BoxConstraints
               * 帮助设置了TextField的宽高
               */
              // ConstrainedBox(
              //     constraints:
              //         BoxConstraints(maxWidth: 285, maxHeight: 32.5),
              //     child: TextField(
              //       decoration: InputDecoration(
              //           // contentPadding: const EdgeInsets.symmetric(vertical: 8),
              //           prefixIcon: Image.asset(
              //             'images/icon_titlebar_search_btn.png',
              //             width: 20,
              //             height: 20,
              //             package: 'nim_conversationkit_ui',
              //             fit:BoxFit.cover
              //           ),
              //           hintText: "搜索",
              //           // hintStyle: TextStyle(),
              //           border: OutlineInputBorder(
              //               borderRadius: BorderRadius.circular(24),
              //               borderSide:
              //                   const BorderSide(style: BorderStyle.none)),
              //           filled: true,
              //           fillColor: Color(0xFFA350E2)),
              //     ))
              /**
               * 功能1和功能2的最终版
               */
              ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: 285, maxHeight: 32.5),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      // contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      /**
                       * 功能5 实现方式1 设置TextField输入框垂直居中
                       */
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        /**
                         * 功能5 实现方式2 设置TextField输入框垂直居中
                         */
                        // contentPadding:EdgeInsets.only(top: 0, bottom: 0),
                        prefixIcon: Padding(
                          // padding: EdgeInsets.fromLTRB(10,10,10,10), //
                          padding: const EdgeInsets.only(
                              left: 30, top: 5, right: 10, bottom: 5),
                          //
                          // (defaultPadding),
                          // child: Image(image:AssetImage
                          //   ("assets/icons/signup_icon_user.webp"),width:10),
                          child: Image.asset(
                              'images/icon_titlebar_search_btn.png',
                              width: 20,
                              height: 20,
                              package: 'nim_conversationkit_ui',
                              fit: BoxFit.cover),
                        ),
                        prefixIconConstraints:
                        const BoxConstraints(maxWidth: 60, maxHeight: 30),
                        // prefixIcon: Image.asset(
                        //   'images/icon_titlebar_search_btn.png',
                        //   width: 20,
                        //   height: 20,
                        //   package: 'nim_conversationkit_ui',
                        //   fit:BoxFit.cover
                        // ),
                        // prefixIconConstraints: BoxConstraints(maxWidth: 20, maxHeight: 20),
                        hintText: S.of(context).search,
                        hintStyle: const TextStyle(color: Color(0x73FFFFFF)),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        disabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        focusedErrorBorder: inputBorder,
                        filled: true,
                        fillColor: const Color(0xFFA350E2)),
                    onChanged: (value) {
                      keyword = value;
                      setState(() {});
                    },
                  )),
              const SizedBox(width: 10),
              // TextButton(style: TextButton.styleFrom(
              //     backgroundColor: Color(0xFFA350E2),
              //     shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(24))),child: Text(""),onPressed:
              //     (){},)
              /**
               * 功能3 给按钮设置背景图片,使用AssetImage需要指定package（如果引入的图片资源是在library里）
               */
              if (_titleBarConfig.showTitleBarRightIcon)
                _titleBarConfig.titleBarRightIcon ??
                    ConversationPopMenuButton()
            ],
          ),
        ),
      ),
      preferredSize: const Size.fromHeight(56),
    );

    // return AppBar(
    //   backgroundColor: _titleBarConfig.backgroundColor,
    //   centerTitle: true,
    //   flexibleSpace: Container(
    //     decoration: BoxDecoration(
    //         gradient: getGradientBackground()),
    //   ),
    //   title: Padding(
    //     padding: EdgeInsets.only(bottom: 17),
    //     child: Row(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         // SvgPicture.asset(
    //         //   'images/ic_search.svg',
    //         //   width: 26,
    //         //   height: 26,
    //         //   package: 'nim_conversationkit_ui',
    //         // )
    //         // Text("data"),
    //         /**
    //          * 1.（功能1：设置Image.asset的宽高）直接使用Image.asset设置width、height可以用
    //          */
    //         // Image.asset(
    //         //     'images/icon_titlebar_search_btn.png',
    //         //     width: 20,
    //         //     height: 20,
    //         //     package: 'nim_conversationkit_ui',
    //         //     // fit:BoxFit.cover
    //         // )
    //         /**
    //          * 2.（功能1：设置Image.asset的宽高）
    //          * 如果作为TextField的prefixIcon的话，直接使用Image
    //          * .asset设置width、height不可用，必须设置prefixIconConstraints来设置宽高，为什么？？
    //          *
    //          * 这里同时也涉及到（功能2：设置TextField的宽高）使用ConstrainedBox和BoxConstraints
    //          * 帮助设置了TextField的宽高
    //          */
    //         // ConstrainedBox(
    //         //     constraints:
    //         //         BoxConstraints(maxWidth: 285, maxHeight: 32.5),
    //         //     child: TextField(
    //         //       decoration: InputDecoration(
    //         //           // contentPadding: const EdgeInsets.symmetric(vertical: 8),
    //         //           prefixIcon: Image.asset(
    //         //             'images/icon_titlebar_search_btn.png',
    //         //             width: 20,
    //         //             height: 20,
    //         //             package: 'nim_conversationkit_ui',
    //         //             fit:BoxFit.cover
    //         //           ),
    //         //           hintText: "搜索",
    //         //           // hintStyle: TextStyle(),
    //         //           border: OutlineInputBorder(
    //         //               borderRadius: BorderRadius.circular(24),
    //         //               borderSide:
    //         //                   const BorderSide(style: BorderStyle.none)),
    //         //           filled: true,
    //         //           fillColor: Color(0xFFA350E2)),
    //         //     ))
    //         /**
    //          * 功能1和功能2的最终版
    //          */
    //         ConstrainedBox(
    //             constraints:
    //                 const BoxConstraints(maxWidth: 285, maxHeight: 32.5),
    //             child: TextField(
    //               style: const TextStyle(color: Colors.white),
    //               decoration: InputDecoration(
    //                   // contentPadding: const EdgeInsets.symmetric(vertical: 8),
    //                   /**
    //                  * 功能5 实现方式1 设置TextField输入框垂直居中
    //                  */
    //                   contentPadding: const EdgeInsets.symmetric(vertical: 0),
    //                   /**
    //                    * 功能5 实现方式2 设置TextField输入框垂直居中
    //                    */
    //                   // contentPadding:EdgeInsets.only(top: 0, bottom: 0),
    //                   prefixIcon: Padding(
    //                     // padding: EdgeInsets.fromLTRB(10,10,10,10), //
    //                     padding: const EdgeInsets.only(
    //                         left: 30, top: 5, right: 10, bottom: 5),
    //                     //
    //                     // (defaultPadding),
    //                     // child: Image(image:AssetImage
    //                     //   ("assets/icons/signup_icon_user.webp"),width:10),
    //                     child: Image.asset(
    //                         'images/icon_titlebar_search_btn.png',
    //                         width: 20,
    //                         height: 20,
    //                         package: 'nim_conversationkit_ui',
    //                         fit: BoxFit.cover),
    //                   ),
    //                   prefixIconConstraints:
    //                       const BoxConstraints(maxWidth: 60, maxHeight: 30),
    //                   // prefixIcon: Image.asset(
    //                   //   'images/icon_titlebar_search_btn.png',
    //                   //   width: 20,
    //                   //   height: 20,
    //                   //   package: 'nim_conversationkit_ui',
    //                   //   fit:BoxFit.cover
    //                   // ),
    //                   // prefixIconConstraints: BoxConstraints(maxWidth: 20, maxHeight: 20),
    //                   hintText: "搜索",
    //                   hintStyle:
    //                       const TextStyle(color: const Color(0x73FFFFFF)),
    //                   border: inputBorder,
    //                   enabledBorder: inputBorder,
    //                   disabledBorder: inputBorder,
    //                   focusedBorder: inputBorder,
    //                   focusedErrorBorder: inputBorder,
    //                   filled: true,
    //                   fillColor: const Color(0xFFA350E2)),
    //             )),
    //         const SizedBox(width: 10),
    //         // TextButton(style: TextButton.styleFrom(
    //         //     backgroundColor: Color(0xFFA350E2),
    //         //     shape: RoundedRectangleBorder(
    //         //         borderRadius: BorderRadius.circular(24))),child: Text(""),onPressed:
    //         //     (){},)
    //         /**
    //          * 功能3 给按钮设置背景图片,使用AssetImage需要指定package（如果引入的图片资源是在library里）
    //          */
    //         Container(
    //             width: 48,
    //             height: 32.5,
    //             decoration: const BoxDecoration(
    //               // color: Colors.white,
    //               image: DecorationImage(
    //                   image: AssetImage("images/icon_titlebar_add_btn.png",
    //                       package: 'nim_conversationkit_ui'),
    //                   fit: BoxFit.fill),
    //             ),
    //             child: TextButton(
    //                 style: TextButton.styleFrom(
    //                     backgroundColor: Colors.transparent,
    //                     shape: RoundedRectangleBorder(
    //                         borderRadius: BorderRadius.circular(24))),
    //                 child: const Text(""),
    //                 onPressed: () {}))
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget buildSearchList(BuildContext context, String keyword) {
    Future<List<SearchInfo>> _search(String text) async {
      return [
        ...(await SearchRepo.instance.searchFriend(text)),
        ...(await SearchRepo.instance.searchTeam(text))
      ];
    }

    Widget _buildItem(
        BuildContext context, SearchInfo currentItem, SearchInfo? lastItem) {
      RecordHitInfo record = currentItem.hitInfo!;
      TextStyle normalStyle =
      TextStyle(fontSize: 16, color: '#333333'.toColor());
      TextStyle highStyle = TextStyle(fontSize: 16, color: '#337EFF'.toColor());

      String _getTitle() {
        switch (currentItem.getType()) {
          case SearchType.contact:
            return /*S.of(context).search_search_friend*/ "search_search_friend";
          case SearchType.normalTeam:
            return /*S.of(context).search_search_normal_team*/ "search_search_normal_team";
          case SearchType.advancedTeam:
            return /*S.of(context).search_search_advance_team*/ "search_search_advance_team";
        }
      }

      Widget _getContactWidget() {
        ContactInfo contact = (currentItem as FriendSearchInfo).contact;

        String? _getHitName() {
          switch (currentItem.hitType) {
            case HitType.alias:
              return contact.friend?.alias;
            case HitType.userName:
              return contact.user.nick;
            case HitType.account:
              return contact.user.userId;
            default:
              return contact.getName();
          }
        }

        String _hitName = _getHitName()!;
        Widget _hitWidget(TextStyle textStyle, TextStyle hitStyle) {
          return RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(children: [
              if (record.start > 0)
                TextSpan(
                  text: _hitName.substring(0, record.start),
                  style: textStyle,
                ),
              TextSpan(
                  text: _hitName.substring(record.start, record.end),
                  style: hitStyle),
              if (record.end <= _hitName.length - 1)
                TextSpan(text: _hitName.substring(record.end), style: textStyle)
            ]),
          );
        }

        return InkWell(
          onTap: () {
            // TODO: UI
            goToP2pChat(context, contact.user.userId!);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Avatar(
                radius: 5,
                avatar: contact.user.avatar,
                name: contact.getName(),
                width: 36,
                height: 36,
                bgCode: AvatarColor.avatarColor(content: contact.user.userId),
              ),
              Expanded(
                child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: currentItem.hitType == HitType.account
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.getName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: normalStyle,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        _hitWidget(
                            TextStyle(
                                fontSize: 12, color: '#333333'.toColor()),
                            TextStyle(
                                fontSize: 12,
                                color: '#337EFF'.toColor())),
                      ],
                    )
                        : _hitWidget(normalStyle, highStyle)),
              ),
            ],
          ),
        );
      }

      Widget _getTeamWidget() {
        NIMTeam team = (currentItem as TeamSearchInfo).team;
        return InkWell(
          onTap: () {
            // TODO: UI
            goToTeamChat(context, team.id!);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Avatar(
                radius: 5,
                avatar: team.icon,
                name: team.name,
                width: 32,
                height: 32,
                bgCode: AvatarColor.avatarColor(content: team.id),
              ),
              Expanded(
                child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(children: [
                        if (record.start > 0)
                          TextSpan(
                            text: team.name!.substring(0, record.start),
                            style: normalStyle,
                          ),
                        TextSpan(
                            text:
                            team.name!.substring(record.start, record.end),
                            style: highStyle),
                        if (record.end <= team.name!.length - 1)
                          TextSpan(
                              text: team.name!.substring(record.end),
                              style: normalStyle)
                      ]),
                    )),
              )
            ],
          ),
        );
      }

      TextStyle titleStyle =
      TextStyle(fontSize: 14, color: '#B3B7BC'.toColor());

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastItem == null ||
                lastItem.getType() != currentItem.getType()) ...[
              Text(
                _getTitle(),
                style: titleStyle,
              ),
              Container(
                height: 1,
                color: '#DBE0E8'.toColor(),
                margin: const EdgeInsets.only(bottom: 8, top: 8),
              )
            ],
            if (currentItem.getType() == SearchType.contact)
              _getContactWidget(),
            if (currentItem.getType() == SearchType.normalTeam ||
                currentItem.getType() == SearchType.advancedTeam)
              _getTeamWidget(),
          ],
        ),
      );
    }

    if (keyword.isEmpty) {
      return Container();
    } else {
      return FutureBuilder<List<SearchInfo>>(
          future: _search(keyword),
          builder: (context, snapShot) {
            List<SearchInfo> searchList = snapShot.data ?? List.empty();
            if (searchList.isEmpty) {
              return Column(
                children: [
                  const SizedBox(
                    height: 68,
                  ),
                  SvgPicture.asset(
                    'images/ic_search_empty.svg',
                    package: 'nim_searchkit_ui',
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  const Text(
                    /*S.of(context).search_empty_tips*/ "无记录",
                    style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                  )
                ],
              );
            } else {
              return ListView.builder(
                  itemCount: searchList.length,
                  itemBuilder: (context, index) {
                    SearchInfo currentItem = searchList[index];
                    var lastItem = index > 0 ? searchList[index - 1] : null;
                    return _buildItem(context, currentItem, lastItem);
                  });
            }
          });
    }
  }

  Widget getScaffoldBodyWidget(Widget child) {
    return Expanded(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: getGradientBackground()),
              width: double.infinity,
              height: 30,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30), right: Radius.circular(30))),
              child: Padding(
                child: child,
                padding: const EdgeInsets.only(top: 10),
              ),
            ),
          ],
        ))
    /**
     * 功能4 最终版 实现层叠布局，
     * 底层是高度为15的矩形
     * 上册是左右上角弧度为15的圆角，高度是撑满屏幕
     */
    // Expanded(child: Stack(
    //   children: [
    //     Container(
    //       color: Colors.red,
    //       width: double.infinity,
    //       height: 15,
    //     ),
    //     Container(
    //       width: MediaQuery.of(context).size.width,
    //       height: MediaQuery.of(context).size.height,
    //       decoration: const BoxDecoration(
    //           color: Colors.green,
    //           borderRadius: BorderRadius.horizontal(
    //               left: Radius.circular(15),
    //               right: Radius.circular(15))),
    //       /*child: ConversationList(
    //           config: uiConfig.itemConfig,
    //           onUnreadCountChanged: widget.onUnreadCountChanged,
    //         ),*/
    //     ),
    //   ],
    // ))
    /**
     * 功能4 有问题版 实现层叠布局，
     * 底层是高度为15的矩形
     * 上册是左右上角弧度为15的圆角，高度是撑满屏幕
     * Stack直接child不能是Expanded
     */
    // Stack(
    //   children: [
    //     Container(
    //       color: Colors.red,
    //       width: double.infinity,
    //       height: 15,
    //     ),
    //     Container(
    //       width: MediaQuery.of(context).size.width,
    //       height: MediaQuery.of(context).size.height,
    //         decoration: const BoxDecoration(
    //             color: Colors.green,
    //             borderRadius: BorderRadius.horizontal(
    //                 left: Radius.circular(15),
    //                 right: Radius.circular(15))),
    //         /*child: ConversationList(
    //           config: uiConfig.itemConfig,
    //           onUnreadCountChanged: widget.onUnreadCountChanged,
    //         ),*/
    //       ),
    //   ],
    // )
        ;
  }

  Gradient getGradientBackground() {
    return const LinearGradient(colors: [Color(0xff6913CF), Color(0xff8919DA)]);
  }
}
