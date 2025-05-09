using Printf # Printf を使うために追加

# Simulation Parameters (Common settings for JuliaStudyMeeting)
# このファイルでは、シミュレーション全体で共通して使われる基本的な設定値（パラメータ）を定義しています。
# 各シミュレーションスクリプト (execute_simX.jl や run_fine_amount_experiments.jl など) は、
# このファイルを読み込んで、ここで定義された値を使用します。

# --- Population & Generations (集団と世代に関する設定) ---
const NUM_AGENTS = 200            # N: 集団内のエージェント（個体）の総数
const NUM_GENERATIONS = 1000      # G: シミュレーションを実行する総世代数

# --- Game Payoffs & Costs (ゲームの利得とコストに関する設定) ---
const COOPERATION_MULTIPLIER = 5.0 # b: 協力によって投じられた点数が何倍になるかを示す係数
const COST_OF_COOPERATION = 1.0    # C_c: エージェントが1回協力行動をとるために支払うコスト
const COST_OF_PUNISHMENT = 1.0     # C_p: エージェントが他のエージェントを1回罰するために支払うコスト
# F: 罰せられたエージェントが科される罰金のデフォルト値。
#    特定のシミュレーションスクリプトでは、この値が上書きされることがあります。
const DEFAULT_FINE_AMOUNT = 1.0    

# --- Evolution & Learning (進化と学習に関する設定) ---
# mu: エージェントの特性（協力傾向、制裁傾向、戦略など）が世代交代時に変化する「突然変異」の確率
const MUTATION_RATE = 0.05         

# --- Simulation Structure (シミュレーションの構造に関する設定) ---
# T: 1世代あたりに繰り返される試行（ゲームのラウンド数）
const NUM_TRIALS_PER_GENERATION = 10 

# --- Sanctioning (制裁に関する設定) ---
# 制裁行動を有効にするかどうか (enable_sanctioning) は、
# basic_simulation.jl 内の run_simulation! 関数の引数で制御されます。
# Sim1, Sim2, Sim3 の各実行関数 (run_simulationX) 内では、この引数は true に設定されています。

println("Loaded common parameters from config.jl")
# 最も長いラベルの長さを基準にフォーマットを定義
# "Number of Trials per Generation (NUM_TRIALS_PER_GENERATION): " の文字数を数える
# 必要に応じて手動で調整してください。
const LABEL_WIDTH = 60 # 仮の幅、実際のラベル長に合わせて調整

println(@sprintf("  %-*s %s", LABEL_WIDTH, "Number of Agents (NUM_AGENTS):", NUM_AGENTS))
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Number of Generations (NUM_GENERATIONS):", NUM_GENERATIONS))
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Cooperation Multiplier (COOPERATION_MULTIPLIER):", COOPERATION_MULTIPLIER))
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Cost of Cooperation (COST_OF_COOPERATION):", COST_OF_COOPERATION))
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Cost of Punishment (COST_OF_PUNISHMENT):", COST_OF_PUNISHMENT))
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Mutation Rate (MUTATION_RATE):", MUTATION_RATE))
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Default Fine Amount (DEFAULT_FINE_AMOUNT):", DEFAULT_FINE_AMOUNT)) # Note: This is a default value.
println(@sprintf("  %-*s %s", LABEL_WIDTH, "Number of Trials per Generation (NUM_TRIALS_PER_GENERATION):", NUM_TRIALS_PER_GENERATION))