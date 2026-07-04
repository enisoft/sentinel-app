/// Zona de responsabilidade do operador (vinda de GET /me).
class OperatorZone {
  const OperatorZone({
    required this.id,
    required this.nome,
    required this.tipo,
  });

  final String id;
  final String nome;
  final String tipo;

  factory OperatorZone.fromJson(Map<String, dynamic> json) {
    return OperatorZone(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: json['tipo'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo,
      };
}
