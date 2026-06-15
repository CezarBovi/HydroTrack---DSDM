class Consumo {
  final int? id;
  final String data;       // formato 'yyyy-MM-dd'
  final String horario;    // formato 'HH:00'
  final int quantidadeMl;

  Consumo({
    this.id,
    required this.data,
    required this.horario,
    required this.quantidadeMl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'horario': horario,
      'quantidade_ml': quantidadeMl,
    };
  }

  factory Consumo.fromMap(Map<String, dynamic> map) {
    return Consumo(
      id: map['id'],
      data: map['data'],
      horario: map['horario'],
      quantidadeMl: map['quantidade_ml'],
    );
  }
}