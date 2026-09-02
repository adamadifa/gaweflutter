import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gaweflutter/features/project/data/models/project_model.dart';
import 'package:gaweflutter/features/project/data/repositories/project_repository.dart';
import 'package:gaweflutter/features/project/presentation/providers/project_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final int taskId;
  final String? initialTaskTitle;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.initialTaskTitle,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int? _localProgress;
  String? _localStatus;
  bool _isSavingProgress = false;
  bool _isSendingComment = false;
  bool _isUploadingAttachment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
        return Colors.green;
    }
  }

  Future<void> _handleSaveProgress(ProjectTaskDetailModel task) async {
    if (_localProgress == null && _localStatus == null) return;

    final progressToSave = _localProgress ?? task.progress;
    final statusToSave = _localStatus ?? task.status;

    setState(() {
      _isSavingProgress = true;
    });

    try {
      final repository = ref.read(projectRepositoryProvider);
      final success = await repository.updateTaskStatus(
        task.id,
        statusToSave,
        progressToSave,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress & status tugas berhasil diperbarui!'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(taskDetailProvider(widget.taskId));
        ref.invalidate(projectDetailProvider(task.projectId));
        ref.invalidate(projectsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui progress tugas'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProgress = false;
        });
      }
    }
  }

  Future<void> _handleSendComment(int taskId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSendingComment = true;
    });

    try {
      final repository = ref.read(projectRepositoryProvider);
      final success = await repository.addComment(taskId, text);

      if (!mounted) return;

      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dikirim'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(taskDetailProvider(widget.taskId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  Future<void> _handlePickAndUploadAttachment(int taskId) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Lampiran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Galeri / Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih gambar dari galeri perangkat', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null) {
                    _uploadFile(taskId, File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF059669)),
                ),
                title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ambil foto dokumen langsung', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (picked != null) {
                    _uploadFile(taskId, File(picked.path));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadFile(int taskId, File file) async {
    setState(() {
      _isUploadingAttachment = true;
    });

    try {
      final repository = ref.read(projectRepositoryProvider);
      final success = await repository.uploadAttachment(taskId, file);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lampiran berhasil diunggah!'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(taskDetailProvider(widget.taskId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
        });
      }
    }
  }

  Future<void> _handleDeleteAttachment(int attachmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lampiran'),
        content: const Text('Apakah Anda yakin ingin menghapus lampiran ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repository = ref.read(projectRepositoryProvider);
      final success = await repository.deleteAttachment(attachmentId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lampiran berhasil dihapus.'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(taskDetailProvider(widget.taskId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.initialTaskTitle ?? 'Detail Tugas',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: taskAsync.when(
        data: (task) {
          final currentProgress = _localProgress ?? task.progress;
          final currentStatus = _localStatus ?? task.status;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(taskDetailProvider(widget.taskId));
            },
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. INFO CARD
                  _buildTaskInfoCard(task, primaryColor),

                  const SizedBox(height: 16),

                  // 2. PROGRESS & STATUS UPDATE CARD
                  _buildProgressUpdateCard(task, currentProgress, currentStatus, primaryColor),

                  const SizedBox(height: 16),

                  // 3. SUBTASKS CARD
                  if (task.subtasks.isNotEmpty) ...[
                    _buildSubtasksCard(task.subtasks, primaryColor),
                    const SizedBox(height: 16),
                  ],

                  // 4. ATTACHMENTS CARD
                  _buildAttachmentsCard(task, primaryColor),

                  const SizedBox(height: 16),

                  // 5. COMMENTS / DISCUSSION CARD
                  _buildCommentsCard(task, primaryColor),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(taskDetailProvider(widget.taskId)),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoCard(ProjectTaskDetailModel task, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.kodeTask,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.prioritas).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.prioritas.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(task.prioritas),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(task.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(task.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(task.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.judul,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          if (task.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.deskripsi,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Project', task.projectName),
          if (task.parentJudul != null)
            _buildInfoRow('Induk Tugas', task.parentJudul!),
          _buildInfoRow('Mulai', task.startDate.isNotEmpty ? task.startDate : '-'),
          _buildInfoRow('Deadline', task.dueDate.isNotEmpty ? task.dueDate : '-'),
          const SizedBox(height: 8),
          const Text(
            'Anggota Ditugaskan:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          if (task.members.isEmpty)
            const Text('Belum ada anggota ditugaskan', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: task.members.map((m) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    backgroundImage: m.foto.isNotEmpty ? NetworkImage(m.foto) : null,
                    child: m.foto.isEmpty
                        ? Text(
                            m.nama.isNotEmpty ? m.nama[0].toUpperCase() : 'U',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                          )
                        : null,
                  ),
                  label: Text(m.nama, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressUpdateCard(ProjectTaskDetailModel task, int currentProgress, String currentStatus, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'UPDATE PROGRESS & STATUS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (task.isAssigned) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Persentase Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                Text(
                  '$currentProgress%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            Slider(
              value: currentProgress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: primaryColor,
              inactiveColor: const Color(0xFFE2E8F0),
              label: '$currentProgress%',
              onChanged: (val) {
                final newProgress = val.round();
                setState(() {
                  _localProgress = newProgress;
                  if (newProgress == 100) {
                    _localStatus = 'completed';
                  } else if (newProgress < 100 && currentStatus == 'completed') {
                    _localStatus = 'in_progress';
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            const Text('Status Tugas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'todo', child: Text('To Do')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'review', child: Text('Review / Testing')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed (Selesai)')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled (Batal)')),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _localStatus = val;
                      if (val == 'completed') {
                        _localProgress = 100;
                      } else if (val == 'todo') {
                        _localProgress = 0;
                      } else if (val == 'in_progress' && currentProgress == 0) {
                        _localProgress = 10;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSavingProgress ? null : () => _handleSaveProgress(task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSavingProgress
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Progress & Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hanya anggota yang ditugaskan pada tugas ini yang dapat memperbarui progress dan status.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtasksCard(List<ProjectTaskSubtaskModel> subtasks, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'SUB-TASKS (${subtasks.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subtasks.length,
            separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final sub = subtasks[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(taskId: sub.id, initialTaskTitle: sub.judul),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub.kodeTask, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(
                              sub.judul,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(sub.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(sub.status),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getStatusTextColor(sub.status)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sub.progress}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(ProjectTaskDetailModel task, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    'LAMPIRAN (${task.attachments.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                ],
              ),
              if (task.isAssigned)
                InkWell(
                  onTap: _isUploadingAttachment ? null : () => _handlePickAndUploadAttachment(task.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Upload',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_isUploadingAttachment) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          if (task.attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('Belum ada lampiran tugas.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: task.attachments.length,
              separatorBuilder: (context, index) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final att = task.attachments[index];
                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF64748B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.namaFile,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${att.formattedSize} • ${att.uploaderNama}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF2563EB)),
                      tooltip: 'Buka File',
                      onPressed: () async {
                        final uri = Uri.parse(att.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    if (att.isUploader)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        tooltip: 'Hapus',
                        onPressed: () => _handleDeleteAttachment(att.id),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsCard(ProjectTaskDetailModel task, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'DISKUSI (${task.comments.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Form comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar atau update...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                width: 42,
                child: ElevatedButton(
                  onPressed: _isSendingComment ? null : () => _handleSendComment(task.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSendingComment
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (task.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('Belum ada diskusi.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: task.comments.length,
              separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final com = task.comments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      backgroundImage: com.authorFoto.isNotEmpty ? NetworkImage(com.authorFoto) : null,
                      child: com.authorFoto.isEmpty
                          ? Text(
                              com.authorNama.isNotEmpty ? com.authorNama[0].toUpperCase() : 'U',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                com.authorNama,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                com.createdAt,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            com.komentar,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
