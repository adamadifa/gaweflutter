class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String nik;
  final String? jabatan;
  final String? departemen;
  final String? cabang;
  final String? foto;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.nik,
    this.jabatan,
    this.departemen,
    this.cabang,
    this.foto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      nik: json['nik'] as String,
      jabatan: json['jabatan'] as String?,
      departemen: json['departemen'] as String?,
      cabang: json['cabang'] as String?,
      foto: json['foto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'nik': nik,
      'jabatan': jabatan,
      'departemen': departemen,
      'cabang': cabang,
      'foto': foto,
    };
  }
}
