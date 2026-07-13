class ProjectModel {
  final int id;
  final String kodeProject;
  final String namaProject;
  final String deskripsi;
  final String category;
  final String startDate;
  final String endDate;
  final String status;
  final String prioritas;
  final int progress;
  final int membersCount;
  final int pendingTasksCount;

  final String leaderName;
  final String categoryColor;

  final double budget;

  ProjectModel({
    required this.id,
    required this.kodeProject,
    required this.namaProject,
    required this.deskripsi,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.prioritas,
    required this.progress,
    required this.membersCount,
    required this.pendingTasksCount,
    required this.leaderName,
    required this.categoryColor,
    required this.budget,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? 0,
      kodeProject: json['kode_project'] ?? '',
      namaProject: json['nama_project'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      category: json['category'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'active',
      prioritas: json['prioritas'] ?? 'medium',
      progress: json['progress'] ?? 0,
      membersCount: json['members_count'] ?? 0,
      pendingTasksCount: json['pending_tasks_count'] ?? 0,
      leaderName: json['leader_name'] ?? 'Belum ditentukan',
      categoryColor: json['category_color'] ?? '#64748b',
      budget: (json['budget'] ?? 0.0).toDouble(),
    );
  }
}

class ProjectMemberModel {
  final String nik;
  final String nama;
  final String role;
  final String foto;

  ProjectMemberModel({
    required this.nik,
    required this.nama,
    required this.role,
    required this.foto,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      nik: json['nik'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'] ?? 'Member',
      foto: json['foto'] ?? '',
    );
  }
}

class ProjectTaskMemberModel {
  final String nik;
  final String nama;
  final String foto;

  ProjectTaskMemberModel({
    required this.nik,
    required this.nama,
    required this.foto,
  });

  factory ProjectTaskMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskMemberModel(
      nik: json['nik'] ?? '',
      nama: json['nama'] ?? '',
      foto: json['foto'] ?? '',
    );
  }
}

class ProjectTaskModel {
  final int id;
  final int? parentId;
  final String kodeTask;
  final String judul;
  final String deskripsi;
  final String status;
  final String prioritas;
  final int progress;
  final String startDate;
  final String dueDate;
  final List<ProjectTaskMemberModel> members;

  ProjectTaskModel({
    required this.id,
    this.parentId,
    required this.kodeTask,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.prioritas,
    required this.progress,
    required this.startDate,
    required this.dueDate,
    required this.members,
  });

  factory ProjectTaskModel.fromJson(Map<String, dynamic> json) {
    final list = json['members'] as List? ?? [];
    return ProjectTaskModel(
      id: json['id'] ?? 0,
      parentId: json['parent_id'],
      kodeTask: json['kode_task'] ?? '',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      status: json['status'] ?? 'todo',
      prioritas: json['prioritas'] ?? 'medium',
      progress: json['progress'] ?? 0,
      startDate: json['start_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      members: list.map((e) => ProjectTaskMemberModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class ProjectDetailResponse {
  final ProjectModel project;
  final List<ProjectTaskModel> tasks;
  final List<ProjectMemberModel> members;

  ProjectDetailResponse({
    required this.project,
    required this.tasks,
    required this.members,
  });

  factory ProjectDetailResponse.fromJson(Map<String, dynamic> json) {
    final taskList = json['tasks'] as List? ?? [];
    final memberList = json['members'] as List? ?? [];

    return ProjectDetailResponse(
      project: ProjectModel.fromJson(Map<String, dynamic>.from(json['project'] ?? {})),
      tasks: taskList.map((e) => ProjectTaskModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      members: memberList.map((e) => ProjectMemberModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
