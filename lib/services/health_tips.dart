import 'dart:math';

class HealthTips {
  static final List<Map<String, String>> tips = [
    {
      'title': 'Omega-3 Yağ Asitleri',
      'body': 'Haftada en az 2 porsiyon balık tüketmek, kalp hastalığı riskini %30 azaltabilir. Somon, sardalya ve uskumru iyi kaynaklardır.',
    },
    {
      'title': 'Günlük Yürüyüş',
      'body': 'Günde 30 dakika tempolu yürüyüş, kalp krizi riskini %35 azaltır. Asansör yerine merdiven kullanarak başlayabilirsiniz.',
    },
    {
      'title': 'Tuz Tüketimi',
      'body': 'Günlük tuz tüketimini 5 gramın altında tutmak, tansiyonu düşürmeye yardımcı olur. Hazır gıdalar gizli tuz kaynağıdır.',
    },
    {
      'title': 'Stres Yönetimi',
      'body': 'Kronik stres, kalp hastalığı riskini artırır. Günde 10 dakika derin nefes egzersizi yapmak tansiyonu düşürebilir.',
    },
    {
      'title': 'Uyku Düzeni',
      'body': 'Günde 7-8 saat kaliteli uyku, kalp sağlığını korur. Düzensiz uyku, kalp ritim bozukluklarına yol açabilir.',
    },
    {
      'title': 'Lif Tüketimi',
      'body': 'Günde 25-30 gram lif tüketmek, kolesterolü düşürür. Yulaf, mercimek ve tam tahıllar iyi kaynaklardır.',
    },
    {
      'title': 'Sigaranın Zararları',
      'body': 'Sigara bırakıldıktan 1 yıl sonra kalp hastalığı riski yarıya düşer. 15 yıl sonra hiç içmemiş gibi olursunuz.',
    },
    {
      'title': 'Kan Basıncı Takibi',
      'body': 'Tansiyon 120/80 mmHg altında olmalıdır. Düzenli ölçüm, erken teşhis için çok önemlidir.',
    },
    {
      'title': 'Potasyum Zengini Gıdalar',
      'body': 'Muz, avokado ve ıspanak gibi potasyum zengini gıdalar tansiyonu dengelemeye yardımcı olur.',
    },
    {
      'title': 'Kahve ve Kalp',
      'body': 'Günde 2-3 fincan filtre kahve, kalp hastalığı riskini azaltabilir. Ancak aşırı tüketimden kaçının.',
    },
    {
      'title': 'Hidrasyon',
      'body': 'Yeterli su içmek, kanın akıcılığını artırır ve kalbin işini kolaylaştırır. Günde en az 8 bardak su için.',
    },
    {
      'title': 'Zeytinyağı',
      'body': 'Akdeniz diyetinin temel taşı olan zeytinyağı, iyi kolesterolü (HDL) artırır ve damar sağlığını korur.',
    },
    {
      'title': 'Düzenli Egzersiz',
      'body': 'Haftada en az 150 dakika orta şiddetli egzersiz, kalp kasını güçlendirir ve kan dolaşımını iyileştirir.',
    },
    {
      'title': 'Kilo Kontrolü',
      'body': 'Bel çevresi erkeklerde 94 cm, kadınlarda 80 cm altında olmalıdır. Fazla kilo kalbe ekstra yük bindirir.',
    },
    {
      'title': 'Hareketsizliğin Zararları',
      'body': 'Uzun süre hareketsiz kalmak kalp hastalığı riskini %147 artırır. Her 1 saatte bir 5 dakika ayağa kalkıp yürüyün.',
    },
    {
      'title': 'Çikolata ve Kalp',
      'body': 'Yüksek kakaolu bitter çikolata (en az %70), antioksidanlar sayesinde damar sağlığını destekler. Günde 1-2 kare yeterli.',
    },
    {
      'title': 'Nabız Kontrolü',
      'body': 'Dinlenme nabzı 60-100 arasında olmalıdır. Düzenli egzersiz yapanların nabzı daha düşük ve kalpleri daha verimli çalışır.',
    },
    {
      'title': 'Ceviz ve Badem',
      'body': 'Günde bir avuç ceviz veya badem, kötü kolesterolü (LDL) düşürmeye yardımcı olur.',
    },
    {
      'title': 'Sarımsak',
      'body': 'Düzenli sarımsak tüketimi, kan basıncını düşürmeye ve damar sertliğini önlemeye yardımcı olabilir.',
    },
    {
      'title': 'Gülmek İlaçtır',
      'body': 'Gülmek, damarları genişletir ve kan akışını artırır. Günde en az 15 dakika gülmek kalp sağlığını destekler.',
    },
  ];

  static Map<String, String> getDailyTip() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return tips[dayOfYear % tips.length];
  }

  static Map<String, String> getRandomTip() {
    return tips[Random().nextInt(tips.length)];
  }
}
