# execute_sim1.jl
# 論文で説明されている第1シミュレーション（確率的戦略を採用し、制裁行動がある場合）を再現実行するためのスクリプトです。

include("../src/BasicSimulation.jl") # シミュレーションの基本ロジックが書かれたファイルを読み込みます。
include("config.jl") # シミュレーションの共通設定が書かれたファイルを読み込みます。
                     # (例: エージェント数 NUM_AGENTS, 総世代数 NUM_GENERATIONS, デフォルトの罰金額 DEFAULT_FINE_AMOUNT などが定義されています)
using .BasicSimulation # BasicSimulation モジュールを使えるようにします。

println("Starting Simulation 1 (Paper Replication: Probabilistic Strategy, Sanctioning Enabled)...")

# 第1シミュレーション固有のパラメータを設定します。
# ここでは、config.jl で定義されているデフォルトの罰金額を、第1シミュレーション用に上書きするイメージです。
const FINE_AMOUNT_S1 = 5.0 # 罰金額 F を、第1シミュレーション用に設定します (論文記載の中間的な値)。
println("  FINE_AMOUNT (Sim1 specific) = ", FINE_AMOUNT_S1)
# NUM_AGENTS (エージェント数) など、他の共通パラメータは config.jl の設定値をそのまま使います。

# シミュレーションを実行します。(共通パラメータは config.jl から読み込まれたものを使用します)
pop_sim1_repl = run_simulation1(NUM_AGENTS, NUM_GENERATIONS, # run_simulation1 関数を呼び出します。
                                cooperation_multiplier=COOPERATION_MULTIPLIER, # config.jl から
                                cost_of_cooperation=COST_OF_COOPERATION,     # config.jl から
                                cost_of_punishment=COST_OF_PUNISHMENT,       # config.jl から
                                fine_amount=FINE_AMOUNT_S1,                  # このファイルで設定したSim1専用の値
                                mutation_rate=MUTATION_RATE,                 # config.jl から
                                num_trials_per_generation=NUM_TRIALS_PER_GENERATION) # config.jl から

println("Simulation 1 (Paper Replication) finished.") 