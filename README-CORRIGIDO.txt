JogoDaVelha 3.2 - correção v3

Substitua:
lib\main.dart
lib\admin_main.dart

Correções:
- Compatibilidade com a API atual do file_picker usada pelo projeto: pickFiles retorna List<PlatformFile>.
- Removido withData, inexistente nessa versão.
- Corrigido acesso a files -> single.
- Corrigido DropdownButtonFormField: value -> initialValue.

Depois execute:
flutter clean
flutter pub get
flutter analyze
flutter build apk --release -t lib/main.dart
