# bloc-hanson
DartのライブラリBlocを学習。  
[前回](https://github.com/SRsawaguchi/bloc-cubit-hanson)はこのライブラリのCubitについて学んだが、今回はBlocを見てみる。  


## Blocとは
Blocは特殊なCubitという扱い。  
Cubitでは関数を公開することで状態を変更していたものの、Blocではイベントを受け取り、それに応じて適切な処理を行うという考え方。  
Cubitに比べれば少し複雑になるものの、より状態のトレーサビリティが向上するとのこと。  
