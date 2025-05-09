module BasicSimulation

using Statistics # 平均値 (mean) や標準偏差 (std) を計算するために使います。
using Random     # ランダムな並び替え (shuffle!) を行うために使います。(perform_reproduction_mutation! 関数内で使用)
using StatsBase  # ランダムなサンプリング (sample) を行うために使います。(perform_reproduction_mutation! 関数内で使用)

# エージェントが取りうる戦略の種類を定義します。
# Probabilistic: 確率に基づいて行動する戦略
# GroupRetaliation: 集団応報戦略 (周りの協力度合いに応じて行動を変える戦略)
@enum StrategyType Probabilistic GroupRetaliation

export Agent # Agent構造体を、このモジュールの外からでも使えるようにします。
export Population # Population構造体も同様に、モジュールの外から使えるようにします。

"""
エージェント（シミュレーション内の個々の主体）の状態や属性をまとめて保持するための設計図（構造体）です。
シミュレーションの種類によって、この中のどの属性が使われるかが変わります。
"""
mutable struct Agent
    id::Int             # エージェントを識別するための番号（ID）
    cooperation_propensity::Float64          # エージェントがどれくらい協力行動を取りやすいかを示す数値 (0.0 から 1.0 の間)
    punishment_propensity::Float64          # エージェントがどれくらい非協力者を罰しやすいかを示す数値 (0.0 から 1.0 の間)
    retaliation_threshold::Int              # 集団応報戦略において、協力行動をとるために必要な「周りの協力者数」のボーダーライン (0 から (集団サイズ - 1) の間)
    strategy_type::StrategyType              # エージェントが現在採用している戦略の種類 (Probabilistic または GroupRetaliation)
    score::Float64      # 現在の世代でエージェントが得た得点の合計
    cooperated::Bool    # 現在の試行（ゲームの1回）で、このエージェントが協力行動をとったかどうか (trueなら協力、falseなら非協力)
    previous_cooperated::Bool # 1つ前の試行で、このエージェントが協力行動をとったかどうか

    # Agent構造体の初期インスタンスを作成するための特別な関数（コンストラクタ）です。
    # いくつかの属性については、初期値を指定できるようにしています。
    Agent(
        id::Int; # エージェントIDは必須です。
        cooperation_propensity=rand(), # 指定がなければ、協力傾向はランダムに設定されます。
        punishment_propensity=rand(), # 指定がなければ、制裁傾向はランダムに設定されます。
        retaliation_threshold=0, # 指定がなければ、集団応報の閾値は0に設定されます。
        strategy_type=Probabilistic, # 指定がなければ、戦略タイプは確率的戦略に設定されます。
        score=0.0, # 指定がなければ、初期スコアは0.0です。
        cooperated=false, # 指定がなければ、初期状態では協力していません。
        previous_cooperated=false # 指定がなければ、初期状態では前回も協力していません。
    ) = new( # new(...) を使って、新しいAgentインスタンスの各フィールドに値を設定します。
        id,
        cooperation_propensity,
        punishment_propensity,
        retaliation_threshold,
        strategy_type,
        score,
        cooperated,
        previous_cooperated
    )
end

"""
エージェントの集団全体と、シミュレーション実験全体に関わる設定値（パラメータ）をまとめて管理するための設計図（構造体）です。
"""
mutable struct Population
    agents::Vector{Agent}                   # シミュレーションに参加している全エージェントのリスト (Agent型の配列)
    num_agents::Int                         # 集団のサイズ（エージェントの総数）
    current_generation::Int                 # シミュレーションが現在何世代目かを示す数値
    current_trial::Int                      # 現在の世代の中で、何回目の試行（ゲーム）かを示す数値
    previous_num_cooperators::Int           # 1つ前の試行での、集団全体の協力者数
    
    # シミュレーションのルールを定めるパラメータ (元論文の値や、実験で使う標準値を設定します)
    cooperation_multiplier::Float64         # 協力行動によって生み出される共有資源の増え具合（倍率）
    cost_of_cooperation::Float64            # 協力行動をとるためにエージェントが支払うコスト
    cost_of_punishment::Float64             # 非協力者を罰するためにエージェントが支払うコスト
    fine_amount::Float64                    # 非協力者が罰として科される罰金の額（この値は実験条件によって変わることがあります）
    mutation_rate::Float64                  # 世代交代時に、エージェントの属性がランダムに変化する（突然変異する）確率
    num_trials_per_generation::Int          # 1つの世代が終了するまでに繰り返される試行（ゲーム）の回数

    # Population構造体の初期インスタンスを作成するための特別な関数（コンストラクタ）です。
    function Population(num_agents::Int; # 集団サイズは必須です。
                        cooperation_multiplier::Float64, # 以降のパラメータも全て指定が必要です。
                        cost_of_cooperation::Float64,
                        cost_of_punishment::Float64,
                        fine_amount::Float64,
                        mutation_rate::Float64,
                        num_trials_per_generation::Int)
        
        agents = Vector{Agent}(undef, num_agents) # まず、指定された数のエージェントを格納できる空のリストを用意します。
        # `previous_num_cooperators` は、シミュレーション開始時は0で初期化します。
        new( # new(...) を使って、新しいPopulationインスタンスの各フィールドに値を設定します。
            agents,
            num_agents,
            0,  # current_generation (最初は0世代目)
            0,  # current_trial (最初は0試行目)
            0,  # previous_num_cooperators (最初は0人)
            cooperation_multiplier,
            cost_of_cooperation,
            cost_of_punishment,
            fine_amount,
            mutation_rate,
            num_trials_per_generation
        )
    end
end

export initialize_population! # この関数もモジュールの外から使えるようにします。

