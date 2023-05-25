import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyAuthPage(),
    );
  }
}

class MyAuthPage extends StatefulWidget {
  @override
  _MyAuthPageState createState() => _MyAuthPageState();
}

class _MyAuthPageState extends State<MyAuthPage> {
  // メッセージ表示用
  String infoText = "";
  // 入力されたメールアドレス・パスワード
  String email = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'パスワード'),
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('ユーザー登録'),
                  onPressed: () async {
                    try {
                      //メール/パスワードでユーザー登録

                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      // ユーザー登録に成功した場合
                      //チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (contex) {
                          return TodoAddPage(result.user!);
                        }),
                      );
                    } catch (e) {
                      //ユーザー登録に失敗した場合
                      setState(() {
                        infoText = "登録に失敗しました${e.toString()}";
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: () async {
                      try {
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final result = await auth.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        //ログインに成功した場合
                        //チャット画面に遷移＋ログイン画面を破棄
                        // !は「non-nullable(＝nullではない)な型にキャスト
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                            return TodoAddPage(result.user!);
                          }),
                        );
                      } catch (e) {
                        setState(() {
                          infoText = "ログインに失敗しました。${e.toString()}";
                        });
                      }
                    },
                    child: Text('ログイン')),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// チャット一覧画面用Widget
// リスト追加画面用
class TodoAddPage extends StatelessWidget {
  // 入力されたテキストをデータとして持つ
  String _text = '';
  //作成したドキュメントの一覧
  List<DocumentSnapshot> documentList = [];
  // 指定したドキュメントの情報
  String orderDocumentInfo = '';

  //引数からユーザー情報を受けとれる様にする.
  TodoAddPage(this.user);
  //ユーザー情報
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("チャット"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // 戻れなくする。
              // ログアウト処理
              // 内部で保持しているログイン情報等が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut();
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                return MyAuthPage();
              }));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Text('ログイン情報:${user.email}'),
          ),
          Expanded(
            //FutureBuilder
            //非同期処理の結果をもとにWidgetを作れる.
            //FutureBuilder
            //StraamBuilder・・・非同期処理の結果を元にWidgetを作れる
            child: StreamBuilder<QuerySnapshot>(
                //投稿メッセージ一覧を取得(非同期処理)
                ////投稿日時でソート
                //futureプロパティは型がFutureのメソッドまたは変数を指定
                //builderプロパティの第二引数はstreamプロパティ(今回はFirebaseFirestore〜、メソッドでも可)で取得したきた値をセット。
                // snapshotはfutureプロパティで指定したメソッドの状況を格納
                // 処理状況の変化に応じて自動的にbuilderプロパティに合致する部分が再ビルドされます。
                //StreamBuilderの場合はプロパティはstreamとする。
                // 投稿メッセージ一覧を取得（非同期処理）
                // 投稿日時でソート
                stream: FirebaseFirestore.instance
                    .collection('post')
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  //データが取得できた場合
                  if (snapshot.hasData) {
                    final List<DocumentSnapshot> documents =
                        snapshot.data!.docs;
                    //取得した投稿メッセージ一覧をもとにリストに表示
                    return ListView(
                      children: documents.map((document) {
                        return Card(
                          child: ListTile(
                            title: Text(document['text']),
                            subtitle: Text(document['email']),
                            // 自分の投稿メッセージの場合は削除ボタンを表示(emailが同じの場合)
                            trailing: document['email'] == user.email
                                ? IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('post')
                                          .doc(document.id)
                                          .delete();
                                    },
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  }
                  //データが読み込み中の場合
                  return Center(
                    child: Text('読み込み中。。。'),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                // チャット投稿画面に遷移
                return AddPostPage(user);
              }),
            );
          }),
    );
  }
}

//投稿用画面Widget
class AddPostPage extends StatefulWidget {
  //引数からユーザー情報を受け取る
  const AddPostPage(this.user);
  //ユーザー情報
  final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("チャット投稿"),
      ),
      body: Center(
        child: Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: '投稿メッセージ'),
                  //複数行のテキスト入力
                  keyboardType: TextInputType.multiline,
                  //最大3行
                  maxLines: 3,
                  onChanged: (String value) {
                    setState(() {
                      messageText = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text('投稿'),
                    onPressed: () async {
                      //現在の時刻
                      final date = DateTime.now().toLocal().toIso8601String();
                      //AddPostPageのデータを参照
                      final email = widget.user.email;
                      //投稿メッセージ用ドキュメント作成
                      await FirebaseFirestore.instance
                          .collection('post')
                          .doc()
                          .set({
                        'text': messageText,
                        'email': email,
                        'date': date
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            )),
      ),
    );
  }
}
