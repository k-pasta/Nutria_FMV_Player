class ProjectInfo {
  final String title;
  final String description;

  ProjectInfo({required this.title, required this.description});

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      title: json['title'],
      description: json['description'],
    );
  }
}