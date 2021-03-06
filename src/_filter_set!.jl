function _filter_set!(se_fe_, re, in_, mi, ma)

    println("Before filtering sets")

    OnePiece.dict.print(se_fe_, n_pa = 0)

    if re

        println("Removing set genes not found in gene-x-sample genes")

        for (se, fe_) in se_fe_

            se_fe_[se] = intersect(fe_, in_)

        end

    end

    println("Keeping sets: $mi <= size <= $ma")

    for (se, fe_) in se_fe_

        if !(mi <= length(fe_) <= ma)

            pop!(se_fe_, se)

        end

    end

    println("After")

    OnePiece.dict.print(se_fe_, n_pa = 0)

end
