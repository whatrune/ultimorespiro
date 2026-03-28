# Ultimo Respiro

ストグラ系の「幽体離脱薬」風演出を目指した FiveM / QBCore 用スクリプトです。  
薬を使用すると本体がその場に残り、一定時間だけ魂状態で移動できます。

## できること

- pill アニメ後に魂状態へ移行
- 本体クローンをその場に残す
- 魂状態中は一定時間だけ移動可能
- 攻撃 / ジャンプ / 乗車 / スプリントを制限
- 無線使用可
- 自分だけ半透明の魂クローンを表示可能
- 本体クローンの接地補正対応

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
    label = 'ウルティモレスピーロ',
    weight = 100,
    stack = true,
    close = true,
    description = '仮死と剥離を引き起こす危険な薬',
    client = {
        export = 'ultimorespiro.useItem'
    }
},
```

## QBCore items.lua 系の定義例

```lua
['ultimorespiro'] = {
    ['name'] = 'ultimorespiro',
    ['label'] = 'ウルティモレスピーロ',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'ultimorespiro.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = '仮死と剥離を引き起こす危険な薬'
},
```

## 基本設定

主な設定は `shared/config.lua` から変更できます。

### 効果時間

```lua
Config.Duration = 30
```

魂状態の継続時間です。

### 使用時アニメ

```lua
Config.UsePillAnim = true
Config.PillAnimDict = 'mp_suicide'
Config.PillAnimClip = 'pill'
Config.PillAnimDuration = 2200
```

使用時の pill 演出です。

### 魂の移動速度

```lua
Config.MoveRate = 1.0
```

魂状態中の移動速度です。

### 本体クローンの接地補正

```lua
Config.BodyGroundOffset = 0.035
```

本体が少し浮いて見える場合に調整します。

### 自分だけ見える魂クローン

```lua
Config.ShowSoulToSelf = true
Config.SoulSelfAlpha = 175
Config.SoulSelfOffsetZ = 0.0
```

自分視点だけで表示する魂クローンの設定です。

### 無線モーション

```lua
Config.UseSoulRadioAnim = true
Config.SoulRadioAnimDict = 'random@arrests'
Config.SoulRadioAnimClip = 'generic_radio_chatter'
```

魂クローンに無線モーションを付ける設定です。

## 使用条件

以下の状態では使用できません。

- 既に使用中
- 死亡中
- laststand 中
- 車両内

## pma-voice 連携

無線モーション判定には `LocalPlayer.state.radioActive` を使用します。  
そのため、pma-voice 環境での使用を前提にしています。

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
