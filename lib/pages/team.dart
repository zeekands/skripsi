class Team {
  Team({
    required this.id,
    required this.name,
    required this.score,
    required this.slot,
  });
  late final String id;
  late final String name;
  late final int score;
  late final int slot;

  Team.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    score = json['score'];
    slot = json['slot'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['name'] = name;
    _data['score'] = score;
    _data['slot'] = slot;
    return _data;
  }
}
