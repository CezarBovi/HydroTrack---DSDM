class Lembrete {
  final int? id;
  final String titulo;
  final String horario;       // 'HH:mm'
  final int intervaloHoras;   // 0 = não repete por intervalo, 1, 4, 8, 12, 24
  final String diasSemana;    // ex: '1,2,3,4,5' (seg a sex), '1,2,3,4,5,6,7' = todos
  final int ativo;            // 1 = ativo, 0 = pausado

  Lembrete({
    this.id,
    required this.titulo,
    required this.horario,
    required this.intervaloHoras,
    required this.diasSemana,
    this.ativo = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'horario': horario,
      'intervalo_horas': intervaloHoras,
      'dias_semana': diasSemana,
      'ativo': ativo,
    };
  }

  factory Lembrete.fromMap(Map<String, dynamic> map) {
    return Lembrete(
      id: map['id'],
      titulo: map['titulo'],
      horario: map['horario'],
      intervaloHoras: map['intervalo_horas'],
      diasSemana: map['dias_semana'],
      ativo: map['ativo'],
    );
  }
}