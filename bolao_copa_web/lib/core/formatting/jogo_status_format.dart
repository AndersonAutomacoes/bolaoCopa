/// Rótulos em português para valores de status de jogo retornados pela API.
String formatJogoStatus(String status) {
  switch (status.toUpperCase()) {
    case 'SCHEDULED':
      return 'Agendado';
    case 'IN_PROGRESS':
      return 'Em andamento';
    case 'FINISHED':
      return 'Finalizado';
    default:
      return status;
  }
}
