# run_fine_amount_experiments.jl
#
# Description (スクリプトの概要):
# This script executes a series of simulations (Sim1, Sim2, Sim3) based on the
# `basic_simulation.jl` module. It systematically varies the `FINE_AMOUNT` parameter
# across a defined range. For each combination of simulation type and fine amount,
# it runs a specified number of replications. Aggregated data from the final
# generation of each replication is collected and then saved to a CSV file.
# This process is designed to reproduce and potentially extend the analysis
# regarding the impact of fine amounts on cooperation levels, as discussed in
# the referenced research paper (see `docs/src/ref.md`).
# (このスクリプトは、`basic_simulation.jl` モジュールに基づいた一連のシミュレーション（Sim1, Sim2, Sim3）を実行します。
#  `FINE_AMOUNT`（罰金額）のパラメータを定義された範囲で体系的に変化させます。
#  シミュレーションの種類と罰金額の各組み合わせについて、指定された回数の繰り返し実行を行います。
#  各繰り返しの最終世代から集約されたデータが収集され、CSVファイルに保存されます。
#  このプロセスは、参照論文（`docs/src/ref.md` を参照）で議論されているように、
#  罰金額が協力レベルに与える影響に関する分析を再現し、拡張することを目的としています。)
#
# Output (出力されるもの):
# - A CSV file, for example, `fine_amount_experiment_results_yyyymmdd_HHMMSS.csv`, 
#   is generated in the `results/` directory.
#   Each row in this CSV file represents a single simulation replication, detailing
#   its parameters and a summary of the results from its final generation.
# (例: `fine_amount_experiment_results_yyyymmdd_HHMMSS.csv` という名前のCSVファイルが
#  `results/` ディレクトリに生成されます。
#  このCSVファイルの各行は、単一のシミュレーションの繰り返し実行を表し、
#  そのパラメータと最終世代からの結果の要約が詳述されます。)

println("Starting the FINE_AMOUNT experiment series...")

# Ensure the environment is set up to find modules in the correct project.
# This is typically handled by running Julia from the project root directory
# or by activating the project environment.
# For robustness, if you intend to run this script directly from the `scripts/` directory,
# you might need to activate the project environment explicitly:
# (モジュールが正しいプロジェクトで見つかるように、環境が設定されていることを確認してください。
#  これは通常、プロジェクトのルートディレクトリからJuliaを実行するか、プロジェクト環境をアクティブにすることで処理されます。
#  堅牢性のため、このスクリプトを `scripts/` ディレクトリから直接実行する場合は、
#  プロジェクト環境を明示的にアクティブにする必要があるかもしれません:)
# import Pkg
# Pkg.activate("..") # Activates the JuliaStudyMeeting project environment.
# (上記2行のコメントを解除して Pkg.activate("..") を実行すると、
#  このスクリプトファイルの一つ上の階層にあるプロジェクト環境を有効化します。)

include("../src/BasicSimulation.jl") # シミュレーションの基本ロジックが定義されたファイルを読み込みます。
include("config.jl") # 共通パラメータ (NUM_AGENTS など) が定義された設定ファイルを読み込みます。
using .BasicSimulation # BasicSimulation モジュール内の関数や型を使えるようにします。
using CSV              # CSVファイルを扱うためのパッケージです。
using DataFrames       # データフレーム (表形式データ) を作成・操作するためのパッケージです。
using Dates            # 日付や時刻を扱うためのパッケージで、出力ファイル名にタイムスタンプを付与するのに使います。
using ProgressMeter    # シミュレーションの進捗状況を表示するためのプログレスバーを提供します。
# Threads.@threads は Julia 1.3 以降の Base モジュールで利用可能です。

