import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:flutter/services.dart';

import '../../common/shared_state.dart';

class DesktopTabPage extends StatefulWidget {
  const DesktopTabPage({Key? key}) : super(key: key);

  @override
  State<DesktopTabPage> createState() => _DesktopTabPageState();

  static void onAddSetting(
      {SettingsTabKey initialPage = SettingsTabKey.general}) {
    try {
      DesktopTabController tabController = Get.find<DesktopTabController>();
      tabController.add(TabInfo(
          key: kTabLabelSettingPage,
          label: kTabLabelSettingPage,
          selectedIcon: Icons.build_sharp,
          unselectedIcon: Icons.build_outlined,
          page: DesktopSettingPage(
            key: const ValueKey(kTabLabelSettingPage),
            initialTabkey: initialPage,
          )));
    } catch (e) {
      debugPrintStack(label: '$e');
    }
  }
}

class _DesktopTabPageState extends State<DesktopTabPage> {
  final tabController = DesktopTabController(tabType: DesktopTabType.main);

  _DesktopTabPageState() {
    RemoteCountState.init();
    Get.put<DesktopTabController>(tabController);
    tabController.add(TabInfo(
        key: kTabLabelHomePage,
        label: kTabLabelHomePage,
        selectedIcon: Icons.home_sharp,
        unselectedIcon: Icons.home_outlined,
        closable: false,
        page: DesktopHomePage(
          key: const ValueKey(kTabLabelHomePage),
        )));
    if (bind.isIncomingOnly()) {
      tabController.onSelected = (key) {
        if (key == kTabLabelHomePage) {
          windowManager.setSize(getIncomingOnlyHomeSize());
          setResizable(false);
        } else {
          windowManager.setSize(getIncomingOnlySettingsSize());
          setResizable(true);
        }
      };
    }
  }

  @override
  void initState() {
    super.initState();
    // HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /*
  bool _handleKeyEvent(KeyEvent event) {
    if (!mouseIn && event is KeyDownEvent) {
      print('key down: ${event.logicalKey}');
      shouldBeBlocked(_block, canBeBlocked);
    }
    return false; // allow it to propagate
  }
  */

  @override
  void dispose() {
    // HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    Get.delete<DesktopTabController>();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleBarBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3);
    final titleBarBorder = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0);
    final iconColor = isDark ? Colors.white54 : Colors.black54;

    final tabWidget = Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // Barra de título customizada com drag + botões de janela
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            onDoubleTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
            child: Container(
              height: 32,
              color: titleBarBg,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(child: Container()), // área de drag
                  // Minimizar
                  _TitleBarButton(
                    icon: Icons.remove,
                    color: iconColor,
                    onTap: () => windowManager.minimize(),
                  ),
                  // Maximizar / Restaurar
                  Obx(() => _TitleBarButton(
                    icon: stateGlobal.isMaximized.value
                        ? Icons.fullscreen_exit
                        : Icons.crop_square,
                    color: iconColor,
                    onTap: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  )),
                  // Fechar
                  _TitleBarButton(
                    icon: Icons.close,
                    color: iconColor,
                    hoverColor: Colors.red,
                    onTap: () => windowManager.hide(),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: titleBarBorder),
          Expanded(
            child: Obx(() {
              final state = tabController.state.value;
              if (state.tabs.isEmpty) return const SizedBox.shrink();
              return state.tabs[state.selected].page;
            }),
          ),
        ],
      ),
    );
    return isMacOS || kUseCompatibleUiMode
        ? tabWidget
        : Obx(
            () => DragToResizeArea(
              resizeEdgeSize: stateGlobal.resizeEdgeSize.value,
              enableResizeEdges: windowManagerEnableResizeEdges,
              child: tabWidget,
            ),
          );
  }
}

class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? hoverColor;
  final VoidCallback onTap;
  const _TitleBarButton({required this.icon, required this.color, required this.onTap, this.hoverColor});
  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final bg = _hover ? (widget.hoverColor ?? Colors.grey.withOpacity(0.2)) : Colors.transparent;
    final iconColor = (_hover && widget.hoverColor != null) ? Colors.white : widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 32,
          color: bg,
          child: Icon(widget.icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}
