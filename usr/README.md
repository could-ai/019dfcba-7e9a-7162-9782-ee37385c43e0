# Surebet Tracker

O Surebet Tracker é uma aplicação Flutter gerada para a gestão de bancas e depósitos em várias casas de apostas, permitindo o acompanhamento do lucro total ao longo do tempo.

## Funcionalidades

- **Dashboard:** Visão geral da banca atual, total de depósitos e lucro global.
- **Gráfico de Evolução:** Visualização do histórico do lucro ao longo dos dias.
- **Gestão de Casas de Apostas:** Adicione, edite ou remova diferentes casas de apostas com registo de saldo e depósitos individuais.
- **Armazenamento Local:** Todos os dados são guardados localmente no dispositivo.

## Stack Tecnológico

- Flutter & Dart
- `shared_preferences` para armazenamento local do estado.
- `fl_chart` para os gráficos de evolução da banca.
- `intl` para a formatação de moeda (Euros).

## Como Executar

1. Certifique-se de que possui o [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.
2. Clone o repositório.
3. Obtenha as dependências executando:
   ```bash
   flutter pub get
   ```
4. Execute a aplicação (para Web, iOS, Android ou Desktop):
   ```bash
   flutter run
   ```

---

## Sobre o CouldAI

Esta aplicação foi gerada com o [CouldAI](https://could.ai), um construtor de aplicações IA que transforma prompts em aplicações nativas multiplataforma (iOS, Android, Web e Desktop) prontas para produção. Através de agentes de IA autónomos que desenham a arquitetura, desenvolvem, testam, implementam e iteram, o CouldAI permite criar software completo e robusto.