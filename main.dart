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

void exampleOfStreamUsage() async {
  final bloc = CounterBloc();
  final subscription = bloc.listen((state) {
    print('state changed: $state');
  });
  bloc.add(CounterEvent.increment);
  bloc.add(CounterEvent.increment);
  await Future.delayed(Duration.zero);
  await subscription.cancel();
  await bloc.close();
}

void exampleOfStateChange() {
  CounterBloc()
    ..add(CounterEvent.increment)
    ..add(CounterEvent.decrement)
    ..close();
}

void main() {
  // exampleOfBasicUsage();
  // exampleOfStreamUsage();
  exampleOfStateChange();
}
