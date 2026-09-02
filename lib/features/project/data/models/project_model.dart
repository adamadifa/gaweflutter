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
  final bool isLeader;

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
    this.isLeader = false,
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
      isLeader: json['is_leader'] ?? false,
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

class ProjectTaskSubtaskModel {
  final int id;
  final String kodeTask;
  final String judul;
  final String status;
  final int progress;
  final String dueDate;

  ProjectTaskSubtaskModel({
    required this.id,
    required this.kodeTask,
    required this.judul,
    required this.status,
    required this.progress,
    required this.dueDate,
  });

  factory ProjectTaskSubtaskModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskSubtaskModel(
      id: json['id'] ?? 0,
      kodeTask: json['kode_task'] ?? '',
      judul: json['judul'] ?? '',
      status: json['status'] ?? 'todo',
      progress: json['progress'] ?? 0,
      dueDate: json['due_date'] ?? '',
    );
  }
}

class ProjectTaskAttachmentModel {
  final int id;
  final String namaFile;
  final String url;
  final int ukuran;
  final String tipeFile;
  final String uploaderNama;
  final bool isUploader;
  final String createdAt;

  ProjectTaskAttachmentModel({
    required this.id,
    required this.namaFile,
    required this.url,
    required this.ukuran,
    required this.tipeFile,
    required this.uploaderNama,
    required this.isUploader,
    required this.createdAt,
  });

  factory ProjectTaskAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskAttachmentModel(
      id: json['id'] ?? 0,
      namaFile: json['nama_file'] ?? '',
      url: json['url'] ?? '',
      ukuran: json['ukuran'] ?? 0,
      tipeFile: json['tipe_file'] ?? '',
      uploaderNama: json['uploader_nama'] ?? 'Admin',
      isUploader: json['is_uploader'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get formattedSize {
    if (ukuran < 1024) return '$ukuran B';
    if (ukuran < 1024 * 1024) return '${(ukuran / 1024).toStringAsFixed(1)} KB';
    return '${(ukuran / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class ProjectTaskCommentModel {
  final int id;
  final String komentar;
  final String nik;
  final String authorNama;
  final String authorFoto;
  final String createdAt;
  final String createdAtRaw;

  ProjectTaskCommentModel({
    required this.id,
    required this.komentar,
    required this.nik,
    required this.authorNama,
    required this.authorFoto,
    required this.createdAt,
    required this.createdAtRaw,
  });

  factory ProjectTaskCommentModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskCommentModel(
      id: json['id'] ?? 0,
      komentar: json['komentar'] ?? '',
      nik: json['nik'] ?? '',
      authorNama: json['author_nama'] ?? 'Admin',
      authorFoto: json['author_foto'] ?? '',
      createdAt: json['created_at'] ?? '',
      createdAtRaw: json['created_at_raw'] ?? '',
    );
  }
}

class ProjectTaskDetailModel {
  final int id;
  final int projectId;
  final String projectName;
  final int? parentId;
  final String? parentJudul;
  final String kodeTask;
  final String judul;
  final String deskripsi;
  final String status;
  final String prioritas;
  final int progress;
  final String startDate;
  final String dueDate;
  final String? completedAt;
  final bool isAssigned;
  final List<ProjectTaskMemberModel> members;
  final List<ProjectTaskSubtaskModel> subtasks;
  final List<ProjectTaskAttachmentModel> attachments;
  final List<ProjectTaskCommentModel> comments;

  ProjectTaskDetailModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.parentId,
    this.parentJudul,
    required this.kodeTask,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.prioritas,
    required this.progress,
    required this.startDate,
    required this.dueDate,
    this.completedAt,
    required this.isAssigned,
    required this.members,
    required this.subtasks,
    required this.attachments,
    required this.comments,
  });

  factory ProjectTaskDetailModel.fromJson(Map<String, dynamic> json) {
    final memberList = json['members'] as List? ?? [];
    final subtaskList = json['subtasks'] as List? ?? [];
    final attachmentList = json['attachments'] as List? ?? [];
    final commentList = json['comments'] as List? ?? [];

    return ProjectTaskDetailModel(
      id: json['id'] ?? 0,
      projectId: json['project_id'] ?? 0,
      projectName: json['project_name'] ?? '',
      parentId: json['parent_id'],
      parentJudul: json['parent_judul'],
      kodeTask: json['kode_task'] ?? '',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      status: json['status'] ?? 'todo',
      prioritas: json['prioritas'] ?? 'medium',
      progress: json['progress'] ?? 0,
      startDate: json['start_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      completedAt: json['completed_at'],
      isAssigned: json['is_assigned'] ?? false,
      members: memberList.map((e) => ProjectTaskMemberModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      subtasks: subtaskList.map((e) => ProjectTaskSubtaskModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      attachments: attachmentList.map((e) => ProjectTaskAttachmentModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      comments: commentList.map((e) => ProjectTaskCommentModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