"""
Populationオブジェクト（集団全体の情報を持つもの）を受け取り、その中に含まれるエージェントのリスト (`agents`) を初期化します。
各エージェントの主な属性値（協力傾向 `cooperation_propensity`、制裁傾向 `punishment_propensity`）は、
元となった論文の研究に従って、ランダムな値に設定されます。
集団応報戦略の閾値 `retaliation_threshold` は、0 から (集団サイズ N - 1) の範囲でランダムに設定されます。
"""
function initialize_population!(pop::Population)
    for i in 1:pop.num_agents # 集団の全エージェントに対してループ処理を行います。
        initial_m = rand(0:(pop.num_agents - 1)) # 集団応報戦略の閾値 m をランダムに決定します。
        # cooperation_propensity, punishment_propensity, strategy_type といった他の属性は、
        # Agent構造体のデフォルトのコンストラクタ（初期設定を行う関数）で設定される値を使います。
        pop.agents[i] = Agent(i, retaliation_threshold=initial_m) # 新しいエージェントを作成し、リストに追加します。
    end
    return pop # 更新されたPopulationオブジェクトを返します（これはJuliaの慣習的な書き方です）。
end

export calculate_scores! # この関数もモジュールの外から使えるようにします。

"""
現在の試行（ゲームの1回）における各エージェントの得点を計算し、それぞれの `score` に加算します。
この関数が呼ばれる前に、各エージェントが協力したか非協力したか (`agent.cooperated` フラグ) は既に決まっているとします。
"""
function calculate_scores!(pop::Population)
    num_cooperators = 0 # まず、協力者の数を数えるための変数を0で初期化します。
    for agent in pop.agents # 全エージェントをチェックします。
        if agent.cooperated # もしエージェントが協力していたら、
            num_cooperators += 1 # 協力者数を1増やします。
        end
    end

    # 協力によって生み出された共有資源からの分配額を計算します。
    # (これは論文中の k*b/N という式に相当します。ここで、
    #  `pop.cooperation_multiplier` が b (協力の倍率) に、
    #  `pop.num_agents` が N (集団サイズ) に対応します。)
    benefit_per_agent = num_cooperators * pop.cooperation_multiplier / pop.num_agents

    for agent in pop.agents # 再度、全エージェントをチェックします。
        current_trial_score = benefit_per_agent # まず、共有資源からの分配分を得点とします。
        if agent.cooperated # もしエージェントが協力行動をとっていたら、
            # 協力のためのコスト (`pop.cost_of_cooperation`、論文中の C_c に相当) を支払うため、得点から引きます。
            current_trial_score -= pop.cost_of_cooperation
        end
        agent.score += current_trial_score # 計算された今回の試行の得点を、世代の累積スコアに加算します。
    end
    return pop # 更新されたPopulationオブジェクトを返します。
end

export run_simulation! # この関数もモジュールの外から使えるようにします。

"""
シミュレーションを実行するメインの処理ループです。
引数 `enable_sanctioning` が `true` の場合、非協力者に対する制裁行動が実行されます。
引数 `simulation_type` を追加し、これによって世代交代時の突然変異のルールが変わるようにしました。
引数 `verbose` が `true` の場合、各世代の結果などの詳細情報をコンソールに出力します。
"""
function run_simulation!(pop::Population, num_generations::Int, simulation_type::Symbol; enable_sanctioning::Bool = false, verbose::Bool = true) # simulation_type と verbose 引数を追加しました。
    for generation_index in 1:num_generations # 指定された世代数だけループを繰り返します。(変数名を g から generation_index に変更)
        pop.current_generation = generation_index # 現在の世代番号を記録します。
        for agent in pop.agents; agent.score = 0.0; end # 各世代の開始時に、全エージェントのスコアを0にリセットします。

        for trial_index in 1:pop.num_trials_per_generation # 1世代あたりの試行回数だけループを繰り返します。(変数名を t_trial から trial_index に変更)
            pop.current_trial = trial_index # 現在の試行番号を記録します。
            choose_action_mixed_strategy!(pop) # 各エージェントが行動を選択します (この中で agent.cooperated が決定されます)。
            calculate_scores!(pop) # 各エージェントのスコアを計算します。

            if enable_sanctioning # もし制裁が有効なら (引数に基づいて判断)、
                perform_sanctioning!(pop) # 制裁行動を実行します。
            end
        end
        # 世代の全試行が終了したら、世代交代処理（淘汰と突然変異）を行います。
        # `verbose` の値を `show_std_warnings` 引数に渡して、警告メッセージの表示を制御します。
        perform_reproduction_mutation!(pop, simulation_type, show_std_warnings=verbose)
        if verbose; log_generation_results(pop); end # もし詳細表示が有効なら、世代の結果をログに出力します。
    end
    if verbose; println("Simulation finished."); end # 全世代終了後、詳細表示が有効なら終了メッセージを出力します。
    return pop # シミュレーション後のPopulationオブジェクトを返します。
end

export perform_reproduction_mutation! # この関数もモジュールの外から使えるようにします。

