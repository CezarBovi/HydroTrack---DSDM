class Usuario {
  final int? id;
  final double peso;
  final double altura;
  final double imc;
  final double metaDiariaMl;

  Usuario({
    this.id,
    required this.peso,
    required this.altura,
    required this.imc,
    required this.metaDiariaMl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peso': peso,
      'altura': altura,
      'imc': imc,
      'meta_diaria_ml': metaDiariaMl,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      peso: map['peso'],
      altura: map['altura'],
      imc: map['imc'],
      metaDiariaMl: map['meta_diaria_ml'],
    );
  }
}