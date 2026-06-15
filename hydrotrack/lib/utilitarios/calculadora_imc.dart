class ResultadoCalculo {
  final double imc;
  final String classificacao;
  final double metaDiariaMl;

  ResultadoCalculo({
    required this.imc,
    required this.classificacao,
    required this.metaDiariaMl,
  });
}

ResultadoCalculo calcularImcEMeta(double pesoKg, double alturaCm) {
  double alturaM = alturaCm / 100;
  double imc = pesoKg / (alturaM * alturaM);

  String classificacao;
  if (imc < 18.5) {
    classificacao = 'Abaixo do peso';
  } else if (imc < 25) {
    classificacao = 'Normal';
  } else if (imc < 30) {
    classificacao = 'Sobrepeso';
  } else {
    classificacao = 'Obesidade';
  }

  // Regra simples e amplamente usada: ml por kg de peso corporal,
  // ajustada conforme a classificação do IMC
  double mlPorKg;
  if (imc < 18.5) {
    mlPorKg = 40;
  } else if (imc < 25) {
    mlPorKg = 35;
  } else if (imc < 30) {
    mlPorKg = 32;
  } else {
    mlPorKg = 30;
  }

  double metaDiariaMl = pesoKg * mlPorKg;

  return ResultadoCalculo(
    imc: double.parse(imc.toStringAsFixed(1)),
    classificacao: classificacao,
    metaDiariaMl: metaDiariaMl,
  );
}