import 'package:fluttron_shared/fluttron_shared.dart';
import 'package:flutter/material.dart';

/// A sidebar widget that displays a file tree of markdown files.
///
/// Shows the current directory name at the top, followed by a list of
/// `.md` files. Clicking a file triggers [onFileSelected].
class Sidebar extends StatelessWidget {
  /// Creates a Sidebar widget.
  const Sidebar({
    required this.directoryPath,
    required this.files,
    required this.currentFilePath,
    required this.onFileSelected,
    super.key,
  });

  /// The path to the currently open directory.
  /// If null, shows an empty state with "No folder open".
  final String? directoryPath;

  /// The list of markdown files in the current directory.
  final List<FileEntry> files;

  /// The path to the currently open file, for highlighting.
  final String? currentFilePath;

  /// Callback when a file is selected.
  final void Function(FileEntry file) onFileSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildFileList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String displayName;
    if (directoryPath == null) {
      displayName = 'No folder open';
    } else {
      // Extract the folder name from the path
      displayName = directoryPath!.split('/').where((s) => s.isNotEmpty).last;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Icon(
            directoryPath == null
                ? Icons.folder_off_outlined
                : Icons.folder_open,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: directoryPath == null ? Colors.grey : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (directoryPath == null) {
      return _buildEmptyState(
        icon: Icons.folder_off_outlined,
        message: 'Open a folder\nto view files',
      );
    }

    if (files.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        message: 'No markdown files\nin this folder',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = file.path == currentFilePath;
        return _FileTreeItem(
          file: file,
          isSelected: isSelected,
          onTap: () => onFileSelected(file),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A single item in the file tree.
class _FileTreeItem extends StatelessWidget {
  const _FileTreeItem({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  final FileEntry file;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.blue.shade50 : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                _getFileIcon(),
                size: 18,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    if (file.isDirectory) {
      return Icons.folder_outlined;
    }
    // Check file extension
    final name = file.name.toLowerCase();
    if (name.endsWith('.md')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}
