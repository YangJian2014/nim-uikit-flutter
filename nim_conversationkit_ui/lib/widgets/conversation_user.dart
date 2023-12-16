class ConversationUser {
  final String title;
  final bool showIcon;

  ConversationUser(this.title, this.showIcon);

  ConversationUser.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        showIcon = json['showIcon'];

  Map<String, dynamic> toJson() => {
        'title': title,
        'showIcon': showIcon,
      };
}
