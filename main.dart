import 'dart:developer';

import './counter_bloc.dart';

void exampleOfBasicUsage() async {
  final bloc = CounterBloc();
  print(bloc.state); // 0
  bloc.add(CounterEvent.increment);
  await Future.delayed(Duration.zero);
  print(bloc.state); // 1
  await bloc.close();
}

void main() {
  exampleOfBasicUsage();
}
