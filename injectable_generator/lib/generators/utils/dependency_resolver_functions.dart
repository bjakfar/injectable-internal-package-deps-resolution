import 'package:analyzer/dart/element/element.dart';
import 'package:injectable_generator/generators/utils/type_checker_functions.dart';
import 'package:source_gen/source_gen.dart';

import '../../models/dependency_config.dart';
import '../../resolvers/dependency_resolver.dart';
import '../../utils.dart';

Future<Iterable<DependencyConfig>> generateDependenciesJson({
  required LibraryReader library,
  required List<LibraryElement> libs,
  required bool autoRegister,
  required RegExp? classNameMatcher,
  required RegExp? fileNameMatcher,
}) async {
  final deps = <DependencyConfig>[];

  for (var clazz in library.classes) {
    if (hasModuleAnnotation(clazz)) {
      throwIf(
        !clazz.isAbstract,
        '[${clazz.name}] must be an abstract class!',
        element: clazz,
      );
      final executables = <ExecutableElement>[
        ...clazz.accessors,
        ...clazz.methods,
      ];
      for (var element in executables) {
        if (element.isPrivate) continue;
        deps.add(
          DependencyResolver(
            getResolver(libs),
          ).resolveModuleMember(clazz, element),
        );
      }
    } else if (hasInjectable(clazz) ||
        (autoRegister && hasConventionalMatch(clazz, classNameMatcher, fileNameMatcher))) {
      deps.add(DependencyResolver(
        getResolver(libs),
      ).resolve(clazz));
    }
  }

  return deps;
}
