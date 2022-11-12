"""
Run data-rank (single-sample) GSEA.

# Arguments

  - `setting_json`:
  - `gene_x_sample_x_score_tsv`:
  - `set_genes_json`:
  - `output_directory`:
"""
@cast function data_rank(setting_json, gene_x_sample_x_score_tsv, set_genes_json, output_directory)

    ke_ar = OnePiece.Dict.read(setting_json)

    fe_x_sa_x_sc = OnePiece.Table.read(gene_x_sample_x_score_tsv)

    se_fe_ = OnePiece.Dict.read(set_genes_json)

    _filter_set!(
        se_fe_,
        ke_ar["remove_gene_set_genes"],
        fe_x_sa_x_sc[!, 1],
        ke_ar["minimum_gene_set_size"],
        ke_ar["maximum_gene_set_size"],
    )

    se_x_sa_x_en = OnePiece.FeatureSetEnrichment.score_set(
        fe_x_sa_x_sc,
        se_fe_;
        al = ke_ar["algorithm"],
        _make_keyword_argument(ke_ar)...,
    )

    OnePiece.Table.write(
        joinpath(mkpath(output_directory), "set_x_sample_x_enrichment.tsv"),
        se_x_sa_x_en,
    )

end
