---
title: "Protocol Buffer の import におけるファイルの取扱いについて"
date: 2021-01-20T00:25:28+09:00
tags: ["protobuf"]
---

# Protocol Buffer の import について

import 周りで躓いたので、検証結果をまとめておく。

```
$ protoc --version
libprotoc 3.6.0
$ protoc-gen-go --version
protoc-gen-go v1.25.0
$ protoc-gen-go-grpc --version
protoc-gen-go-grpc 1.1.0
```

## import 時の同一ファイル判定について

サンプルのディレクトリ構成は以下とする。

```
~/
└── src/
    └── github.com
        └── sat8bit
            └── protobuf
                ├── models
                │   └── user.proto
                └── service.proto
```

この後の `protoc` コマンドは全て `src/github.com/sat8bit/protobuf` ディレクトリ配下で実行する。

`service.proto` の内容は次の通り。

```proto3
syntax = "proto3";

package io.github.sat8bit;

import "models/user.proto";

option go_package = "github.com/sat8bit/protobuf";

service UserService {
    rpc GetUser(GetUserMessage) returns (GetUserResponse) {}
}

message GetUserMessage {
    string id = 1;
}

message GetUserResponse {
    models.User user = 1;
}
```

`user.proto` の内容は次の通り。

```proto3
syntax = "proto3";

package io.github.sat8bit.models;

option go_package = "github.com/sat8bit/protobuf/models";

message User {
    string id = 1;
    string name = 2;
}
```

この状態で go-grpc_out で grpc を吐き出すと、以下の構造になる。

```
$ protoc --go_out ./go --go-grpc_out ./go service.proto
$ tree go
go
└── github.com
    └── sat8bit
        └── protobuf
            ├── service.pb.go
            └── service_grpc.pb.go
```

ただ、実際は `grpc-gateway` などの `grpc-ecosystem` や、`validator` などを src 配下に展開していたので、それを再現するために `-I` を追加する。

```
$ protoc -I . -I ~/src --go_out ./go --go-grpc_out ./go service.proto
```

この状態では、models/user.proto を import するパスは２種類ある。

```proto3
// . から見た相対パス
import "models/user.proto";
// ~/src から見た相対パス
import "github.com/sat8bit/protobuf/models/user.proto";
```

試しに import を２種類書いてみる。（実際はこんなことしないが）

```proto3
syntax = "proto3";

package io.github.sat8bit;

import "models/user.proto";
import "github.com/sat8bit/protobuf/models/user.proto";

option go_package = "github.com/sat8bit/protobuf";

service UserService {
    rpc GetUser(GetUserMessage) returns (GetUserResponse) {}
}

message GetUserMessage {
    string id = 1;
}

message GetUserResponse {
    models.User user = 1;
}
```

すると、以下のエラーになる。

```
github.com/sat8bit/protobuf/models/user.proto:8:12: "io.github.sat8bit.models.User.id" is already defined in file "models/user.proto".
github.com/sat8bit/protobuf/models/user.proto:9:12: "io.github.sat8bit.models.User.name" is already defined in file "models/user.proto".
github.com/sat8bit/protobuf/models/user.proto:7:9: "io.github.sat8bit.models.User" is already defined in file "models/user.proto".
service.proto: Import "github.com/sat8bit/protobuf/models/user.proto" was not found or had errors.
```

既に定義済みエラーである。一方、`import "models/user.proto";` を 2 個書いた場合はこんなエラーになる。

```
service.proto: Import "models/user.proto" was listed twice.
```

import を ２回しているエラーである。

以上から、**protoc では、相対パスの完全一致によって、同一ファイルかどうかを判断することがわかる。**

## 別のファイルを経由した import の場合

enum 定義のあるファイルを追加で作成する。

```
~/
└── src/
    └── github.com
        └── sat8bit
            └── protoc
                ├── models
                │   ├── user.proto
                │   └── role.proto
                └── service.proto
```

`models/role.proto` の内容は次の通り。

```
syntax = "proto3";

package io.github.sat8bit.models;

option go_package = "github.com/sat8bit/protobuf/models";

enum Role {
  UNKNOWN = 0;
  ADMIN = 1;
  READ = 2;
}
```

`models/user.proto` からこれを import する。

```proto3
syntax = "proto3";

package io.github.sat8bit.models;

option go_package = "github.com/sat8bit/protobuf/models";

import "models/role.proto";

message User {
    string id = 1;
    string name = 2;
    Role role = 3;
}
```

このとき、import で指定するファイルパスは インクルードパスからの相対パスになる。`models/user.proto` から見た相対パスではない。

この状態で、`model/user.proto` を protoc してみる。

```
$ protoc -I . -I ~/src --go_out ./go --go-grpc_out ./go models/user.proto models/role.proto
$ tree go
go
└── github.com
    └── sat8bit
        └── protobuf
            ├── models
            │   ├── role.pb.go
            │   └── user.pb.go
            ├── service.pb.go
            └── service_grpc.pb.go
```

更に、`service.proto` でも role が必要になったので import する。

```proto3
syntax = "proto3";

package io.github.sat8bit;

import "models/user.proto";
import "models/role.proto";

option go_package = "github.com/sat8bit/protobuf";

service UserService {
    rpc GetUser(GetUserMessage) returns (GetUserResponse) {}
}

message GetUserMessage {
    string id = 1;
    models.Role role = 2;
}

message GetUserResponse {
    models.User user = 1;
}
```

このときの依存関係は、以下の通り。

