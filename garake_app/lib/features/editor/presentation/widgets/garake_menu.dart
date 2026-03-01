// カワイイ風メニューリスト。タップ操作でアイテム選択。
/*
Dependency Memo
- Depends on: Flutter widgets, AppTheme colors.
- Requires methods: onUpPressed(), onDownPressed(), onOkPressed() callbacks.
- Provides methods: GarakeMenu.build().
*/
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// ガラケーのディスプレイ内に表示されるメニュー選択UI（カワイイ風）。
class GarakeMenu extends StatelessWidget {
  const GarakeMenu({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onUpPressed,
    required this.onDownPressed,
    required this.onOkPressed,
  });

  final String title;
  final List<String> items;
  final int selectedIndex;
  final VoidCallback onUpPressed;
  final VoidCallback onDownPressed;
  final VoidCallback onOkPressed;

  @override
  Widget build(BuildContext context) {
    // カワイイ風液晶メニュー
    return Container(
      color: const Color(0xFF180810),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // タイトル行（ピンク装飾付き）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF6A3050), width: 1),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  '♡ ',
                  style: TextStyle(fontSize: 11, color: AppTheme.heartRed),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.pinkLight,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // メニューアイテムリスト（タップ可能）
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final bool isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () {
                    // 選択されてないなら移動、選択済みなら決定
                    if (!isSelected) {
                      // index方向にカーソルを移動
                      if (index > selectedIndex) {
                        for (int i = 0; i < index - selectedIndex; i++) {
                          onDownPressed();
                        }
                      } else {
                        for (int i = 0; i < selectedIndex - index; i++) {
                          onUpPressed();
                        }
                      }
                    } else {
                      onOkPressed();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A1830)
                          : Colors.transparent,
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.pink,
                              width: 1,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: <Widget>[
                        // 選択カーソル（ハート）
                        Text(
                          isSelected ? '♥' : '  ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? AppTheme.heartRed
                                : Colors.transparent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // アイテムラベル
                        Expanded(
                          child: Text(
                            items[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? const Color(0xFFFFE4EC)
                                  : const Color(0xFF8A5070),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 操作ヒント行
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF6A3050), width: 1),
              ),
            ),
            child: const Text(
              'タップで選択・決定',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF6A4060),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
