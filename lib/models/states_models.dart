class StateModel {
  final int id;
  final String name;
  final List<CityModel> cities;

  StateModel({
    required this.id,
    required this.name,
    required this.cities,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'],
      name: json['name'],
      cities: (json['cities'] as List)
          .map((e) => CityModel.fromJson(e))
          .toList(),
    );
  }
}

class CityModel {
  final int id;
  final int stateId;
  final String name;

  CityModel({
    required this.id,
    required this.stateId,
    required this.name,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      stateId: json['state_id'],
      name: json['name'],
    );
  }
}
