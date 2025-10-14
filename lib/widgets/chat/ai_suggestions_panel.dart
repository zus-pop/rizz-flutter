import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AISuggestionsPanel extends StatelessWidget {
  final List<String> suggestions;
  final bool isGenerating;
  final VoidCallback onRefresh;
  final Function(String) onSuggestionTap;

  const AISuggestionsPanel({
    super.key,
    required this.suggestions,
    required this.isGenerating,
    required this.onRefresh,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: context.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: context.primary),
                const SizedBox(width: 8),
                Text(
                  'Gợi ý AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                if (isGenerating)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 16,
                    color: context.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: isGenerating ? null : onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Suggestions
          Flexible(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  child: InkWell(
                    onTap: () => onSuggestionTap(suggestion),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: context.primary.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