"""
世代交代の処理（淘汰と突然変異）を行います。
淘汰は、各エージェントのスコアに基づいて行われます。具体的には、全体の平均スコア ±1標準偏差 (SD) を基準にします。
突然変異は、一定の確率 (`pop.mutation_rate`) で発生します。
突然変異が発生した場合、引数 `simulation_type` (シミュレーションの種類) に応じて、
適切な属性（c:協力傾向, p:制裁傾向, m:集団応報閾値, t:戦略タイプ）が、元論文の記述通りに再設定されます。
引数 `show_std_warnings` が `true` の場合、スコアの標準偏差に関する警告メッセージをコンソールに出力します。
"""
function perform_reproduction_mutation!(pop::Population, simulation_type::Symbol; show_std_warnings::Bool = true) # show_std_warnings 引数を追加しました。
    num_agents = pop.num_agents # 集団のエージェント数を取得します。
    if num_agents == 0 # もしエージェントがいなければ、
        return pop # 何もせずに処理を終了します。
    end
    
    scores = [agent.score for agent in pop.agents] # 全エージェントのスコアのリストを作成します。
    
    # --- 論文に基づいた淘汰のロジック (一部修正済み) ---
    mean_score = mean(scores) # スコアの平均値を計算します。
    std_dev_score = std(scores) # スコアの標準偏差を計算します。

    offspring_counts = zeros(Int, num_agents) # 各エージェントが残す子孫の数を格納する配列を、まず全て0で初期化します。

    # --- 平均値や標準偏差が非有限(NaN, Inf)でないか、または標準偏差がほぼゼロでないかを確認します ---
    if !isfinite(mean_score) || !isfinite(std_dev_score) || std_dev_score < 1e-9
        if !isfinite(mean_score) || !isfinite(std_dev_score) # 平均か標準偏差が非有限の場合
            if show_std_warnings # 警告表示が有効な場合
                println("Warning: Non-finite mean or std score detected (Mean: $(mean_score), StdDev: $(std_dev_score)). Skipping score-based selection for this generation.")
            end
        else # std_dev_score < 1e-9 (標準偏差がほぼゼロ) の場合
            if show_std_warnings # 警告表示が有効な場合
                println("Warning: Standard deviation of scores is near zero (Value: $(std_dev_score)). Skipping score-based selection, all agents get 1 offspring.")
            end
        end
        # フォールバック処理: スコアに基づく選択をスキップし、全員が1人の子孫を残すことにします (ランダムな遺伝的浮動)。
        fill!(offspring_counts, 1)
        # この場合、`num_to_reproduce_or_eliminate` は実質的に0として扱われ、選択のブロックはスキップされます。
    else
        # --- 元のロジックは、スコアが有限で、かつ標準偏差が十分にゼロから離れている場合にのみ実行します ---
        epsilon = 1e-9 # 浮動小数点数の比較のための微小な値
        # 平均スコア + 標準偏差以上のスコアを持つエージェントのインデックス（番号）を見つけます。
        high_scorers_indices = findall(s -> s >= mean_score + std_dev_score - epsilon, scores)
        # 平均スコア - 標準偏差以下のスコアを持つエージェントのインデックスを見つけます。
        low_scorers_indices = findall(s -> s <= mean_score - std_dev_score + epsilon, scores)
        
        num_high_scorers = length(high_scorers_indices) # 高得点者の数を数えます。
        num_low_scorers = length(low_scorers_indices) # 低得点者の数を数えます。

        # 子孫を増やす（または減らす）対象となるエージェントの数は、高得点者と低得点者のうち少ない方の数に合わせます。(論文の脚注7より)
        num_to_reproduce_or_eliminate = min(num_high_scorers, num_low_scorers)
            
        fill!(offspring_counts, 1) # まず、全てのエージェントが1人の子孫を残すと仮定します。
            
        if num_to_reproduce_or_eliminate > 0 # もし、子孫数を調整する対象がいる場合
            # 低得点者の中から `num_to_reproduce_or_eliminate` 人をランダムに選び、その子孫数を0にします。
            if num_low_scorers >= num_to_reproduce_or_eliminate # 十分な数の低得点者がいることを確認します。
                indices_to_set_zero = sample(low_scorers_indices, num_to_reproduce_or_eliminate, replace=false) # 重複なしでランダムに選びます。
                for idx in indices_to_set_zero
                    if 1 <= idx <= num_agents # 配列の範囲外アクセスを防ぐための追加の安全チェック
                        offspring_counts[idx] = 0
                    else
                        # このメッセージが表示されるのは、pop.agents と num_agents の整合性が取れていない場合など、通常は起こりえません。
                        println("Error: Invalid index $(idx) from low_scorers_indices. num_agents: $(num_agents). Skipping assignment.")
                    end
                end
            elseif num_low_scorers > 0 # 対象人数には満たないが、低得点者が存在する場合
                println("Warning: Not enough unique low scorers ($(num_low_scorers)) to meet num_to_reproduce_or_eliminate ($(num_to_reproduce_or_eliminate)). Assigning 0 to all available low scorers.")
                for idx in low_scorers_indices # 存在する低得点者全員の子孫数を0にします。
                     if 1 <= idx <= num_agents
                        offspring_counts[idx] = 0
                    else
                        println("Error: Invalid index $(idx) from low_scorers_indices during partial assignment. num_agents: $(num_agents). Skipping assignment.")
                    end
                end
                # 注意: この場合、子孫を0にするエージェントの数が `num_to_reproduce_or_eliminate` より少なくなります。
                # 高得点者への対称的な割り当てが調整されない場合、集団サイズが変動する可能性があります。
                # 現状は簡単のためそのまま進めますが、この不均衡は将来的な改善点です。
            end # それ以外の場合 (低得点者がいない場合) は、子孫数を0にする対象がいません。
            
            # 高得点者の中から `num_to_reproduce_or_eliminate` 人をランダムに選び、その子孫数を2にします。
            if num_high_scorers >= num_to_reproduce_or_eliminate # 十分な数の高得点者がいることを確認します。
                indices_to_set_two = sample(high_scorers_indices, num_to_reproduce_or_eliminate, replace=false) # 重複なしでランダムに選びます。
                for idx in indices_to_set_two
                    if 1 <= idx <= num_agents # 配列の範囲外アクセスを防ぐための追加の安全チェック
                        offspring_counts[idx] = 2
                    else
                        # 通常は起こりえません。
                        println("Error: Invalid index $(idx) from high_scorers_indices. num_agents: $(num_agents). Skipping assignment.")
                    end
                end
            elseif num_high_scorers > 0 # 対象人数には満たないが、高得点者が存在する場合
                 println("Warning: Not enough unique high scorers ($(num_high_scorers)) to meet num_to_reproduce_or_eliminate ($(num_to_reproduce_or_eliminate)). Assigning 2 to all available high scorers.")
                 for idx in high_scorers_indices # 存在する高得点者全員の子孫数を2にします。
                    if 1 <= idx <= num_agents
                        offspring_counts[idx] = 2
                    else
                        println("Error: Invalid index $(idx) from high_scorers_indices during partial assignment. num_agents: $(num_agents). Skipping assignment.")
                    end
                end
                # 上記と同様に、低得点者の処理数と異なる場合、不均衡が生じます。
            end # それ以外の場合 (高得点者がいない場合) は、子孫数を2にする対象がいません。
        end
    end 
    # --- ここまでが論文に基づいた淘汰のロジックです ---

    # 次の世代のエージェント集団を、選ばれた親の子孫に突然変異を適用して作成します。
    next_generation_agents = Vector{Agent}() # 次世代のエージェントを格納する空のリストを用意します。
    sizehint!(next_generation_agents, num_agents) # 事前に大体のサイズを確保しておくと、効率が良くなることがあります。

    new_agent_id_counter = 1 # 新しいエージェントに割り当てるIDのカウンターです。
    for parent_idx in 1:num_agents # 現在の世代の全エージェント（親）に対してループ処理を行います。
        parent_agent = pop.agents[parent_idx] # 親エージェントを取得します。
        for _ in 1:offspring_counts[parent_idx]
            # まず、親の属性をそのままコピーします（突然変異が起こる前の状態）。
            current_c = parent_agent.cooperation_propensity
            current_p = parent_agent.punishment_propensity
            current_m = parent_agent.retaliation_threshold
            current_t = parent_agent.strategy_type # これが論文中の t (戦略タイプ) に相当します (Probabilisticなら0, GroupRetaliationなら1のようなイメージ)。

            # --- 論文に基づいた突然変異のロジック ---
            # 新しい属性値を、まず現在の値で初期化します。
            new_c = current_c
            new_p = current_p
            new_m = current_m
            new_t = current_t

            if simulation_type == :sim1 # 第1シミュレーションの場合
                # Sim1: 協力傾向 c と制裁傾向 p が、それぞれ 5% (mutation_rate) の確率でランダムな値に変わります。
                if rand() < pop.mutation_rate; new_c = rand(); end
                if rand() < pop.mutation_rate; new_p = rand(); end
                # 集団応報閾値 m と戦略タイプ t は変化しません (Sim1では全員が確率的戦略 Probabilistic)。
                new_m = current_m
                new_t = Probabilistic
            elseif simulation_type == :sim2 # 第2シミュレーションの場合
                # Sim2: 集団応報閾値 m と制裁傾向 p が、それぞれ 5% の確率でランダムな値に変わります。
                if rand() < pop.mutation_rate; new_m = rand(0:(pop.num_agents - 1)); end # m の範囲は 0 から (集団サイズ N - 1) です。
                if rand() < pop.mutation_rate; new_p = rand(); end
                # 協力傾向 c と戦略タイプ t は変化しません (Sim2では全員が集団応報戦略 GroupRetaliation)。
                new_c = current_c
                new_t = GroupRetaliation
            elseif simulation_type == :sim3 # 第3シミュレーションの場合
                # Sim3: m, c, p がそれぞれ 5% の確率でランダムな値に変わり、t は 5% の確率で現在の戦略と反対の戦略に変わります（トグル）。
                if rand() < pop.mutation_rate; new_m = rand(0:(pop.num_agents - 1)); end
                if rand() < pop.mutation_rate; new_c = rand(); end
                if rand() < pop.mutation_rate; new_p = rand(); end
                if rand() < pop.mutation_rate # 戦略タイプ t の変異
                    new_t = (current_t == Probabilistic) ? GroupRetaliation : Probabilistic # 現在がProbabilisticならGroupRetaliationに、そうでなければProbabilisticに。
                end
            else
                # 未知の `simulation_type` が指定された場合の処理 (エラーメッセージを出すか、デフォルトの動作をします)。
                println("Warning: Unknown simulation_type ' $(simulation_type)' in mutation. Using default mutation (all random).")
                if rand() < pop.mutation_rate; new_c = rand(); end
                if rand() < pop.mutation_rate; new_p = rand(); end
                if rand() < pop.mutation_rate; new_m = rand(0:(pop.num_agents - 1)); end
                if rand() < pop.mutation_rate; new_t = rand(instances(StrategyType)); end # StrategyTypeの全種類からランダムに選択
            end
            # --- 突然変異のロジックここまで ---
                
            # 新しい属性値を持つエージェントを作成し、次世代のリストに追加します。
            push!(next_generation_agents, Agent(
                new_agent_id_counter, # 新しいIDを割り当てます。
                cooperation_propensity=new_c,
                punishment_propensity=new_p,
                retaliation_threshold=new_m,
                strategy_type=new_t,
                score=0.0, # スコアは0で初期化
                cooperated=false, #協力状態も初期化
                previous_cooperated=false #前回の協力状態も初期化
            ))
            new_agent_id_counter += 1 # 次のエージェントのためにIDを増やします。
        end
    end

    # 集団サイズのチェック (淘汰と再生産のロジックが正しければ、変わらないはずです)。
    if length(next_generation_agents) != num_agents
        println("Warning: Population size changed after reproduction! Expected $(num_agents), Got $(length(next_generation_agents))")
    end

    pop.agents = next_generation_agents # エージェント集団を新しい世代のものに更新します。
    return pop # 更新されたPopulationオブジェクトを返します。
