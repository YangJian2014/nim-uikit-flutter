import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

class TeamQRCodePage extends StatefulWidget {
  TeamQRCodePage({Key? key, required this.tId, required this.tName})
      : super(key: key);
  String tId;
  String tName;

  @override
  State<TeamQRCodePage> createState() => _TeamQRCodePageState();
}

class _TeamQRCodePageState extends State<TeamQRCodePage> {
  String _qrCode = '';

  @override
  void initState() {
    super.initState();
    _getQRInfo();
  }

  _getQRInfo() async {
    var userParams = {'tid': widget.tId};
    var response = await UtilsNetworkHelper.groupQRCode(userParams);
    var rspData = response?.data;
    var code = rspData['code'] ?? -1;
    if (code != 0) {
      print('获取二维码失败, status=$code');
      return;
    }

    String qrcodeUrl = rspData['data']['qrcode_url'] ?? '';
    if (qrcodeUrl.isEmpty) {
      print('获取二维码失败, tid=$qrcodeUrl');
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _qrCode = qrcodeUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('群二维码'),
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
        elevation: 0,
      ),
      body: Center(
          child: Column(
        children: [
          const Padding(padding: EdgeInsets.only(top: 30)),
          Container(
              child: _qrCode.isEmpty
                  ? Container()
                  : SizedBox(
                      width: 230,
                      height: 230,
                      child: Center(
                          child: Image(
                        width: 230,
                        height: 230,
                        image: NetworkImage(_qrCode, scale: 1),
                      )),
                    )),
          const Padding(padding: EdgeInsets.only(top: 30)),
          Text('群聊：${widget.tName}'),
        ],
      )),
    );
  }
}
