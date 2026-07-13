import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:gaweflutter/features/project/data/models/project_model.dart';
import 'package:gaweflutter/features/project/data/repositories/project_repository.dart';
import 'package:gaweflutter/features/project/presentation/providers/project_provider.dart';
import 'package:intl/intl.dart';

class ProjectBoardScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectBoardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends ConsumerState<ProjectBoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF64748B);
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
      case 'todo':
        return const Color(0xFFF1F5F9);
      case 'in_progress':
      case 'active':
        return const Color(0xFFDBEAFE);
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'on_hold':
      case 'review':
        return const Color(0xFFFEF3C7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
      case 'todo':
        return const Color(0xFF475569);
      case 'in_progress':
      case 'active':
        return const Color(0xFF1D4ED8);
      case 'completed':
        return const Color(0xFF15803D);
      case 'on_hold':
      case 'review':
        return const Color(0xFF92400E);
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF475569);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return 'PLANNING';
      case 'todo':
        return 'TO DO';
      case 'in_progress':
      case 'active':
        return 'IN PROGRESS';
      case 'completed':
        return 'SELESAI';
      case 'on_hold':
        return 'ON HOLD';
      case 'review':
        return 'REVIEW';
      case 'cancelled':
        return 'BATAL';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityBgColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFEE2E2);
      case 'high':
        return const Color(0xFFFEF3C7);
      case 'medium':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 'Kritis';
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      default:
        return priority;
    }
  }

  void _showTaskDetailsBottomSheet(BuildContext context, ProjectTaskModel task) {
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        int localProgress = task.progress;
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isUpdating = false;

            Future<void> updateStatus(String newStatus, int progress) async {
              setModalState(() => isUpdating = true);
              try {
                final repo = ref.read(projectRepositoryProvider);
                final success = await repo.updateTaskStatus(task.id, newStatus, progress);
                if (success) {
                  ref.invalidate(projectDetailProvider(widget.projectId));
                  ref.invalidate(projectsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task berhasil dipindahkan ke ${_getStatusText(newStatus)}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  throw Exception('Gagal memperbarui status');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                setModalState(() => isUpdating = false);
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task.kodeTask,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityBgColor(task.prioritas),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPriorityLabel(task.prioritas).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(task.prioritas),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.judul,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deskripsi Tugas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.deskripsi.isNotEmpty ? task.deskripsi : 'Tidak ada deskripsi.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Mulai',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.play_arrow_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.startDate.isNotEmpty ? task.startDate : '-',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tenggat Waktu (Due)',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.alarm, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.dueDate.isNotEmpty ? task.dueDate : '-',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (task.members.isNotEmpty) ...[
                        const Text(
                          'Anggota Ditugaskan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: task.members.map((member) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundImage: member.foto.isNotEmpty ? NetworkImage(member.foto) : null,
                                    backgroundColor: primaryColor,
                                    child: member.foto.isEmpty
                                        ? Text(
                                            member.nama.isNotEmpty ? member.nama[0].toUpperCase() : '?',
                                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    member.nama,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (isUpdating)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        (() {
                          final myNik = ref.read(authProvider).user?.nik ?? '';
                          final isAssigned = task.members.any((m) => m.nik == myNik);

                          if (!isAssigned) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded, color: Colors.amber.shade800, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hanya anggota yang ditugaskan yang dapat memperbarui progress tugas ini.',
                                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Update Progress',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    '$localProgress%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Slider(
                                value: localProgress.toDouble(),
                                min: 0.0,
                                max: 100.0,
                                divisions: 20,
                                label: '$localProgress%',
                                activeColor: primaryColor,
                                inactiveColor: const Color(0xFFE2E8F0),
                                onChanged: (val) {
                                  setModalState(() {
                                    localProgress = val.round();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildActionButton(
                                context: context,
                                label: 'Simpan Progress',
                                icon: Icons.save_rounded,
                                color: primaryColor,
                                onTap: () {
                                  String newStatus = task.status;
                                  if (localProgress == 100) {
                                    newStatus = 'completed';
                                  } else if (task.status == 'completed' && localProgress < 100) {
                                    newStatus = 'in_progress';
                                  } else if (localProgress == 0) {
                                    newStatus = 'todo';
                                  } else if (task.status == 'todo' && localProgress > 0) {
                                    newStatus = 'in_progress';
                                  }
                                  updateStatus(newStatus, localProgress);
                                },
                              ),
                            ],
                          );
                        })(),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(projectDetailProvider(widget.projectId));
    final myNik = ref.watch(authProvider).user?.nik ?? '';
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Detail Project',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: detailState.when(
        data: (res) {
          final project = res.project;
          final catColor = _parseHexColor(project.categoryColor);
          final statusBg = _getStatusBgColor(project.status);
          final statusTextCol = _getStatusTextColor(project.status);
          final statusTextLabel = _getStatusText(project.status);

          // Split tasks: My Tasks vs Other Tasks
          final myTasks = res.tasks.where((t) => t.members.any((m) => m.nik == myNik)).toList();
          final otherTasks = res.tasks.where((t) => !t.members.any((m) => m.nik == myNik)).toList();

          return Column(
            children: [
              // 1. Scrollable Project Info Header Details
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(projectDetailProvider(widget.projectId));
                  },
                  color: primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Detail Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      project.namaProject.length >= 2
                                          ? project.namaProject.substring(0, 2).toUpperCase()
                                          : project.namaProject.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.namaProject,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${project.kodeProject} • ${project.category}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusTextLabel,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: statusTextCol,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Info details body
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildInfoRow('Tanggal Mulai', project.startDate),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Deadline', project.endDate),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Leader', project.leaderName),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Anggaran',
                                    project.budget > 0
                                        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(project.budget)
                                        : '-',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Progress', '${project.progress}%', valueColor: primaryColor),
                                ],
                              ),
                            ),

                            // Description Section if not empty
                            if (project.deskripsi.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DESKRIPSI',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      project.deskripsi,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Team Members list Row
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TIM (${res.members.length})',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Stack(
                                        children: List.generate(
                                          res.members.length > 5 ? 5 : res.members.length,
                                          (idx) {
                                            final m = res.members[idx];
                                            return Container(
                                              margin: EdgeInsets.only(left: idx * 14.0),
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundImage: m.foto.isNotEmpty ? NetworkImage(m.foto) : null,
                                                backgroundColor: primaryColor,
                                                child: m.foto.isEmpty
                                                    ? Text(
                                                        m.nama.isNotEmpty ? m.nama.substring(0, 2).toUpperCase() : '?',
                                                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                                      )
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (res.members.length > 5) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '+${res.members.length - 5}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Tab Bar Header
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: primaryColor,
                          labelColor: primaryColor,
                          unselectedLabelColor: const Color(0xFF94A3B8),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: [
                            Tab(text: 'TUGAS SAYA (${myTasks.length})'),
                            Tab(text: 'TUGAS LAIN (${otherTasks.length})'),
                          ],
                        ),
                      ),

                      // 3. Tab views
                      SizedBox(
                        height: 400, // Fixed height for ListView content inside list
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTasksList(context, myTasks, primaryColor),
                            _buildTasksList(context, otherTasks, primaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, List<ProjectTaskModel> list, Color primaryColor) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_box_outlined, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'Tidak ada tugas terdaftar.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final task = list[index];
        final statusBg = _getStatusBgColor(task.status);
        final statusTextCol = _getStatusTextColor(task.status);
        final statusTextLabel = _getStatusText(task.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTaskDetailsBottomSheet(context, task),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.judul,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.kodeTask,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusTextLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: statusTextCol,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Task progress & deadline body
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Deadline: ${task.dueDate.isNotEmpty ? task.dueDate : '-'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${task.progress}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: task.progress / 100.0,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
