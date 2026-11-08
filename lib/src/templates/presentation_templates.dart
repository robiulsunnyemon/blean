import '../utils/string_case.dart';

/// Templates for the Presentation layer (BLoC, Cubit, Events, States, Pages).
class PresentationTemplates {
  static String bloc(
    String projectName,
    StringCase feature,
    StringCase blocName,
  ) {
    final featurePascal = feature.pascalCase;
    final featureSnake = feature.snakeCase;
    final blocPascal = blocName.pascalCase;
    final blocSnake = blocName.snakeCase;

    return '''
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$projectName/features/$featureSnake/domain/entities/${featureSnake}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/usecases/get_${featureSnake}_usecase.dart';

part '${blocSnake}_event.dart';
part '${blocSnake}_state.dart';

class ${blocPascal}Bloc extends Bloc<${blocPascal}Event, ${blocPascal}State> {
  final Get${featurePascal}UseCase get${featurePascal}UseCase;

  ${blocPascal}Bloc({
    required this.get${featurePascal}UseCase,
  }) : super(const ${blocPascal}Initial()) {
    on<Load${blocPascal}Event>(_onLoad$blocPascal);
  }

  Future<void> _onLoad$blocPascal(
    Load${blocPascal}Event event,
    Emitter<${blocPascal}State> emit,
  ) async {
    emit(const ${blocPascal}Loading());
    final result = await get${featurePascal}UseCase(
      Get${featurePascal}Params(id: event.id),
    );
    result.fold(
      (failure) => emit(${blocPascal}Error(failure.message)),
      (data) => emit(${blocPascal}Loaded(data)),
    );
  }
}
''';
  }

  static String blocEvent(StringCase blocName) {
    final pascal = blocName.pascalCase;
    final snake = blocName.snakeCase;
    return '''
part of '${snake}_bloc.dart';

abstract class ${pascal}Event extends Equatable {
  const ${pascal}Event();

  @override
  List<Object?> get props => [];
}

class Load${pascal}Event extends ${pascal}Event {
  final String id;

  const Load${pascal}Event(this.id);

  @override
  List<Object?> get props => [id];
}
''';
  }

  static String blocState(
    StringCase feature,
    StringCase blocName, {
    bool isCubit = false,
  }) {
    final featurePascal = feature.pascalCase;
    final pascal = blocName.pascalCase;
    final snake = blocName.snakeCase;
    final partOfFile = isCubit ? '${snake}_cubit.dart' : '${snake}_bloc.dart';

    return '''
part of '$partOfFile';

abstract class ${pascal}State extends Equatable {
  const ${pascal}State();

  @override
  List<Object?> get props => [];
}

class ${pascal}Initial extends ${pascal}State {
  const ${pascal}Initial();
}

class ${pascal}Loading extends ${pascal}State {
  const ${pascal}Loading();
}

class ${pascal}Loaded extends ${pascal}State {
  final ${featurePascal}Entity data;

  const ${pascal}Loaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ${pascal}Error extends ${pascal}State {
  final String message;

  const ${pascal}Error(this.message);

  @override
  List<Object?> get props => [message];
}
''';
  }

  static String cubit(
    String projectName,
    StringCase feature,
    StringCase cubitName,
  ) {
    final featurePascal = feature.pascalCase;
    final featureSnake = feature.snakeCase;
    final cubitPascal = cubitName.pascalCase;
    final cubitSnake = cubitName.snakeCase;

    return '''
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$projectName/features/$featureSnake/domain/entities/${featureSnake}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/usecases/get_${featureSnake}_usecase.dart';

part '${cubitSnake}_state.dart';

class ${cubitPascal}Cubit extends Cubit<${cubitPascal}State> {
  final Get${featurePascal}UseCase get${featurePascal}UseCase;

  ${cubitPascal}Cubit({
    required this.get${featurePascal}UseCase,
  }) : super(const ${cubitPascal}Initial());

  Future<void> load$cubitPascal(String id) async {
    emit(const ${cubitPascal}Loading());
    final result = await get${featurePascal}UseCase(
      Get${featurePascal}Params(id: id),
    );
    result.fold(
      (failure) => emit(${cubitPascal}Error(failure.message)),
      (data) => emit(${cubitPascal}Loaded(data)),
    );
  }
}
''';
  }

  static String page(
    String projectName,
    StringCase feature, {
    bool useCubit = false,
  }) {
    final pascal = feature.pascalCase;
    final snake = feature.snakeCase;
    final title = feature.titleCase;
    final stateClass = useCubit ? '${pascal}Cubit' : '${pascal}Bloc';
    final stateFolder = useCubit ? 'cubit' : 'bloc';
    final stateFile = useCubit ? '${snake}_cubit.dart' : '${snake}_bloc.dart';

    return '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$projectName/features/$snake/presentation/$stateFolder/$stateFile';
import 'package:$projectName/injection_container.dart';

class ${pascal}Page extends StatelessWidget {
  const ${pascal}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<$stateClass>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('$title'),
        ),
        body: BlocBuilder<$stateClass, ${pascal}State>(
          builder: (context, state) {
            if (state is ${pascal}Loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ${pascal}Loaded) {
              return Center(child: Text('Loaded ID: \${state.data.id}'));
            } else if (state is ${pascal}Error) {
              return Center(child: Text('Error: \${state.message}'));
            }
            return const Center(child: Text('$title Initial State'));
          },
        ),
      ),
    );
  }
}
''';
  }
}
