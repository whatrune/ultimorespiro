# Ultimo Respiro

スト〇ラ系の「幽体離脱薬」風演出を目指した FiveM / QBCore 用スクリプトです。  
薬を使用すると本体がその場に残り、一定時間だけ魂状態で移動できます。

## できること

- pill アニメ後に魂状態へ移行
- 本体クローンをその場に残す
- 魂状態中は一定時間だけ移動可能
- 攻撃 / ジャンプ / 乗車 / スプリントを制限
- 無線使用可能
- スマートフォン使用可能
- 自分だけの魂クローンを表示

## 前提環境

- FiveM
- QBCore
- pma-voice
- ox_inventory 系、または QBCore の useable item 運用

## インストール

1. リソースを `resources` 配下に配置します  
2. `server.cfg` に以下を追加します

```cfg
ensure ultimorespiro
```

3. アイテム定義を追加します  
4. サーバーを再起動、またはリソースを再読み込みします

## アイテム名

このスクリプトの使用アイテム名は以下です。

```lua
ultimorespiro
```

`shared/config.lua` の `Config.ItemName` と、inventory 側の item 名を必ず一致させてください。

## ox_inventory 系の定義例

```lua
['ultimorespiro'] = {
    label = 'ウルティモ レスピーロ',
    weight = 100,
    stack = true,
    close = true,
    description = '仮死と剥離を引き起こす危険な薬',
    client = {
        export = 'ultimorespiro.useItem',
        image = 'ultimorespiro.png'
    }
},
```

## 基本設定

主な設定は `shared/config.lua` から変更できます。

### 効果時間

```lua
Config.Duration = 30
```

魂状態の継続時間です。


### 魂の移動速度

```lua
Config.MoveRate = 1.0
```

魂状態中の移動速度です。


## 使用条件

以下の状態では使用できません。

- 既に使用中
- 死亡中
- laststand 中
- 車両内

## phone 連携について

phone 演出は、使用している phone スクリプトによって見え方が変わることがあります。  
必要に応じて `LocalPlayer.state.phoneOpen` を利用した制御を追加してください。

## 導入確認

導入後は以下を確認してください。

- アイテム使用で pill アニメが再生される
- 本体クローンがその場に残る
- 魂状態へ移行できる
- 効果終了後に正常状態へ戻る
- 無線が使用できる
- 本体が浮かずに地面へ接地している

## 補足

このスクリプトは「本体をその場に残し、魂だけが短時間移動する」演出を目的とした構成です。  
他スクリプトとの組み合わせによっては、キー競合や見た目の微調整が必要になる場合があります。
