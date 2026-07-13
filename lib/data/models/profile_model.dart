class ProfileModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String nik;
  final String? noHp;
  final String? noKtp;
  final String? alamat;
  final String? jabatan;
  final String? departemen;
  final String? cabang;
  final String? foto;

  ProfileModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.nik,
    this.noHp,
    this.noKtp,
    this.alamat,
    this.jabatan,
    this.departemen,
    this.cabang,
    this.foto,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nik: json['nik'] as String? ?? '',
      noHp: json['no_hp'] as String?,
      noKtp: json['no_ktp'] as String?,
      alamat: json['alamat'] as String?,
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
      'no_hp': noHp,
      'no_ktp': noKtp,
      'alamat': alamat,
      'jabatan': jabatan,
      'departemen': departemen,
      'cabang': cabang,
      'foto': foto,
    };
  }

  ProfileModel copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? nik,
    String? noHp,
    String? noKtp,
    String? alamat,
    String? jabatan,
    String? departemen,
    String? cabang,
    String? foto,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      nik: nik ?? this.nik,
      noHp: noHp ?? this.noHp,
      noKtp: noKtp ?? this.noKtp,
      alamat: alamat ?? this.alamat,
      jabatan: jabatan ?? this.jabatan,
      departemen: departemen ?? this.departemen,
      cabang: cabang ?? this.cabang,
      foto: foto ?? this.foto,
    );
  }
}
