import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/paywall_result.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../theme/app_theme.dart';
import '../../providers/authentication_provider.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isPremium;
  final bool isAIEnabled;
  final bool isAIGenerating;
  final VoidCallback onSend;
  final VoidCallback onAISuggest;
  final AuthenticationProvider authProvider;
  final VoidCallback? onRecordStart;
  final VoidCallback? onRecordStop;
  final bool isRecording;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isPremium,
    required this.isAIEnabled,
    required this.isAIGenerating,
    required this.onSend,
    required this.onAISuggest,
    required this.authProvider,
    this.onRecordStart,
    this.onRecordStop,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            // AI Suggestion Button (only for premium users)
            if (isPremium)
              _buildAIButton(context)
            else
              _buildPremiumPromptButton(context),

            // Voice recording button
            _buildVoiceButton(context),

            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: isRecording ? 'Đang ghi âm...' : 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isRecording
                      ? Colors.red.withValues(alpha: 0.1)
                      : context.surface.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                enabled: !isRecording,
              ),
            ),
            const SizedBox(width: 8),
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: isAIEnabled
            ? context.primary.withValues(alpha: 0.1)
            : context.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isAIGenerating ? null : onAISuggest,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: isAIGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: isAIEnabled
                        ? context.primary
                        : context.onSurface.withValues(alpha: 0.5),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPromptButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: context.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showPremiumDialog(context),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(Icons.diamond, size: 18, color: context.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: isRecording
            ? Colors.red.withValues(alpha: 0.2)
            : context.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (isRecording) {
              onRecordStop?.call();
            } else {
              onRecordStart?.call();
            }
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              isRecording ? Icons.stop : Icons.mic,
              size: 20,
              color: isRecording ? Colors.red : context.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final canSend = controller.text.trim().isNotEmpty && !isSending;

    return Material(
      color: canSend ? context.primary : context.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: canSend ? onSend : null,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.send,
                  color: canSend
                      ? Colors.white
                      : context.onSurface.withValues(alpha: 0.5),
                ),
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.diamond, color: context.primary),
            const SizedBox(width: 8),
            const Text('Nâng cấp Plus'),
          ],
        ),
        content: const Text(
          'Truy cập AI gợi ý tin nhắn thông minh để tạo cuộc trò chuyện hấp dẫn hơn!\n\n'
          '• Gợi ý tin nhắn phù hợp với tình huống\n'
          '• Tăng khả năng thành công trong hẹn hò\n'
          '• Trải nghiệm trò chuyện thông minh',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final status = await RevenueCatUI.presentPaywallIfNeeded(
                "premium",
                displayCloseButton: true,
              );
              if (status == PaywallResult.purchased) {
                authProvider.isRizzPlus = true;
              } else if (status == PaywallResult.restored) {
                debugPrint("Restored");
              } else {
                debugPrint("No purchased occur");
              }
              navigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
            ),
            child: const Text('Nâng cấp ngay'),
          ),
        ],
      ),
    );
  }
}
