import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:source_gen/source_gen.dart';

import '../utils.dart';

class InjectablePackageDepsGenerator extends GeneratorForAnnotation<PackageDependenciesLoader> {
  static const _matchesMultiplePeriods = r'.*\..*\.+.*';

  @override
  Future<void> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    throwIf(
      element.library == null,
      'Annotated Element is null',
    );

    final libraryElement = element.library!;
    final bootstrapPackageName = _resolveMicroModuleName(libraryElement);
    final pubspecAssetId = AssetId('$bootstrapPackageName', 'pubspec.yaml');

    throwIf(
      (await buildStep.canRead(pubspecAssetId)) == false,
      'Cannot read asset: $pubspecAssetId',
    );

    final yaml = await buildStep.readAsString(pubspecAssetId);

    final localDependencies = _resolveLocalDependenciesFromPubspecYamlContent(yaml);

    for (final localDependency in localDependencies) {
      final glob = Glob('**.dart');

      final allDartFilePathsInModule = await glob
          .list(
            root: current.replaceFirst('/$bootstrapPackageName', '/$localDependency/lib'),
          )
          .map((fileSystemEntity) => fileSystemEntity.path)
          .where((path) => path.contains(RegExp(_matchesMultiplePeriods)) == false)
          .toList();

      final analysisContextCollection = AnalysisContextCollection(includedPaths: allDartFilePathsInModule);

      AnalysisSession? currentAnalysisSession;
      for (final dartFilePath in allDartFilePathsInModule) {
        currentAnalysisSession ??= analysisContextCollection.contextFor(dartFilePath).currentSession;

        final maybeResolvedLibraryResult = await currentAnalysisSession.getResolvedLibrary(dartFilePath);
        if (maybeResolvedLibraryResult is! ResolvedLibraryResult) {
          throw 'Could not parse unit from path $dartFilePath in analysis session';
        }

        print(maybeResolvedLibraryResult.element.identifier);
        print(
            'imported libs: ${maybeResolvedLibraryResult.element.importedLibraries.map((lib) => lib.identifier).join(', ')}');
        print(
            'classes: ${maybeResolvedLibraryResult.element.definingCompilationUnit.classes.map((cl) => cl.name).join(', ')}');
      }
    }
  }

  String? _resolveMicroModuleName(LibraryElement libraryElement) {
    final uri = libraryElement.source.uri;

    if (uri.scheme != 'package') {
      return null;
    }

    return uri.pathSegments.first;
  }

  Iterable<String> _resolveLocalDependenciesFromPubspecYamlContent(String yaml) {
    final lines = LineSplitter().convert(yaml).toList();

    final copiedLines = lines.toList();
    for (final line in lines) {
      if (line == 'dependencies:') {
        break;
      }
      copiedLines.remove(line);
    }

    // print('copiedLines: $copiedLines');

    int? endOfDependenciesIndex;
    for (final line in copiedLines.skip(1) /*skip 'dependencies:' key*/) {
      // print('line ${copiedLines.indexOf(line)}: $line');
      if (line.startsWith('  ') == false) {
        endOfDependenciesIndex = copiedLines.indexOf(line);
        break;
      }
    }

    endOfDependenciesIndex ??= copiedLines.length;

    // Sublist in range [0, endOfDependenciesIndex) will only contain entries within 'dependencies:' key.
    // If the for-loop above matches a new dictionary key (a line without leading whitespace),
    // the sublist will contain the elements 'dependencies:' and all the following lines
    // until, but not including, the next dictionary key (e.g. 'dev_dependencies:').
    // Otherwise, if no new dictionary key is matched, the sublist operation will be idempotent.
    final dependenciesList = copiedLines.sublist(0, endOfDependenciesIndex);

    // print('dependenciesList: $dependenciesList');
    final localDependencies = dependenciesList.indexed.where((indexed) {
      if (indexed.$1 >= dependenciesList.length - 2) {
        return false;
      }

      return dependenciesList[indexed.$1 + 1].trim().startsWith('path');
    }).map((element) => element.$2.trim().replaceAll(':', ''));

    // print('local dependencies: [${localDependencies.join('][')}]');
    return localDependencies;
  }
}
