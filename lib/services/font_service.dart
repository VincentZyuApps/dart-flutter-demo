import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFontFamily {
  system(
    id: 'system',
    displayName: '系统默认 (System Default)',
    category: '无额外开销',
    description: '操作系统原生字体，零网络加载与内存负担',
  ),
  lxgwWenKai(
    id: 'lxgw',
    displayName: '霞鹜文楷 (LXGW WenKai)',
    category: '国风温润手写',
    description: '温润雅致的手写楷体风格，极具东方美学',
  ),
  notoSansSc(
    id: 'notoSans',
    displayName: '思源黑体 (Noto Sans SC)',
    category: '中文标准无衬线',
    description: '最广泛适配的标准中文黑体，结构严谨清晰',
  ),
  inter(
    id: 'inter',
    displayName: 'Inter',
    category: '现代国际无衬线',
    description: '现代 UI 设计标杆字体，极高屏幕辨识度',
  ),
  roboto(
    id: 'roboto',
    displayName: 'Roboto',
    category: '现代国际无衬线',
    description: 'Google 原生 Material Design 经典骨架',
  ),
  poppins(
    id: 'poppins',
    displayName: 'Poppins',
    category: '现代前卫几何',
    description: '饱满几何圆润线条，富有亲和力与动感',
  ),
  jetBrainsMono(
    id: 'jetBrainsMono',
    displayName: 'JetBrains Mono',
    category: '极客代码等宽',
    description: 'IDE 专属等宽字体，扩大的小写字母与专有连字',
  ),
  firaCode(
    id: 'firaCode',
    displayName: 'Fira Code',
    category: '极客代码等宽',
    description: '编程连字鼻祖，标志性符号连结极客风',
  ),
  notoSerifSc(
    id: 'notoSerif',
    displayName: '思源宋体 (Noto Serif SC)',
    category: '东方传统衬线',
    description: '古雅端庄的长文本排版，沉浸式阅读质感',
  ),
  miSans(
    id: 'miSans',
    displayName: 'MiSans 科技',
    category: '现代扁平科技',
    description: '平直干练的现代科技感屏幕排版',
  );

  const AppFontFamily({
    required this.id,
    required this.displayName,
    required this.category,
    required this.description,
  });

  final String id;
  final String displayName;
  final String category;
  final String description;
}

class FontService {
  FontService._();

  static final FontService instance = FontService._();

  final ValueNotifier<AppFontFamily> currentFontNotifier =
      ValueNotifier<AppFontFamily>(AppFontFamily.lxgwWenKai);

  AppFontFamily get currentFont => currentFontNotifier.value;

  void setFont(AppFontFamily font) {
    if (currentFontNotifier.value == font) return;
    currentFontNotifier.value = font;
  }

  TextTheme applyFont(TextTheme baseTextTheme, AppFontFamily font) {
    switch (font) {
      case AppFontFamily.system:
        return baseTextTheme;

      case AppFontFamily.lxgwWenKai:
        return GoogleFonts.lxgwWenKaiTcTextTheme(baseTextTheme);

      case AppFontFamily.notoSansSc:
        return GoogleFonts.notoSansScTextTheme(baseTextTheme);

      case AppFontFamily.inter:
        return GoogleFonts.interTextTheme(baseTextTheme);

      case AppFontFamily.roboto:
        return GoogleFonts.robotoTextTheme(baseTextTheme);

      case AppFontFamily.poppins:
        return GoogleFonts.poppinsTextTheme(baseTextTheme);

      case AppFontFamily.jetBrainsMono:
        return GoogleFonts.jetBrainsMonoTextTheme(baseTextTheme);

      case AppFontFamily.firaCode:
        return GoogleFonts.firaCodeTextTheme(baseTextTheme);

      case AppFontFamily.notoSerifSc:
        return GoogleFonts.notoSerifScTextTheme(baseTextTheme);

      case AppFontFamily.miSans:
        // 以思源黑体作为科技无衬线基线
        return GoogleFonts.notoSansScTextTheme(baseTextTheme);
    }
  }
}