```
service.proto -------> models/user.proto
     |                         |
     |                         V
     `---------------> models/role.proto
```

`service.proto` から見ると、`models/role.proto` は 2 系統から import されてることになる。

この状態で、`service.proto` を protoc してみる。

```
protoc -I . -I ~/src --go_out ./go --go-grpc_out ./go service.proto
```

エラーにはならない。

以上のことから、**違うファイル経由で同じファイルを import した場合、`Import "XXXXX" was listed twice.` のエラーにはならずに正常に処理されるということがわかる。**

## 別のファイルを経由した import の場合（別ファイル扱いの場合）

ここで、試しに `service.proto` の方だけ `~/src` からの相対パス指定に変更してみる。

```proto3
syntax = "proto3";

package io.github.sat8bit;

import "github.com/sat8bit/protobuf/models/user.proto";
import "github.com/sat8bit/protobuf/models/role.proto";

option go_package = "github.com/sat8bit/protobuf";

service UserService {
    rpc GetUser(GetUserMessage) returns (GetUserResponse) {}
}

message GetUserMessage {
    string id = 1;
    models.Role role = 2;
}

message GetUserResponse {
    models.User user = 1;
}
```

`service.proto` を protoc すると、以下のエラーになる。

```
$ protoc -I . -I ~/src --go_out ./go --go-grpc_out ./go service.proto
github.com/sat8bit/protobuf/models/role.proto:8:3: "io.github.sat8bit.models.UNKNOWN" is already defined in file "models/role.proto".
github.com/sat8bit/protobuf/models/role.proto:8:3: Note that enum values use C++ scoping rules, meaning that enum values are siblings of their type, not children of it.  Therefore, "UNKNOWN" must be unique within "io.github.sat8bit.models", not just within "Role".
github.com/sat8bit/protobuf/models/role.proto:9:3: "io.github.sat8bit.models.ADMIN" is already defined in file "models/role.proto".
github.com/sat8bit/protobuf/models/role.proto:9:3: Note that enum values use C++ scoping rules, meaning that enum values are siblings of their type, not children of it.  Therefore, "ADMIN" must be unique within "io.github.sat8bit.models", not just within "Role".
github.com/sat8bit/protobuf/models/role.proto:10:3: "io.github.sat8bit.models.READ" is already defined in file "models/role.proto".
github.com/sat8bit/protobuf/models/role.proto:10:3: Note that enum values use C++ scoping rules, meaning that enum values are siblings of their type, not children of it.  Therefore, "READ" must be unique within "io.github.sat8bit.models", not just within "Role".
github.com/sat8bit/protobuf/models/role.proto:7:6: "io.github.sat8bit.models.Role" is already defined in file "models/role.proto".
service.proto: Import "github.com/sat8bit/protobuf/models/role.proto" was not found or had errors.
service.proto:16:5: "io.github.sat8bit.models.Role" seems to be defined in "models/role.proto", which is not imported by "service.proto".  To use it here, please add the necessary import.
service.proto:16:5: "models.Role" is resolved to "io.github.sat8bit.models.Role", which is not defined. The innermost scope is searched first in name resolution. Consider using a leading '.'(i.e., ".models.Role") to start from the outermost scope.
```

既に定義済みエラーとなった。

これは、**`service.proto` から見てる `role.proto` と、 `user.proto` から見てる `role.proto` が違うファイルと認識されたためである。**

## パス指定で発生する差分について（go_out / grpc に限る）

ここまでの検証で `models/user.proto` と `service.proto` の import が揃っていればよいことがわかったが、何に揃えればいいのかを考える。

ここで、enum が含まれるファイルを import した場合の生成されるファイルの差分を見てみる。

```
$ diff user.pb.go._models_role.proto user.pb.go.github.com_sat8bit_protobuf_models_role.proto
91,103c91,101
(rawDesc の差分は省略)
137c135
<       file_github_com_sat8bit_protobuf_models_role_proto_init()
---
>       file_models_role_proto_init()
```

enum を含むファイルを import した場合は、対象の enum を含むファイルの init function が呼び出されるが、その呼び出すメソッド名が違うことがわかる。

ちなみに、このままの流れで以下のコマンドで role.proto を protoc すると、生成される init は `file_models_role_proto_init` になる。

```
$ protoc -I . -I ~/src --go_out ./go --go-grpc_out ./go models/role.proto
$ grep init go/github.com/sat8bit/protobuf/models/role.pb.go
func init() { file_models_role_proto_init() }
func file_models_role_proto_init() {
```

ちなみに `file_github_com_sat8bit_protobuf_models_role_proto_init` を生成したい場合は、もう一方のインクルードパスからのパスを指定してあげれば良い。

```
$ protoc -I . -I ~/src --go_out ./go --go-grpc_out ./go ~/src/github.com/sat8bit/protobuf/models/role.proto
$ grep init go/github.com/sat8bit/protobuf/models/role.pb.go
func init() { file_github_com_sat8bit_protobuf_models_role_proto_init() }
func file_github_com_sat8bit_protobuf_models_role_proto_init() {
```

以上のことから、 **protoc を実行したときのパスの指定/インクルードパスの指定で、成果物が変わることがわかる。**

import で指定するパスと、protoc のコマンド実行時のファイルを指定するパスを同じにしておけば良い話だけど、ちょっとわかりづらい。

個人的には `find . -name *.proto | protoc -I XXXX` でドバーッと 1 ファイルずつ protoc したいので、前者のほうが都合が良いことが多い気がした。
