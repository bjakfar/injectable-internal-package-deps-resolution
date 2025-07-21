import 'package:analyzer/dart/element/element.dart';
import 'package:injectable/injectable.dart';
import 'package:source_gen/source_gen.dart';

import '../../resolvers/importable_type_resolver.dart';

const TypeChecker _typeChecker = TypeChecker.fromRuntime(Injectable);
const TypeChecker _moduleChecker = TypeChecker.fromRuntime(Module);

bool hasModuleAnnotation(ClassElement clazz) {
  return _moduleChecker.hasAnnotationOfExact(clazz);
}

bool hasInjectable(ClassElement element) {
  return _typeChecker.hasAnnotationOf(element);
}

// checks for matches defined by auto registration options
bool hasConventionalMatch(ClassElement clazz, RegExp? classNameMatcher, RegExp? fileNameMatcher) {
  if (clazz.isAbstract) {
    return false;
  }
  final fileName = clazz.source.shortName.replaceFirst('.dart', '');
  return (classNameMatcher != null && classNameMatcher.hasMatch(clazz.name)) ||
      (fileNameMatcher != null && fileNameMatcher.hasMatch(fileName));
}

ImportableTypeResolver getResolver(List<LibraryElement> libs) {
  return ImportableTypeResolverImpl(libs);
}