end

export log_generation_results # この関数もモジュールの外から使えるようにします。

"""
現在の世代のシミュレーション結果を整形してコンソールに出力します。
出力する主な情報は以下の通りです：
- 集団全体の平均協力傾向
- 集団全体の平均制裁傾向
- 集団応報戦略をとっているエージェントの割合
- 集団応報戦略をとっているエージェントの平均応報閾値
- (Sim3の場合) 確率戦略をとっているエージェントの平均協力傾向
- 前の試行での総協力者数

各情報はラベル付きで複数行にわたって表示されるため、このままではCSVファイルとして直接保存するのには向きません。
"""
function log_generation_results(pop::Population)
    num_agents = pop.num_agents # 集団のエージェント数を取得します。
    if num_agents == 0 # もしエージェントがいなければ、
        println("Generation $(pop.current_generation): No agents in population.")
        return # 何もせずに処理を終了します。
    end

    total_cooperation_propensity = 0.0 # 全エージェントの協力傾向の合計
    total_punishment_propensity = 0.0  # 全エージェントの制裁傾向の合計
    count_group_retaliation_strategy_agents = 0 # 集団応報戦略のエージェント数
    total_retaliation_threshold_grp = 0 # 集団応報戦略エージェントの応報閾値の合計

    # --- Sim3（混合戦略シミュレーション）用に集計する値 ---
    count_probabilistic_agents = 0 # 確率戦略のエージェント数
    total_cooperation_propensity_prob = 0.0 # 確率戦略エージェントの協力傾向の合計
    # -------------------------------------------------

    for agent in pop.agents # 全エージェントに対してループ処理を行います。
        total_cooperation_propensity += agent.cooperation_propensity # 全体の協力傾向に加算します。
        total_punishment_propensity += agent.punishment_propensity # 全体の制裁傾向に加算します。
        if agent.strategy_type == GroupRetaliation # もし集団応報戦略なら、
            count_group_retaliation_strategy_agents += 1
            total_retaliation_threshold_grp += agent.retaliation_threshold
        else # agent.strategy_type == Probabilistic (確率戦略の場合)
            # --- Sim3 用の集計 ---
            count_probabilistic_agents += 1
            total_cooperation_propensity_prob += agent.cooperation_propensity
            # --------------------
        end
    end

    average_cooperation_propensity = total_cooperation_propensity / num_agents # 全体の平均協力傾向
    average_punishment_propensity = total_punishment_propensity / num_agents   # 全体の平均制裁傾向
    proportion_group_retaliation_agents = count_group_retaliation_strategy_agents / num_agents # 集団応報戦略エージェントの割合
    
    average_retaliation_threshold_grp = 0.0 # 集団応報戦略エージェントの平均応報閾値
    if count_group_retaliation_strategy_agents > 0 # 該当エージェントがいれば計算)
        average_retaliation_threshold_grp = total_retaliation_threshold_grp / count_group_retaliation_strategy_agents
    end

    # --- Sim3 用の計算 ---
    average_cooperation_propensity_prob = 0.0 # 確率戦略エージェントの平均協力傾向
    if count_probabilistic_agents > 0 # 該当するエージェントがいれば計算)
        average_cooperation_propensity_prob = total_cooperation_propensity_prob / count_probabilistic_agents
    end
    # --------------------

    # コンソール出力用に値を準備します。
    generation_id = pop.current_generation # 現在の世代番号
    avg_coop_prop_rounded = round(average_cooperation_propensity, digits=3) # 小数点以下3桁に丸めます。
    avg_pun_prop_rounded = round(average_punishment_propensity, digits=3)
    prop_grp_ret_rounded = round(proportion_group_retaliation_agents, digits=3)
    avg_ret_thresh_grp_rounded = round(average_retaliation_threshold_grp, digits=3)
    cooperators_last = pop.previous_num_cooperators # 前の試行での協力者数

    # --- Sim3 用の値 ---
    avg_coop_prop_prob_rounded = round(average_cooperation_propensity_prob, digits=3)
    # ------------------

    println("Generation $(generation_id):")
    println("  Avg Coop. Propensity (All) = $(avg_coop_prop_rounded)")
    println("  Avg Coop. Prop (Prob)      = $(avg_coop_prop_prob_rounded)")
    println("  Avg Pun. Propensity       = $(avg_pun_prop_rounded)")
    println("  Prop. Group Retaliation   = $(prop_grp_ret_rounded)")
    println("  Avg Ret. Threshold (GR)   = $(avg_ret_thresh_grp_rounded)")
    println("  Cooperators (last trial)    = $(cooperators_last)")
