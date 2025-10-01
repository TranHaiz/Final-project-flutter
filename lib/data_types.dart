// Class trees
class EnvData {
  String name;
  String imagePath;

  EnvData({required this.name, required this.imagePath});

  Map<String, dynamic> toJson() => {
        "name": name,
        "imagePath": imagePath,
      };

  factory EnvData.fromJson(Map<String, dynamic> json) {
    return EnvData(
      name: json["name"],
      imagePath: json["imagePath"],
    );
  }
}

// Class garden
class Garden {
  String name;
  List<EnvData> envDatas;
  Map<String, double> envParams;

  Garden({
    required this.name,
    List<EnvData>? envDatas,
    Map<String, double>? envParams,
  })  : envDatas = envDatas ?? [],
        envParams = envParams ?? {};

  Map<String, dynamic> toJson() => {
        "name": name,
        "envDatas": envDatas.map((p) => p.toJson()).toList(),
        "envParams": envParams,
      };

  factory Garden.fromJson(Map<String, dynamic> json) {
    return Garden(
      name: json["name"],
      envDatas: (json["envDatas"] as List<dynamic>?)
              ?.map((p) => EnvData.fromJson(p))
              .toList() ??
          [],
      envParams: Map<String, double>.from(json["envParams"] ?? {}),
    );
  }
}
