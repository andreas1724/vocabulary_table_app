import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/chapter_controller.dart';

class UniversalToolbar extends StatelessWidget {
  const UniversalToolbar({super.key, required this.isVertical});

  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).colorScheme.surfaceContainer;
    final vocabularyController = GetIt.I<VocabularyController>();
    final chapterController = GetIt.I<ChapterController>();

    return ExcludeFocus(
      child: Material(
        color: appBarColor,
        elevation: 0,
        child: Container(
          width: isVertical ? kToolbarHeight : double.infinity,
          height: isVertical ? double.infinity : kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Flex(
            direction: isVertical ? .vertical : .horizontal,
            mainAxisAlignment: .spaceBetween,
            crossAxisAlignment: .center,
            children: [
              Expanded(
                child: SignalBuilder(
                  builder: (context) {
                    final chapterId = vocabularyController
                        .vocabularyItems
                        .value
                        .first
                        .chapterId;
                    final chapterName =
                        chapterController.chapters.value
                            .where((chapter) => chapter.id == chapterId)
                            .firstOrNull
                            ?.name ??
                        '';
                    return _ToolbarTitle(
                      title: vocabularyController.title.value,
                      chapterName: chapterName,
                      isVertical: isVertical,
                    );
                  },
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: isVertical ? .vertical : .horizontal,
                  child: Flex(
                    direction: isVertical ? .vertical : .horizontal,
                    mainAxisSize: .min,
                    children: [
                      const _CommentsToggle(),
                      const _ModeToggler(),
                      _ToolbarMenu(isVertical: isVertical),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Extracted Private Sub-Widgets for the Toolbar ---

class _ToolbarTitle extends StatelessWidget {
  const _ToolbarTitle({
    required this.title,
    required this.chapterName,
    required this.isVertical,
  });

  final String title;
  final String chapterName;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Column(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            chapterName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ),
      ],
    );

    const extraSpace = 8.0;

    return Padding(
      padding: EdgeInsets.only(
        top: isVertical ? extraSpace : 0,
        bottom: isVertical ? extraSpace : 0,
        left: isVertical ? 0 : extraSpace,
        right: isVertical ? 0 : extraSpace,
      ),
      child: isVertical
          ? RotatedBox(quarterTurns: 3, child: titleWidget)
          : titleWidget,
    );
  }
}

class _CommentsToggle extends StatelessWidget {
  const _CommentsToggle();

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final isVisible = tableLayoutController.showComment.value;
        return IconButton(
          icon: Icon(isVisible ? Icons.speaker_notes : Icons.speaker_notes_off),
          tooltip: 'Toggle Comments',
          onPressed: () => tableLayoutController.toggleComment(),
        );
      },
    );
  }
}

class _ModeToggler extends StatelessWidget {
  // ignore: unused_element_parameter
  const _ModeToggler({super.key});

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return SignalBuilder(
      builder: (context) {
        final currentMode = tableLayoutController.appMode.value;
        return IconButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            tableLayoutController.nextMode();
          },
          icon: Icon(currentMode.icon),
        );
      },
    );
  }
}

class _ToolbarMenu extends StatelessWidget {
  const _ToolbarMenu({required this.isVertical});
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    const iconWidth = 40.0;
    return MenuAnchor(
      alignmentOffset: isVertical
          ? const Offset((kToolbarHeight + iconWidth) / 2, -iconWidth)
          : const Offset(0, (kToolbarHeight - iconWidth) / 2),
      builder: (context, controller, child) {
        return IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Menu',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            // TODO: Implement Open Book action
          },
          child: const _MenuRow(title: 'Open Book', icon: Icons.library_books),
        ),
        MenuItemButton(
          onPressed: () {
            // TODO: Implement Import CSV action
          },
          child: const _MenuRow(title: 'Imports CSV', icon: Icons.download),
        ),
        MenuItemButton(
          onPressed: () {
            // TODO: Implement Export CSV action
          },
          child: const _MenuRow(title: 'Export CSV', icon: Icons.upload),
        ),
        MenuItemButton(
          onPressed: () {
            // TODO: Implement Settings routing
          },
          child: const _MenuRow(title: 'Settings', icon: Icons.settings),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [Icon(icon), const SizedBox(width: 12), Text(title)],
    );
  }
}
