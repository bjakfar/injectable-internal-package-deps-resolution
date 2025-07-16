@packageDependenciesLoader
library;

import 'package:injectable/injectable.dart';
import 'package:a/a.module.dart';
import 'package:b/b.module.dart';

@InjectableInit.microPackage(
  externalPackageModulesAfter: [
    ExternalModule(APackageModule),
    ExternalModule(BPackageModule),
  ],
)

/// MicroPackages are sub packages that can be depended on and used by the root
/// package.
///
/// Packages annotated as micro will generate a MicroPackageModule
/// instead of an init-method and the initiation of those modules is done
/// automatically by the root package's init-method.
void initMicroPackage() {}

/// To Register third party types, add your third party types as property
/// accessors or methods as follows:
@module
abstract class RegisterModule {}
