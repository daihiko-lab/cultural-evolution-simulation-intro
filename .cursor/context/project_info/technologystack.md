# 技術スタック

## コア技術
- Julia: ^1.11.5
- **管理方法:** Homebrew, juliaup

## 開発ツール（推奨）
- Shell: zsh
- Shell Framework: Oh My Zsh
- Prompt: Starship
- Editor: Cursor, Positron (R, Quarto)
- **テスト・品質管理:**
  - Julia 標準の `Test` モジュール
  - `Coverage.jl`
  - レポート形式: LCOV (`.lcov` ファイル)

---

# Juliaの実装規則

必要に応じて https://github.com/JuliaLang/julia/tree/master/doc/src/manual を参照します。
**また、主要な標準ライブラリのドキュメントは `docs/archive/julia_docs/` に Markdown 形式で保存されています。こちらも適宜参照してください。**

## パッケージ管理
- `Project.toml` と `Manifest.toml` によるパッケージ管理
  - **注意:** `Manifest.toml` は `Pkg` によって自動管理されるため、**直接編集しないでください**。パッケージの追加・削除・更新は `Project.toml` の編集または `Pkg` コマンドで行います。
  - **重要:** AIアシスタントを含む開発者は、これらのファイルを**絶対に直接編集してはなりません**。常に `Pkg` コマンド (例: `Pkg.add`, `Pkg.rm`, `Pkg.update`, `Pkg.instantiate`) を使用してください。
- 外部依存パッケージは必ず `Project.toml` に記載
- 標準ライブラリの使用:
  - **`Base` のサブモジュール** (例: `Iterators`, `Dates`, `LinearAlgebra`) を使用する場合:
    - **必ず `Base` から明示的にインポート:** `using Base.Iterators`
    - `Project.toml` への記述は不要 (Julia 1.9 以降)
    - 単に `using Iterators` とするのは避ける。
  - **独立した標準ライブラリ** (例: `Random`, `Printf`, `Statistics`, `SparseArrays` 等) を使用する場合:
    - **通常通り `using` でインポート:** `using Random`
    - **推奨:** `Project.toml` の `[deps]` と `[compat]` に明示的に追加する。これにより、テスト環境での互換性問題を防ぎ、依存関係が明確になります。

## コーディングスタイル
- Julia公式のスタイルガイドに従うことを推奨
- 関数名はスネークケース (`function my_function()`)
- 型名はパスカルケース (`struct MyType`)
- 定数は大文字スネークケース (`const MAX_ITERATIONS = 1000`)
- インデントは4スペース
- 1行の最大文字数は92文字を目安とする
- ドキュメンテーションはDocstringで記述
- 引数を変更する可能性のある関数には末尾に`!`を付ける慣習に従う (例: `sort!`)

## パフォーマンスに関するヒント
- **型安定性:** 関数の引数や変数の型が実行前に特定できるよう記述する。型不安定性はパフォーマンス低下の主因となるため、`@code_warntype`で確認することを推奨。
- **グローバル変数:** 非`const`なグローバル変数の参照・更新は型推論を妨げ、パフォーマンスを低下させるため、関数内での使用は極力避ける。値は引数で渡すか、`const`で定義する。
- **ブロードキャスト:** 配列等の要素ごとの操作には、明示的なループよりドット構文 (`.`) によるブロードキャスト (`y = sin.(x)`) を推奨。コードが簡潔になり、効率的な場合が多い。
- **配列の反復:** `1:length(A)`のような形式ではなく`eachindex(A)`や`axes(A)`を使用する。これにより一般性、効率性、可読性が向上する。例: `for i in eachindex(A) ... end`

## コードの再利用性
- **抽象型の活用:** 関数の引数型は、可能な限り具象型 (`Array{Float64, 1}`) ではなく適切な抽象型 (`AbstractVector{<:Real}`) を使用する。これにより、多様な型の引数を受け入れ可能になり、関数の汎用性が高まる。

## シミュレーション固有の規則
- **乱数生成:** 再現性のため、乱数シードを明示的に設定する場合は `Random.seed!(seed)` を使用する。
- **パラメータ管理:** シミュレーションパラメータは `scripts/config.jl` で一元管理する。
- **結果出力:** シミュレーション結果は `results/` ディレクトリに保存し、タイムスタンプを含むファイル名を使用する。
- **データ形式:** 結果データは基本的にCSV形式で保存し、必要に応じてJLD2形式も使用可能。

## テストに関する注意点
- テストは `test/` ディレクトリ内に配置し、機能ごとにテストファイルを分割する。
- テストの実行は Julia REPL から `include("test/runtests.jl")` を使用する。
- カバレッジ測定を行う場合は、`--code-coverage=user` フラグ付きで REPL を起動する。 