class Option {
  final String text;
  final String? target; //if null end the sequence

  Option({required this.text, this.target});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      text: json['option'] ?? '',
      target: json['target'],
    );
  }
}