/// Textos de `title` e `description` ao confirmar rascunho (contrato API).
class OccurrenceConfirmText {
  const OccurrenceConfirmText({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

/// Resolve título e descrição no confirm: nota do operador ou default por tipo de mídia.
OccurrenceConfirmText resolveOccurrenceConfirmText({
  String? note,
  String? mediaType,
}) {
  final trimmed = note?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return OccurrenceConfirmText(title: trimmed, description: trimmed);
  }

  return OccurrenceConfirmText(
    title: 'Ocorrência',
    description: _defaultDescriptionForMediaType(mediaType),
  );
}

String _defaultDescriptionForMediaType(String? mediaType) {
  return switch (mediaType) {
    'image' => 'Registro fotográfico',
    'audio' => 'Registro de áudio',
    'video' => 'Registro de vídeo',
    _ => 'Registro de ocorrência',
  };
}
