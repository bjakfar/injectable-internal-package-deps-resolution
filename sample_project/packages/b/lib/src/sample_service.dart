import 'package:injectable/injectable.dart';

@singleton
class SampleService {}

@singleton
class InterfaceConsumingClass {
  InterfaceConsumingClass(DataServiceInterface dataServiceInterface);
}

abstract interface class DataServiceInterface {}