end

export choose_action_mixed_strategy! # この関数もモジュールの外から使えるようにします。

"""
各エージェントが、自身の戦略タイプ (`strategy_type`) と内部状態に基づいて、
今回の試行で協力行動をとるか非協力行動をとるかを選択します。
この関数内で、各エージェントの `cooperated` フラグが更新されます。
また、次回の試行のために、今回の協力状態を `previous_cooperated` に保存し、
集団全体の協力者数を `pop.previous_num_cooperators` に記録します。
"""
function choose_action_mixed_strategy!(pop::Population)
    # 現在が「第1世代」かつ「第1試行」であるかどうかのフラグ
    is_first_trial_first_gen = pop.current_generation == 1 && pop.current_trial == 1
    
    for agent in pop.agents # 全エージェントに対してループ処理を行います。
        if agent.strategy_type == Probabilistic # もしエージェントが確率的戦略なら、
            # 自身の協力傾向 `cooperation_propensity` の確率で協力します。
            agent.cooperated = rand() < agent.cooperation_propensity
        elseif agent.strategy_type == GroupRetaliation # もしエージェントが集団応報戦略なら、
            if is_first_trial_first_gen # もし最初の世代の最初の試行なら、
                if pop.num_agents == 0 # エージェントがいない場合のエラーを避けます (rand(0:-1) など)。
                    agent.cooperated = false # または他のデフォルトの行動
                else
                    # 論文の記述: 第1世代第1試行では、「前回の試行での協力者数」を
                    # 0からN(集団サイズ)の間でランダムに決定します。
                    # ここでは、自分を除いた最大人数である (N-1) を上限とします。
                    # このエージェント自身の `previous_cooperated` は false (前回は協力していない) とみなします (初回なので)。
                    mock_previous_total_cooperators = rand(0:(pop.num_agents > 0 ? pop.num_agents -1 : 0))
                    # この場合、「自分を除いた協力者数」は `mock_previous_total_cooperators` と同じになります
                    # (自分が前回協力したとは仮定しないため)。
                    agent.cooperated = mock_previous_total_cooperators >= agent.retaliation_threshold
                end
            else
                # 通常の試行の場合: 自分を除いた前回の協力者数を参照します。
                # `agent.previous_cooperated` には、このエージェントの前回の `agent.cooperated` の値が入っています。
                num_cooperators_excluding_self = pop.previous_num_cooperators - (agent.previous_cooperated ? 1 : 0)
                # `num_cooperators_excluding_self` がマイナスになる可能性も考慮します (通常はほぼありませんが、念のため)。
                actual_cooperators_excluding_self = max(0, num_cooperators_excluding_self)
                agent.cooperated = actual_cooperators_excluding_self >= agent.retaliation_threshold
            end
        else # 未知の戦略タイプなどの場合 (エラー処理など)
            agent.cooperated = false # とりあえず非協力とします。
        end
    end

    current_cooperators = 0 # 今回の試行での協力者数を数えるための変数を初期化します。
    for agent in pop.agents # 全エージェントを再度チェックします。
        if agent.cooperated # もしエージェントが協力していたら、
            current_cooperators += 1 # 協力者数を1増やします。
        end
        # 今回の協力状態 (`agent.cooperated`) を、次回の試行のために `agent.previous_cooperated` に保存します。
        agent.previous_cooperated = agent.cooperated 
    end
    # 集団全体の協力者数を更新します。これは次の試行で参照されます。
    pop.previous_num_cooperators = current_cooperators
    
    return pop # 更新されたPopulationオブジェクトを返します。
