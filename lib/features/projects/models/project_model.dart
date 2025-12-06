class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> members;
  final String inviteCode; // Opsional: untuk fitur join nanti

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.members,
    required this.inviteCode,
  });

  // Mengubah data dari Firebase (Map) menjadi object Dart
  factory ProjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProjectModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      inviteCode: map['inviteCode'] ?? '',
    );
  }

  // Mengubah object Dart menjadi Map untuk dikirim ke Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': members,
      'inviteCode': inviteCode,
    };
  }
}