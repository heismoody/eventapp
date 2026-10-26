class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.releaseNotes,
    this.mandatory = false,
  });

  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String? releaseNotes;
  final bool mandatory;

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    return AppRelease(
      versionCode: json['versionCode'] as int,
      versionName: json['versionName'] as String,
      apkUrl: json['apkUrl'] as String,
      releaseNotes: json['releaseNotes'] as String?,
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
}