end

export perform_sanctioning! # この関数もモジュールの外から使えるようにします。

"""
2次的ジレンマの状況における、非協力者に対する制裁行動を実行します。
各エージェントは、協力しなかった他のエージェントを、
自身の制裁傾向 `punishment_propensity` に基づいて確率的に罰することがあります。
制裁を行ったエージェントはコストを支払い、制裁を受けたエージェントは罰金を科されます。
これらのコストと罰金は、エージェントの `score` に直接反映（増減）されます。
この関数が呼び出された場合のみ、制裁が発生します。
"""
function perform_sanctioning!(pop::Population)
    if pop.num_agents < 2 # 観察対象となる他のエージェントがいない場合 (自分自身しかいない、または誰もいない場合)、
        return pop # 何もせずに処理を終了します。
    end

    for punisher_agent in pop.agents # 各エージェントが制裁者になる可能性を考えます。
        # 自分以外のエージェントのリストを作成します。
        # `filter` を使って、自分自身 (punisher_agent) を除外します。
        # `sample` を使う前に、potential_targets が空でないことを確認します。
        potential_targets = filter(a -> a.id != punisher_agent.id, pop.agents)
        if isempty(potential_targets) # もし他に誰もいなければ、
            continue # 次の制裁者の処理に移ります。
        end
        
        # ランダムに1人のターゲット（制裁対象候補）を選択します。
        target_agent = rand(potential_targets) 

        if !target_agent.cooperated # もしターゲットが非協力者だった場合、
            if rand() < punisher_agent.punishment_propensity # 制裁者が自身の制裁傾向 p の確率で制裁を試みます。
                # 制裁を実行します。
                punisher_agent.score -= pop.cost_of_punishment # 制裁者は制裁コストを支払います。
                target_agent.score -= pop.fine_amount        # ターゲットは罰金を科されます。
            end
        end
    end
    return pop # 更新されたPopulationオブジェクトを返します。
end

export run_simulation1 # この関数もモジュールの外から使えるようにします。

"""
第1シミュレーション（全員が確率的戦略を採用し、制裁行動あり）を実行します。
論文の追試を目的としています。
引数 `verbose` が `true` の場合、実行開始・終了メッセージなどをコンソールに出力します。
"""
function run_simulation1(num_agents::Int, num_generations::Int;
                         cooperation_multiplier::Float64,
                         cost_of_cooperation::Float64,
                         cost_of_punishment::Float64,
                         fine_amount::Float64,
                         mutation_rate::Float64,
                         num_trials_per_generation::Int,
                         verbose::Bool = true) # verbose引数を追加しました。
    
    if verbose; println("--- Running Simulation 1: Probabilistic Strategy, Sanctioning Enabled ---"); end # 詳細表示が有効なら開始メッセージを出力します。
    # Populationオブジェクトを、Sim1用の設定で初期化します。
    pop = Population(num_agents,
                     cooperation_multiplier=cooperation_multiplier,
                     cost_of_cooperation=cost_of_cooperation,
                     cost_of_punishment=cost_of_punishment, # 制裁コスト
                     fine_amount=fine_amount,             # 罰金額
                     mutation_rate=mutation_rate,
                     num_trials_per_generation=num_trials_per_generation)

    initialize_population!(pop) # エージェント集団を初期化します。
    # Sim1では、全エージェントが確率的戦略 (Probabilistic) をとります。
    for agent in pop.agents
        agent.strategy_type = Probabilistic
    end

    # メインのシミュレーションループを実行します。
    # simulation_type に `:sim1` を、enable_sanctioning に `true` を指定します。
    # verbose の値を渡します。
    run_simulation!(pop, num_generations, :sim1, enable_sanctioning=true, verbose=verbose)
    
    if verbose; println("--- Simulation 1 Finished ---"); end # 詳細表示が有効なら終了メッセージを出力します。
    return pop # シミュレーション後のPopulationオブジェクトを返します。
