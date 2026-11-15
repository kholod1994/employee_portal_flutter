enum NavBarStyle {
  neonWave,       // نمط 1: التموج النيون المشع (Fluid wave with neon contour)
  spotlightBeam,  // نمط 2: إضاءة الكشاف العلوية (Overhead neon beam light)
  floatingBubble, // نمط 3: الفقاعة المنحنية العائمة (Elevated bubble FAB with liquid notch)
  minimalGlassy,  // نمط 4: الزجاجي الهادئ (Refined frosted pill)
}

extension NavBarStyleExtension on NavBarStyle {
  String get titleAr {
    switch (this) {
      case NavBarStyle.neonWave:
        return 'التموج المشع (Neon Wave)';
      case NavBarStyle.spotlightBeam:
        return 'إضاءة الكشاف (Spotlight Beam)';
      case NavBarStyle.floatingBubble:
        return 'الفقاعة العائمة (Floating Bubble)';
      case NavBarStyle.minimalGlassy:
        return 'الزجاجي الهادئ (Minimal Glassy)';
    }
  }

  String get descriptionAr {
    switch (this) {
      case NavBarStyle.neonWave:
        return 'تموج انسيابي مع خط كونتور نيون مشع يتحرك بسلاسة مع التبويب النشط';
      case NavBarStyle.spotlightBeam:
        return 'كشاف ضوئي علوي يركز إشعاعاً مضيئاً على التبويب المختار';
      case NavBarStyle.floatingBubble:
        return 'أيقونة بارزة عائمة أعلى الشريط مع انحناء زجاجي متدفق';
      case NavBarStyle.minimalGlassy:
        return 'شريط زجاجي عائم بتصميم خفيف وأنيق مع مؤشر نيون ناعم';
    }
  }
}

