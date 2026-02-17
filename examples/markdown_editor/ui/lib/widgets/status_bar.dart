import 'package:flutter/material.dart';

/// A status bar widget displayed at the bottom of the markdown editor.
///
/// Shows real-time statistics including:
/// - Current file name
/// - Save status (Saved/Unsaved)
/// - Character count
/// - Line count
/// - Optional status message
class StatusBar extends StatelessWidget {
  /// Creates a StatusBar widget.
  const StatusBar({
    super.key,
    required this.fileName,
    required this.isDirty,
    required this.characterCount,
    required this.lineCount,
    this.statusMessage,
  });

  /// The name of the currently open file.
  final String fileName;

  /// Whether the current document has unsaved changes.
  final bool isDirty;

  /// The character count of the current content.
  final int characterCount;

  /// The line count of the current content.
  final int lineCount;

  /// Optional status message to display on the right side.
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          _StatusSegment(text: fileName),
          _StatusSegment(text: isDirty ? 'Unsaved' : 'Saved'),
          _StatusSegment(text: '$characterCount chars'),
          _StatusSegment(text: '$lineCount lines'),
          const Spacer(),
          if (statusMessage != null) _StatusSegment(text: statusMessage!),
        ],
      ),
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
      ),
    );
  }
}
