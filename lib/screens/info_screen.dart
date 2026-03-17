import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilgilendirme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── TANSIYON ──
          _SectionHeader(
            icon: Icons.monitor_heart,
            title: 'Tansiyon Hakkında Bilinmesi Gerekenler',
            color: AppTheme.primaryRed,
          ),
          const SizedBox(height: 8),
          _MythFactCard(
            myth: 'Başım veya ensem ağrımıyor, tansiyonum normal demektir.',
            fact: 'Yüksek tansiyon çoğu zaman hiçbir belirti vermez. '
                '"Sessiz katil" olarak adlandırılır çünkü ağrı hissetmeden '
                'kalp, böbrek ve beyin hasarı verebilir. Düzenli ölçüm tek '
                'güvenilir yöntemdir.',
          ),
          _MythFactCard(
            myth: 'Tansiyonum bir kez normal çıktıysa artık ölçtürmeme gerek yok.',
            fact: 'Tansiyon gün içinde ve mevsimsel olarak değişir. Stres, '
                'tuz tüketimi, uyku bozukluğu gibi faktörler tansiyonu '
                'yükseltebilir. Yılda en az 2 kez, risk grubundaysanız '
                'daha sık ölçtürmeniz gerekir.',
          ),
          _MythFactCard(
            myth: 'İlaç kullanmaya başladım, artık ölçmeye gerek yok.',
            fact: 'İlaç kullanırken de düzenli ölçüm şarttır. İlacın '
                'etkili olup olmadığını, dozun yeterli olup olmadığını '
                'ancak düzenli takiple anlayabilirsiniz.',
          ),
          _MythFactCard(
            myth: 'Genç yaşta tansiyon yükselmez.',
            fact: 'Hareketsizlik, obezite ve tuzlu beslenme nedeniyle '
                'gençlerde de hipertansiyon görülebilir. 18 yaşından '
                'itibaren düzenli kontrol önerilir.',
          ),
          _InfoTipCard(
            icon: Icons.info_outline,
            text: 'Tansiyon ölçümü öncesi 5 dakika dinlenin. Ölçümden '
                '30 dakika önce kahve, sigara ve egzersizden kaçının. '
                'Her iki koldan ölçüm yapın; fark 10 mmHg\'dan fazlaysa '
                'doktorunuza bildirin.',
          ),
          const SizedBox(height: 24),

          // ── HAREKETLİ YAŞAM ──
          _SectionHeader(
            icon: Icons.directions_run,
            title: 'Hareketli Olmanın Önemi',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              const Text(
                'Düzenli fiziksel aktivite kalp hastalığı riskini %35-50 oranında azaltır. '
                'Egzersiz tansiyonu düşürür, kolesterolü dengeler, kilo kontrolü '
                'sağlar ve stresi azaltır.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Haftalık Hareket Hedefleri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              _ActivityRow(
                icon: Icons.directions_walk,
                title: 'Tempolu Yürüyüş',
                desc: 'Haftada en az 150 dakika (günde 30 dk x 5 gün)',
                color: Colors.green,
              ),
              _ActivityRow(
                icon: Icons.pool,
                title: 'Yüzme',
                desc: 'Haftada 2-3 seans, 30-45 dakika',
                color: Colors.blue,
              ),
              _ActivityRow(
                icon: Icons.pedal_bike,
                title: 'Bisiklet',
                desc: 'Haftada 3-5 gün, 30 dakika',
                color: Colors.orange,
              ),
              _ActivityRow(
                icon: Icons.self_improvement,
                title: 'Yoga / Pilates',
                desc: 'Haftada 2-3 seans, esneklik ve stres yönetimi',
                color: Colors.purple,
              ),
              _ActivityRow(
                icon: Icons.stairs,
                title: 'Merdiven Çıkma',
                desc: 'Asansör yerine merdiven, günlük alışkanlık',
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              const Text(
                'Günlük Hareket İpuçları',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              _BulletPoint('Her 1 saatte bir 5 dakika ayağa kalkıp yürüyün'),
              _BulletPoint('Telefon görüşmelerini ayakta veya yürüyerek yapın'),
              _BulletPoint('Otobüsten 1-2 durak erken inin ve yürüyün'),
              _BulletPoint('Öğle arasında 10-15 dakikalık kısa yürüyüş yapın'),
              _BulletPoint('Alışveriş merkezinde arabanızı uzağa park edin'),
              _BulletPoint('TV izlerken reklam aralarında basit egzersizler yapın'),
              _BulletPoint('Hafta sonları aile veya arkadaşlarla doğa yürüyüşü planlayın'),
            ],
          ),
          _WarningCard(
            text: 'Egzersize yeni başlıyorsanız veya kronik bir hastalığınız varsa, '
                'programa başlamadan önce mutlaka doktorunuza danışın. '
                'Yavaş başlayıp kademeli olarak artırın.',
          ),
          const SizedBox(height: 24),

          // ── VÜCUT ÖLÇÜLERİ ──
          _SectionHeader(
            icon: Icons.straighten,
            title: 'Vücut Ölçülerinizi Bilin',
            color: Colors.teal,
          ),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              const Text(
                'Vücut ölçülerinizi bilmek, kalp hastalığı riskinizi anlamanın '
                'ilk adımıdır. Aşağıdaki değerleri düzenli takip edin:',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              _MeasureRow(
                title: 'Vücut Kitle İndeksi (VKİ)',
                normal: '18.5 - 24.9 kg/m²',
                risk: '≥ 25 fazla kilolu, ≥ 30 obez',
                icon: Icons.monitor_weight,
              ),
              const Divider(),
              _MeasureRow(
                title: 'Bel Çevresi',
                normal: 'Erkek < 94 cm, Kadın < 80 cm',
                risk: 'Erkek ≥ 102 cm, Kadın ≥ 88 cm yüksek risk',
                icon: Icons.loop,
              ),
              const Divider(),
              _MeasureRow(
                title: 'Tansiyon',
                normal: '< 120/80 mmHg',
                risk: '≥ 140/90 mmHg hipertansiyon',
                icon: Icons.monitor_heart,
              ),
              const Divider(),
              _MeasureRow(
                title: 'Açlık Kan Şekeri',
                normal: '70 - 100 mg/dL',
                risk: '≥ 126 mg/dL diyabet',
                icon: Icons.water_drop,
              ),
              const Divider(),
              _MeasureRow(
                title: 'Toplam Kolesterol',
                normal: '< 200 mg/dL',
                risk: '≥ 240 mg/dL yüksek',
                icon: Icons.bloodtype,
              ),
              const Divider(),
              _MeasureRow(
                title: 'Dinlenme Nabzı',
                normal: '60 - 100 bpm',
                risk: '> 100 taşikardi, < 60 bradikardi',
                icon: Icons.favorite,
              ),
            ],
          ),
          _InfoTipCard(
            icon: Icons.calendar_month,
            text: 'Bu değerleri yılda en az bir kez kontrol ettirin. '
                '40 yaş üstü veya risk grubundaysanız 6 ayda bir '
                'kapsamlı check-up yaptırmanız önerilir.',
          ),
          const SizedBox(height: 24),

          // ── TÜTÜN BIRAKMA ──
          _SectionHeader(
            icon: Icons.smoke_free,
            title: 'Tütün Bırakmanın Önemi',
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              const Text(
                'Sigara, kalp damar hastalıklarının en önlenebilir risk faktörüdür. '
                'Tütün kullanımı damar sertliğini hızlandırır, kan pıhtılaşmasını '
                'artırır ve kalp krizi riskini 2-4 kat yükseltir.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bıraktıktan Sonra Vücudunuzda Neler Olur?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              _TimelineItem('20 dakika', 'Nabız ve tansiyon normale döner', Icons.timer),
              _TimelineItem('12 saat', 'Kandaki karbonmonoksit seviyesi normale düşer', Icons.air),
              _TimelineItem('2-12 hafta', 'Kan dolaşımı düzelir, akciğer fonksiyonları artar', Icons.favorite),
              _TimelineItem('1-9 ay', 'Öksürük ve nefes darlığı azalır', Icons.masks),
              _TimelineItem('1 yıl', 'Koroner kalp hastalığı riski yarıya düşer', Icons.monitor_heart),
              _TimelineItem('5 yıl', 'İnme riski sigara içmeyenlerle eşitlenir', Icons.psychology),
              _TimelineItem('10 yıl', 'Akciğer kanseri riski yarıya düşer', Icons.local_hospital),
              _TimelineItem('15 yıl', 'Kalp hastalığı riski hiç içmemiş gibi olur', Icons.celebration),
            ],
          ),
          const SizedBox(height: 8),

          // Pasif İçicilik
          _InfoCard(
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Pasif İçiciliğin Tehlikesi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pasif içicilik de kalp hastalığı riskini %25-30 artırır. '
                'Çocuklar, hamileler ve kalp hastaları özellikle risk altındadır. '
                'Kapalı alanlarda ve araç içinde sigara içilmesine izin vermeyin.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // E-sigara
          _InfoCard(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'E-Sigara Güvenli Değildir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Elektronik sigara da nikotin içerir ve damar sağlığını olumsuz etkiler. '
                'Sigara bırakma aracı olarak önerilmemektedir. '
                'Kanıta dayalı bırakma yöntemlerini tercih edin.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Yardım Hatları
          Card(
            color: Colors.green.shade700,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sigara Bırakma Yardım Hatları',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ücretsiz destek alabilirsiniz',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _PhoneRow(
                    name: 'ALO 171 - Sigara Bırakma Hattı',
                    number: '171',
                    desc: 'Sağlık Bakanlığı ücretsiz danışma hattı, 7/24 hizmet',
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _PhoneRow(
                    name: 'ALO 182 - Sağlık Bakanlığı',
                    number: '182',
                    desc: 'SABİM - Sağlık bilgi ve şikayet hattı',
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _PhoneRow(
                    name: 'ALO 112 - Acil Sağlık',
                    number: '112',
                    desc: 'Acil durumlarda (göğüs ağrısı, nefes darlığı)',
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sigara Bırakma Poliklinikleri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tüm devlet hastanelerinde ücretsiz sigara bırakma '
                          'poliklinikleri bulunmaktadır. Bırakma ilacı ve nikotin '
                          'bandı/sakızı reçete ile ücretsiz verilmektedir. '
                          'Randevu için ALO 182\'yi arayabilirsiniz.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Disclaimer
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_information, color: AppTheme.textLight, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bu sayfadaki bilgiler genel sağlık eğitimi amaçlıdır ve '
                      'tıbbi teşhis veya tedavi yerine geçmez. Sağlık sorunlarınız '
                      'için mutlaka bir sağlık kuruluşuna başvurun.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── WIDGETS ──

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class _MythFactCard extends StatelessWidget {
  final String myth;
  final String fact;
  const _MythFactCard({required this.myth, required this.fact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    myth,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fact,
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _InfoTipCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTipCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;
  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.07),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _ActivityRow({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(desc, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.3))),
        ],
      ),
    );
  }
}

class _MeasureRow extends StatelessWidget {
  final String title;
  final String normal;
  final String risk;
  final IconData icon;
  const _MeasureRow({required this.title, required this.normal, required this.risk, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Normal: $normal', style: const TextStyle(fontSize: 12.5, color: Colors.green))),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Risk: $risk', style: TextStyle(fontSize: 12.5, color: Colors.orange.shade700))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String desc;
  final IconData icon;
  const _TimelineItem(this.time, this.desc, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700)),
                Text(desc, style: const TextStyle(fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String name;
  final String number;
  final String desc;
  final BuildContext context;
  const _PhoneRow({required this.name, required this.number, required this.desc, required this.context});

  @override
  Widget build(BuildContext innerContext) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: number));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$number numarası kopyalandı'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.content_copy, color: Colors.white.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}
