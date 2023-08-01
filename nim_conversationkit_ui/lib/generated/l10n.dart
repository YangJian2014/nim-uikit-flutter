// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `CommsEase IM`
  String get conversationTitle {
    return Intl.message(
      'CommsEase IM',
      name: 'conversationTitle',
      desc: '',
      args: [],
    );
  }

  /// `create advanced team success`
  String get createAdvancedTeamSuccess {
    return Intl.message(
      'create advanced team success',
      name: 'createAdvancedTeamSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Stick`
  String get stickTitle {
    return Intl.message(
      'Stick',
      name: 'stickTitle',
      desc: '',
      args: [],
    );
  }

  /// `Cancel stick`
  String get cancelStickTitle {
    return Intl.message(
      'Cancel stick',
      name: 'cancelStickTitle',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get deleteTitle {
    return Intl.message(
      'Delete',
      name: 'deleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Recent chat`
  String get recentTitle {
    return Intl.message(
      'Recent chat',
      name: 'recentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancelTitle {
    return Intl.message(
      'Cancel',
      name: 'cancelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Sure`
  String get sureTitle {
    return Intl.message(
      'Sure',
      name: 'sureTitle',
      desc: '',
      args: [],
    );
  }

  /// `Sure({size})`
  String sureCountTitle(int size) {
    return Intl.message(
      'Sure($size)',
      name: 'sureCountTitle',
      desc: '',
      args: [size],
    );
  }

  /// `The current network is unavailable, please check your network settings.`
  String get conversationNetworkErrorTip {
    return Intl.message(
      'The current network is unavailable, please check your network settings.',
      name: 'conversationNetworkErrorTip',
      desc: '',
      args: [],
    );
  }

  /// `add friends`
  String get addFriend {
    return Intl.message(
      'add friends',
      name: 'addFriend',
      desc: '',
      args: [],
    );
  }

  /// `Please enter account`
  String get addFriendSearchHint {
    return Intl.message(
      'Please enter account',
      name: 'addFriendSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `This user does not exist`
  String get addFriendSearchEmptyTips {
    return Intl.message(
      'This user does not exist',
      name: 'addFriendSearchEmptyTips',
      desc: '',
      args: [],
    );
  }

  /// `create group team`
  String get createGroupTeam {
    return Intl.message(
      'create group team',
      name: 'createGroupTeam',
      desc: '',
      args: [],
    );
  }

  /// `create advanced team`
  String get createAdvancedTeam {
    return Intl.message(
      'create advanced team',
      name: 'createAdvancedTeam',
      desc: '',
      args: [],
    );
  }

  /// `[Nonsupport message type]`
  String get chatMessageNonsupportType {
    return Intl.message(
      '[Nonsupport message type]',
      name: 'chatMessageNonsupportType',
      desc: '',
      args: [],
    );
  }

  /// `no chat`
  String get conversationEmpty {
    return Intl.message(
      'no chat',
      name: 'conversationEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Scan`
  String get group_scan {
    return Intl.message(
      'Scan',
      name: 'group_scan',
      desc: '',
      args: [],
    );
  }

  /// `search`
  String get search {
    return Intl.message(
      'search',
      name: 'search',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
