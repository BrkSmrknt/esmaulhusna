class EsmaModel {
  final int index;
  final String arapca;
  final String latin;
  final String turkce;
  final String anlami;
  final int ebced;
  final String fazilet;

  const EsmaModel({
    required this.index,
    required this.arapca,
    required this.latin,
    required this.turkce,
    required this.anlami,
    required this.ebced,
    required this.fazilet,
  });

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'arapca': arapca,
      'latin': latin,
      'turkce': turkce,
      'anlami': anlami,
      'ebced': ebced,
      'fazilet': fazilet,
    };
  }

  factory EsmaModel.fromMap(Map<String, dynamic> map) {
    return EsmaModel(
      index: map['index'] as int,
      arapca: map['arapca'] as String,
      latin: map['latin'] as String,
      turkce: map['turkce'] as String,
      anlami: map['anlami'] as String,
      ebced: map['ebced'] as int,
      fazilet: map['fazilet'] as String,
    );
  }
}
