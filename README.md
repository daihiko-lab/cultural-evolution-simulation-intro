# Juliaと文化進化シミュレーション入門 2025

実施日: 2025/05/10 (土)

## 1. 概要

このリポジトリは、Julia言語を用いた文化進化シミュレーションの学習と実装を目的とした勉強会のための教材・コードを提供します。

リポジトリは不完全な点も多いです。特に、シミュレーションコードについては検証と修正が必要です。また, 環境構築は弊院ゼミで使用率の高いMacを想定しており, Windowsユーザーは[計算科学のためのWindowsセットアップ](https://zenn.dev/ohno/books/356315a0e6437c)などを参考にしてください。



## 2. 資料の構成

このリポジトリには、以下の5つの主要な資料が含まれています:

1. **環境構築手順書** ([`docs/environment_setup.md`](./docs/environment_setup.md))
   - macOSでの開発環境構築の詳細な手順
   - ターミナルの基本操作から、Julia、Python、R、IDEのインストールまで
   - 仮想環境の設定方法や、パッケージ管理の基礎知識

2. **Julia初心者向けレジュメ** ([`docs/julia_beginner_resume.md`](./docs/julia_beginner_resume.md))
   - Julia言語の基本的な文法と機能の解説
   - 変数、制御構造、関数、データ構造などの基礎概念
   - パッケージ管理とプロジェクト環境の利用方法
   - データ処理と可視化の基本的な方法

3. **CursorとAIコーディング入門** ([`docs/cursor_ai_coding_resume.md`](./docs/cursor_ai_coding_resume.md))
   - Cursorエディタの基本的な使い方
   - AIを活用した効率的なコーディング手法

4. **シミュレーション・モデリング入門** ([`docs/simulation_modeling_introduction_summary.md`](./docs/simulation_modeling_introduction_summary.md))
   - Smaldino (2023) "Modeling social behavior" の要約
   - モデリングの本質と重要性
   - 数理モデルとエージェントベースモデルの基本概念
   - 具体的なモデル事例 (ボイドモデル、SIRモデルなど)



5. **シミュレーション概要** ([`docs/simulation_overview_summary.md`](./docs/simulation_overview_summary.md))
   - 文化進化シミュレーションの実装の概要
   - エージェントベースモデルの構造と主要コンポーネント
   - シミュレーションの実行フローと各機能の説明

これらの資料は、環境構築から始まり、Juliaの基礎を学び、AIを活用した効率的な開発手法を習得し、モデリングの基礎を理解した上で、最終的にシミュレーションの実装に至るまでの勉強会の流れに沿って構成されています。

## 3. 目的と対象読者

### 3.1 学習目的
- Julia言語の基本的な文法、データ構造、制御フローを理解する
- Juliaにおけるパッケージ管理とプロジェクト環境の利用方法を習得する
- エージェントベースシミュレーションの基本的な考え方と実装の流れを学ぶ (少し)
- 既存の研究論文のシミュレーションモデルを読解し、コードに落とし込む経験をする (少し)

### 3.2 対象読者
- Juliaプログラミング初心者の方
- 科学技術計算、データ分析、特にシミュレーション分野でJuliaを使ってみたいと考えている学部生、大学院生

## 4. インストール方法

1. リポジトリのクローン:
```bash
git clone https://github.com/daihiko-lab/cultural-evolution-simulation-intro-2025.git
cd cultural-evolution-simulation-intro-2025
```

2. Juliaパッケージのインストール:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## 5. プロジェクト構成

```
cultural-evolution-simulation-intro-2025/
├── .cursor/                  # Cursorルール関係
├── LICENSE                    # MITライセンス
├── README.md                  # このファイル
├── docs/                      # ドキュメント
└── julia_project/            # シミュレーション実装
    ├── README.md             # 実装の詳細な説明
    ├── Project.toml          # プロジェクト設定・依存関係
    ├── scripts/              # シミュレーションスクリプト
    ├── src/                  # コアロジック
    └── results/              # 実験結果出力先
```

## 6. 参考資料

- [Julia言語公式ドキュメント](https://docs.julialang.org/)
- その他の参考資料は [Julia初心者向けレジュメ](./docs/julia_beginner_resume.md) を参照

- [計算科学のためのWindowsセットアップ](https://zenn.dev/ohno/books/356315a0e6437c)\
今回の会はMac使用者が多いので, Macのセットアップに重きを置いている。Windowsユーザーは参考にされたし。


## 7. ライセンス

このプロジェクトは [MIT License](./LICENSE) の下で公開されています。

### 著作権に関する注意事項

- このプロジェクトのコードとドキュメントはMITライセンスの下で自由に利用できます。
- ただし、`docs/simulation_modeling_introduction_summary.md`は、Smaldino (2023) "Modeling social behavior"の要約を含んでおり、原著の著作権は原著者に帰属します。
- 要約版ドキュメントの利用については、原著の著作権を尊重し、適切な引用を行ってください。

## 8. 作成者

作成者: yamanori99
- [GitHub](https://github.com/yamanori99)
- [ホームページ](https://yamanori.net)
