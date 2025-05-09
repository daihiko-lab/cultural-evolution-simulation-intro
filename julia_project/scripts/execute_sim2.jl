# execute_sim2.jl
# 論文で説明されている第2シミュレーション（全員が集団応報戦略を採用し、制裁行動がある場合）を
# 再現実行するためのスクリプトです。

include("../src/BasicSimulation.jl") # シミュレーションの基本ロジックが書かれたファイルを読み込みます。
include("config.jl") # シミュレーションの共通設定が書かれたファイルを読み込みます。
                     # (例: エージェント数 NUM_AGENTS, 総世代数 NUM_GENERATIONS, デフォルトの罰金額 DEFAULT_FINE_AMOUNT などが定義されています)
using .BasicSimulation # BasicSimulation モジュールを使えるようにします。

println("Starting Simulation 2 (Paper Replication: Group Retaliation, Sanctioning Enabled)...")

# 第2シミュレーション固有のパラメータを設定します。
const FINE_AMOUNT_S2 = 3.5 # 罰金額 F を、第2シミュレーション用に設定します (論文中で協力が達成された時の値)。
println("  FINE_AMOUNT (Sim2 specific) = ", FINE_AMOUNT_S2)
# 他の共通パラメータは config.jl の設定値をそのまま使います。

# 第2シミュレーションを実行します。(共通パラメータは config.jl から読み込まれたものを使用します)
pop_sim2_repl = run_simulation2(NUM_AGENTS, NUM_GENERATIONS, # run_simulation2 関数を呼び出します。
                            fine_amount=FINE_AMOUNT_S2,                    # このファイルで設定したSim2専用の値
                            cost_of_punishment=COST_OF_PUNISHMENT,         # config.jl から
                            cooperation_multiplier=COOPERATION_MULTIPLIER, # config.jl から
                            cost_of_cooperation=COST_OF_COOPERATION,       # config.jl から
                            mutation_rate=MUTATION_RATE,                   # config.jl から
                            num_trials_per_generation=NUM_TRIALS_PER_GENERATION) # config.jl から
                            
println("Simulation 2 (Paper Replication) finished.") 