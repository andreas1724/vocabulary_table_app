import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/app_mode_controller.dart';
import 'package:vocabulary_table_app/widgets/table_scope.dart';

class UniversalToolbar extends StatelessWidget {
  const UniversalToolbar({super.key, required this.isVertical});

  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Container(
        width: isVertical ? kToolbarHeight : double.infinity,
        height: isVertical ? double.infinity : kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: isVertical ? .vertical : .horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isVertical ? 0 : constraints.maxWidth,
                  minHeight: isVertical ? constraints.maxHeight : 0,
                ),
                child: Flex(
                  direction: isVertical ? .vertical : .horizontal,
                  mainAxisAlignment: .spaceBetween,
                  crossAxisAlignment: .center,
                  children: [
                    _ToolbarTitle(isVertical: isVertical),
                    Flex(
                      direction: isVertical ? .vertical : .horizontal,
                      mainAxisSize: .min,
                      // The children are completely independent and const!
                      children: [
                        _CommentsToggle(),
                        _ModeSelector(isVertical),
                        _SettingsButton(),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Extracted Private Sub-Widgets for the Toolbar ---

class _ToolbarTitle extends StatelessWidget {
  const _ToolbarTitle({required this.isVertical});

  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      'Vocabulary',
      style: Theme.of(context).textTheme.titleLarge,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
    final tableLayoutController = TableScope.of(context).tableLayoutController;
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

class _ModeSelector extends StatefulWidget {
  const _ModeSelector(this.isVertical);

  final bool isVertical;

  @override
  State<_ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<_ModeSelector> {
  final _focusNodeModeSelector = FocusNode(debugLabel: 'menu button');

  @override
  void dispose() {
    _focusNodeModeSelector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModeController = TableScope.of(context).appModeController;
    final theme = Theme.of(context);
    const iconWidth = 40.0;

    return SignalBuilder(
      builder: (context) {
        final currentMode = appModeController.appMode.value;

        return MenuAnchor(
          alignmentOffset: widget.isVertical
              ? Offset((kToolbarHeight + iconWidth) / 2, -iconWidth)
              : Offset(0, (kToolbarHeight - iconWidth) / 2),
          childFocusNode: _focusNodeModeSelector,
          builder: (context, menuController, child) {
            return IconButton(
              focusNode: _focusNodeModeSelector,
              constraints: const BoxConstraints.tightFor(
                width: iconWidth,
                height: iconWidth,
              ),
              onPressed: () => menuController.isOpen
                  ? menuController.close()
                  : menuController.open(),
              icon: Icon(currentMode.icon),
            );
          },
          menuChildren: AppMode.values.map((mode) {
            final isSelected = currentMode == mode;

            return MenuItemButton(
              onPressed: () => appModeController.appMode.value = mode,
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(
                    mode.icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mode.title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () {
        // TODO: Implement settings routing here
      },
    );
  }
}