end

export run_simulation2 # この関数もモジュールの外から使えるようにします。

"""
第2シミュレーション（全員が集団応報戦略を採用し、制裁行動あり）を実行します。
論文の追試を目的としています。
引数 `verbose` が `true` の場合、実行開始・終了メッセージなどをコンソールに出力します。
"""
function run_simulation2(num_agents::Int, num_generations::Int;
                         fine_amount::Float64,
                         cost_of_punishment::Float64,
                         cooperation_multiplier::Float64,
                         cost_of_cooperation::Float64,
                         mutation_rate::Float64,
                         num_trials_per_generation::Int,
                         verbose::Bool = true) # verbose引数を追加しました。
    
    if verbose; println("--- Running Simulation 2: Group Retaliation, Sanctioning Enabled ---"); end # 詳細表示が有効なら開始メッセージを出力します。
    # Populationオブジェクトを、Sim2用の設定で初期化します。
    pop = Population(num_agents,
                     fine_amount=fine_amount,
                     cost_of_punishment=cost_of_punishment,
                     cooperation_multiplier=cooperation_multiplier,
                     cost_of_cooperation=cost_of_cooperation,
                     mutation_rate=mutation_rate,
                     num_trials_per_generation=num_trials_per_generation)
    
    initialize_population!(pop) # エージェント集団を初期化します。
    # Sim2では、全エージェントが集団応報戦略 (GroupRetaliation) をとります。
    for agent in pop.agents
        agent.strategy_type = GroupRetaliation
    end

    # メインのシミュレーションループを実行します。
    # simulation_type に `:sim2` を指定し、verbose の値を渡します。
    run_simulation!(pop, num_generations, :sim2, enable_sanctioning=true, verbose=verbose)
    
    if verbose; println("--- Simulation 2 Finished ---"); end # 詳細表示が有効なら終了メッセージを出力します。
    return pop # シミュレーション後のPopulationオブジェクトを返します。
end

export run_simulation3 # この関数もモジュールの外から使えるようにします。

"""
第3シミュレーション（確率戦略と集団応報戦略が混在し、制裁行動あり）を実行します。
論文の追試を目的としています。
引数 `verbose` が `true` の場合、実行開始・終了メッセージなどをコンソールに出力します。
"""
function run_simulation3(num_agents::Int, num_generations::Int;
                         fine_amount::Float64,
                         cost_of_punishment::Float64,
                         cooperation_multiplier::Float64,
                         cost_of_cooperation::Float64,
                         mutation_rate::Float64,
                         num_trials_per_generation::Int,
                         verbose::Bool = true) # verbose引数を追加しました。

    if verbose; println("--- Running Simulation 3: Mixed Strategy, Sanctioning Enabled ---"); end # 詳細表示が有効なら開始メッセージを出力します。
    # Populationオブジェクトを、Sim3用の設定で初期化します。
    pop = Population(num_agents,
                     fine_amount=fine_amount,
                     cost_of_punishment=cost_of_punishment,
                     cooperation_multiplier=cooperation_multiplier,
                     cost_of_cooperation=cost_of_cooperation,
                     mutation_rate=mutation_rate,
                     num_trials_per_generation=num_trials_per_generation)

    initialize_population!(pop) # エージェント集団を初期化します。
    # Sim3では、最初は全員がデフォルトの戦略（通常はProbabilistic）で始まり、
    # 世代交代時の突然変異によって集団応報戦略 (GroupRetaliation) をとるエージェントが現れます。
    # そのため、ここでは `strategy_type` の初期設定は不要です (論文の記述通り)。

    # メインのシミュレーションループを実行します。
    # simulation_type に `:sim3` を指定し、verbose の値を渡します。
    run_simulation!(pop, num_generations, :sim3, enable_sanctioning=true, verbose=verbose)
    
    if verbose; println("--- Simulation 3 Finished ---"); end # 詳細表示が有効なら終了メッセージを出力します。
    return pop # シミュレーション後のPopulationオブジェクトを返します。
end

export extract_final_generation_data # この新しい関数もモジュールの外から使えるようにします。

