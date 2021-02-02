# bloc-hanson
DartのライブラリBlocを学習。  
[前回](https://github.com/SRsawaguchi/bloc-cubit-hanson)はこのライブラリのCubitについて学んだが、今回はBlocを見てみる。  


## Blocとは
Blocは特殊なCubitという扱い。  
Cubitでは関数を公開することで状態を変更していたものの、Blocではイベントを受け取り、それに応じて適切な処理を行うという考え方。  
Cubitに比べれば少し複雑になるものの、より状態のトレーサビリティが向上するとのこと。  

これは後に紹介するが、`onTransition`という仕組みがあるから。  
「どのようなイベントが発生したから、このような状態になった」という、状態の遷移状況が把握できる。  
※一方で、Cubitでは状態変化の内容しかトレースできない。(値が何からなにに変わったのか。)  

### Blocの作成
BlocもCubitと同じように、Blocライブラリが提供しているクラスをExtendsして作る。  

```dart
enum CounterEvent { increment }

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);
}

```

※このコードは実質`mapEventToState()`を実装していないため動かない。

BlocはGenericsで複数のパラメタをとる。
- 1つ目(`CounterEvent`に相当)は、イベントのenum。
- 2つ目(`int`に相当)はCubitと同じで、管理する状態の型。

そして、以下のように`mapEventToState()`をオーバーライドして、それぞれのイベントに対して処理を割り当てる。  

```dart
  @override
  Stream<int> mapEventToState(CounterEvent event) async* {
    switch (event) {
      case CounterEvent.increment:
        yield state + 1;
        break;
      case CounterEvent.decrement:
        yield state - 1;
        break;
    }
  }
```

ここで、`async*`が出てているが、これはDartのAsync Generatorというもの。  
Goのchannelのように、並列処理にて順次、複数の値を返すことができる。  
なお、値を返すときは`yield`というキーワードを使う。(`return`ではない。)  

Async Generatorについては以下を参照。  
https://dart.dev/guides/language/language-tour#generators


Cubitと違い、Blocでは`emit()`を利用しない。`mapEventToState()`をオーバーライドすることで、イベントを次の状態にマッピングするという考え方になる。  
なお、BlocはCubitを継承しているため、`state`ゲッターにアクセス可能。  

では、さっそくこのBlocを利用してみる。  


```dart
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
```

Cubitの時と違い、関数を呼び出すのでは無く、`bloc.add()`メソッドを通じてイベントを発生させている。  


また、Cubitと同様に、以下のようにStreamとしても利用できる。  

```dart
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

void main() {
  exampleOfStreamUsage();
}
```

このプログラムを実行すると、以下が表示される。  

```
state changed: 1
state changed: 2
```

### onChange
また、Cubitと同様、Blocのなかで`onChange()`をオーバーライドすることで、状態の変更を受け取り、必要な処理を行う事ができる。  

```dart
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
        yield state - 1;
        break;
    }
  }

  @override
  void onChange(Change<int> change) {
    print('CouterBloc.onChange(): $change');
    super.onChange(change);
  }
}
```

以下のように`main()`を変更します。  

```dart
void main() {
  CounterBloc()
    ..add(CounterEvent.increment)
    ..add(CounterEvent.decrement)
    ..close();
}
```

すると、以下が表示されます。  

```
CouterBloc.onChange(): Change { currentState: 0, nextState: 1 }
CouterBloc.onChange(): Change { currentState: 1, nextState: 0 }
```

### onTransition
Cubitとちがい、BlocはEventドリブン。  
そのため、「どんなイベントを受け取って、どんな状態に遷移するのか」を把握したい場合がある。  
その場合は、`onTransition`をオーバーライドすればよい。  

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
   // 省略

  @override
  void onTransition(Transition<CounterEvent, int> transition) {
    print('CouterBloc.onTransition(): $transition');
    super.onTransition(transition);
  }
}
```

この状態で先ほどの`onChange`と同様の`main()`を実行すると、以下が出力される。  

```
CouterBloc.onTransition(): Transition { currentState: 0, event: CounterEvent.increment, nextState: 1 }
CouterBloc.onChange(): Change { currentState: 0, nextState: 1 }
CouterBloc.onTransition(): Transition { currentState: 1, event: CounterEvent.decrement, nextState: 0 }
CouterBloc.onChange(): Change { currentState: 1, nextState: 0 }
```

このように、発生したイベントの種類が取得できる。  
なお、`onTransition`は`onChange`よりも前に呼ばれる。  

※なお、`onEvent`という、イベントが`add()`された直後に呼び出されるメソッドもオーバーライドできる。  

### 全てのBlocのObserve
Cubitと同様に、大きいアプリでは複数のBlocが存在することが普通。  
全てのBlocの`onChange`や`onTransition`をobserveするには、Cubitと同じように`BlocObserver`を継承したクラスを作成する。  


```dart
import 'package:bloc/bloc.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(Cubit cubit, Change change) {
    print('Bloc.onChange(): $change');
    super.onChange(cubit, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print('Bloc.onTransition(): $transition');
    super.onTransition(bloc, transition);
  }
}
```

そして、`main()`では以下のように利用する。  

```dart
void main() {
  Bloc.observer = SimpleBlocObserver();
  CounterBloc()
    ..add(CounterEvent.increment)
    ..add(CounterEvent.decrement)
    ..close();
}
```

すると以下のように表示される。  

```
CouterBloc.onTransition(): Transition { currentState: 0, event: CounterEvent.increment, nextState: 1 }
Bloc.onTransition(): Transition { currentState: 0, event: CounterEvent.increment, nextState: 1 }
CouterBloc.onChange(): Change { currentState: 0, nextState: 1 }
Bloc.onChange(): Change { currentState: 0, nextState: 1 }
CouterBloc.onTransition(): Transition { currentState: 1, event: CounterEvent.decrement, nextState: 0 }
Bloc.onTransition(): Transition { currentState: 1, event: CounterEvent.decrement, nextState: 0 }
CouterBloc.onChange(): Change { currentState: 1, nextState: 0 }
Bloc.onChange(): Change { currentState: 1, nextState: 0 }
```

呼び出される順番に注意する。  

1. CounterBloc.onTransition
1. Bloc.onTransition
1. CounterBloc.onChange
1. Bloc.onChange

まずはBlocクラスに定義した同種のメソッドから実行されていく。  

### エラーハンドリング

Cubitと同じように、`addError()`でエラーを追加できる。  
そして、それを`onError()`でobserveできる。  

```dart
// 省略
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0);

  @override
  Stream<int> mapEventToState(CounterEvent event) async* {
    switch (event) {
    // 省略
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
  void onError(Object error, StackTrace stackTrace) {
    print('CounterBloc.onError(): $error');
    super.onError(error, stackTrace);
  }
}
```

なお、Cubitと同様に、以下のようにBlocObserverでもobserveできる。  

```dart
class SimpleBlocObserver extends BlocObserver {
    // 省略

  @override
  void onError(Cubit cubit, Object error, StackTrace stackTrace) {
    print('Bloc.onError(): ($cubit) $error');
    super.onError(cubit, error, stackTrace);
  }
}
```

`main()`を以下のようにする。  


```dart
void main() {
  Bloc.observer = SimpleBlocObserver();
  CounterBloc()
    ..add(CounterEvent.decrement)
    ..close();
}
```

実行すると、以下が得られる。  

```
CounterBloc.onError(): Exception: cannot decrement!
Bloc.onError(): (Instance of 'CounterBloc') Exception: cannot decrement!
```

こちらも、これまでの`onChange`などと同様、Blocクラスの`onError`が先に呼ばれるので注意。  
