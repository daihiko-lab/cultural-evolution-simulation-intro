# プロジェクトディレクトリ構造

```
cultural-evolution-simulation-intro-2025/
├── .git/                    # Gitリポジトリ
├── .cursor/                 # プロジェクト管理・開発支援
│   ├── context/            # プロジェクトコンテキスト
│   │   └── project_info/   # プロジェクト情報
│   │       ├── progress.md # 進捗・TODO管理
│   │       ├── technologystack.md # 技術スタック・実装規則
│   │       └── directorystructure.md # ディレクトリ構造定義
│   ├── rules/             # 開発ルール
│   │   ├── common_rules.mdc # 共通ルール
│   │   ├── programming.mdc  # プログラミングルール
│   │   └── research.mdc     # 研究・ドキュメントルール
│   └── scripts/           # AIチャット利用する開発支援スクリプト
│       └── get_current_date.sh # 日付取得スクリプト
├── docs/                  # ドキュメント
│   ├── environment_setup.md # 環境構築手順
│   ├── julia_beginner_resume.md # Julia初心者向けレジュメ
│   └── ref.md            # 論文解説
├── julia_project/        # シミュレーション実装
│   ├── Project.toml      # プロジェクト定義
│   ├── Manifest.toml     # 依存関係
│   ├── README.md        # 実装詳細説明
│   ├── src/             # ソースコード
│   │   └── BasicSimulation.jl # シミュレーション本体
│   ├── test/            # テストコード
│   │   ├── runtests.jl  # テスト実行
│   │   └── test_basic_simulation.jl # 基本テスト
│   ├── scripts/         # 実行スクリプト
│   │   ├── config.jl    # 設定
│   │   ├── execute_sim1.jl # シミュレーション1
│   │   ├── execute_sim2.jl # シミュレーション2
│   │   ├── execute_sim3.jl # シミュレーション3
│   │   └── run_fine_amount_experiments.jl # 実験実行
│   └── results/         # 実験結果
│       └── *.csv        # CSVデータ
├── .gitignore           # Git除外設定
├── LICENSE              # ライセンス
└── README.md           # メインREADME
```

## ディレクトリ説明

### トップレベル
- `.git/`: Gitリポジトリ
- `.cursor/`: プロジェクト管理・開発支援ファイル
- `docs/`: プロジェクトドキュメント
- `julia_project/`: シミュレーション実装
- `.gitignore`: Git除外設定
- `LICENSE`: MITライセンス
- `README.md`: プロジェクト概要

### .cursor/
プロジェクト管理と開発支援のためのファイル群
- `context/`: プロジェクトの状態や規則を定義
- `rules/`: 開発ルールを定義
- `scripts/`: 開発支援スクリプト

### docs/
プロジェクトの説明・解説ドキュメント
- `environment_setup.md`: 環境構築手順
- `julia_beginner_resume.md`: Julia言語の基礎解説
- `ref.md`: 実装の基となる論文の解説

### julia_project/
シミュレーション実装の本体
- `src/`: ソースコード
- `test/`: テストコード
- `scripts/`: 実行スクリプト
- `results/`: 実験結果の出力先

## ファイル命名規則

1. **ソースコード**
   - モジュール: アッパーキャメルケース (例: `BasicSimulation.jl`)
   - スクリプト: スネークケース (例: `execute_sim1.jl`)

2. **テスト**
   - テストファイル: `test_` プレフィックス (例: `test_basic_simulation.jl`)

3. **ドキュメント**
   - Markdown: スネークケース (例: `environment_setup.md`)

4. **実験結果**
   - CSVファイル: 実験名_日付 (例: `fine_amount_experiment_20250415.csv`) 