// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/input/emoji.dart';
import 'package:collection/collection.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:selectable_autolink_text/selectable_autolink_text.dart';
import 'package:selectable_autolink_text/src/tap_and_long_press.dart';
import 'package:selectable_autolink_text/src/text_element.dart';
import 'package:selectable_autolink_text/src/highlighted_text_span.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatKitMessageTextItem extends StatefulWidget {
  final String text;

  final ChatUIConfig? chatUIConfig;
  final bool isSelf;

  const ChatKitMessageTextItem(
      {Key? key, required this.text, this.chatUIConfig, required this.isSelf})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageTextState();
}

class ChatKitMessageTextState extends State<ChatKitMessageTextItem> {
  TextSpan _textSpan(String text) {
    return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, color: CommonColors.color_333333));
  }

  WidgetSpan? _imageSpan(String? tag) {
    var item = emojiData.firstWhereOrNull((element) => element['tag'] == tag);
    if (item == null) return null;
    String name = item['name'] as String;
    return WidgetSpan(
      child: Image.asset(
        name,
        package: kPackage,
        height: 24,
        width: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(widget.text);
    List<InlineSpan> spans = [];
    int preIndex = 0;
    if (matches.isNotEmpty) {
      final String text = widget.text;
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.add(_textSpan(text.substring(preIndex, match.start)));
        }
        var span = _imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans.add(_textSpan(text.substring(preIndex, text.length)));
      }
    }
    return Container(
        //放到里面
        padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 8),
        child: buildNewText()
        // child: matches.isEmpty
        //     ? Text(
        //         widget.text,
        //         style: TextStyle(
        //             fontSize: widget.chatUIConfig?.messageTextSize ?? 16,
        //             color: widget.chatUIConfig?.messageTextColor ??
        //                 '#333333'.toColor()),
        //       )
        //     : Text.rich(TextSpan(children: spans)),
        );
  }

  final _gestureRecognizers = <TapAndLongPressGestureRecognizer>[];

  @override
  void dispose() {
    _clearGestureRecognizers();
    super.dispose();
  }

  Future<bool> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      return false;
    }
  }

  Widget buildNewText() {
    return Text.rich(
      TextSpan(children: _createTextSpans()),
    );
  }

  List<TextElement> _generateElements(String text) {
    if (text.isEmpty) return [];

    final elements = <TextElement>[];

    final matches =
        RegExp('(@[\\w]+|#[\\w]+|${AutoLinkUtils.urlRegExpPattern})')
            .allMatches(text);
    if (matches.isEmpty) {
      elements.add(TextElement(
        type: TextElementType.text,
        text: text,
      ));
    } else {
      var index = 0;
      for (var match in matches) {
        // widget.onDebugMatch?.call(match);

        if (match.start != 0) {
          elements.add(TextElement(
            type: TextElementType.text,
            text: text.substring(index, match.start),
          ));
        }
        elements.add(TextElement(
          type: TextElementType.link,
          text: match.group(0) ?? '',
        ));
        index = match.end;
      }

      if (index < text.length) {
        elements.add(TextElement(
          type: TextElementType.text,
          text: text.substring(index),
        ));
      }
    }

    return elements;
  }

  List<TextSpan> _createTextSpans() {
    _clearGestureRecognizers();
    return _generateElements(widget.text).map(
      (e) {
        var isLink = e.type == TextElementType.link;
        final linkAttr = isLink ? AutoLinkUtils.shrinkUrl.call(e.text) : null;
        final link = linkAttr != null ? linkAttr.link : e.text;
        isLink = isLink && link != null;

        return HighlightedTextSpan(
          text: linkAttr?.text ?? e.text,
          style: linkAttr?.style ??
              (isLink
                  ? const TextStyle(color: Color.fromARGB(255, 50, 121, 244))
                  : TextStyle(
                      fontSize: widget.chatUIConfig?.messageTextSize ?? 16,
                      color: (widget.isSelf
                          ? Color.fromARGB(255, 253, 251, 251)
                          : Color.fromARGB(255, 57, 57, 57)))),
          highlightedStyle: isLink
              ? (linkAttr?.highlightedStyle ??
                  TextStyle(
                    color: Colors.deepOrangeAccent,
                    backgroundColor: Colors.deepOrangeAccent.withAlpha(0x33),
                  ))
              : null,
          recognizer: isLink ? _createGestureRecognizer(link) : null,
        );
      },
    ).toList();
  }

  TapAndLongPressGestureRecognizer? _createGestureRecognizer(String link) {
    // if (widget.onTap == null && widget.onLongPress == null) {
    //   return null;
    // }
    final recognizer = TapAndLongPressGestureRecognizer();
    _gestureRecognizers.add(recognizer);
    recognizer.onTap = () async {
      print('Tap: $link');
      if (!await _launchUrl(link)) {
        // _alert(context, 'Tap', link);
      }
    };
    recognizer.onLongPress = () async {
      print('Tap: $link');
      if (!await _launchUrl(link)) {
        // _alert(context, 'Tap', link);
      }
    };

    return recognizer;
  }

  void _clearGestureRecognizers() {
    for (var r in _gestureRecognizers) {
      r.dispose();
    }
    _gestureRecognizers.clear();
  }
}
