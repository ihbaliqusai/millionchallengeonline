import 'package:flutter/material.dart';

import '../../widgets/game_shell.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<_PolicySectionData> _sections = <_PolicySectionData>[
    _PolicySectionData(
      icon: Icons.badge_rounded,
      accent: Color(0xFF38BDF8),
      title: 'البيانات التي نجمعها',
      points: <String>[
        'معلومات الحساب التي تختار مشاركتها عند تسجيل الدخول، مثل الاسم المعروض، الصورة الشخصية، ومعرّف الحساب.',
        'بيانات اللعب مثل المستوى، الخبرة، الإنجازات، الإحصاءات، نتائج المباريات، والغرف التي تنضم إليها أو تنشئها.',
        'بيانات تقنية محدودة لازمة للتشغيل، مثل إعدادات التطبيق، نوع الجهاز، وبعض سجلات الأعطال عند الحاجة لتحسين الاستقرار.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.settings_suggest_rounded,
      accent: Color(0xFF22C55E),
      title: 'كيف نستخدم بياناتك',
      points: <String>[
        'لتسجيل الدخول والتحقق من الهوية وربط حسابك بتقدمك داخل اللعبة.',
        'لحفظ نتائجك وتشغيل المنافسات والغرف ولوحة الصدارة والملف العام للاعب.',
        'لتسليم المكافآت داخل اللعبة، تشغيل الإعلانات الاختيارية، والحد من التلاعب أو إساءة الاستخدام.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.public_rounded,
      accent: Color(0xFFF59E0B),
      title: 'ما الذي قد يظهر للآخرين',
      points: <String>[
        'قد يرى اللاعبون الآخرون اسمك المعروض وصورتك ومستواك ورتبتك وكؤوسك وبعض الإحصاءات العامة المرتبطة بالمنافسة.',
        'لا نعرض بريدك الإلكتروني أو أي بيانات حساسة ضمن المسارات العامة داخل اللعبة.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.ondemand_video_rounded,
      accent: Color(0xFFA78BFA),
      title: 'الإعلانات والعملات داخل اللعبة',
      points: <String>[
        'قد نوفر إعلانات اختيارية ومكافأة داخل اللعبة، مثل مشاهدة إعلان للحصول على عملات أو عناصر افتراضية.',
        'العملات والجواهر والعناصر الرقمية داخل اللعبة مخصصة للاستخدام داخل التطبيق فقط، ولا تمثل رصيدًا ماليًا أو قيمة نقدية قابلة للسحب.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.credit_card_off_rounded,
      accent: Color(0xFFFB7185),
      title: 'لا توجد مدفوعات حقيقية',
      points: <String>[
        'لا يوفّر التطبيق حاليًا أي عمليات شراء بأموال حقيقية، ولا يدعم الدفع عبر بطاقات ائتمان أو ماستر كارد أو أي وسيلة دفع مصرفية داخل التطبيق.',
        'نحن لا نجمع ولا نخزن بيانات بطاقاتك البنكية لأن التطبيق لا يعالج هذا النوع من المدفوعات في وضعه الحالي.',
        'إذا تمت إضافة أي مزايا مالية مستقبلًا، فسيتم تحديث هذه السياسة بوضوح قبل تفعيلها.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.cloud_done_rounded,
      accent: Color(0xFF14B8A6),
      title: 'الخدمات الخارجية',
      points: <String>[
        'نعتمد على خدمات خارجية لتشغيل أجزاء من التجربة، مثل Firebase للمصادقة وحفظ البيانات، وGoogle Sign-In لتسجيل الدخول.',
        'قد نستخدم Google AdMob لتقديم الإعلانات الاختيارية والمكافآت الإعلانية وفق إعدادات جهازك وسياسات Google.',
        'تخضع بعض البيانات التي تعالجها هذه الخدمات لسياسات الخصوصية الخاصة بمزوديها بالإضافة إلى هذه السياسة.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.lock_rounded,
      accent: Color(0xFF60A5FA),
      title: 'الاحتفاظ بالبيانات وحذفها',
      points: <String>[
        'نحتفظ بالبيانات ما دامت ضرورية لتشغيل الحساب، حفظ التقدم، أو الالتزام بالمتطلبات التشغيلية والأمنية.',
        'قد تبقى بعض البيانات المحلية محفوظة على جهازك إلى أن تحذف التطبيق أو تمسح بياناته من إعدادات النظام.',
        'إذا رغبت في طلب حذف بيانات حسابك أو الاستفسار عن الخصوصية، يمكنك التواصل معنا عبر البريد الإلكتروني الموضح في هذه الصفحة.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.workspace_premium_rounded,
      accent: Color(0xFF4ADE80),
      title: 'الحقوق والاعتمادات',
      points: <String>[
        'ملفات الشخصيات الكرتونية المستخدمة في التطبيق مرخّصة بموجب Envato Market Regular License للعنصر: Set of Businessmen Saudi Arab Man Cartoon Character Design للمؤلف ridjam، لصالح kaka ankidu، بتاريخ شراء 22 سبتمبر 2020.',
        'رابط العنصر المرخّص: https://graphicriver.net/item/set-of-businessmen-saudi-arab-man-cartoon-character-design/21822749، ومعرّف العنصر: 21822749.',
        'ملفات الموسيقى والمؤثرات الصوتية المشار إليها في اللعبة من المصدر: https://www.101soundboards.com/.',
        'تظل جميع العلامات التجارية وحقوق المواد المملوكة للغير محفوظة لأصحابها الأصليين وفق شروطهم وتراخيصهم.',
      ],
    ),
    _PolicySectionData(
      icon: Icons.update_rounded,
      accent: Color(0xFF7DD3FC),
      title: 'التحديثات والتواصل',
      points: <String>[
        'قد نقوم بتحديث هذه السياسة من وقت إلى آخر عند إضافة ميزات جديدة أو تعديل طريقة المعالجة أو الامتثال لمتطلبات جديدة.',
        'استمرارك في استخدام تطبيق تحدي المليون بعد نشر أي تحديث يعني قبولك للصيغة الأحدث من هذه السياسة.',
        'لأي أسئلة أو اقتراحات بخصوص سياسة الخصوصية، يمكنك التواصل عبر: IhbaliQusai@gmail.com.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'سياسة الخصوصية',
      subtitle:
          'شرح واضح لكيفية جمع البيانات واستخدامها، مع توضيح الحقوق والاعتمادات الخاصة بالمحتوى المستخدم داخل تحدي المليون.',
      showMascot: false,
      action: _BackButton(onTap: () => Navigator.of(context).pop()),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 1000;
          if (wide) {
            return const Row(
              children: <Widget>[
                SizedBox(
                  width: 340,
                  child: Column(
                    children: <Widget>[
                      _HeroPanel(),
                      SizedBox(height: 14),
                      _QuickFactsPanel(),
                    ],
                  ),
                ),
                SizedBox(width: 14),
                Expanded(child: _SectionsList(sections: _sections)),
              ],
            );
          }

          return ListView(
            children: <Widget>[
              const _HeroPanel(),
              const SizedBox(height: 14),
              const _QuickFactsPanel(),
              const SizedBox(height: 14),
              ..._sections.map(
                (_PolicySectionData section) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PolicySectionCard(section: section),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionsList extends StatelessWidget {
  const _SectionsList({required this.sections});

  final List<_PolicySectionData> sections;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: index == sections.length - 1 ? 0 : 14),
          child: _PolicySectionCard(section: sections[index]),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tint: const Color(0xFF0F766E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E)],
              ),
            ),
            child: const Icon(
              Icons.shield_moon_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'خصوصيتك وحقوق المحتوى جزء أساسي من تجربة اللعب.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'نوضح هنا ما الذي نجمعه، ولماذا نحتاجه، وما الذي يظل خاصًا، مع توضيح أن التطبيق لا يقدم مدفوعات حقيقية حاليًا ويعرض الاعتمادات الخاصة بالمواد المرخّصة.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FactChip(label: 'Firebase'),
              _FactChip(label: 'Google Sign-In'),
              _FactChip(label: 'AdMob'),
              _FactChip(label: 'لا مدفوعات نقدية'),
              _FactChip(label: 'حقوق ومواد مرخّصة'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickFactsPanel extends StatelessWidget {
  const _QuickFactsPanel();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tint: const Color(0xFF1D4ED8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _MetaRow(
            icon: Icons.calendar_month_rounded,
            label: 'آخر تحديث',
            value: '23 أبريل 2026',
          ),
          const SizedBox(height: 12),
          const _MetaRow(
            icon: Icons.games_rounded,
            label: 'التطبيق',
            value: 'تحدي المليون',
          ),
          const SizedBox(height: 12),
          const _MetaRow(
            icon: Icons.credit_card_off_rounded,
            label: 'المدفوعات',
            value: 'لا توجد مشتريات بأموال حقيقية أو بطاقات بنكية داخل التطبيق',
          ),
          const SizedBox(height: 12),
          const _MetaRow(
            icon: Icons.mail_outline_rounded,
            label: 'التواصل',
            value: 'IhbaliQusai@gmail.com',
          ),
          const SizedBox(height: 12),
          Text(
            'للاستفسارات أو طلبات الحذف أو الملاحظات حول الحقوق والاعتمادات، يمكنك التواصل مباشرة عبر البريد الإلكتروني الموضح أعلاه.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({required this.section});

  final _PolicySectionData section;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tint: section.accent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: section.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: section.accent.withValues(alpha: 0.45)),
                ),
                child: Icon(section.icon, color: section.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...section.points.map(
            (String point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: section.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: const Color(0xFF7DD3FC), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }
}

class _PolicySectionData {
  const _PolicySectionData({
    required this.icon,
    required this.accent,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final List<String> points;
}
