# execute_sim3.jl
# 論文で説明されている第3シミュレーション（確率戦略と集団応報戦略が混在し、制裁行動がある場合）を
# 再現実行するためのスクリプトです。

include("../src/BasicSimulation.jl") # シミュレーションの基本ロジックが書かれたファイルを読み込みます。
include("config.jl") # シミュレーションの共通設定が書かれたファイルを読み込みます。
                     # (例: エージェント数 NUM_AGENTS, 総世代数 NUM_GENERATIONS, デフォルトの罰金額 DEFAULT_FINE_AMOUNT などが定義されています)
using .BasicSimulation # BasicSimulation モジュールを使えるようにします。

println("Starting Simulation 3 (Paper Replication: Mixed Strategy, Sanctioning Enabled)...")

# 第3シミュレーション固有のパラメータを設定します。
const FINE_AMOUNT_S3 = 10.0 # 罰金額 F を、第3シミュレーション用に設定します (論文中で協力が達成された時の値)。
println("  FINE_AMOUNT (Sim3 specific) = ", FINE_AMOUNT_S3)
# 他の共通パラメータは config.jl の設定値をそのまま使います。

# 第3シミュレーションを実行します。(共通パラメータは config.jl から読み込まれたものを使用します)
pop_sim3_repl = run_simulation3(NUM_AGENTS, NUM_GENERATIONS, # run_simulation3 関数を呼び出します。
                            fine_amount=FINE_AMOUNT_S3,                    # このファイルで設定したSim3専用の値
                            cost_of_punishment=COST_OF_PUNISHMENT,         # config.jl から
                            cooperation_multiplier=COOPERATION_MULTIPLIER, # config.jl から
                            cost_of_cooperation=COST_OF_COOPERATION,       # config.jl から
                            mutation_rate=MUTATION_RATE,                   # config.jl から
                            num_trials_per_generation=NUM_TRIALS_PER_GENERATION) # config.jl から
                            
println("Simulation 3 (Paper Replication) finished.") 