using Test: @test

using BioLab

using GSEA

# ---- #

# ----------------------------------------------------------------------------------------------- #

const TE = BioLab.Path.make_directory(joinpath(BioLab.TE, "GSEA"))

const DA = joinpath(dirname(@__DIR__), "data")

# ---- #

const SE = joinpath(DA, "set_features.json")

# ---- #

@test BioLab.Error.@is_error GSEA._read_set(SE, Vector{String}(), 33, 36, 0)

# ---- #

const SE1_, FE11___ = GSEA._read_set(SE, unique(vcat(values(BioLab.Dict.read(SE))...)), 33, 36, 0)

@test length(SE1_) == 2

@test length(FE11___) == 2

# ---- #

const SE2_, FE12___ = GSEA._read_set(SE, ["SHH", "XIST"], 1, 5656, 0)

@test length(SE2_) == 2

@test length(FE12___) == 2

# ---- #

const TSF = joinpath(DA, "feature_x_sample_x_number.tsv")

# ---- #

@test BioLab.Error.@is_error GSEA.data_rank("", TSF, SE)

const OUD = BioLab.Path.make_directory(joinpath(TE, "data_rank"))

GSEA.data_rank(OUD, TSF, SE)

const SET_FEATURES_X_SAMPLE_X_ENRICHMENT =
    BioLab.DataFrame.read(joinpath(OUD, "set_features_x_sample_x_enrichment.tsv"))

@test size(SET_FEATURES_X_SAMPLE_X_ENRICHMENT) == (8, 10)

@test SET_FEATURES_X_SAMPLE_X_ENRICHMENT[!, "Set"] == [
    "HALLMARK_ESTROGEN_RESPONSE_LATE",
    "HALLMARK_EPITHELIAL_MESENCHYMAL_TRANSITION",
    "HALLMARK_ESTROGEN_RESPONSE_EARLY",
    "HALLMARK_KRAS_SIGNALING_DN",
    "HALLMARK_IL2_STAT5_SIGNALING",
    "HALLMARK_APICAL_JUNCTION",
    "HALLMARK_HYPOXIA",
    "HALLMARK_GLYCOLYSIS",
]

# ---- #

const TSM = joinpath(DA, "feature_x_metric_x_score.tsv")

# ---- #

@test BioLab.Error.@is_error GSEA.user_rank("", TSM, SE)

const OUU = BioLab.Path.make_directory(joinpath(TE, "user_rank"))

GSEA.user_rank(
    OUU,
    TSM,
    SE;
    number_of_sets_to_plot = 2,
    more_sets_to_plot = [
        "HALLMARK_MYC_TARGETS_V1",
        "HALLMARK_UV_RESPONSE_DN",
        "HALLMARK_UV_RESPONSE_UP",
    ],
)

const SET_X_STATISTIC_X_NUMBERU =
    BioLab.DataFrame.read(joinpath(OUU, "set_x_statistic_x_number.tsv"))

@test size(SET_X_STATISTIC_X_NUMBERU) == (50, 5)

@test length(BioLab.Path.read(OUU; ke_ = (r"html$",))) == 6

# ---- #

for (nu1_, nu2_, re) in (
    (collect(1:3), collect(10:10:30), -1.6363636363636365),
    (fill(0, 3), fill(0, 3), 0.0),
    (fill(1, 3), fill(0.001, 3), 4.990009990009989),
    (fill(0.001, 3), fill(1, 3), -4.990009990009989),
    (fill(0.001, 3), fill(10, 3), -4.999000099990002),
)

    @test GSEA._get_signal_to_noise_ratio(nu1_, nu2_) == re

    # 48.196 ns (0 allocations: 0 bytes)
    # 21.899 ns (0 allocations: 0 bytes)
    # 57.646 ns (0 allocations: 0 bytes)
    # 57.631 ns (0 allocations: 0 bytes)
    # 57.587 ns (0 allocations: 0 bytes)
    #@btime GSEA._get_signal_to_noise_ratio($nu1_, $nu2_)

end

# ---- #

const TST = joinpath(DA, "target_x_sample_x_number.tsv")

@test BioLab.Error.@is_error GSEA.metric_rank("", TST, TSF, SE)

const OUM = BioLab.Path.make_directory(joinpath(TE, "metric_rank"))

GSEA.metric_rank(OUM, TST, TSF, SE)

const FEATURE_X_METRIC_X_SCORE =
    BioLab.DataFrame.read(joinpath(OUM, "feature_x_metric_x_score.tsv"))

@test size(FEATURE_X_METRIC_X_SCORE) == (1000, 2)

@test names(FEATURE_X_METRIC_X_SCORE) == ["Feature", "signal_to_noise_ratio"]

@test isapprox(view(FEATURE_X_METRIC_X_SCORE, [1, 1000], 2), [1.7411, -1.83724]; atol = 1e-5)

const SET_X_STATISTIC_X_NUMBERM =
    BioLab.DataFrame.read(joinpath(OUM, "set_x_statistic_x_number.tsv"))

@test size(SET_X_STATISTIC_X_NUMBERM) == (8, 5)

@test length(BioLab.Path.read(OUM; ke_ = (r"html$",))) == 8

# ---- #

const OUMS = BioLab.Path.make_directory(joinpath(TE, "metric_rank_small"))

GSEA.metric_rank(
    OUMS,
    TST,
    TSF,
    joinpath(DA, "2set_features.json");
    minimum_set_size = 3,
    maximum_set_size = 3,
    number_of_sets_to_plot = 2,
)

@test length(BioLab.Path.read(OUMS; ke_ = (r"html$",))) == 2

# ---- #

include("outer_loop.jl")