"""
指定された Population オブジェクトから、シミュレーションの最終世代における主要な統計データを抽出します。
抽出されたデータは、名前付きタプル (NamedTuple) として返されます。
この関数は、主に論文の図1（結果のグラフ）を作成したり、結果を分析したりするために必要なデータを集めることを目的としています。
引数 `sim_type` (シミュレーションの種類) によって、特にSim3（混合戦略）における
確率戦略エージェントに関連するデータの扱い方を調整します。
"""
function extract_final_generation_data(pop::Population, sim_type::Symbol)
    num_agents = pop.num_agents # 集団のエージェント数を取得します。
    if num_agents == 0 # もしエージェントがいなければ、
        # 全ての統計値をデフォルト値 (NaN: Not a Number, または 0) に設定した名前付きタプルを返します。
        return (
            avg_coop_propensity_all = NaN,       # 全体の平均協力傾向
            avg_punishment_propensity = NaN,     # 全体の平均制裁傾向
            prop_group_retaliation = NaN,      # 集団応報戦略エージェントの割合
            avg_ret_threshold_gr = NaN,        # 集団応報戦略エージェントの平均応報閾値
            prop_probabilistic = NaN,          # 確率戦略エージェントの割合
            avg_coop_propensity_prob = NaN,    # 確率戦略エージェントの平均協力傾向
            cooperators_last_trial = 0,        # 最終試行での協力者数
            is_cooperation_achieved = false    # 協力が達成されたかどうかのフラグ
        )
    end

    total_cooperation_propensity_all = 0.0 # 全エージェントの協力傾向の合計 (全体)
    total_punishment_propensity_all = 0.0  # 全エージェントの制裁傾向の合計 (全体)
    
    count_group_retaliation_agents = 0     # 集団応報戦略のエージェント数
    total_retaliation_threshold_grp = 0.0  # 集団応報戦略エージェントの応報閾値の合計
    
    count_probabilistic_agents = 0         # 確率戦略のエージェント数
    total_cooperation_propensity_prob = 0.0 # 確率戦略エージェントの協力傾向の合計

    for agent in pop.agents # 全エージェントに対してループ処理を行います。
        total_cooperation_propensity_all += agent.cooperation_propensity
        total_punishment_propensity_all += agent.punishment_propensity
        
        if agent.strategy_type == GroupRetaliation # もし集団応報戦略なら、
            count_group_retaliation_agents += 1
            total_retaliation_threshold_grp += agent.retaliation_threshold
        elseif agent.strategy_type == Probabilistic # もし確率戦略なら、
            count_probabilistic_agents += 1
            total_cooperation_propensity_prob += agent.cooperation_propensity
        end
    end

    avg_coop_prop_all = total_cooperation_propensity_all / num_agents # 全体の平均協力傾向
    avg_pun_prop_all = total_punishment_propensity_all / num_agents   # 全体の平均制裁傾向
    
    prop_grp_ret = count_group_retaliation_agents / num_agents # 集団応報戦略エージェントの割合
    # 集団応報戦略エージェントの平均応報閾値 (該当エージェントがいれば計算)
    avg_ret_thresh_grp = count_group_retaliation_agents > 0 ? total_retaliation_threshold_grp / count_group_retaliation_agents : 0.0
    
    prop_prob = count_probabilistic_agents / num_agents # 確率戦略エージェントの割合
    avg_coop_prop_prob = 0.0 # 確率戦略エージェントの平均協力傾向 (初期値)

    if sim_type == :sim1 # 第1シミュレーションの場合 (全員が確率戦略)
        avg_coop_prop_prob = avg_coop_prop_all # 全体の平均協力傾向と同じになります。
    elseif sim_type == :sim3 && count_probabilistic_agents > 0 # 第3シミュレーションで、かつ確率戦略エージェントが存在する場合
        avg_coop_prop_prob = total_cooperation_propensity_prob / count_probabilistic_agents
    elseif sim_type == :sim2 # 第2シミュレーションの場合 (全員が集団応報戦略)
        avg_coop_prop_prob = 0.0 # 確率戦略エージェントはいないので0.0 (またはNaNなど、扱いやすい値) とします。
    else # その他の場合 (Sim3で確率戦略エージェントが0人の場合など、念のためのフォールバック)
        avg_coop_prop_prob = count_probabilistic_agents > 0 ? total_cooperation_propensity_prob / count_probabilistic_agents : 0.0
    end


    # Sim1, Sim2 の場合は、戦略の割合が明確に決まっています。
    # Sim1: 全員が確率戦略 (Probabilistic) であり、そのように初期化され、突然変異でもその戦略を維持します。
    # Sim2: 全員が集団応報戦略 (GroupRetaliation) です。
    # Sim3: どちらの戦略も取り得ます。
    if sim_type == :sim1
        prop_prob = 1.0 # 確率戦略の割合は100%
        prop_grp_ret = 0.0 # 集団応報戦略の割合は0%
        avg_ret_thresh_grp = 0.0 # 集団応報エージェントはいないので、平均閾値も0.0
    elseif sim_type == :sim2
        prop_prob = 0.0 # 確率戦略の割合は0%
        prop_grp_ret = 1.0 # 集団応報戦略の割合は100%
        avg_coop_prop_prob = 0.0 # 確率戦略エージェントはいないので、平均協力傾向も0.0
    end

    # 最終試行での協力者数は、`pop.previous_num_cooperators` に記録されています。
    # (このフィールドは各試行の終わりに更新されます)
    coop_last_trial = pop.previous_num_cooperators 
    
    # 協力が達成されたかの判定 (先行研究の定義に合わせて変更)
    # 旧: coop_achieved = avg_coop_prop_all >= 0.85 (平均協力傾向で判定)
    # 新: 最終試行の実際の協力率で判定
    actual_cooperation_rate_last_trial = (num_agents > 0) ? (coop_last_trial / num_agents) : 0.0
    coop_achieved = actual_cooperation_rate_last_trial >= 0.85

    # 抽出したデータを名前付きタプルとして返します。
    return (
        avg_coop_propensity_all = avg_coop_prop_all,
        avg_punishment_propensity = avg_pun_prop_all,
        prop_group_retaliation = prop_grp_ret,
        avg_ret_threshold_gr = avg_ret_thresh_grp,
        prop_probabilistic = prop_prob,
        avg_coop_propensity_prob = avg_coop_prop_prob,
        cooperators_last_trial = coop_last_trial,
        is_cooperation_achieved = coop_achieved
    )
end

end # module BasicSimulation の終わり 