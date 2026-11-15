enum NavBarStyle {
  v10FloatingDome, // نمط 1: كبسولة V10 المقوسة العائمة (المنيو الأخيرة في الفيديو)
  neonWave,        // نمط 2: التموج النيون المشع (خلفية صلبة بدون زجاج)
  spotlightBeam,   // نمط 3: إضاءة الكشاف المركزة (خلفية صلبة)
  solidCapsule,    // نمط 4: الكبسولة العصرية الهادئة (تصميم صلب ناعم)
}

extension NavBarStyleExtension on NavBarStyle {
  String get titleAr {
    switch (this) {
      case NavBarStyle.v10FloatingDome:
        return 'شريط V10 المقوس (V10 Floating Dome)';
      case NavBarStyle.neonWave:
        return 'التموج المشع (Neon Wave)';
      case NavBarStyle.spotlightBeam:
        return 'إضاءة الكشاف (Spotlight Beam)';
      case NavBarStyle.solidCapsule:
        return 'الكبسولة العصرية (Modern Solid Pill)';
    }
  }

  String get descriptionAr {
    switch (this) {
      case NavBarStyle.v10FloatingDome:
        return 'تصميم V10 المعتمد في الفيديو: كبسولة عائمة صلبة وفخمة مع فقاعة دائرية مشعة ومقوسة للتبويب النشط بدون زجاج';
      case NavBarStyle.neonWave:
        return 'تموج انسيابي مع خط كونتور مشع يتحرك بسلاسة بخلفية صلبة فائقة الوضوح';
      case NavBarStyle.spotlightBeam:
        return 'كشاف ضوئي علوي يركز إشعاعاً مضيئاً على التبويب المختار بخلفية داكنة صلبة';
      case NavBarStyle.solidCapsule:
        return 'شريط صلب أنيق عائم مع كبسولة ناعمة ومريحة للعين بدون تأثيرات زجاجية';
    }
  }
}
