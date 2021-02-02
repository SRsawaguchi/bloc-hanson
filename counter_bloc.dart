import 'package:bloc/bloc.dart';

enum CounterEvent { increment, decrement }

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);

  @override
  Stream<int> mapEventToState(CounterEvent event) async* {
    switch (event) {
      case CounterEvent.increment:
        yield state + 1;
        break;
      case CounterEvent.decrement:
        if (state <= 0) {
          addError(Exception('cannot decrement!'), StackTrace.current);
          break;
        }
        yield state - 1;
        break;
    }
  }

  @override
  void onChange(Change<int> change) {
    print('CouterBloc.onChange(): $change');
    super.onChange(change);
  }

  @override
  void onTransition(Transition<CounterEvent, int> transition) {
    print('CouterBloc.onTransition(): $transition');
    super.onTransition(transition);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('CounterBloc.onError(): $error');
    super.onError(error, stackTrace);
  }
}
