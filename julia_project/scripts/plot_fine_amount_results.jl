using CSV
using DataFrames
using Plots

# Define the input CSV file path
# TODO: Make this configurable or an argument
const CSV_FILE_PATH = "results/fine_amount_experiment_results_20250508_013057.csv"
const OUTPUT_PLOT_PATH = "results/fine_amount_vs_cooperation.png"

function load_and_process_data(csv_path::String)
    # Check if the CSV file exists
    if !isfile(csv_path)
        error("CSV file not found at: $(csv_path)")
    end

    try
        df = CSV.read(csv_path, DataFrame)

        # Ensure required columns exist
        required_cols = ["simulation_type", "fine_amount", "is_cooperation_achieved"]
        for col in required_cols
            if !hasproperty(df, Symbol(col))
                error("CSV file is missing required column: $(col)")
            end
        end

        # Convert is_cooperation_achieved to Bool if it's not already
        if eltype(df.is_cooperation_achieved) != Bool
            try
                df.is_cooperation_achieved = map(x -> isa(x, Bool) ? x : (lowercase(string(x)) == "true"), df.is_cooperation_achieved)
            catch e
                error("Failed to convert 'is_cooperation_achieved' column to Bool: $e")
            end
        end


        # Calculate the frequency of cooperation achieved for each simulation_type and fine_amount
        # Ensure correct grouping and aggregation
        grouped_df = groupby(df, [:simulation_type, :fine_amount])
        
        # The following aggregation was causing issues.
        # It seems `combine` with a direct function on a column (like `mean(:is_cooperation_achieved)`)
        # might not work as expected if `is_cooperation_achieved` is not numeric for mean.
        # Instead, we calculate sum and count, then divide.
        agg_df = combine(grouped_df) do sdf
            DataFrame(
                cooperation_achieved_freq = sum(sdf.is_cooperation_achieved) / nrow(sdf),
                n_replications = nrow(sdf) # Keep track of replications for context
            )
        end
        
        # Sort for consistent plotting
        sort!(agg_df, [:simulation_type, :fine_amount])
        
        return agg_df
    catch e
        println("Error during CSV processing: ", e)
        rethrow(e)
    end
end

function main()
    println("Loading and processing data from: ", CSV_FILE_PATH)
    try
        processed_data = load_and_process_data(CSV_FILE_PATH)
        println("Data processed successfully:")
        println(processed_data)

        # Create the plot
        println("Generating plot...")
        plot_types = unique(processed_data.simulation_type)
        
        # Initialize plot with some common attributes
        p = plot(
            xlabel = "Fine Amount",
            ylabel = "Frequency of Cooperation Achieved",
            title = "Impact of Fine Amount on Cooperation (ref.md Fig 1 style)",
            legend = :topright, # Adjust legend position as needed (e.g., :bottomright, :outertopright)
            linewidth = 2,
            markershape = :circle,
            markerstrokewidth = 0.5,
            markersize = 4
        )

        # Define a color palette to ensure different colors for different sim_types if more than default
        # You can expand this palette if you have many simulation_types
        colors = [:blue, :red, :green, :purple, :orange, :brown]

        for (i, sim_type) in enumerate(plot_types)
            sim_data = filter(row -> row.simulation_type == sim_type, processed_data)
            if nrow(sim_data) > 0
                # Sort by fine_amount to ensure lines are drawn correctly
                sim_data = sort(sim_data, :fine_amount)
                plot!(p, sim_data.fine_amount, sim_data.cooperation_achieved_freq, 
                      label="Sim: $(sim_type)", 
                      color=colors[mod1(i, length(colors))]) # Cycle through colors
            else
                println("No data to plot for simulation_type: $(sim_type)")
            end
        end
        
        # Ensure the output directory exists
        output_dir = dirname(OUTPUT_PLOT_PATH)
        if !isdir(output_dir)
            println("Creating output directory: ", output_dir)
            mkpath(output_dir)
        end

        savefig(p, OUTPUT_PLOT_PATH)
        println("Plot saved to: ", OUTPUT_PLOT_PATH)

    catch e
        println("An error occurred in main: ", e)
        # Display stack trace for more detailed error information
        println(stacktrace(catch_backtrace()))
    end
end

# Run the main function
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end 