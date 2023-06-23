// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CheckBoxButton extends StatelessWidget {
  final bool isChecked;
  final Function(bool isChecked)? onChanged;
  final double size;

  const CheckBoxButton(
      {Key? key, required this.isChecked, required this.size, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: InkWell(
      onTap: () {
        if (onChanged != null) {
          onChanged!(!isChecked);
        }
      },
      child: !isChecked
          ? Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                border: Border.all(color: '#969AA0'.toColor()),
                shape: BoxShape.circle,
              ),
            )
          : SvgPicture.asset(
              'images/ic_agree.svg',
              package: 'nim_contactkit_ui',
              width: 25,
              height: 25,
            ),
    ));
  }
}
