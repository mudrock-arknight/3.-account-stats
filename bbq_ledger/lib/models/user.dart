class AppUser {
  final String id;
  final String name;
  final String pinCode;
  final String avatarColor;

  const AppUser({
    required this.id,
    required this.name,
    required this.pinCode,
    this.avatarColor = '#4CAF50',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      pinCode: json['pin_code'] as String,
      avatarColor: (json['avatar_color'] as String?) ?? '#4CAF50',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pin_code': pinCode,
      'avatar_color': avatarColor,
    };
  }
}