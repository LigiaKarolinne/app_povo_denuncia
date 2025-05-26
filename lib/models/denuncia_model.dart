class Denuncia {
  final int? id;
  final String titulo;
  final String descricao;
  final String tipo;
  final String endereco;
  final String imagemPath;
  final double latitude;
  final double longitude;
  final DateTime dataHora;

  Denuncia({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.endereco,
    required this.imagemPath,
    required this.latitude,
    required this.longitude,
    required this.dataHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo,
      'endereco': endereco,
      'imagemPath': imagemPath,
      'latitude': latitude,
      'longitude': longitude,
      'dataHora': dataHora.toIso8601String(),
    };
  }

  factory Denuncia.fromMap(Map<String, dynamic> map) {
    return Denuncia(
      id: map['id'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      imagemPath: map['imagemPath'],
      endereco: map['endereco'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      dataHora: DateTime.parse(map['dataHora']),
      tipo: '',
      
    );
  }
}
// TODO Implement this library.