# --- Experiment Configuration (実験設定) ---
# 罰金額 (FINE_AMOUNT) の変動範囲: 1.0 から 10.0 まで 0.5 刻み
const FINE_AMOUNT_RANGE = 1.0:0.5:10.0
# 各パラメータ設定での繰り返し実行回数 (論文に従い100回)
const NUM_REPLICATIONS = 100 
# 実行するシミュレーションの種類 (Sim1, Sim2, Sim3)
const SIMULATION_TYPES = [:sim1, :sim2, :sim3]

# 結果を保存するディレクトリとファイル名の設定
const RESULTS_DIR = joinpath(@__DIR__, "..", "results") # 結果保存用ディレクトリ (`scripts`の一つ上の階層の`results`)
# 出力CSVファイルのパスは、実行時にタイムスタンプ付きで動的に生成されます。

# --- Helper Function for Parameter Setup (共通パラメータ取得ヘルパー関数) ---
# config.jl から共通のシミュレーションパラメータを取得します。
function get_common_simulation_params()
    return (
        cooperation_multiplier=COOPERATION_MULTIPLIER,
        cost_of_cooperation=COST_OF_COOPERATION,
        cost_of_punishment=COST_OF_PUNISHMENT,
        mutation_rate=MUTATION_RATE,
        num_trials_per_generation=NUM_TRIALS_PER_GENERATION
    )
end

