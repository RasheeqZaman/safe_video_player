import 'dart:developer' as developer;

class LoggerUtils {
  static void print(int code, String message, {int maxStackTrace = 1}) {
    final int lineLength = 150;
    final stack = StackTrace.current.toString().split('\n');

    developer.log('┌${List.generate(lineLength, (i) => '─').join()}');
    for (int i = 1; i < (maxStackTrace + 1) && i < stack.length; i++) {
      developer.log('| ${stack[i]}');
    }
    developer.log('├${List.generate(lineLength, (i) => '─').join()}');
    developer.log('| ${DateTime.now().toIso8601String()}');
    developer.log('├${List.generate(lineLength, (i) => '─').join()}');
    developer.log('| 🧙‍🧙‍️🧙‍ C$code: $message');
    developer.log('└${List.generate(lineLength, (i) => '─').join()}');
    developer.log('');
  }
}
