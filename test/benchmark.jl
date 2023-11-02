using Test: @test

using Printf: @sprintf

using Nucleus

using GSEA

# ---- #

function make(di)

    if !isdir()

        mkdir(di)

    end

end

# ---- #

const DIP = joinpath(homedir(), "Desktop", "benchmark")

# ---- #

const DIJ = joinpath(DIP, "json_files")

# ---- #

const DID = joinpath(DIP, "Datasets_and_Phenotypes")

# ---- #

const DIS = joinpath(DIP, "Gene_Sets_Collections")

# ---- #

const DIR = joinpath(DIP, "results")

# ---- #

const AL_ = ("ks", "kli", "kli1", "kliom", "kliop")

# ---- #

const DIB = make(joinpath(dirname(@__DIR__), "benchmark"))

# ---- #

const TE_ = String[]

# ---- #

const PE_ = Float64[]

# ---- #

function log(te, is_, py, ju)

    if any(is_)

        pe = 100 - 100sum(is_) / size(py, 1)

        pyi = view(py, is_, :)

        jui = view(ju, is_, :)

        @warn "$te $(@sprintf "%.3g" pe)%" pyi jui

    else

        pe = 100.0

        pyi = nothing

        jui = nothing

    end

    push!(TE_, te)

    push!(PE_, pe)

    nothing

end

# ---- #

function compare(jsk, al, st, py, pyi, ju, jui)

    log("$jsk $al $st", py[!, pyi] .!= ju[!, jui], py, ju)

end

# ---- #

function compare(jsk, al, st, py, pyi, ju, jui, atol)

    log(
        "$jsk $al $st",
        .!isapprox.(
            # TODO
            (fl -> fl isa AbstractString ? parse(Float64, lstrip(fl, '≤')) : fl).(py[!, pyi]),
            ju[!, jui];
            atol,
        ),
        py,
        ju,
    )

end

# ---- #

const BA_ = Set((
    "CCLE_STAT3_vs_mRNA.json", # Number of sets differ.
    "CCLE_YAP_vs_mRNA.json", # Number of sets differ.
    "CFC1-overexpressing NGP cells.json", # Target directionalities differ.
    "CRISPR_FOXA1_vs_mRNA.json", # Number of sets differ.
    "CRISPR_NFE2L2_vs_mRNA.json", # Number of sets differ.
    "CRISPR_SOX10_vs_mRNA.json", # Number of sets differ.
    "Cyclin_D1.json", # Number of sets differ.
    "EBV_Arrested.json", # Genes are duplicates.
    "ERbeta.json", # Number of sets differ.
    "European and African American Lung Comparison.json", # Enrichments differ.
    "Gender.json", # Number of sets differ.
    "MD_C1_vs_others.json", # Enrichments differ.
    "MYC mut and wt vs RNA.json", # Enrichments differ.
    "NRF2_Liver_Cancer.json", # Number of sets differ.
    "NRF2_mouse_model.json", # Number of sets differ.
    "PI3K_Inihibtion.json", # Enrichments differ.
    "PIK3CA mut and wt vs RNA.json", # Enrichments differ.
    "Regulation of ZBTB18 in glioblastoma.json", # Target directionalities differ.
    "Stroma_senescence.json", # Genes are duplicates.
))

# ---- #

for (idb, js) in enumerate(Nucleus.Path.read(DIJ))

    if js in BA_

        continue

    end

    @info "$idb $js"

    jsk = view(js, 1:(lastindex(js) - 5))

    ke_va = Nucleus.Dict.read(joinpath(DIJ, js))[jsk]

    di = make(joinpath(DIB, Nucleus.Path.clean(jsk)))

    dii = make(joinpath(di, "input"))

    tst = joinpath(dii, "target_x_sample_x_number.tsv")

    tsf = joinpath(dii, "feature_x_sample_x_number.tsv")

    if !isfile(tst) || !isfile(tsf)

        GSEA.convert_cls_gct(tst, tsf, joinpath(DID, ke_va["cls"]), joinpath(DID, ke_va["ds"]))

    end

    jss = joinpath(dii, "set_features.json")

    if !isfile(jss)

        GSEA.convert_gmt(jss, (joinpath(DIS, gm) for gm in ke_va["gene_sets_collections"])...)

    end

    dir = joinpath(DIR, basename(ke_va["results_directory"]))

    for (al, pr, no) in
        zip(AL_, ke_va["results_files_prefix"], ke_va["standardize_genes_before_gene_sel"])

        @info al

        dio = make(joinpath(di, "output_$al"))

        txm = joinpath(dir, "$(pr)_gene_selection_scores.txt")

        txs = joinpath(dir, "$(pr)_GSEA_results_table.txt")

        tsm = joinpath(dio, "feature_x_metric_x_score.tsv")

        tss = joinpath(dio, "set_x_statistic_x_number.tsv")

        if !isfile(tsm)

            GSEA.metric_rank(
                dio,
                tst,
                tsf,
                jss;
                algorithm = al,
                normalization_dimension = Int(no),
                normalization_standard_deviation = 3.0,
                number_of_permutations = 0,
            )

            Nucleus.Path.remove(tss)

        end

        py = Nucleus.DataFrame.read(txm; select = [1, 2])

        ju = Nucleus.DataFrame.read(tsm)

        # TODO

        n_ch = 50

        py[!, 1] = Nucleus.String.limit.(py[!, 1], n_ch)

        ju[!, 1] = Nucleus.String.limit.(ju[!, 1], n_ch)

        sort!(py)

        sort!(ju)

        compare(jsk, al, "Gene", py, 1, ju, 1)

        compare(jsk, al, "Signal-to-Noise Ratio", py, 2, ju, 2, 0.00001)

        if !isfile(tss)

            GSEA.user_rank(
                dio,
                txm,
                jss;
                algorithm = al,
                permutation = joinpath(dir, "$(pr)_rand_perm_gene_scores.txt"),
            )

        end

        py = sort!(Nucleus.DataFrame.read(txs; select = [1, 5, 4, 6, 7]))

        ju = sort!(Nucleus.DataFrame.read(tss))

        compare(jsk, al, "Set", py, 1, ju, 1)

        compare(jsk, al, "Enrichment", py, 3, ju, 2, 0.01)

        compare(jsk, al, "Normalized Enrichment", py, 2, ju, 3, 0.01)

        compare(jsk, al, "P-Value", py, 4, ju, 4, 0.01)

        compare(jsk, al, "Adjusted P-Value", py, 5, ju, 5, 0.1)

    end

end

# ---- #

const ST_ = ("Enrichment", "Normalized Enrichment", "P-Value", "Adjusted P-Value")

# ---- #

for al in AL_

    is___ = (findall(endswith("$al $st"), TE_) for st in ST_)

    Nucleus.Plot.plot_bar(
        joinpath(DIB, "summary_$al.html"),
        Tuple(view(PE_, is_) for is_ in is___),
        Tuple(Nucleus.String.split_get.(view(TE_, is_), ' ', 1) for is_ in is___),
        name_ = ST_,
        layout = Dict(
            "title" => Dict("text" => al),
            "yaxis" => Dict("title" => Dict("text" => "% Match")),
        ),
    )

end
