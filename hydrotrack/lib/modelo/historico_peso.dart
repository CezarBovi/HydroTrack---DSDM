class HistoricoPeso {
  final int? id;
  final double peso;
  final double altura;
  final double imc;
  final double metaDiariaMl;
  final String dataRegistro;

  HistoricoPeso({
    this.id,
    required this.peso,
    required this.altura,
    required this.imc,
    required this.metaDiariaMl,
    required this.dataRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peso': peso,
      'altura': altura,
      'imc': imc,
      'meta_diaria_ml': metaDiariaMl,
      'data_registro': dataRegistro,
    };
  }

  factory HistoricoPeso.fromMap(Map<String, dynamic> map) {
    return HistoricoPeso(
      id: map['id'],
      peso: map['peso'],
      altura: map['altura'],
      imc: map['imc'],
      metaDiariaMl: map['meta_diaria_ml'],
      dataRegistro: map['data_registro'],
    );
  }
}
