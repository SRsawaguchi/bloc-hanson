# bloc-hanson
DartのライブラリBlocを学習。  
[前回](https://github.com/SRsawaguchi/bloc-cubit-hanson)はこのライブラリのCubitについて学んだが、今回はBlocを見てみる。  


## Blocとは
Blocは特殊なCubitという扱い。  
Cubitでは関数を公開することで状態を変更していたものの、Blocではイベントを受け取り、それに応じて適切な処理を行うという考え方。  
Cubitに比べれば少し複雑になるものの、より状態のトレーサビリティが向上するとのこと。  


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


