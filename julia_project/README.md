# 文化進化シミュレーション実装プロジェクト

このディレクトリには、文化進化シミュレーションの実装コードと関連ファイルが含まれています。

## 1. プロジェクト構成

```
julia_project/
├── Manifest.toml         # 依存パッケージの正確なリスト
├── Project.toml          # プロジェクトの依存関係定義
├── README.md             # このファイル
├── results/              # シミュレーション結果の出力ディレクトリ
│   └── *.csv            # 実験結果のCSVファイル
├── scripts/             # シミュレーション実行用スクリプト
│   ├── config.jl        # シミュレーション共通パラメータ設定
│   ├── execute_sim1.jl  # 第1シミュレーション実行
│   ├── execute_sim2.jl  # 第2シミュレーション実行
│   ├── execute_sim3.jl  # 第3シミュレーション実行
│   └── run_fine_amount_experiments.jl # 罰金額の影響分析実験
└── src/                 # メインのシミュレーションロジック
    └── BasicSimulation.jl # コアロジック実装
```

## 2. 依存パッケージ

このプロジェクトは以下のJuliaパッケージに依存しています：

- `Random`: 乱数生成 (Julia標準ライブラリ)
- `Statistics`: 統計計算 (Julia標準ライブラリ)
- `DataFrames`: データフレーム操作
- `CSV`: CSVファイル入出力
- `Plots`: グラフ描画
- `ProgressMeter`: 進捗表示

## 3. シミュレーション実行方法

### 3.1 環境のセットアップ

1. このディレクトリ (`julia_project/`) に移動:
   ```bash
   cd path/to/JuliaStudyMeeting/julia_project
   ```

2. Juliaを起動し、プロジェクト環境をアクティベート:
   ```julia
   # Juliaを起動
   julia

   # パッケージモードに移行 (']'キーを押す)
   (@v1.x) pkg> activate .

   # 依存パッケージをインストール
   (julia_project) pkg> instantiate
   ```

### 3.2 個別シミュレーションの実行

各シミュレーションは以下のコマンドで実行できます：

```bash
# 第1シミュレーション
julia --project=. scripts/execute_sim1.jl

# 第2シミュレーション
julia --project=. scripts/execute_sim2.jl

# 第3シミュレーション
julia --project=. scripts/execute_sim3.jl
```

### 3.3 罰金額の影響分析実験

罰金額を変化させた実験を実行：

```bash
julia --project=. scripts/run_fine_amount_experiments.jl
```

## 4. 実装の詳細

### 4.1 シミュレーションパラメータ (`config.jl`)

- `NUM_AGENTS`: エージェント数 (デフォルト: 100)
- `NUM_GENERATIONS`: 世代数 (デフォルト: 1000)
- `NUM_TRIALS`: 1世代あたりの試行回数 (デフォルト: 100)
- `MUTATION_RATE`: 突然変異率 (デフォルト: 0.01)
- `COOPERATION_COST`: 協力行動のコスト (デフォルト: 1.0)
- `FINE_AMOUNT`: 制裁時の罰金額 (デフォルト: 3.0)

### 4.2 エージェントの種類 (`BasicSimulation.jl`)

1. **集団応報戦略エージェント (Group Retaliation Strategy)**
   - 応報閾値に基づいて協力/非協力を決定
   - 集団内の非協力者への制裁行動を実施

2. **確率戦略エージェント (Probabilistic Strategy)**
   - 一定の確率で協力/非協力を選択
   - 戦略の進化により協力確率が変化

### 4.3 結果の出力形式

実験結果は `results/` ディレクトリにCSVファイルとして保存されます。主な出力項目：

- `simulation_type`: シミュレーションタイプ
- `replication_id`: 実験回数ID
- `fine_amount`: 設定された罰金額
- `avg_coop_propensity_all`: 平均協力傾向
- `avg_punishment_propensity`: 平均制裁傾向
- `prop_group_retaliation`: 集団応報戦略の割合
- `is_cooperation_achieved`: 協力達成フラグ

## 5. 結果の分析

実験結果の分析には、以下のようなJuliaコードを使用できます：

```julia
using CSV, DataFrames, Plots

# 結果の読み込み
results = CSV.read("results/fine_amount_experiment_results.csv", DataFrame)

# 協力達成率の計算
cooperation_rates = combine(
    groupby(results, :fine_amount),
    :is_cooperation_achieved => mean => :cooperation_rate
)

# 結果のプロット
plot(
    cooperation_rates.fine_amount,
    cooperation_rates.cooperation_rate,
    xlabel="Fine Amount",
    ylabel="Cooperation Achievement Rate",
    title="Effect of Fine Amount on Cooperation",
    marker=:circle
)
```

## 6. 注意事項

- シミュレーションの実行には十分なメモリと計算時間が必要です
- 大規模な実験を行う場合は、パラメータを適切に調整してください
- 結果の再現性を確保するため、乱数シードを固定することができます

## 7. 貢献とフィードバック

バグ報告や機能改善の提案は、プロジェクトのIssueトラッカーにお願いします。
プルリクエストも歓迎します。
