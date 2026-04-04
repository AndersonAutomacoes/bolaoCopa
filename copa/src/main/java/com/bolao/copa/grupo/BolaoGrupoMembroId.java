package com.bolao.copa.grupo;

import java.io.Serializable;
import java.util.Objects;

public class BolaoGrupoMembroId implements Serializable {

    private Long bolaoId;
    private Long userId;

    protected BolaoGrupoMembroId() {
    }

    public BolaoGrupoMembroId(Long bolaoId, Long userId) {
        this.bolaoId = bolaoId;
        this.userId = userId;
    }

    public Long getBolaoId() {
        return bolaoId;
    }

    public Long getUserId() {
        return userId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        BolaoGrupoMembroId that = (BolaoGrupoMembroId) o;
        return Objects.equals(bolaoId, that.bolaoId) && Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(bolaoId, userId);
    }
}