# --- Main Experiment Loop (メインの実験実行ループ) ---
function run_experiments()
    # 結果保存用ディレクトリが存在しない場合は作成します。
    if !isdir(RESULTS_DIR)
        println("Creating results directory: $(RESULTS_DIR)")
        mkpath(RESULTS_DIR)
    end

    common_params = get_common_simulation_params() # 共通パラメータを取得します。
    all_results = DataFrame() # 全ての結果を格納するための空のデータフレームを初期化します。

    # 実行時刻に基づいたユニークなファイル名を生成します。
    timestamp_str = Dates.format(Dates.now(), "yyyymmdd_HHMMSS")
    output_filename = "fine_amount_experiment_results_$(timestamp_str).csv"
    dynamic_output_csv_path = joinpath(RESULTS_DIR, output_filename) # 完全な出力パス

    # --- 実行する全タスクのリストを作成します --- (並列処理のため)
    tasks = [] # タスクを格納する空の配列
    for sim_type_task in SIMULATION_TYPES       # 各シミュレーションタイプについてループ
        for fine_amount_task in FINE_AMOUNT_RANGE # 各罰金額についてループ
            for rep_idx_task in 1:NUM_REPLICATIONS  # 各繰り返し回数についてループ
                # タスクのパラメータをタプルとしてリストに追加します。
                push!(tasks, (sim_type=sim_type_task, fine_amount=fine_amount_task, rep_idx=rep_idx_task))
            end
        end
    end
    total_runs = length(tasks) # 実行する総シミュレーション回数

    println("Total simulation runs to perform (will be run in parallel): $(total_runs)")

    # 各タスク/スレッドからの結果 (1行のデータフレーム) を格納するためのベクトルを準備します。
    result_dfs_vector = Vector{DataFrame}(undef, total_runs)

    # `@showprogress` で進捗バーを表示し、`Threads.@threads` で並列処理を行います。
    @showprogress dt=0.5 desc="Simulations (threaded): " color=:cyan Threads.@threads for i in 1:total_runs
        task_params = tasks[i] # 現在のスレッドが担当するタスクのパラメータを取得
        sim_type = task_params.sim_type
        fine_amount_val = task_params.fine_amount
        rep_idx = task_params.rep_idx
        
        # このレプリケーションの最終的なPopulationオブジェクトを格納するローカル変数
        local final_pop_for_this_replication::Population 

        # デバッグ用のプリント文は既にコメントアウトされています。

        if sim_type == :sim1
            final_pop_for_this_replication = run_simulation1(NUM_AGENTS, NUM_GENERATIONS;
                                                        common_params...,
                                                        fine_amount=fine_amount_val,
                                                        verbose=false) # 詳細出力はオフ
        elseif sim_type == :sim2
            final_pop_for_this_replication = run_simulation2(NUM_AGENTS, NUM_GENERATIONS;
                                                        common_params...,
                                                        fine_amount=fine_amount_val,
                                                        verbose=false) # 詳細出力はオフ
        elseif sim_type == :sim3
            final_pop_for_this_replication = run_simulation3(NUM_AGENTS, NUM_GENERATIONS;
                                                        common_params...,
                                                        fine_amount=fine_amount_val,
                                                        verbose=false) # 詳細出力はオフ
        else
            # SIMULATION_TYPESが正しければ、この分岐には到達しないはずです。
            # 問題発生時のスレッドセーフな対応として、空のDataFrameまたはエラーマーカーを割り当てることができます。
            println("Warning: Unknown simulation_type '$(sim_type)' encountered in task $(i). Skipping this task.")
            result_dfs_vector[i] = DataFrame() # 未定義参照エラーを避けるため、空のDataFrameを割り当てます。
            continue # このスレッドのループの現在のイテレーションをスキップします。
        end
    
        # シミュレーション結果から最終世代のデータを抽出します。
        results_tuple = extract_final_generation_data(final_pop_for_this_replication, sim_type)

        # 抽出した結果を1行のデータフレームにまとめます。
        current_result_df = DataFrame(
            simulation_type = String(sim_type), # シミュレーションの種類 (文字列として保存)
            replication_id = rep_idx,           # 繰り返しID
            fine_amount = fine_amount_val,      # 罰金額
            avg_coop_propensity_all = results_tuple.avg_coop_propensity_all, # 全体の平均協力傾向
            avg_punishment_propensity = results_tuple.avg_punishment_propensity, # 全体の平均制裁傾向
            prop_group_retaliation = results_tuple.prop_group_retaliation,    # 集団応報戦略の割合
            avg_ret_threshold_gr = results_tuple.avg_ret_threshold_gr,      # 集団応報戦略の平均閾値
            prop_probabilistic = results_tuple.prop_probabilistic,        # 確率戦略の割合
            avg_coop_propensity_prob = results_tuple.avg_coop_propensity_prob, # 確率戦略の平均協力傾向
            cooperators_last_trial = results_tuple.cooperators_last_trial,  # 最終試行の協力者数
            is_cooperation_achieved = results_tuple.is_cooperation_achieved # 協力達成フラグ
        )
        result_dfs_vector[i] = current_result_df # 結果をベクトルに格納
        # next!(prog) は @showprogress がループを管理するため不要になりました。
    end 
    # finish!(prog) も @showprogress を使う場合は通常不要です。

    # 全スレッド/タスクからの結果 (データフレームのベクトル) を結合します。
    # エラーやスキップにより生成された可能性のある空のデータフレームを除外します。
    valid_result_dfs = filter(df -> !isempty(df), result_dfs_vector)
    if isempty(valid_result_dfs)
        println("Warning: No valid simulation results were collected. The CSV file will be empty or may not be generated.")
        all_results = DataFrame() # all_results が空のデータフレームであることを保証します。
    else
        all_results = vcat(valid_result_dfs...) # 有効な結果データフレームを全て縦に結合します。
    end

    # 全ての結果をCSVファイルに保存します。
    println("\nWriting results to $(dynamic_output_csv_path)...")
    try
        CSV.write(dynamic_output_csv_path, all_results)
        println("Successfully wrote results to CSV: $(dynamic_output_csv_path)")
    catch e
        println("Error writing CSV file at $(dynamic_output_csv_path): ", e)
    end
    
    println("Experiment series finished.")
end

# --- Entry Point (スクリプト実行時のエントリーポイント) ---
# このファイルが直接実行された場合にのみ run_experiments() を呼び出します。
if abspath(PROGRAM_FILE) == @__FILE__
    run_experiments()
end

println("Script execution completed. If run_experiments() was called, results should have been saved.") 